+++
date = "2016-08-09T17:39:42+08:00"
description = "JDK集合框架源码分析之ArrayList"
draft = false
tags = ["Java","JDK源码分析","Collections-framework","ArrayList"]
title = "Java集合框架JDK源码分析之ArrayList"
topics = ["JDK源码分析"]

+++

作为一个Java开发者，JDK中的集合框架在我们平时的开发过程中使用频率是非常高的，比如说``ArrayList``,``LinkedList``,``HashMap``,``HashSet``等。阅读并分析这些API的JDK源码，可以帮助我们更好的理解它们底层的实现原理、适用和不适用的场景，以及在使用过程中需要注意些什么等等。<!--more-->

## 概述

为了更好地对Java的集合框架有一个整体的了解，先来看一张集合框架API的UML图。([原图地址](http://www.codejava.net/java-core/collections/overview-of-java-collections-framework-api-uml-diagram))

![Collections framework overview](http://7xsskq.com1.z0.glb.clouddn.com/blog/collections-framework-overview/collections-framework-overview.png "Collections framework overview")

图中列出了主要使用的接口和类。可以看到，Java中集合框架的主要被分成四个组(4个接口)——``List,Set,Map,Queue``。各个接口下又有各自的抽象类，抽象类下是具体的实现类。``List``的主要实现有``ArrayList``，``LinkedList``等，``Set``的主要实现有``HashSet``，``TreeSet``，``LinkedHashSet``等，``Map``的主要实现有``HashMap``，``LinkedHashMap``，``TreeMap``等，``Queue``的主要实现是``LinkedList``和``PriorityQueue``等。不同的集合适用于不同的场景，如果使用不当，可能会造成性能等问题。

## ArrayList的存储实现

**说明**：源码分析基于JDK1.8。

这篇文章主要要说的就是最常用的集合之一——``ArrayList``。当程序试图将多个值放入ArrayList中时，以如下代码为例：

```java
List<Integer> list = new ArrayList<>()
list.add(1);
list.add(2);
list.add(3);
```

ArrayList底层采用的存储数据结构是数组，确切地说是动态调整大小的数组。既然是数组，当然需要指定长度，也就是容量。JDK中默认的容量是10:

```java
private static final int DEFAULT_CAPACITY = 10;
```

底层存储数据的数组：

```java
transient Object[] elementData;
```

## ArrayList的基本操作

### 获取元素的个数(size方法)

ArrayList类中用一个``size``字段记录了当前存储的数据的个数，也就是数组的长度,每当调用``add``或``remove``等方法时，会对``size``字段做出相应的修改。

```java
private int size;
```

调用``size()``方法就是简单的返回``size``字段。

```java
public int size() {
        return size;
    }
```

### 增加元素(add，addAll方法)

每当调用``add()``方法往ArrayList中添加元素的时候，ArrayList类内部都会先将目前数组的容量增加1，增加容量的核心方法是``grow()``方法

```java
private void grow(int minCapacity) {
        // overflow-conscious code
        int oldCapacity = elementData.length;
        int newCapacity = oldCapacity + (oldCapacity >> 1);
        if (newCapacity - minCapacity < 0)
            newCapacity = minCapacity;
        if (newCapacity - MAX_ARRAY_SIZE > 0)
            newCapacity = hugeCapacity(minCapacity);
        // minCapacity is usually close to size, so this is a win:
        elementData = Arrays.copyOf(elementData, newCapacity);
    }
```

``grow()``方法首先获取当前元素的个数保存为旧的容量，将旧容量*1.5作为新的容量，如果新容量小于需要调整到的最小容量，那么将新容量赋值为最小容量，如果新容量大于数组最大容量，那么将新容量赋值为数组最大容量，最后，将原数组复制到新容量大小的数组中。

代码部分还是比较好理解的，唯一可能会有疑惑的地方是``oldCapacity >> 1``，这是一个位移操作，相当于``oldCapacity/2``，使用位操作的原因是可能位操作性能更好。

可以看到，每次add操作都会发生一次底层数组的复制操作，因此如果可以的话尽量使用``addAll()``方法，一次性增加所有的元素，这样只会发生一次数组的复制。

```java
public boolean addAll(Collection<? extends E> c) {
        Object[] a = c.toArray();
        int numNew = a.length;
        ensureCapacityInternal(size + numNew);  // Increments modCount
        System.arraycopy(a, 0, elementData, size, numNew);
        size += numNew;
        return numNew != 0;
    }
```

与``add()``方法的不同之处在于``addAll()``方法不是将数组的容量加1，而是将数组的容量增加传递进来的集合的元素个数，最后将参数集合转换成的数组复制到ArrayList中存放元素的数组中，最后将size增加相应的长度。

在使用``add()``方法增加大量的元素时，可以先将ArrayList的容量一次性增加，避免多次地动态调整数组的大小而发生的数组复制操作，这在某些情况下是非常有必要的，比如说在循环中调用``add()``方法。

```java
private void ensureExplicitCapacity(int minCapacity) {
        modCount++;

        // overflow-conscious code
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
    }
```

``ensureExplicitCapacity()``是一个ArrayList的私有方法，当调用add方法时，会调用这个方法去判断是否需要增加数组的容量，判断的依据是，当需要的最小容量大于当前数组的长度时，就会发生调整数组容量的操作，因此可以事先将容量一次性增加，避免了每次add时都调整容量加1。

```java
public void ensureCapacity(int minCapacity) {
        int minExpand = (elementData != DEFAULTCAPACITY_EMPTY_ELEMENTDATA)
            ? 0
            : DEFAULT_CAPACITY;

        if (minCapacity > minExpand) {
            ensureExplicitCapacity(minCapacity);
        }
    }
```

``ensureCapacity()``方法可以用来调整ArrayList的容量大小。

