---
layout: post
title: "Docker Argument vs Variable vs Secret"
date: "2024-12-07 00:00:00"
category: "Development"
image: "/assets/images/2024-12-07-docker-argument-vs-variable-vs-secret.webp"
feature_image: true
description: "Learn the differences between Docker build arguments, environment variables, and build secrets. Understand when and how to use each for configuring your Docker builds and containers."
keywords:
  - Docker
  - Container
comments: true
archived: false
---

You might be wondering how to pass a value while building a Docker image. I've been there; in fact, I still revisit this topic from time to time. So I want to dedicate a post to building an image with arguments, variables, and secrets.

Let's start with a simple Dockerfile with multiple stages:

```Dockerfile
FROM golang:1.23
WORKDIR /src
COPY <<EOF ./main.go
package main

import "fmt"

func main() {
  fmt.Println("hello, world")
}
EOF
RUN go build -o /bin/hello ./main.go

FROM scratch
COPY --from=0 /bin/hello /bin/hello
CMD ["/bin/hello"]
```

The `FROM` statements you saw in the example above define stages. The first one builds the file, and the second runs the built binary.

Now let's talk about build arguments and environment variables. Build arguments in Docker are closely related to environment variables; they are written as `ARG` and `ENV`, respectively. They are used to pass information to the build process. 

## Build Arguments

The way you use `ARG` is by defining it either before the stage (a.k.a Global Scope) or inside the stage (a.k.a Local Scope). 

The benefit of using `ARG` is we can build the image in different way without editing the `Dockerfile`. 

The value of `ARG` is only available during the build process and will not be available when the image is running as a container, unless it is explicitly passed.

I recommend using `ARG` for configuring builds. For example, to build a different version, or to use different base image.

This is an example of using `ARG` to define the base image to be used for the build.

```Dockerfile
# create argument for image version
ARG GO_VERSION="1.23"

# use argmument
FROM golang:${GO_VERSION}

# rest of the file stay the same as first example
...
```

Try to build the example above, and you will see that it uses `golang:1.23`
```bash
docker build -t example:latest .
```

But if you pass a different version, let's say `1.22`, it will use `golang:1.22` instead.
```bash
docker build --build-arg GO_VERSION="1.22" -t example:latest .
```

### Without Default Value

We can also just set the argument name without defining the value. This way, the value of the argument will be empty if not provided in the build command.
```Dockerfile
# create argument without default value
ARG GO_VERSION

# use argmument
FROM golang:${GO_VERSION}

# rest of the file stay the same as first example
...
```

### Scope

If we declare `ARG` in the global scope and want to use it inside a stage, `ARG` has to be redeclared inside the stage to allow the stage to read the value. There's no need to write the value again; just the name is enough for the stage to inherit the value.

This version will not work

```Dockerfile
ARG MESSAGE="helo, world"

FROM golang:1.23
WORKDIR /src
# this will fail
COPY <<EOF ./main.go
package main

import "fmt"

func main() {
  fmt.Println("${MESSAGE}")
}
EOF
RUN go build -o /bin/hello ./main.go

# rest of the file stay the same as first example
...
```

With redeclaration, it now works perfectly.

```Dockerfile
ARG MESSAGE="helo, world"

FROM golang:1.23
# inherit the arg from global scope
ARG MESSAGE 
WORKDIR /src
COPY <<EOF ./main.go
package main

import "fmt"

func main() {
  fmt.Println("${MESSAGE}")
}
EOF
RUN go build -o /bin/hello ./main.go

# rest of the file stay the same as first example
...
```

## Environment Variables

The way you use `ENV` is by defining it inside the stage (a.k.a Local Scope). 

The benefit of using `ENV` is we can configure the way our container run. 

The value of `ENV` available during build process and when the image is running as container.

I recommend using `ENV` for configuring runtime. For example, to set API endpoints. I don't recommend using it for sensitive values like passwords.

To pass environment variables during build, we need to use build arguments. This is why I previously said they are closely related.

