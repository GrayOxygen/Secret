+++
date = "2016-11-05T15:33:49+08:00"
description = "RabbitMQ指南(中)"
draft = false
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

RabbitMQ中的exchange类型有这么几种：``direct``，``topic`，``headers``以及``fanout``。这一小节将会主要介绍最后一种类型——``fanout`。
使用RabbitMQ的client来创建一个``fanout``类型的exchange，命令为``logs``：

```java
channel.exchangeDeclare("logs","fanout");
```

fanout类型的exchange非常简单，从名字也可以猜测出来，它会向所有的queue广播所有收到的消息。这正是我们的log系统需要的。

在之前的部分我们对exchange一无所知，但是我们仍然可以将消息发送到queue中，这是因为我们使用了默认的exchange，在代码中使用空字符串("")表示。

```java
channel.basicPublish("", "hello", null, message.getBytes());
```

第一个参数表示exchange的名字，使用空字符串表示使用默认的无名的exchange：如果有的话，消息将根据``routingKey``被发送到指定的queue中。

现在，可以将消息发送到之前已经声明过的exchange中

```java
channel.basicPublish( "logs", "", null, message.getBytes());
```

### 临时队列

在之前的小节中使用queue都是指定了名字的(hello和task_queue)，给queue命名是非常重要的，因为我们需要将的workers指定到相同的queue上，
并且在consumer与producer之间也需要指定相同的queue。

但是这对我们的log系统来说不是必须的，我们需要监听所有的log消息，而不是其中的一部分。我们也只关心现在的消息而不关注以前的消息，
为了解决这个问题我们需要做两件事情。

首先，无论何时连接到RabbitMQ server上都需要一个新的、空的queue。为了做到这一点需要能够使用一个随机的名字来创建queue，
更好的方式是由server来为我们选择一个随机的名字。

其次，一旦我们与consumer断开连接，queue应该被自动删除。

在Java client中，提供了一个无参数的``queueDeclare()``方来来创建一个非持久化的、独有的并且是自动删除的已命名的queue。

```java
String queueName = channel.queueDeclare().getQueue();
```

``queueName``会包含一个随机的queue名字，可能看起来类似``amq.gen-JzTY20BRgKO-HjmUJj0wLg``。

### 绑定

