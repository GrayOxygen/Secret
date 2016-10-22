+++
date = "2016-10-22T15:21:40+08:00"
description = "RabbitMQ指南(上)"
draft = false
tags = ["MQ","RabbitMQ","Tutorials"]
title = "RabbitMQ指南(上)"
topics = ["RabbitMQ"]

+++

RabbitMQ是一个消息中间件，在一些需要异步处理、发布/订阅等场景的时候，使用RabbitMQ可以完成我们的需求。
下面是我在学习RabbitMQ的过程中的一些记录，内容主要翻译自[RabbitMQ官网的Tutorials](http://www.rabbitmq.com/getstarted.html)，
再加上我的一些个人理解。我将会用三篇文章来从RabbitMQ的Hello World介绍起，到最后的通过RabbitMQ实现``RPC``调用，
相信看完这三篇文章大家应该会对RabbitMQ的基本概念和使用有一定的了解。<!--more-->

**说明：**

1. 由于RabbitMQ支持许多种语言的client，在这里我使用的是``Java``语言的client。
2. 所有的图片均来自RabbitMQ官网。

## Hello World

首先需要安装RabbitMQ，关于RabbitMQ的安装这里就不赘述了，可以到RabbitMQ的官网去看相应的OS的安装方法。
安装完成后使用``rabbitmq-server``即可启动RabbitMQ，RabbitMQ还提供了一个UI管理界面，本地默认的地址为``localhost:15672``,
用户名和密码均为guest。

安装完成之后，按照惯例，先来完成一个简单的Hello World的例子。
最简单的一种消息发送的模型为一个消息发送者(Producer)将消息发送到Queue中，另一端的消息接受者(Consumer)从Queue中接受消息，
大致模型如下图所示：

![RabbitMQ](http://www.rabbitmq.com/img/tutorials/python-one.png)

先来看发送的代码，新建一个类命名为``Send.java``，代码的第一步为连接server

```java
ConnectionFactory factory = new ConnectionFactory();
factory.setHost("localhost");
Connection connection = factory.newConnection();
Channel channel = connection.createChannel();
```

``connection``抽象了socket的连接，并且为我们处理了协议版本的协商、权限认证等等。这里我们连接的是本地的中间件，
也就是``localhost``，接下来我们创建一个``channel``，这是大多数API完成任务的所在，也就是说我们的API操作基本都是通过channel来完成的。

```java
channel.queueDeclare(QUEUE_NAME, false, false, false, null);
String message = "Hello World!";
channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
System.out.println(" [x] Sent '" + message + "'");
```

首先是通过channel来声明一个queue，并且声明queue的操作是幂等的，也即是说只有在这个queue不存在的情况下才会新创建一个queue。
这里发送一个``Hello World!``的消息，实际传递的消息内容为字节数组。

```java
channel.close();
connection.close();
```

最后关闭channel和connection的连接，注意关闭的顺序，是先关闭channel的连接，再关闭connection的连接。

完整的``Send.java``代码

```java
public class Send {

    private static final String QUEUE_NAME = "hello";
    
    public static void main(String[] args) {
        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();
        
        channel.queueDeclare(QUEUE_NAME, false, false, false, null);
        String message = "Hello World!";
        channel.basicPublish("", QUEUE_NAME, null, message.getBytes());
        System.out.println(" [x] Sent '" + message + "'");
        
        channel.close();
        connection.close();
    }

}
```

完成发送的代码之后是接受消息的代码，新建一个类为``Recv.java``

```java
public class Recv {

    private final static String QUEUE_NAME = "hello";

    public static void main(String[] argv) throws Exception {
      ConnectionFactory factory = new ConnectionFactory();
      factory.setHost("localhost");
      Connection connection = factory.newConnection();
      Channel channel = connection.createChannel();

      channel.queueDeclare(QUEUE_NAME, false, false, false, null);
      System.out.println(" [*] Waiting for messages. To exit press CTRL+C");

      Consumer consumer = new DefaultConsumer(channel) {
        @Override
        public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body)
            throws IOException {
          String message = new String(body, "UTF-8");
          System.out.println(" [x] Received '" + message + "'");
        }
      };
      channel.basicConsume(QUEUE_NAME, true, consumer);
    }
}
```

可以发现一开始的连接部分的代码是相同的，在接收的时候我们也要声明一个queue，注意整理queue的名称和之前发送消息声明的queue的名称必须是相同的，
否则就收不到消息了。

``DefaultConsumer``类实现了``Consumer``接口，由于发送消息是异步的，因此在这里我们提供了一个callback来缓冲消息，
直到我们准备使用这些消息，最后分别运行``Send.java``和``Recv.java``，就能看到``Hello World!``消息了。

## Work Queues

在第一部分的Hello World中我们通过一个命名的queue来传递消息，在这一部分，我们会创建``Work Queue``来将耗时的任务分发至多个worker。
假设一个消息就是一个耗时的任务，比如文件I/O等等，我们可以通过几个worker来完成这些工作。

![RabbitMQ](http://www.rabbitmq.com/img/tutorials/python-two.png)

在Web应用中这是非常有用的，因为在一次非常短的HTTP请求窗口中完成一个非常复杂的任务是很困难的。

### 准备

这一部分是建立在上一部分``Hello World``的基础之上的，我们将发送字符串来表示一些复杂的任务，
由于并没有一些真实的复杂的工作，因此使用``Thread.sleep()``来模拟这是一个很耗时的任务，
并且在发送的字符串当中含有一个点号就表示这个任务需要耗时1秒，比如发送``Hello...``表示将要耗时3秒。

在前一部分的``Send.java``的基础上做一些修改，得到一个新的类称为``NewTask.java``。

```java
String message = getMessage(argv);

channel.basicPublish("", "hello", null, message.getBytes());
System.out.println(" [x] Sent '" + message + "'");
```

``getMessage``方法为从命令行中获取参数

```java
private static String getMessage(String[] strings){
    if (strings.length < 1)
        return "Hello World!";
    return joinStrings(strings, " ");
}

private static String joinStrings(String[] strings, String delimiter) {
    int length = strings.length;
    if (length == 0) return "";
    StringBuilder words = new StringBuilder(strings[0]);
    for (int i = 1; i < length; i++) {
        words.append(delimiter).append(strings[i]);
    }
    return words.toString();
}
```

我们之前的``Recv.java``也需要做一些变化，它需要模拟一些耗时的任务，消息内容中一个.表示1秒，并且它会处理消息，
我们称它为``Worker.java``

```java
final Consumer consumer = new DefaultConsumer(channel) {
  @Override
  public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
    String message = new String(body, "UTF-8");

    System.out.println(" [x] Received '" + message + "'");
    try {
      doWork(message);
    } finally {
      System.out.println(" [x] Done");
    }
  }
};
boolean autoAck = true; // acknowledgment is covered below
channel.basicConsume(TASK_QUEUE_NAME, autoAck, consumer);
```

这里有一个``autoAck``变量的作用在后面会提到。``doWork``方法就是模拟的耗时任务

```java
private static void doWork(String task) throws InterruptedException {
    for (char ch: task.toCharArray()) {
        if (ch == '.') Thread.sleep(1000);
    }
}
```

### 循环发送

使用任务队列其中的一个好处是可以非常方便的并行处理这些任务。如果我们在处理一些积压的工作，
只需要增加更多的worker即可，非常容易扩展。

首先，来试试两个worker实例的情况。很显然，两个worker都会接受到消息，但是具体的情况是怎么样的呢？
我们在控制台启动两个实例，C1和C2表示两个consumer，然后使用Producer来发送消息，一共发送五条消息，来看看具体的情况。

首先是第一个worker打印出的消息

```
[*] Waiting for messages. To exit press CTRL+C
[x] Received 'First message.'
[x] Received 'Third message...'
[x] Received 'Fifth message.....'
```

第二个worker打印出的消息

```
[*] Waiting for messages. To exit press CTRL+C
[x] Received 'Second message..'
[x] Received 'Fourth message....'
```

默认的，RabbitMQ会顺序的把消息发送到下一个Consumer，上面打印出的消息也印证了这一点。
平均来说每个Consumer接收到的消息数量是相同的，这种发送消息的方式称为循环发送(round-robin)，
思考下有三个或者更多Worker的情况。

### 消息接收(Message acknowledgment)

处理一个任务需要耗费几秒钟的时间。你也许想知道如果一个consumer在处理一个任务的时候只处理了一部分就挂了会出现什么情况。
在我们现在的代码下，一旦RabbitMQ将一个消息传递到consumer，它马上会从内存中删除这条消息，
也就是说如果杀掉了一个正在处理任务的worker，那么将会失去所有的这个worker正在处理的所有消息。
我也也会失去发送给这个worker但是还未处理的消息。

一般情况下，我们不希望丢失消息，如果某个worker挂了，我们希望任务能发送给另一个worker来处理。
为了确保消息不会丢失，RabbitMQ支持消息接收(message acknowledgments)。
当consumer确认收到某个消息，并且已经处理完成，RabbitMQ可以删除它时，consumer会向RabbitMQ发送一个``ack(nowledgement)``。

如果一个consumer挂了(channel关闭了、connection关闭了或者TCP连接断了)而没有发送ack，RabbitMQ就会知道这个消息没有被完全处理，
将会对这条消息做``re-queue ``处理。如果此时有另一个consumer连接，消息会被重新发送至另一个consumer。
使用这种方式可以保证消息不会丢失。

消息不会超时；RabbitMQ会在consumer挂了之后重新发送消息。即使处理消息耗时非常长也是没有问题的。

消息接收是默认开启的，在之前的例子中我们通过``autoAck=true``标志显式的关闭了它，``true``则表示自动接收，不需要发送ack。
现在是时候来开启ack。当consumer处理完成之后，向rabbitMQ发送ack。

```java
channel.basicQos(1); // accept only one unack-ed message at a time (see below)

final Consumer consumer = new DefaultConsumer(channel) {
  @Override
  public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
    String message = new String(body, "UTF-8");

    System.out.println(" [x] Received '" + message + "'");
    try {
      doWork(message);
    } finally {
      System.out.println(" [x] Done");
      channel.basicAck(envelope.getDeliveryTag(), false);
    }
  }
};
boolean autoAck = false;
channel.basicConsume(TASK_QUEUE_NAME, autoAck, consumer);
```

s使用以上代码能够保证即使在一个worker处使消息的时候用CTRL+C来杀掉这个worker，也不会丢失消息。
在这个worker挂掉之后所有未接收(ack)的消息将被重新发送。

### 消息持久化

我们学习了如何在worker挂掉的情况下不丢消息，但是在RabbitMQ server停止之后消息还是会丢失。
如果不进行任何配置，在RabbitMQ退出或崩溃的时候，将会失去所有的queue和消息。
要保证在这种情况小消息不丢失需要做两件事情：我们需要同时标志queue和message是持久化的。

首先，我们需要确保RabbitMQ不会丢失queue

```java
boolean durable = true;
channel.queueDeclare("task_queue", durable, false, false, null);
```

我们重新声明一个queue(不能修改已经声明为不持久化的queue为持久化)，名字为``task_queue``，
第二个布尔参数表示是否持久化的意思，这里设置为``true``，
包括consumer和producer声明queue的时候都需要声明durable为true。现在，即使重启RabbitMQ，``task_queue``queue也不会丢失了。

接下来我们将消息做持久化配置处理，通过设置``MessageProperties``(实现了BasicProperties)中的``PERSISTENT_TEXT_PLAIN``属性。

```java
channel.basicPublish("", "task_queue",
            MessageProperties.PERSISTENT_TEXT_PLAIN,
            message.getBytes());
```

### 公平分发(Fair dispatch)

在某种场景下有两个worker，当所有奇数的消息处理起来都比较耗时，而偶数的消息处理起来都比较快，
这就会发生一个worker总是处于busy状态，而另一个worker则总是处理空闲状态，RabbitMQ并不知道这个情况，
仍然只是正常的发送消息。

出现这种情况的原因在于当消息在queue中的时候RabbitMQ只是发送这些消息而已，它不会去关注某个consumer未ack的消息的数量，
它只是盲目的将某个消息发送到某个consumer。

![RabbitMQ](http://www.rabbitmq.com/img/tutorials/prefetch-count.png)

为了处理这种情况我们可以使用``basicQos``方法来设置``prefetchCount = 1``。
这告诉RabbitMQy一次只给worker一条消息，换句话来说，就是直到worker发回ack，然后再向这个worker发送下一条消息。

```java
int prefetchCount = 1;
channel.basicQos(prefetchCount);
```

完整的``NewTask.java``代码

```java
public class NewTask {

  private static final String TASK_QUEUE_NAME = "task_queue";

  public static void main(String[] argv)
                      throws java.io.IOException {

    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    Connection connection = factory.newConnection();
    Channel channel = connection.createChannel();

    channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, null);

    String message = getMessage(argv);

    channel.basicPublish( "", TASK_QUEUE_NAME,
            MessageProperties.PERSISTENT_TEXT_PLAIN,
            message.getBytes());
    System.out.println(" [x] Sent '" + message + "'");

    channel.close();
    connection.close();
  }      
  //...
}
```

``Worker.java``

```java
public class Worker {
  private static final String TASK_QUEUE_NAME = "task_queue";

  public static void main(String[] argv) throws Exception {
    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    final Connection connection = factory.newConnection();
    final Channel channel = connection.createChannel();

    channel.queueDeclare(TASK_QUEUE_NAME, true, false, false, null);
    System.out.println(" [*] Waiting for messages. To exit press CTRL+C");

    channel.basicQos(1);

    final Consumer consumer = new DefaultConsumer(channel) {
      @Override
      public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException {
        String message = new String(body, "UTF-8");

        System.out.println(" [x] Received '" + message + "'");
        try {
          doWork(message);
        } finally {
          System.out.println(" [x] Done");
          channel.basicAck(envelope.getDeliveryTag(), false);
        }
      }
    };
    boolean autoAck = false;
    channel.basicConsume(TASK_QUEUE_NAME, autoAck, consumer);
  }

  private static void doWork(String task) {
    for (char ch : task.toCharArray()) {
      if (ch == '.') {
        try {
          Thread.sleep(1000);
        } catch (InterruptedException _ignored) {
          Thread.currentThread().interrupt();
        }
      }
    }
  }
}
```