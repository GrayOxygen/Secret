+++
date = "2016-11-05T15:33:49+08:00"
description = "RabbitMQ指南(中)"
draft = true
tags = ["MQ","RabbitMQ","Tutorials"]
title = "RabbitMQ指南(中)"
topics = ["RabbitMQ"]

+++

在[上一篇文章](http://listenzhangbin.com/post/2016/10/rabbitmq-tutorials-1/)中，介绍了使用``RabbitMQ``的Hello World例子，
以及如何创建一个``work queue``。在work queue的例子中每条消息都只会被传递到一个work queue中。
在这篇文章中我们将会学习另一种完全不同的传递消息的方式——每条消息将会被传递给所有的consumer，这种模式一般被称为**"发布/订阅"**。<!--more-->

## 发布/订阅(Publish/Subscribe)

为了说明这种模式，我们将创建一个简单的log系统，它将会由两部分组成——第一部分负责发送log消息，第二部分负责接收并且将消息打印出来。
在我们的log系统中每个运行着的接收程序都会接收到消息，在这种方式下我们可以有一个consumer负责将log持久化到磁盘，
同时由另一个consumer来将log打印到控制台。本质上，发送log消息是对所有消息接收者的广播。

### Exchange

在之前的部分我们都是通过queue来发送和接收消息，现在是时候来介绍RabbitMQ完整的消息模型了。先让我们来快速地回顾一下之前介绍过的几个概念：

+ ``producer``是用户应用负责发送消息
+ ``queue``是存储消息的缓冲(buffer)
+ ``consumer``是用户应用负责接收消息

RabbitMQ的消息模型的核心思想是producer永远不会直接发送任何消息到queue中，实际上，在很多情况下producer根本不知道一条消息是否被发送到了哪个queue中。

在RabbitMQ中，producer只能将消息发送到一个``exchange``中。要理解exchange也非常简单，它一边负责接收producer发送的消息，
另一边将消息推送到queue中。exchange必须清楚的知道在收到消息之后该如何进行下一步的处理，比如是否应该将这条消息发送到某个queue中？
还是应该发送到多个queue中？还是应该直接丢弃这条消息等等。用官方文档上的一张图可以更清楚地了解RabbitMQ的消息模型。

![RabbitMQ Exchange](https://www.rabbitmq.com/img/tutorials/exchanges.png)