![binding](https://www.rabbitmq.com/img/tutorials/bindings.png)

我们已经创建了一个fanout类型的exchange和一个queue。现在我们需要告诉exchange将消息发送到我们的queue中。
这种exchange和queue的关系称为绑定(``binding``)。

```java
channel.queueBind(queueName, "logs", "");
```

之后logs exchange将会把消息发送到我们的queue中。


完整的``EmitLog.java``代码

```java
public class EmitLog {

    private static final String EXCHANGE_NAME = "logs";

    public static void main(String[] argv)
                  throws java.io.IOException {

        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();

        channel.exchangeDeclare(EXCHANGE_NAME, "fanout");

        String message = getMessage(argv);

        channel.basicPublish(EXCHANGE_NAME, "", null, message.getBytes());
        System.out.println(" [x] Sent '" + message + "'");

        channel.close();
        connection.close();
    }
    //...
}
```

可以看到，在创建连接之后声明exchange。这一步是必要的，因为将消息发送到一个不存在的exchange是被禁止的。

如果还没有queue被绑定到exchange上，那么消息将会丢失，但这对我们来说是可以接收的，如果没有consumer正在监听消息，
那么可以安全的丢弃这些消息。

完整的``ReceiveLogs.java``代码

```java
public class ReceiveLogs {
  private static final String EXCHANGE_NAME = "logs";

  public static void main(String[] argv) throws Exception {
    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    Connection connection = factory.newConnection();
    Channel channel = connection.createChannel();

    channel.exchangeDeclare(EXCHANGE_NAME, "fanout");
    String queueName = channel.queueDeclare().getQueue();
    channel.queueBind(queueName, EXCHANGE_NAME, "");

    System.out.println(" [*] Waiting for messages. To exit press CTRL+C");

    Consumer consumer = new DefaultConsumer(channel) {
      @Override
      public void handleDelivery(String consumerTag, Envelope envelope,
                                 AMQP.BasicProperties properties, byte[] body) throws IOException {
        String message = new String(body, "UTF-8");
        System.out.println(" [x] Received '" + message + "'");
      }
    };
    channel.basicConsume(queueName, true, consumer);
  }
}
```

## Routing

在上一小节中我们构建了一个简单的log系统，可以向许多接收者广播消息。在这一小节中我们将会对此增加一个特性——可以只订阅消息的一部分。
举例来说，可以只将critical级别的错误日志持久化到磁盘，同时又能够将所有的消息打印到控制台。

### 绑定(binds)

在前一小节中已经介绍了如何创建绑定

```java
channel.queueBind(queueName, EXCHANGE_NAME, "");
```

绑定是exchange和queue之间的一种关系，这可以简单的理解为：这个queue对这个exchange中的消息感兴趣。

绑定可以使用一个额外的``routingKey``参数，为了避免和``basic_publish``参数混淆，我们称它为``binding key`。
我们可以这样来使用key创建一个绑定:

```java
channel.queueBind(queueName, EXCHANGE_NAME, "black");
```

binding key的含义取决于不同的exchange类型，我们之前使用的fanout类型会直接忽略这个值。

### Direct exchange

我们之前的log消息系统将所有的消息广播到所有的consumer中。我们需要对此进行扩展，允许根据log的级别进行消息的过滤。
之前使用的fanout类型的exchange，没有提供给我们类似的灵活性——它只能简单的广播所有的消息。

在这里将会使用direct类型的exchange作为代替。direct类型的exchange的路由算法很简单——消息将会被传递到与它的``routing key``完全相同的
```binding key``的queue中。

还是使用一张图来说明：

![Routing](https://www.rabbitmq.com/img/tutorials/direct-exchange.png)

在图中可以看到，有两个queue被绑定到了direct类型的exchange X上。第一个queue使用bing key ``orange``绑定，第二个queue使用了两个bing key，
分别为``black``和``green``。

在这样的情况下，使用routing key为``orange``发送的消息将会被路由到queue ``Q1``中，使用routing key为``black``或者``green``的将会被路由到``Q2``中。
所有其他的消息将会被丢弃。

### 多重绑定(Multiple bindings)

![Multiple bindings](https://www.rabbitmq.com/img/tutorials/direct-exchange-multiple.png)

将多个queue使用相同的binding key进行绑定也是可行的。在我们的例子中可以在X和Q1中间增加一个binding key ``black`。
在这种情况下，direct类型的exchange的行为将和fanout类似，它会向所有匹配的queue进行广播，使用routing key为``black``发送的消息将会同时被``Q1``和``Q2``接收。

### 发送log

我们将会为log系统使用这种模型。使用direct类型的exchange代替fanout。我们将会通过routing key提供log的严重级别。
使用这种方式可以选择不同的log严重级别来接收消息。首先来看发送log的部分。

创建一个exchange：

```java
channel.exchangeDeclare(EXCHANGE_NAME, "direct");
```

已经准备好发送消息：

```java
channel.basicPublish(EXCHANGE_NAME, severity, null, message.getBytes());
```

为了简单起见，我们假设日志的级别只会为'info，'warning'，'error'三者中的一个。

### 订阅

接受消息部分将会和上一小节相同，除了一个例外——我们将会为每个感兴趣的严重级别创建新的绑定。

```java
String queueName = channel.queueDeclare().getQueue();

for(String severity : argv){
  channel.queueBind(queueName, EXCHANGE_NAME, severity);
}
```

完整的``EmitLogDirect.java``代码

```java
public class EmitLogDirect {

    private static final String EXCHANGE_NAME = "direct_logs";

    public static void main(String[] argv)
                  throws java.io.IOException {

        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();

        channel.exchangeDeclare(EXCHANGE_NAME, "direct");

        String severity = getSeverity(argv);
        String message = getMessage(argv);

        channel.basicPublish(EXCHANGE_NAME, severity, null, message.getBytes());
        System.out.println(" [x] Sent '" + severity + "':'" + message + "'");

        channel.close();
        connection.close();
    }
    //..
}
```

完整的``ReceiveLogsDirect.java``代码

```java
public class ReceiveLogsDirect {

  private static final String EXCHANGE_NAME = "direct_logs";

  public static void main(String[] argv) throws Exception {
    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    Connection connection = factory.newConnection();
    Channel channel = connection.createChannel();

    channel.exchangeDeclare(EXCHANGE_NAME, "direct");
    String queueName = channel.queueDeclare().getQueue();

    if (argv.length < 1){
      System.err.println("Usage: ReceiveLogsDirect [info] [warning] [error]");
      System.exit(1);
    }

    for(String severity : argv){
      channel.queueBind(queueName, EXCHANGE_NAME, severity);
    }
    System.out.println(" [*] Waiting for messages. To exit press CTRL+C");

    Consumer consumer = new DefaultConsumer(channel) {
      @Override
      public void handleDelivery(String consumerTag, Envelope envelope,
                                 AMQP.BasicProperties properties, byte[] body) throws IOException {
        String message = new String(body, "UTF-8");
        System.out.println(" [x] Received '" + envelope.getRoutingKey() + "':'" + message + "'");
      }
    };
    channel.basicConsume(queueName, true, consumer);
  }
}
```

可以在命令行中传入感兴趣的日志的严重级别来绑定。