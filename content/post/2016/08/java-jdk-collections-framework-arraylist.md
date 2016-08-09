+++
date = "2016-08-09T17:39:42+08:00"
description = "JDK集合框架源码分析之ArrayList"
draft = false
tags = ["Java","JDK源码分析","Collections-framework","ArrayList"]
title = "Java集合框架JDK源码分析之ArrayList"
topics = ["JDK源码分析"]

+++

作为一个Java开发者，JDK中的集合框架在我们平时的开发过程中使用频率是非常高的，比如说``ArrayList``,``LinkedList``,``HashMap``,``HashSet``等。阅读并分析这些API的JDK源码，可以帮助我们更好的理解它们底层的实现原理、适用和不适用的场景，以及在使用过程过程中需要注意些什么等等。

为了更好地对Java的集合框架有一个整体的了解，先来看一张从网上找的集合框架API的UML图。

![Collections framework overview](http://7xsskq.com1.z0.glb.clouddn.com/blog/collections-framework-overview/collections-framework-overview.png "Collections framework overview")


