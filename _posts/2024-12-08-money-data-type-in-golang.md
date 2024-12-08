---
layout: post
title: "Money Data Type in Golang"
date: "2024-12-08 00:00:00"
category: ""
image: "/assets/images/2024-12-08-money-data-type-in-golang.webp"
feature_image: true
description: ""
keywords:
  - 
  - 
comments: true
archived: true
---

It's a common knowledge that using `Float` (or `Number` in JavaScript, it is `Float64` behind the scene) to store monetary data is a bad idea. If you don't know this yet, try doing `10 / 3` in your choice of programming language. I've seen a lot of LinkedIn post ridiculing JavaScript for this.

![Dividing 10 by 3](/assets/others/floating-point-error-1.webp)

When dealing with user's balance, let's say in US Dollar, we sometimes need to deal with cent value. If a user have a balance of US$10.00 and we want to charge them 50 cent (US$0.50), they will have US$9.50 by the end of it. Doesn't look wrong, right?

But what if the user only has US$1.00 and we charge them 70 cent (US$0.70)? 

![Subtracting 0.70 from 1.00](/assets/others/floating-point-error-2.webp)

Mentally we already done the calculation and got US$0.30, but again when I tried the code in JavaScript, I got `0.30000000000000004`. Now the customer has more money than they should have.

> Huh, weird?
>
> That couldn't be right. Curse you JavaScript!

I mean, this problem can be found not only in JavaScript, but also in all programming language that uses [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754) standard. So Golang has this problem too, run [this piece of code](https://go.dev/play/p/WE25YQNwOZ5) if you don't believe me.

## Dealing with Decimal Place

> So what should we use, then?

Worry not! We have other data type.

Throughout my career, I've seen there are 2 way most developers handle this; either by using `Integer` or `String`.

When using `Integer`, we write US$1 as `100`. Notice that there is no comma separator on the value. This way every calculation can be done in `Integer`, no more floating point issue. This way, we will show `100` in API request/response and database to denote US$1.

When using `String`, we write US$1 as `"1.00"`, then we parse it to `Integer` so we get a value like the previous example, do some calculation, and make it into `String` again to be stored in the database. This way we can show `"1.00"` in the API request/response while calculating them fully in `Integer`.

To be honest, I am a bit opinionated on this money-data-type approach.

I think the `Integer` approach is great since there is no extra step necessary for parsing value, but the downside is the API consumer has to be aware that `100` means `US$1` and not `US$100`.

If you worked in backend, you know how silly it is to trust that the API consumer would have the same thought process as the API developer.

Personally, I liked the second approach where the API consumer can just pass `String` value of either `"1"` or `"1.00"` and we would still get the same `Integer` value of `100` to handle. But, I would store them as `Integer` not `String` so that parsing only happened when receiving request or before sending response.

## Enter the JSON Interface

I would use JSON for most of my API, this is the format most consumer expect to get.

In Go, there are JSON interface methods that we can override to customize the behaviour when receiving request and sending response. We will use this to eliminate the need to manually call the `String` to `Integer` parsing method everytime.

### Determining The Number of Decimal Place

Before we start, let's talk a little bit about currency.

