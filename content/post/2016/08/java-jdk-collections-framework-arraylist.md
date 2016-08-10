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

调用``size``方法就是简单的返回``size``字段。

```java
public int size() {
        return size;
    }
```

### 增加元素(add，addAll方法)

每当调用``add``方法往ArrayList中添加元素的时候，ArrayList类内部都会先将目前数组的容量增加1，增加容量的核心方法是``grow``方法

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

``grow``方法首先获取当前元素的个数保存为旧的容量，将旧容量*1.5作为新的容量，如果新容量小于需要调整到的最小容量，那么将新容量赋值为最小容量，如果新容量大于数组最大容量，那么将新容量赋值为数组最大容量，最后，将原数组复制到新容量大小的数组中。

代码部分还是比较好理解的，唯一可能会有疑惑的地方是``oldCapacity >> 1``，这是一个位移操作，相当于``oldCapacity/2``，使用位操作的原因是可能位操作性能更好。

可以看到，每次add操作都会发生一次底层数组的复制操作，因此如果可以的话尽量使用``addAll``方法，一次性增加所有的元素，这样只会发生一次数组的复制。

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

与``add``方法的不同之处在于``addAll``方法不是将数组的容量加1，而是将数组的容量增加传递进来的集合的元素个数，最后将参数集合转换成的数组复制到ArrayList中存放元素的数组中，最后将size增加相应的长度。

在使用``add``方法增加大量的元素时，可以先将ArrayList的容量一次性增加，避免多次地动态调整数组的大小而发生的数组复制操作，这在某些情况下是非常有必要的，比如说在循环中调用``add``方法。

```java
private void ensureExplicitCapacity(int minCapacity) {
        modCount++;

        // overflow-conscious code
        if (minCapacity - elementData.length > 0)
            grow(minCapacity);
    }
```

``ensureExplicitCapacity``是一个ArrayList的私有方法，当调用add方法时，会调用这个方法去判断是否需要增加数组的容量，判断的依据是，当需要的最小容量大于当前数组的长度时，就会发生调整数组容量的操作，因此可以事先将容量一次性增加，避免了每次add时都调整容量加1。

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

``ensureCapacity``方法可以用来调整ArrayList的容量大小。

当需要在ArrayList的某个指定位置插入元素的时候，需要使用传递两个参数的``add``方法。

```java
public void add(int index, E element) {
        rangeCheckForAdd(index);

        ensureCapacityInternal(size + 1);  // Increments modCount!!
        System.arraycopy(elementData, index, elementData, index + 1,
                         size - index);
        elementData[index] = element;
        size++;
    }
```

首先是检查需要插入元素的索引是否超出了数组的长度，然后将数组的容量加1，将原数组的需要插入的位置之后的元素往后复制1个位置，将需要插入元素的位置赋值为传递进来的参数element，最后将size增加1。

与``add``方法类似，每次在ArrayList的中间插入一个元素都要发生一次数组的复制操作(但是不能通过预先调整数组的容量优化)，因此在需要经常在集合的中间插入元素的场景时，使用ArrayList可能不是最合适的选择。

### 获取元素(get方法)

``get``方法比较简单，因为数据都是存储在数组中，因此只要返回相应索引的值即可。

```java
public E get(int index) {
        //对传入的索引进行一次检查，如果超过数组的长度则抛出一个运行时异常
        rangeCheck(index);

        return elementData(index);
    }
```

这也是为什么ArrayList的随机访问元素操作的性能比较好的原因。

### 修改元素(set方法)

``set``方法也比较简单，需要传递两个参数。分别为需要修改的元素的索引和值，将数组的相应索引的值修改为新的值，并返回修改前的值。

```java
public E set(int index, E element) {
        rangeCheck(index);

        E oldValue = elementData(index);
        elementData[index] = element;
        return oldValue;
    }
```

### 删除元素(remove方法)

``remove``方法有两种重载的形式，可以传递一个整形索引，也可以传递一个具体的值。先来看第一种：

```java
public E remove(int index) {
        rangeCheck(index);

        modCount++;
        E oldValue = elementData(index);

        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work

        return oldValue;
    }
```

首先检查传递的索引是否小于等于数组的长度，将该位置上原来的值保存在一个变量中，接着获得需要移动的元素的个数，如果需要移动的元素的个数大于0，那么将该索引之后的元素往前复制一个位置，最后将数组最后的一个值赋值为null，并且size减小1，最后返回原来的值。

第二种``remove``方法：

```java
public boolean remove(Object o) {
        if (o == null) {
            for (int index = 0; index < size; index++)
                if (elementData[index] == null) {
                    fastRemove(index);
                    return true;
                }
        } else {
            for (int index = 0; index < size; index++)
                if (o.equals(elementData[index])) {
                    fastRemove(index);
                    return true;
                }
        }
        return false;
    }
```

第二种``remove``方法比第一种方法要略复杂一点。首选判断传递进来的元素是不是为``null``，如果为null，则遍历整个数组，如果找到一个元素的值为``null``,则删除这个元素，删除的方法为：

```java
private void fastRemove(int index) {
        modCount++;
        int numMoved = size - index - 1;
        if (numMoved > 0)
            System.arraycopy(elementData, index+1, elementData, index,
                             numMoved);
        elementData[--size] = null; // clear to let GC do its work
    }
```

``fastRemove``方法与传递索引的``remove``方法非常类似，只是少了检查索引的合法性和不返回被修改前的值。删除后，返回true。

如果不为null，则遍历整个数组，使用``equals``方法判断是否有相等的元素，这里建议要为存储在ArrayList中的类覆盖``Object``中的``equals``和``hashCode``方法。如果找到相同的元素则删除该元素，返回true。最后如果未找到，则返回false。

由于需要遍历整个数组，因此remove操作的时间复杂度为O(n)。

可以看到，不论是哪一种``remove``方法，除非删除的是最后一个元素，否则每次删除操作都会发生一次数组的复制操作，与在ArrayList插入元素类似，如果需要频繁的在中间删除元素也不是ArrayList适用的场景。

### 其它常用方法

``contains``，``indexOf``,``lastIndexOf``也是常用的方法，分别是检查ArrayList中是否还有参数的值，正向获取某个元素的索引，反向获取某个元素的索引。只需要了解``indexOf``方法，三个方法是类似的。

```java
public int indexOf(Object o) {
        if (o == null) {
            for (int i = 0; i < size; i++)
                if (elementData[i]==null)
                    return i;
        } else {
            for (int i = 0; i < size; i++)
                if (o.equals(elementData[i]))
                    return i;
        }
        return -1;
    }
```

代码非常简单，就是遍历一遍数组，查找是否含有相同的值。``contains``方法就是掉用的``indexOf``方法，``lastIndexOf``方法只是把遍历的顺序改为从后往前遍历。

## 总结

