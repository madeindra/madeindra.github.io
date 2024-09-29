---
layout: post
title: "Shell Script for CI/CD"
date: "2024-09-29 00:00:00"
category: "Project"
image: "/assets/images/2024-09-29-shell-scripting-cicd.webp"
feature_image: true
description: "A hobbyist's guide to simple CI/CD using shell scripts. Covers automating tasks, building Docker images, and deploying containers on a VPS with GitHub Actions."
keywords:
  - Shell
  - Script
  - Automation
comments: true
archived: false
---

In professional settings, code deployment typically involves a CI/CD process that runs in a pipeline. This process ensures everything is in order before updating the deployment on the cloud.

To put it simply, it usually consist of:
- A codebase stored in a repository
- A repository pipeline (e.g. automated testing, building, and deployment)
- A cloud server

---

A few months ago, I wanted to replicate that process for my hobbyist project. The lower the cost, the better.

I already had a VPS ready and my code was already stored in GitHub. 

My goals were to:
- Run automated tasks on commit / merge to the `main` branch.
- Build a private docker image from the code
- Replace the current running container with the new image

It was pretty simple.

I didn't want to use IaC tool like Terraform, that would be overkill. Instead, I opt for Shell Scripts, I know this will suffice my needs.

Since this project is private, I wanted my docker image to be stored in a private Docker repository. Unfortunately, my docker account isn't a Pro account, I needed two private Docker repositories (for backend & frontend).

> Please don't judge me.
> 
> Back then, I had yet to realize that there are several alternatives to Docker Hub

![Oh no! Anyway]({{ site.url }}/assets/gifs/oh-no-anyway.webp)

I thought to myself, "I might as well clone the repo on the server and build it there".

I know, I know. It's not the most ideal solution, but it works.

So I put the script inside the repo, cloned the repo on the server, and designed a pipeline to run the script. The script essentially does the following:
1. Stashes all changes on the local. This is to make sure all uncommited change won't block the git pull.
2. Pulls the latest changes.
3. Builds docker image without cache.
4. Stops the existing container.
5. Reruns the container with the latest image.
6. Connects the container to the docker network.

To achieve this, I needed to create a GitHub Personal Access Token to read the repo and set the token as a secret on the pipeline.

Here's the preview of the script:

```
#!/bin/sh

# Set variables
DOCKER_IMAGE_NAME="your-image-name"
DOCKER_CONTAINER_NAME="your-container-name"
DOCKER_NETWORK_NAME="your-network-name"

# 1. Stash all changes on the local
git stash

# 2. Pull the latest changes
git pull

# 3. Build docker image without cache
docker build --no-cache -t $DOCKER_IMAGE_NAME .

# 4. Stop the existing container
docker stop $DOCKER_CONTAINER_NAME

# 5. Remove the existing container
docker rm $DOCKER_CONTAINER_NAME

# 6. Rerun the container with the latest image
docker run -d --name $DOCKER_CONTAINER_NAME $DOCKER_IMAGE_NAME

# 7. Connect the container to the docker network
docker network connect $DOCKER_NETWORK_NAME $DOCKER_CONTAINER_NAME
```

As for the GitHub Action to run the pipeline, it:
1. Checks out the repo.
2. Sets up programming language.
3. Sets up dependencies of automated taskss.
4. Runs automated task (e.g tests); if they pass, it continues to the next step.
5. SSHs to the server. I used [SSH Remote Command by appleboy](https://github.com/marketplace/actions/ssh-remote-commands). Then, on the ssh, mount the directory and run the script.

I needed to set the SSH credentials as secrets on the pipeline as well. However, I considered the 4th step less than ideal because if I need to move the directory, I'll have to modify the GitHub Action script.

Here's the preview of the script:
```
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
    # 1. Checkout the repository
    - name: Checkout repository
      uses: actions/checkout@v2

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
      
    # 5. SSH to the server and run the script
    - name: Deploy to server
      uses: appleboy/ssh-action@master
      with:
        host: {% raw %}${{ secrets.SERVER_HOST }}{% endraw %}
        username: {% raw %}${{ secrets.SERVER_USERNAME }}{% endraw %}
        key: {% raw %}${{ secrets.SERVER_SSH_KEY }}{% endraw %}
        script: |
          cd /path/to/your/project
          ./script_name.sh
```

One more thing, I wanted to automate database backup. This was still possible with the good ol' Shell Script with the help of Cron.

I just went and open cron on the server:

```
crontab -e
```

Then set the script to run every Sunday midnight:
```
0 0 * * SUN BASH_ENV=/root/.bashrc /path/to/script.sh >> /path/to/script_log.log 2>&1
```

See [crontab.guru](https://crontab.guru/) if you want to learn about other format for cron job.

---

In the future, I'd like to simplify this workflow. Not having to build on the server would be a boon. I've discovered that I can publish docker image for free to [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

I have successfully built the docker image and pushed it to ghcr.io on the pipeline. The next step is to prepare a script to pull the image and run it on the server. Maybe I will write another about this in the future. (｡•̀ᴗ-)✧