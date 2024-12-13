---
layout: post
title: "Learning about Microservice"
date: "2020-02-23 07:00:00"
category: "Project"
description: "Is microservice architecture the solution that fits all needs?"
keywords:
  - Project
  - Microservice
  - CodeIgniter
  - PHP
comments: true
archived: false
---

Earlier in 2020, I got a project assignment to create an example app for an e-commerce application. I was tasked to code in PHP CodeIgniter3 & MariaDB as the database.

The app was planned to have 3 specific classes: Financial, Warehouse, and Order. The Warehouse class would handle item-related functions, the Financial class would handle invoice and payment-related functions, and the Order class would handle user orders.

A simple operation for ordering an item in the app goes like this:

![Monolithic-Architecture](/assets/others/monolithic-poc.png)

**Start: User confirms an order**

1. Order class creates the order in the database.
2. Order class calls the Financial class to generate an invoice.
3. Financial class creates the invoice in the database.
4. Financial class passes the invoice to the Order class.
5. Order class calls the Warehouse class to check item availability.
6. Warehouse class fetches the item's stock data from the database.
7. Warehouse class passes the item data to the Order class.

**End: User is ready to pay for the order**

After completing this step, I was tasked to decouple the classes and move the three classes to their own services.

By "service", it means the class will run on its own server instance and its own database instance, thus making them unable to call each other like in the previous model.

This raises a question: how could they communicate?

One solution is to call the function using an API, but this is not desired because it will cause the service to go through external means of communication. The idea of decoupling was to let the services communicate with each other without using external means of communication.

**Enter Microservice**

At this point, I reached an answer: it was to add another dependency that will pass a message to each service.

The choice was to use either RabbitMQ or Kafka, and for this project, I chose RabbitMQ.

By using RabbitMQ's AMQP communication protocol, each service will pass a message to RabbitMQ, and RabbitMQ will send the message to the designated service. After the service receives the message, the service will run a function according to the message and create another message to the service that sent the message before.

Ordering an item in the app goes like this:

![Microservice-Architecture](/assets/others/microservice-poc.png)

**Start: User confirms an order**

1: Order Service fetches the Order Detail of (orderId 1), Order Service gets (productId 1, quantity 10) details.

2: Order Service passes (orderId 1, productId 1, quantity 10) to Order Worker to create an invoice and to check if the product is in stock.

3: Order Worker sends a message (orderId 1, productId 1, quantity 10) to Exchange 1.

4a, 4b: Exchange 1 receives the message (orderId 1, productId 1, quantity 10), as it is a Direct Exchange, it forwards the message to Subscribing Queue(s).

5a: Financial Worker receives a message (orderId 1, productId 1, quantity 10), then Financial Worker passes the message to Financial Service to be processed.

5b: Warehouse Worker receives a message (orderId 1, productId 1, quantity 10), then Warehouse Worker passes only (productId 1, quantity 10) to Warehouse Service to be checked.

6a: Financial Service creates an Invoice based on the message (orderId 1, productId 1, quantity 10).

6b: Warehouse Service prepares a query to check stock based on productId 1.

7a: Financial Service successfully creates the Invoice in the Financial Database.

7b: Warehouse Service fetches stock from the Warehouse Database.

8a: Financial Service tells Financial Worker that it has created the Invoice.

8b: Warehouse Service gets information (stock 50) and compares it to quantity 10. Because (stock > quantity), the order can be processed. It sends (productId 1, quantity 10, inStock true) to Warehouse Worker.

9: Warehouse Worker sends a message (productId 1, quantity 10, inStock true) to Financial Queue.

10: Financial Worker receives a message (productId 1, quantity 10, inStock true) stored in the Financial Queue.

11: Financial Worker then passes the message to Financial Service to be processed.

12: Financial Service updates the Invoice status.

13: Financial Service tells Financial Worker that it has updated the Invoice.

14: Financial Worker sends a message (productId 1, quantity 10, invoice true) to Exchange 2.

15a, 15b: Exchange 2 receives a message (productId 1, quantity 10, invoice true), as it is a Direct Exchange, it forwards the message to Subscribing Queue(s).

16a: Order Worker receives a message (productId 1, quantity 10, invoice true), then Order Worker passes the message to Order Service to be processed.

16b: Warehouse Worker receives a message (productId 1, quantity 10, invoice true), then Warehouse Worker passes the message to Warehouse Service to be processed.

17a: Order Worker completes the user's check-out process.

17b: Warehouse Service prepares a query to decrease the product's stock based on the message (productId 1, quantity 10, invoice true).

18: Warehouse Service decreases the stock of the product in the Warehouse Database.

19: Warehouse Service tells Warehouse Worker that it has updated the Stock.

**End: User is ready to pay for the order**

It got really complicated for a simple operation, right?

But this approach makes it easier to maintain a single service. A different team can work on a different service at the same time. But in my experience, this made it harder to debug.

Oh right, you must have noticed the **worker** in the picture. This worker is created by making a single `.php` file that runs using a terminal.

**Why was a worker needed?**

For this approach, the PHP code needs to process the user command and send a message to RabbitMQ, but if the code waits for the RabbitMQ message to be sent before continuing the process, it could take a long time. Thus, it needs to be run asynchronously.

At the time, I was unable to find another approach other than using a worker because PHP can't run code asynchronously. So, the worker needs to run separately from the app. To do this, I run it using a terminal command.

This was how I learned about microservices. For those who are interested in following my approach, you can take a look at <a href="https://github.com/madeindra/codeigniter-microservice">Microservice in CodeIgniter 3 (proof-of-concept)</a> on my Github.

This is by no means the best approach to microservices. There's a lot to improve and there might be a wrong step in doing microservices.
