+++
date = "2016-06-18T22:25:42+08:00"
description = "算法与数据结构(一) —— 链表"
draft = false
tags = ["链表","栈","队列"]
title = "算法与数据结构(一) —— 链表"
topics = ["算法与数据结构"]

+++

在Java的集合类库中,``ArrayList``和``LinkedList``是非常常用的两个集合类型,``ArrayList``底层由数组实现,
因此在需要频繁随机访问操作的时候,使用``ArrayList``性能会较高,``LinkedList``底层由链表实现,
在需要频繁添加和删除元素时,使用``LinkedList``的性能会更好。那么究竟为什么``LinkedList``的添加和删除元素操作性能会那么高呢?
这就要来说说数据结构中的基础数据结构 —— **链表**。<!--more-->

## 构造链表

首先来看看链表的的定义:

```
链表是一种递归的数据结构,它或者为空(null),或者是指向一个结点(node)的引用,该结点含有一个泛型的元素和一个指向另一条链表的引用。
```

在面向对象的编程中,我们可以使用内部类的形式来定义结点的抽象数据类型:

```java
private class Node {
    Item item;
    Node next;
}
```

一个Node对象含有两个实例变量,类型分别为Item(泛型的参数类型)和Node。Item表示的是我们希望用链表处理的任意数据类型,
Node类型的实例变量则显示了这种数据结构的链式本质。

接着我们来构造一个链表。根据递归的定义,我们只要有一个Node类型的变量就能表示一条链表,只要保证它的值是null或者指向另一个Node对象
且该对象的next域指向了另一条链表即可。现在假设我们要构造一条含有``one、two、three``三个元素的链表,首先需要为每个元素创建一个结点:

```java
Node first = new Node();
Node second = new Node();
Node third = new Node();
```

并将每个结点的Item域设置为所需的值,这里为了简单起见,全部使用String类型。

```java
first.item = "one";
second.item = "two";
third.item = "three";
```

然后设置next域来构造链表:

```java
first.next = second;
second.next = third;
//这里third.next为null
```

大致的结构如下:

![链表](http://7xsskq.com1.z0.glb.clouddn.com/blog/linkedlist/linkedlist1.png "linkedlist")

可以看到,每个结点都有一个Item域,以及一个Node域是指向下一个结点的引用(除了最后一个结点的Node为null)。

## 链表的操作

在构造完了一条简单的链表之后,再来看看链表的插入结点、删除结点以及遍历操作底层究竟是怎样实现的,
这样就可以解释为什么链表执行这些操作性能高的原因。

### 在表头插入结点

首先,假设希望向一条链表中插入一个新的结点,最容易做到这一点的就是链表的开头。例如,在首结点为first的给定链表开头插入字符串hello,
我们可以先将原来的first保存在``oldFirst``中,然后将一个新结点赋予first,并将它的item域设置为hello,next设置为oldFirst。

```java
Node oldFirst = first;
first = new Node();
first.item = "hello";
first.next = oldFirst;
```

可以看到,这段在链表开头插入一个结点的代码只需要几行赋值语句,所以它所需的时间和链表的长度无关。

### 在表头删除结点

在表头删除结点的操作更简单,只需要将first指向``first.next``即可。和上一个操作一样,
这个操作只有一行赋值语句,因此它的运行时间和链表的长度无关。

```java
first = first.next;
```

### 在表尾插入结点

在表尾插入结点的操作域在表头插入结点的操作有点类似

```java
//最后一个结点
Node oldLast = last;
last = new Node();
last.item = "last";
oldLast.next = last;
```

这里需要注意的一点是,每个修改链表的操作都需要添加检查是否要修改该变量的代码,
比如在之前说到的删除链表首结点的代码就可能改变指向链表的尾结点的引用,因为当链表中只有一个结点时,
它既是首结点又是尾结点。而且上面的代码也无法处理链表为空的情况。

### 其他位置的插入和删除操作

我们已经实现了以下几种链表的操作:

+ 在表头删除结点;
+ 在表头删除结点;
+ 在表尾插入结点;

其他的操作,就不那么容易实现了,比如:

+ 删除指定的结点;
+ 在指定结点前插入一个新结点;

举例来说,如果要删除链表的尾结点,需要得到尾结点的前一个结点,将它的next设置为null,但是在目前构造的链表中,
我们没有办法直接得到尾结点的前一个结点,唯一的解决办法就是遍历整个链表,但这种解决方案肯定是不合理的,
因为它所需的时间和链表的长度成正比。

要实现任意的插入和删除操作的标准解决方案是使用**双向链表**,其中每个结点都含有两个结点,
分别指向不同的方向。双向链表的实现思路和单向链表是类似的,只不过每个结点都含有一个指向前一个结点的引用。

## 遍历

链表的遍历操作的过程为:将循环的索引变量x初始化为链表的首结点,然后通过``x.item``访问和x关联的元素,
并将x设为``x.next``来访问链表中的下一个结点,直到x为null为止。

```java
for (Node x = first;x != null;x = x.next){
    //process x.item
}
```

## 链表的应用

链表是一种基础的数据结构,在学习了链表之后,我们可以使用链表来构造一些其他的更复杂的数据结构。

### 实现栈

```java
public class Stack<T> implements Iterable<T> {
    //栈顶(最近添加的元素)
    private Node first;
    //元素的数量
    private int N;
    
    //node
    private class Node {
        T item;
        Node next;
    }
    
    public boolean isEmpty(){
        return first == null;
    }
    
    public int size(){
        return N;
    }
    
    public void push(T item){
        Node oldFirst = first;
        first = new Node();
        first.item = item;
        first.next = oldFirst;
        N++;
    }
    
    public T pop(){
        T item = first.item;
        first = first.next;
        N--;
        return item;
    }
    
    @Override
    public Iterator<T> iterator(){
        return new Iterator<>(){
            private Node current = first;
            @Override
            public boolean hasNext(){
                return current!=null;
            }
            @Override
            public T next(){
                T item = current.item;
                current = current.next;
                return item;
            }
        };
    }
}

```

### 实现队列

队列的实现与栈相似,主要组别在于队列是先进先出,栈是后进先出。

```java
public class Queue<T> implements Iterable<T> {
    //指向最早添加的结点的链接
    private Node first;
    //指向最近添加的结点的链接
    private Node last;
    
    private class Node {
        T item;
        Node next;
    }
    
    public boolean isEmpty(){
        return first == null;
    }
    
    public int size() {
        return N;
    }
    
    public void enqueue(T item){
        Node oldlast = last;
        last = new Node();
        last.item = item;
        last.next = oldlast;
        if (isEmpty()){
            first = last;
        } else {
            oldlast.next = last;
        }
        N++;
    }
    
    public T dequeue(){
        T item = first.item;
        first = first.next;
        if (isEmpty()){
            last = null;
        }
        N--;
        return item;
    }
    
    //iterator()的实现同stack
}
```

## 总结

使用链表具有以下的优点:

+ 它可以处理任意类型的数据;
+ 所需的空间总是和集合的大小成正比;
+ 操作所需的时间总是和集合的大小无关。

用更通俗的话说就是链表可以处理类型的数据(使用了泛型)。由于链表可以动态地调整大小,因此所需的空间总是和集合的大小成正比。
链表的添加和删除元素的操作都是由一些赋值语句来完成的,因此操作所需的时间总是和集合的大小无关,
这也正是Java中的``LinkedList``执行这些操作性能高的原因所在。

参考:

+ 人民邮电出版社,[《算法(第四版)》](https://book.douban.com/subject/10432347/)