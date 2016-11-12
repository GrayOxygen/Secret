+++
date = "2016-11-12T15:52:15+08:00"
description = "RabbitMQ指南(下)"
draft = false
tags = ["MQ","RabbitMQ","Tutorials"]
title = "RabbitMQ指南(下)"
topics = ["RabbitMQ"]

+++

在上一小节中我们改进了log系统，由于使用``fanout``类型的exchange只能进行全局的广播，因此我们使用``direct``类型的exchange做了代替，
使得我们可以选择性的接收消息。尽管使用fanout exchange改进了log系统，但它仍然有限制——不能基于多个条件做路由。<!--more-->

## Topics

在log系统中可能不只是基于不同的日志级别作订阅，也可能会基于日志的来源。你也许听过Unix下名为``syslog``的工具，
它把日志按照严重级别(info/warn/crit...)和设备(auth/cron/ker...)进行路由。

这会给我们许多的灵活性，也许我们只想监听'cron'中的'critical'级别的错误日志，以及所有'kern'中的日志。
为了实现这种日志系统，我们需要学习一个更复杂的``topic``类型的exchange。

### Topic exchange

发送到topic exchange中的消息不能有一个任意的``routing_key``——它必须是一个使用点分隔的单词列表。单词可以是任意的，
但是通常会指定消息的一些特定。一些有效的routing key例子："stock.usd.nyse"，"nyse.vmw"，"quick.orange.rabbit"。
routing key的长度限制为255个字节数。

binding key也必须是相同的形式。topic exchange背后的逻辑类似于direct——一条使用特定的routing key发送的消息将会被传递至所有使用与该routing key相同的binding key进行绑定的队列中。
然而，对binding key来说有两种特殊的情况：

1. *(star)可以代替任意一个单词
2. #(hash)可以代替0个或多个单词

使用一张图可以很简单地来说明：

