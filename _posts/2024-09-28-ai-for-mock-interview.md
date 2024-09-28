---
layout: post
title: "AI for Mock Interview"
date: "2024-09-21 00:00:00"
category: "Work"
image: "/assets/images/2024-09-28-ai-for-mock-interview.webp"
feature_image: true
description: ""
keywords:
  - Wails
  - Golang
  - React
comments: true
archived: false
---

So, several months ago I created a fullstack web app to help people learn about the developer job interview using AI.

I started simple because the project was intended for beginner to follow. Then, my significant other asked me whether the app can be used to learn about interview for job other than developer.

## Web Application

So the idea of the app is to record a voice and you will get the AI to ask questions in both voice and text. 

You are free to check the [Mock Interview app on GitHub](https://github.com/madeindra/mock-interview).

On the frontend, I made use of MediaStream API to record voice and pass it to the backend. Later the frontend just need to play the audio and show the text that came in the response. When I started, it was a vanilla JavaScript, but later I rewrote it into TypeScript in React.

Meanwhile, on the backend it was a simple Golang api calling for OpenAI API in these step:
- Transcribe the voice into text
- Pass the transcript to chat API to get answer
- Turn the text into voice

When I need to make this app available for non-developer job interview, it was just a matter of updating the prompt. No change necessary from the backend or the frontend.

## Desktop App

So when the app is done, I can run it on my laptop, but the question is how let this app accessible from internet by specific people.

I can just deploy the app on a VPS, but I didn't code a proper authentication.

It would be bothersome for me to start coding authorization, I mean I need to create a specific table for user, thinking about a secure way to store the password hashing key, or even integrating with social login to make OAuth possible.

I asked myself whether I should rewrite the app into Electron app, but I would need to rewrite the whole backend, ouch!

This is where [Wails](https://wails.io) came in.

I don't need to rewrite my backend and frontend, just use the existing one, made several changes, and voila!

Here's several things that I need to update to make my backend and frontend into a desktop app:
- Changed the api handler functions into Wails' app method.
- Call the method using the runtime functions Wails translated.
- Replace unsupported browser function e.g `windows.alert` with Wails desktop function

That's it, it was pretty easy.

One problem I faced was making the MediaStream API available on the Wails. That  API was exposed through `Navigator.mediaDevices` which is available only if the web is accessed through secure context e.g `http://`, `http`, `localhost`, etc. I was sure that Wails appp access through `wails://` that should be alse a secure context.

Moreover, the problem with `Navigator.mediaDevices` not being available was not consistent, sometimes it was `undefined`, other time it was not.

Turns out I need to make a proper policy change on the `.plist` for Mac use.

See the [Desktop Port of the Interview App on GitHub](https://github.com/madeindra/interview-app) if you are interested on the details. 

## The Challenges

For a long time I take Browser APIs for granted, a lot of the functionalities (image, video, audio capture) are bundled in the browser and can be access through JavaScript.

When it is not available, I was forced to handle the process by interacting directly with the OS, and making that work accross Windows; Mac; and Linux at the same time won't be fun.