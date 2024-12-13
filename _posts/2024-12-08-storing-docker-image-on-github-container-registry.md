---
layout: post
title: "Storing Docker Image on GitHub Container Registry"
date: "2024-12-08 00:00:00"
category: "Development"
image: "/assets/images/2024-12-08-storing-docker-image-on-github-container-registry.webp"
feature_image: true
description: "Learn how to use GitHub Actions to build Docker images and store them in GitHub Container Registry (ghcr.io). A guide to improving CI/CD workflow for private repositories without exposing source code to servers."
keywords:
  - Docker
  - GitHub
comments: true
archived: false
---

Months ago I posted about using [Shell Script for CI/CD](../shell-scripting-cicd) in a personal project in which the script includes cloning the repo locally, building the Docker image, and running it as a container right in the VPS. I know, I know. It's not ideal, and it's leaking the source code to the server, so let's redo it.

I want to focus on using GitHub Actions on a private repository to build a Docker image and store it on GitHub Container Registry ([ghcr.io](https://ghcr.io/)). It's perfect for personal projects since we can use up to 500MB total for all images on the GitHub Free plan - it's counted as GitHub Package storage usage, by the way.

What I am looking for in this round is:
- Build the Docker image on GitHub Actions.
- Push the image into GitHub Container Registry.
- Pull the image into the server.
- Run a script to start the image as container on the server.

Let's take a look at how the action looks like.

```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: {% raw %}${{ github.repository }}{% endraw %}

jobs:
  build:
    runs-on: ubuntu-latest

    # this sets permission to read repo content and push image to ghcr.io
    permissions:
      contents: read
      packages: write

    steps:
      # 1. Checkout the repository
      - name: Checkout repository
        uses: actions/checkout@v4

      # 2. Set up Go
      - name: Set up Go
        uses: actions/setup-go@v2
        with:
          go-version: '1.22'

      # 3. Install dependencies
      - name: Get dependencies
        run: |
          go get -v -t -d ./...

      # 4. Run Golang tests
      - name: Run tests
        run: go test -v ./...
        
      # 5. Login to ghcr.io
      - name: Login to the container registry
        uses: docker/login-action@v3
        with:
          registry: {% raw %}${{ env.REGISTRY }}{% endraw %}
          username: {% raw %}${{ github.actor }}{% endraw %}
          password: {% raw %}${{ secrets.GITHUB_TOKEN }}{% endraw %}
      
      # 6. Extract metadata (tags, labels) for Docker
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: {% raw %}${{ env.REGISTRY }}{% endraw %}/{% raw %}${{ env.IMAGE_NAME }}{% endraw %}

      # 7. Build and push image to ghcr.io
      - name: Build and push docker image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: {% raw %}${{ steps.meta.outputs.tags }}{% endraw %}
          labels: {% raw %}${{ steps.meta.outputs.labels }}{% endraw %}
          # you can pass build-args and secrets here
          # see https://github.com/marketplace/actions/build-and-push-docker-images

  deploy:
    # this prevent deployment when image building failed
    needs: build
    runs-on: ubuntu-latest
    steps:
    # 8. SSH to the server and run the script
    - name: executing remote ssh commands using password
      uses: appleboy/ssh-action@v1.2.0
      with:
        host: {% raw %}${{ secrets.HOST }}{% endraw %}
        username: {% raw %}${{ secrets.USERNAME }}{% endraw %}
        password: {% raw %}${{ secrets.PASSWORD }}{% endraw %}
        port: {% raw %}${{ secrets.PORT }}{% endraw %}
        script: |
          # log in to container registry
          echo "{% raw %}${{ secrets.GITHUB_TOKEN }}{% endraw %}" | docker login {% raw %}${{ env.REGISTRY }}{% endraw %} -u {% raw %}${{ github.actor }}{% endraw %} --password-stdin
          
          # pull the image
          docker pull {% raw %}${{ env.REGISTRY }}{% endraw %}/{% raw %}${{ env.IMAGE_NAME }}{% endraw %}:latest
          
          # export necessary environment variables for the script here
          # export VARIABLE_NAME=value

          # download and run deploy script using curl with auth header
          curl -H "Authorization: token {% raw %}${{ secrets.GITHUB_TOKEN }}{% endraw %}" \
               -H "Accept: application/vnd.github.v3.raw" \
               -o /vps/path/to/save/script_name.sh \
               -L "https://api.github.com/repos/{% raw %}${{ github.repository }}{% endraw %}/contents/repo/path/to/script_name.sh?ref={% raw %}${{ github.sha }}{% endraw %}"

          chmod +x /vps/path/to/save/script_name.sh
          /vps/path/to/save/script_name.sh

          # remove script after run completed
          rm -f /vps/path/to/save/script_name.sh
```

With the above changes, no more cloning is needed to build images on the server.

All the build processes happen in the pipeline, and when it's successfully built, the SSH script will log in to ghcr.io and pull the image. I chose to do Docker login before the script to prevent passing the `GITHUB_TOKEN` secret to the script.

> P.S. `GITHUB_TOKEN` is a provided secret value.
> No need to add them to the repository secret.
>
> The only thing I did was adding secrets for the ssh step.

Only the script is downloaded into the server; the rest of the source code is not. This way, the script can be safely stored in the same repository. Moreover, it's deleted from the server after the run is completed. Neat!

Just like the previous post, you can do anything inside the `script_name.sh`. The only difference would be that this time it would be simpler without the Docker build step:

```bash
#!/bin/sh

# Name for the Docker image
IMAGE_NAME="${IMAGE_NAME:-username/imagename:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-containername}"

# Check if a container with CONTAINER_NAME exists and stop/remove it
EXISTING_CONTAINER=$(docker ps -aq -f name="$CONTAINER_NAME")
if [ ! -z "$EXISTING_CONTAINER" ]; then
    echo "Stopping and removing existing container with name $CONTAINER_NAME..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Run Docker container
echo "Running Docker container..."
docker run -d --restart always --name $CONTAINER_NAME $IMAGE_NAME

echo "Docker container started."

```

Finally, you might be wondering whether GitHub has a dashboard for your images like what [DockerHub](https://hub.docker.com/) does. Worry not! You can go to [https://github.com/username?tab=packages](https://github.com/username?tab=packages) (change it to your username) to see a list of images you have stored in ghcr.io.

---

Photo by <a href="https://unsplash.com/@richygreat?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Richy Great on Unsplash</a>
      