```Dockerfile
ARG USER

FROM golang:1.23
WORKDIR /src
COPY <<EOF ./main.go
package main

import (
  "fmt"
  "os"
)

func main() {
  fmt.Println("Hello", os.Getenv("USER_NAME"))
}
EOF
RUN go build -o /bin/hello ./main.go

FROM scratch
# inherit & copy the arg from global scope
ARG USER 
ENV USER_NAME=${USER}
COPY --from=0 /bin/hello /bin/hello
CMD ["/bin/hello"]
```

Now, after building it, the environment variables will be available in the container, and they can be accessed programmatically (`os.Getenv("ENV_NAME")` in Go or `process.env.ENV_NAME` in Node.js).

```bash
docker build --build-arg USER="example" -t example:latest .
```

If you are wondering why the `USER_NAME` is called by the code in the first stage (build), but the environment variable is copied to the second stage (run), I have an answer for you.

This is because the first stage does not need the environment variables to be present; it will still compile. Once compiled, the binary runs in the second stage, which is where we want the environment variables to be present. Hence, we copied them to the second stage and not the first stage.

## Build Argument vs Environment Variables

So here's a TL;DR version of Build Arguments vs Environment Variables.

| Aspect        | Build Arguments (ARG)                             | Environment Variables (ENV)             |
| ------------- | ------------------------------------------------- | --------------------------------------- |
| Declaration   | Using `ARG` keyword                               | Using `ENV` keyword                     |
| Scope         | Can be Global or Local (stage)                    | Local (stage) only                      |
| Availability  | Only during build time (unless explicitly passed) | During build time and container runtime |
| Best Used For | Build configurations (versions, base images)      | Runtime configurations (API endpoints)  |


## Build Secrets

Why would there be build secrets when build arguments and environment variables already exist?

Well, they are for storing sensitive information like passwords or API keys. By using build secrets, the sensitive information will not be exposed.

Let's take an example of passing an API key when building a frontend app in JavaScript:

```Dockerfile
ARG SECRET_API_KEY

FROM node:20 as build

WORKDIR /app
COPY package*.json ./

RUN npm install
COPY . .
ARG SECRET_API_KEY
RUN SECRET_API_KEY=${SECRET_API_KEY} \
    npm run build

FROM node:20
RUN npm install -g serve
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["serve", "-s", "dist", "-l", "3000"]
```

And build it by passing the secret using an argument:

```bash
docker build --build-arg SECRET_API_KEY="example" -t example:latest .
```

Yeah, it did work with build arguments, and even if we pass that argument to an environment variable before using it in the build, it will still work.

The problem is we are leaking sensitive information. Docker will also print a warning message about this.

Let's change the implementation to use build secrets.

```Dockerfile
FROM node:20-alpine AS build

WORKDIR /app
COPY package*.json ./

RUN npm install
COPY . .
RUN --mount=type=secret,id=SECRET_API_KEY \
    SECRET_API_KEY=$(cat /run/secrets/SECRET_API_KEY) \
    npm run build

FROM node:20-alpine
RUN npm install -g serve
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["serve", "-s", "dist", "-l", "3000"]
```

We will also change the build command and add the environment variable to the shell before executing the build command:

```
export SECRET_API_KEY=example
docker build --secret id=SECRET_API_KEY -t example:latest .
```

No more warning messages, and we successfully pass the secret to the build. Yay!

## Environment Variables vs Build Secrets

So here's a TL;DR version of Environment Variables vs Build Secrets.

| Aspect         | Environment Variables (ENV)            | Build Secrets                          |
| -------------- | -------------------------------------- | -------------------------------------- |
| Declaration    | Using `ENV` keyword                    | Using `--mount=type=secret`            |
| Visibility     | Visible in image history and container | Not visible in image history           |
| Security Level | Lower (plaintext)                      | Higher (secure during build)           |
| Best Used For  | Non-sensitive configuration            | Sensitive data (API keys, credentials) |
