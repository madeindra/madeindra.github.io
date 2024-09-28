---
layout: post
title: "AI for Mock Interview"
date: "2024-09-21 00:00:00"
category: "Work"
image: "/assets/images/2024-09-28-ai-for-mock-interview.webp"
feature_image: true
description: "My journey on porting a AI-powered web app for developer interview prep into a desktop app that can be run by anyone on their laptop. Here I will share with you about the fun and challenges I faced during the process."
keywords:
  - Wails
  - Golang
  - React
comments: true
archived: false
---

So, several months ago I created a fullstack web app to assist people in preparing for developer job interview using AI.

I started simple because the project was intended for beginner to follow. Then, my significant other challenged me to make the app accessible for roles other than developer.

## Starting as Web Application

The whole idea of the app is straightforward yet powerful: users record their voice and the AI responds with questions in both voice and text format. 

If you are interested, you can find the [Mock Interview app on GitHub](https://github.com/madeindra/mock-interview).

On the frontend, I made use of MediaStream API to capture voice recordings and pass them to the backend. Later, the frontend will play the audio and show the text that came in the response. When I started, it was a vanilla JavaScript, but later I rewrote it into TypeScript with React.

Meanwhile, the backend was built with Golang, serving as API interface with OpenAI's API. The process follows these steps:

1. Transcribe the voice recording into text
2. Pass the transcript to the chat API to get generate a question
3. Convert the text question into voice

When I need to make this app available for non-developer job interview, it was just a matter of updating the prompt with no change necessary to the backend or the frontend code.

## Porting to Desktop App

With the app running well on my laptop, the next challenge was making it accessible over the internet to specific users.

I can just deploy the app on a VPS, but I didn't have a proper authentication and authorization process in place.

It would be bothersome for me to start coding it back then. I mean, I need to create a user tables in the database, thinking about a secure way to store the password hashing key, or even integrating with social login to make OAuth possible.

I asked myself whether I should rewrite the app into Electron app, but I would need to rewrite the whole backend, ouch!

This is where [Wails](https://wails.io) came to my rescue.

I don't need to rewrite my backend and frontend, just use the existing one with minimal changes, and voila!

The process was surprisingly straightforward:

1. Changed the api handler functions into Wails app method.
2. Replaced the `fetch` call with the Wails-translated runtime functions.
3. Replaced unsupported browser function (e.g `windows.alert`) with Wails desktop equivalents.

That's it, it was pretty easy too.

See the [Desktop Port of the Interview App on GitHub](https://github.com/madeindra/interview-app), if you are interested. 

One significant problem I faced was ensuring the MediaStream API available withing the Wails environment. This API is exposed through `Navigator.mediaDevices`, which available only if the web is accessed in secure context( e.g `http://`, `http`, `localhost`, etc). I was sure that Wails appp access through `wails://` that should be a secure context.

Moreover, the problem with `Navigator.mediaDevices` not being available was not consistent, sometimes it was `undefined`, other time it was not.

Turns out I need to make a proper policy change on the `.plist` for Mac use.

## Lessons Learned

For a long time I take Browser APIs for granted, a lot of the functionalities I usually use (e.g. image, video, and audio capture) come bundled with the browser and are easily accessible through JavaScript.

When they are not available, I will be forced to interact directly with the OS. Making that work across Windows; Mac; and Linux at the same time won't be fun.