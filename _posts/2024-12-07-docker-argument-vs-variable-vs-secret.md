---
layout: post
title: "Building Docker Image - Argument vs Variable vs Secret"
date: "2024-12-07 00:00:00"
category: ""
image: "/assets/images/2024-12-07-docker-argument-vs-variable-vs-secret.webp"
feature_image: true
description: ""
keywords:
  - Docker
  - Container
comments: true
archived: false
---

You might be wondering how to pass a value during building a Docker image. I've been there, in fact, I am still revisiting this topic from time to time. So I want to dedicate a post about building an image with argument, variables, and secrets.

Let's start with simple Dockerfile with multiple stages:

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

The `FROM` that you saw on the example above is the stage, the first one is building the file, and the second is running the built binary.

Now let's talk about build arguments and environment variables. Build arguments in Docker is closely related to environment variables, they are written as `ARG` and `ENV`, respectively. They are used to pass information to the build process. 

## Build Arguments

The way you use `ARG` is by defining it either before the stage (a.k.a Global Scope) or inside the stage (a.k.a Local Scope). 

The benefit of using `ARG` is we can build the image in different way without editing the `Dockerfile`. 

The value of `ARG` only available during build process and will not be available when the image is running as container, unless it is explicitly passed.

I recommend to use `ARG` for configuring build. For example, to build a different version, or to use different base image.

This is an example of using `ARG` to define the base image to be used to build.

```Dockerfile
# create argument for image version
ARG GO_VERSION="1.23"

# use argmument
FROM golang:${GO_VERSION}

# rest of the file stay the same as first example
...
```

Try to build above example and you will see that it uses `golang:1.23`
```bash
docker build . -t example:latest 
```

But if you pass a different version, let's say `1.22`, it will use `golang:1.22` instead.
```bash
docker build --build-arg GO_VERSION="1.22" . -t example:latest 
```

### Without Default Value

We can also just set the argument name without defining the value. This way, the value of the argument will be empty when not provided in the build command.
```Dockerfile
# create argument without default value
ARG GO_VERSION

# use argmument
FROM golang:${GO_VERSION}

# rest of the file stay the same as first example
...
```

### Scope

If we declared `ARG` on the Global Scope and want to use them inside the stage, `ARG` have to be redeclared inside the stage to allow the stage to read the value. No need to write the value again, just the name should be enough for stage to inherit the value.

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

I recommend to use `ENV` for configuring runtime. For example, to set API endpoint, I don't recommend using it for secret value like password.

To pass environment variables during build, we will need to make use of build arguments. This is why previously I said they are closely related.

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

Now building it, environment variables will be available in the container and it can simply accessed programatically (`os.Getenv.ENV_NAME` in Go or `process.env.ENV_NAME` in Node.js).

```bash
docker build --build-arg USER="example" . -t example:latest 
```

If you are wondering on why did the `USER_NAME` called by the code in the first stage (build) but the environment value copied to the second stage (run), I got an answer for you.

It was because the first stage did not need the environment variables to be present, it will still compile. Once compiled, that binary will run on the second stage, that's where we want the environment variables to be present, hence we copied it to the second stage and not the first stage.

## Build Argument vs Environment Variables

So here's a TL;DR version of Build Arguments vs Environment Variables.

| Aspect        | Build Arguments (ARG)                             | Environment Variables (ENV)             |
| ------------- | ------------------------------------------------- | --------------------------------------- |
| Declaration   | Using `ARG` keyword                               | Using `ENV` keyword                     |
| Scope         | Can be Global or Local (stage)                    | Local (stage) only                      |
| Availability  | Only during build time (unless explicitly passed) | During build time and container runtime |
| Best Used For | Build configurations (versions, base images)      | Runtime configurations (API endpoints)  |


## Build Secret