![topic](https://www.rabbitmq.com/img/tutorials/python-five.png)

在图中，我们将要发送被描述的动物的消息。消息的routing key将由三个单词组成(通过两个点分隔)。routing key中的第一个单词将描述速度，
第二个是颜色，第三个是物种：``"<speed>.<colour>.<species>"``。

我们创建三个绑定：Q1使用binding key``"*.orange.*"``来绑定，Q2使用``"*.*.rabbit"``以及``lazy.#``绑定。

这些绑定可以被总结为：

+ Q1对所有橘色的的动物感兴趣
+ Q2想要接收所有关于兔子的消息以及所有关于lazy的动物的消息

一条使用routing key``"quick.orange.rabbit"``发送的消息将被同时传递到两个队列中。消息``"lazy.orange.elephant"``同样如此。
另一方面，``"quick.orange.fox"``只会被第一个queue接收，``"lazy.brown.fox"``只会被第二个queue接收。
``"lazy.pink.rabbit"``只会被传递到Q2一次，即使它对两个binding key都匹配。``"quick.brown.fox"``与两个queue的binding key都不匹配，
因此将被丢弃。

如果打破我们的约定，使用一个单词或者四个单词的routing key例如``"orange"``，``"quick.orange.male.rabbit"``发送消息将会发生什么？
这些消息不会匹配任何绑定，因此会丢失。

但是对于``"lazy.orange.male.rabbit"``，即使它有四个单词，但是它与第二个queue的binding key匹配，因此将会被发送到第二个queue中。

当一个queue使用``"#"``(hash)作为binding key，那么它将会接收所有的消息，忽略routing key，就好像使用了fanout exchange。
当特殊字符"*"(star)和"#"(hash)在绑定中没有用到，topic exchange将会与direct exchange的行为相同。

了解了topic exchange之后，我们将它用在我们的log系统中，我们定义的routing key将会有两个单词组成：``"<facility>.<severity>"``。

完成的``EmitLogTopic.java``：

```java
public class EmitLogTopic {

    private static final String EXCHANGE_NAME = "topic_logs";

    public static void main(String[] argv)
                  throws Exception {

        ConnectionFactory factory = new ConnectionFactory();
        factory.setHost("localhost");
        Connection connection = factory.newConnection();
        Channel channel = connection.createChannel();

        channel.exchangeDeclare(EXCHANGE_NAME, "topic");

        String routingKey = getRouting(argv);
        String message = getMessage(argv);

        channel.basicPublish(EXCHANGE_NAME, routingKey, null, message.getBytes());
        System.out.println(" [x] Sent '" + routingKey + "':'" + message + "'");

        connection.close();
    }
    //...
}
```

完整的``ReceiveLogsTopic.java``:

```java
public class ReceiveLogsTopic {
  private static final String EXCHANGE_NAME = "topic_logs";

  public static void main(String[] argv) throws Exception {
    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    Connection connection = factory.newConnection();
    Channel channel = connection.createChannel();

    channel.exchangeDeclare(EXCHANGE_NAME, "topic");
    String queueName = channel.queueDeclare().getQueue();

    if (argv.length < 1) {
      System.err.println("Usage: ReceiveLogsTopic [binding_key]...");
      System.exit(1);
    }

    for (String bindingKey : argv) {
      channel.queueBind(queueName, EXCHANGE_NAME, bindingKey);
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

运行的时候从命令行中输入binding key来进行绑定，接收不同的消息。

## Remote procedure call (RPC)

在第二小节中我们学习了如何使用``Work Queues``来在多个workers中分发耗时的任务。但是如果我们需要调用远程计算机上的一个函数并等待结果返回呢？
这就是另外一个故事了。这种模式通常称为远程过程调用或RPC。

在这一小节我们将使用RabbitMQ来构建一个RPC系统：一个客户端和一个可扩展的RPC服务器。由于我们没有实际的耗时任务用来分发，
因此我们将创建一个虚拟的RPC服务返回Fibonacci数。

### Client interface

为了说明RPC服务是如何使用的，我们将创建一个简单的客户端类。它将暴露一个名为``call``的方法发送一次RPC请求并且阻塞直到结果返回：

```java
FibonacciRpcClient fibonacciRpc = new FibonacciRpcClient();
String result = fibonacciRpc.call("4");
System.out.println( "fib(4) is " + result);
```

### Callback queue

使用RabbitMQ来进行RPC是非常简单的。客户端发送一个请求到服务端，服务端接收后返回响应的消息。为了接收到响应的消息，我们需要在请求中发送一个callback
的queue地址。我们可以使用默认的queue(在Java的client中它是exclusive的)。

```java
callbackQueueName = channel.queueDeclare().getQueue();

BasicProperties props = new BasicProperties
                            .Builder()
                            .replyTo(callbackQueueName)
                            .build();

channel.basicPublish("", "rpc_queue", props, message.getBytes());

// ... then code to read a response message from the callback_queue ...
```

#### Message properties

AMQP协议预定义了消息的14种属性。大部分的都很少使用，除了以下这些：

+ ``deliveryMode``：标记一条消息是持久化的(使用值2)还是非持久化的(使用其它值)。在第二节中有过介绍。
+ ``contentType``：用来描述mime类型的编码。例如使用JSON的话就这样设置属性：``application/json``。
+ ``replyTo``：一般用来命名一个回调queue。
+ ``correlationId``：用来关联RPC的请求和响应。

我们需要导入新的类：

```java
import com.rabbitmq.client.AMQP.BasicProperties;
```

### Correlation Id

在之前的方法中我们建议为每个RPC请求创建一个回调queue。这显得有点影响性能，幸运的是有一种更好的方式——每个客户端只创建一个回调queue。
但这产生了一个新问题，无法将相应的Response和Request对应起来。这个时候就需要用到``correlationId``属性。对于每个请求它都将有一个唯一的值。
当我们在回调queue中接收到消息之后，检查该属性，看是否与Request匹配。如果是一个未知的``correlationId``值，那么我们可以安全的忽略这条消息，
因为它不属于我们的请求。

你也许会问，为什么我们应该忽略回调queue中未知的消息而不是抛出异常？这是因为服务端可能会出现竞争条件。尽管不太常见，但是也有可能RPC server在发送响应后挂了，
并且也没有接收到客户端发送的ack。如果发生了这种情况，RPC server在重启后将会重新处理这个请求。这就是为什么在客户端我们需要优雅的处理重复的响应，
RPC应该是幂等的。

### Summary

![RPC](https://www.rabbitmq.com/img/tutorials/python-six.png)

我们的RPC整个过程是这样的：

1. 当客户端启动，它创建一个匿名的并且是exclusive的回调queue。
2. 在一次RPC请求中，客户端发送的消息有两个属性：``replyTo``，放置的是回调queue的信息。``correlationId``，放置的是每个请求唯一的值。
3. 请求被发送到一个rpc_queue中。
4. RPC服务端在queue的另一端等待请求。当请求到来时，它处理任务并将消息的结果发送回客户端，使用``replyTo``中设置的queue。
5. 客户端在回调queue中等待响应的数据，当消息出现时，它先检查``correlationId``属性。如果匹配的话就将结果返回到应用中。

最后来看一下完整的代码实现。

Fibonacci函数：

```java
private static int fib(int n) throws Exception {
    if (n == 0) return 0;
    if (n == 1) return 1;
    return fib(n-1) + fib(n-2);
}
```

完整的``RPCServer.java``代码

```java
private static final String RPC_QUEUE_NAME = "rpc_queue";

ConnectionFactory factory = new ConnectionFactory();
factory.setHost("localhost");

Connection connection = factory.newConnection();
Channel channel = connection.createChannel();

channel.queueDeclare(RPC_QUEUE_NAME, false, false, false, null);

channel.basicQos(1);

QueueingConsumer consumer = new QueueingConsumer(channel);
channel.basicConsume(RPC_QUEUE_NAME, false, consumer);

System.out.println(" [x] Awaiting RPC requests");

while (true) {
    QueueingConsumer.Delivery delivery = consumer.nextDelivery();

    BasicProperties props = delivery.getProperties();
    BasicProperties replyProps = new BasicProperties
                                     .Builder()
                                     .correlationId(props.getCorrelationId())
                                     .build();

    String message = new String(delivery.getBody());
    int n = Integer.parseInt(message);

    System.out.println(" [.] fib(" + message + ")");
    String response = "" + fib(n);

    channel.basicPublish( "", props.getReplyTo(), replyProps, response.getBytes());

    channel.basicAck(delivery.getEnvelope().getDeliveryTag(), false);
}
```

server端的代码非常直观：

+ 首先创建一个连接、channel和声明一个queue。
+ 我们也许想要运行不止一个服务端进程。为了在多个server间做到负载均衡，通过channel.basicQos设置``prefetchCount``。
+ 我们使用``basicConsume``来进入queue。然后使用无限循环来等待请求的消息，处理之后再返回响应。

完整的``RPCClient.java``代码

```java
private Connection connection;
private Channel channel;
private String requestQueueName = "rpc_queue";
private String replyQueueName;
private QueueingConsumer consumer;

public RPCClient() throws Exception {
    ConnectionFactory factory = new ConnectionFactory();
    factory.setHost("localhost");
    connection = factory.newConnection();
    channel = connection.createChannel();

    replyQueueName = channel.queueDeclare().getQueue();
    consumer = new QueueingConsumer(channel);
    channel.basicConsume(replyQueueName, true, consumer);
}

public String call(String message) throws Exception {
    String response = null;
    String corrId = java.util.UUID.randomUUID().toString();

    BasicProperties props = new BasicProperties
                                .Builder()
                                .correlationId(corrId)
                                .replyTo(replyQueueName)
                                .build();

    channel.basicPublish("", requestQueueName, props, message.getBytes());

    while (true) {
        QueueingConsumer.Delivery delivery = consumer.nextDelivery();
        if (delivery.getProperties().getCorrelationId().equals(corrId)) {
            response = new String(delivery.getBody());
            break;
        }
    }

    return response;
}

public void close() throws Exception {
    connection.close();
}
```

客户端代码有一点点的复杂：

+ 我们创建连接和channel，以及声明一个exclusive的回调queue用来接收响应的消息。
+ 订阅回调queue，这样就可以接收到RPC服务端响应的消息。
+ call方法发出一个RPC请求。
+ 我们首先生成一个唯一的``correlationId``数字并且保存它——在while循环中使用它来匹配相应的response。
+ 下一步，发送请求的消息，使用两个属性：``replyTo``和``correlationId``。
+ 之后就是等待响应的消息返回。
+ 在while循环中做了一些简单的工作，检查响应的消息的``correlationId``是否与Request相匹配。如果是的话，则保存响应。
+ 最终向用户返回响应。

发送客户端请求：

```java
RPCClient fibonacciRpc = new RPCClient();

System.out.println(" [x] Requesting fib(30)");
String response = fibonacciRpc.call("30");
System.out.println(" [.] Got '" + response + "'");

fibonacciRpc.close();
```

这样就通过RabbitMQ简单的实现了RPC的通信。