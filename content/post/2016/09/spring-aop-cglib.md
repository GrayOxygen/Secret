+++
date = "2016-09-30T15:32:40+08:00"
description = "Spring AOP的实现原理"
draft = false
tags = ["Java","Spring","AOP"]
title = "Spring AOP的实现原理"
topics = ["Spring AOP"]

+++

AOP（Aspect Orient Programming），我们一般称为面向方面（切面）编程，作为面向对象的一种补充，用于处理系统中分布于各个模块的横切关注点，比如事务管理、日志、缓存等等。AOP实现的关键在于AOP框架自动创建的AOP代理，AOP代理主要分为静态代理和动态代理，静态代理的代表为AspectJ；而动态代理则以Spring AOP为代表。本文会分别对AspectJ和Spring AOP的实现进行分析和介绍。<!--more-->

## 使用AspectJ的编译时增强实现AOP

之前说了，AspectJ是静态代理的增强，所谓的静态代理就是AOP框架会在编译阶段生成AOP代理类，因此也称为编译时增强。

举个实例的例子来说，首先我们有一个普通的``Hello``类

```java
public class Hello {
    public void sayHello() {
        System.out.println("hello");
    }

    public static void main(String[] args) {
        Hello h = new Hello();
        h.sayHello();
    }
}
```

使用AspectJ编写一个Aspect

```java
public aspect TxAspect {
    void around():call(void Hello.sayHello()){
        System.out.println("开始事务 ...");
        proceed();
        System.out.println("事务结束 ...");
    }
}
```

这里模拟了一个事务的场景，类似于Spring的声明式事务。使用AspectJ的编译器编译

```
ajc -d . Hello.java TxAspect.aj
```

编译完成之后再运行这个``Hello``类，可以看到以下输出

```
开始事务 ...
hello
事务结束 ...
```

很明显，AOP已经生效了，那么究竟AspectJ是如何在没有修改Hello类的情况下为Hello类增加新功能的呢？

查看一下编译后的``Hello.class``

```java
public class Hello {
    public Hello() {
    }

    public void sayHello() {
        System.out.println("hello");
    }

    public static void main(String[] args) {
        Hello h = new Hello();
        sayHello_aroundBody1$advice(h, TxAspect.aspectOf(), (AroundClosure)null);
    }
}
```

很明显，这个类比原来的``Hello.java``多了一些代码，这就是AspectJ的静态代理，它会在编译阶段直接修改Java编译后的字节码，这样运行的时候就是增加了Aspect的代码。

```java
public void ajc$around$com_listenzhangbin_aop_TxAspect$1$f54fe983(AroundClosure ajc$aroundClosure) {
        System.out.println("开始事务 ...");
        ajc$around$com_listenzhangbin_aop_TxAspect$1$f54fe983proceed(ajc$aroundClosure);
        System.out.println("事务结束 ...");
    }
```

从Aspect编译后的class文件可以更明显的看出执行的逻辑。``proceed``方法就是回调执行被代理类中的方法。

## 使用Spring AOP

