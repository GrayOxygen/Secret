+++
date = "2017-07-15T18:01:10+08:00"
description = "Java并发编程Tips"
draft = false
tags = ["Concurrent Programming"]
title = "Java并发编程Tips"
topics = ["Java"]

+++

距离上一次更新博客已经过去了半年的时间了。现在回过头来看，这半年我学习了关于Java并发编程、JVM、设计模式、ES相关的内容。
一直没更新博客原因，一是因为自己懒，工作一忙就懒得再去花时间写博客，二是因为总觉得看的越多越不知道要写什么，总结下来还是深度不够，
以后除了广度外，还要注重技术积累的深度。这篇博客将会写一些前段时间学习的关于Java并发编程的Tips，之所以称为Tips，
意思是写的点可能会比较散，不是那么系统，但都是一些在Java并发编程中非常常用的东西。<!--more-->

## 对象的共享

+ 一般在多线程中如果要共享某一个对象，我们会使用同步的机制，防止对象被其它线程意外的修改，也就是说保证只有拿到锁的对象能修改这个对象，
但是使用锁除了能保证互斥以外，还包括内存的可见性。为了确保所有线程都能看到共享变量的最新值，
所有执行读操作或者写操作的线程都必须在**同一个**锁上同步。

```java
    private static final Object mutex = new Object();
    private final List<Integer> list = new ArrayList<>();

    public void increase() {
        synchronized (mutex) {
            for (int i = 0; i < 10; i++) {
                list.add(i);
            }
        }
    }
```

+ volatile变量。当且仅当满足以下所有条件时，才应该使用volatile变量。
  1. 对变量的写入操作不依赖变量的当前值，或者你能确保只有单个线程更新变量的值。
  2. 该变量不会与其它状态变量一起纳入不变性条件中。
  3. 在访问变量时不需要加锁。
  
## 对象的组合

在并发编程中会使用到一些线程安全的集合，但是使用线程安全的集合也不一定就一定就能保证线程的安全。

```java
public class ListHelper<E> {

    public final List<E> list = Collections.synchronizedList(new ArrayList());

    //必须使用同一个锁，因此在list上同步
    public boolean putIfAbsent(E x) {
        synchronized(list) {
            boolean absent = !list.contains(x);
            if (absent) {
                list.add(x);
            }
            return absent;
        }
    }    

}
```

在上面的例子中，``list``是一个同步的集合，但是``putIfAbsent``方法仍然需要显式的同步，这是因为其实``putIfAbsent``方法分为两步，
首先判断list中是否包含元素x，如果不包含则将x放到list中，虽然list本身是线程安全的，但在这里是一个复合操作，这个操作不是原子的，
因此会有线程安全的问题，必须使用同步来把这两个操作变为原子操作。

除了使用JDK提供的线程安全的集合外，也可以选择自己封装。

```java
//improvedList通过自身的内置锁增加了一层额外的加锁, Java监视器模式来封装现有的list

public class ImprovedList<T> implements List<T> {

    private final List<T> list;

        public ImprovedList(List<T> list) {
            this.list = list;
        }

        public synchronized boolean putIfAbsent(T x) {
            boolean contains = list.contains(x);
            if (contains) {
                list.add(x);
            }
            return !contains;
        }

        @Override
        public synchronized void clear() {
            list.clear();
        }
}
```

## 同步工具类

+ 闭锁（Latch）

``CountDownLatch``是一个非常有用的类。当在一些异步的场景中需要使用同步时，可以使用。比如有两个线程A和B同时执行两个task，
现在要求程序必须在A和B的任务都完成之后才能走到下一步，这时候就可以使用``CountDownLatch``。

```java
//每个线程首先要在启动门上等待，执行task完毕后调用结束门的countDown方法减1
//最后等待所有的线程执行完毕

public class CountDownLatchTest {

    public long timeTasks(int nThreads, final Runnable task) throws InterruptedException {
    final CountDownLatch startGate = new CountDownLatch(1);
    final CountDownLatch endGate = new CountDownLatch(nThreads);

    for (int i = 0;i < nThreads;i++) {
        Thread r = new Thread(() -> {
            try {
                startGate.await();
                try {
                    task.run();
                } finally {
                    endGate.countDown();
                }
            } catch (InterruptedException e) {
                
            }
        });
        t.start();
    }
    
    long start = System.nanoTime();
    startGate.countDown();
    endGate.await();
    long end = start - System.nanoTime();
    return end;
  }

}
```

+ 信号量（Semaphore）

``Semaphore``也是非常有用的类。它一般会管理着一组虚拟的许可（permit），许可的初始数量可以通过构造函数来执行。在执行时可以先获得许可（只要还有剩余的许可），
并在使用以后释放许可。如果没有可用的许可，那么``acquire``将阻塞直到有许可（或者直到被中断或者操作超时）。``release``方法将返回一个许可给信号量。
可以通过使用信号量来实现接口的限流等等。

```java
//使用Semaphore实现有界的HashSet

public class BoundedHashSet<T> {

    private final Set<T> set;
    private final Semaphore sem;

    public BoundedHashSet(int bound) {
        this.set = Collections.synchronizedSet(new HashSet<T>());
        sem = new Semaphore(bound);
    }

    public boolean add(T o) throws InterruptedException {
        sem.acquire();
        boolean wasAdded = false;
        try {
            wasAdded = set.add(o);
            return wasAdded;
        } finally {
            if (!wasAdded) {
                sem.release();
            }
        }
    }

    public boolean remove(Object o) {
        boolean wasRemoved = set.remove(o);
        if (wasRemoved) {
            sem.release();
        }
        return wasRemoved;
    }    
}
```

## 线程池的使用

+ 在并发编程中肯定会用到线程池，一般都会使用JDK提供的``ExecutorService``，在构造线程池时需要我们自己提供一些参数，
其中有一项参数叫做线程池的基本大小（Core Pool Size），也就是线程池的目标大小，即在没有任务执行时线程池的大小，
这里需要注意的是，只有在工作队列满了的情况下（除了使用SynchronousQueue的情况），才会创建超出这个数量的线程。

因此设置这个参数时需要特别注意，不然可能会造成所有的任务都串行的情况，比如下面这样。

```java
//这样会串行，因为工作队列没有满，基本大小为1，且没有指定工作队列的容量，（使用SynchronousQueue不会有这么问题）
//如果不设置容量，那么工作队列永远不会满，也就会一直串行执行！！
public class ThreadPoolTest {
    
    private static final ExecutorService executors = new ThreadPoolExecutor(1, 10, 10L, TimeUnit.SECONDS,new LinkedBlockingQueue<>());

    public static void main(String[] args) {
        for (int i = 0;i < 10;i++) {
            executors.execute(() -> {
                try {
                    Thread.sleep(1000L);
                } catch(Exception e){}
                System.out.println(Thread.currentThread().getName());
            });
        }
        
    }

}
```

+ 在使用线程池的时候有几种工作队列的选择。比如``LinkedBlockingQueue``、``ArrayBlockingQueue``等。其中比较特殊的是``SynchronousQueue``，
它实际上不是一个真正的队列，因为它不会像其它阻塞队列一样为元素维护存储空间。与其它队列不同是，它维护一组线程，这些线程在等待着把元素加入或移出队列。
仅当有足够的消费者时，并且总有一个消费者准备好获取交付的工作时，才适合使用同步队列。``newCachedThreadPool``就是使用的这种队列，
因为``newCachedThreadPool``的线程是没有上限的，比较符合使用``SynchronousQueue``的场景。

## 死锁

说到并发就不得不提到死锁的问题。为了不发生死锁的情况，我们应该保证所有线程以固定的顺序来获得锁。

来看一个《Java并发编程实战》中的例子。

```java
public void transferMoney(Account fromAccount, Account toAccount, DollarAmount amount) throw InsufficientFundsException {
    synchronized(fromAccount) {
        synchronized(toAccount) {
            if (fromAccount.getBalance().compareTo(amount) < 0) {
                throw new InsufficientFundsException();
            } else {
                fromAccount.debit(amount);
                toAccount.credit(amount);
            }
        }
    }
}
```

假设有这么一个转钱的方法，从fromAccount转到toAccount，方法中需要先获得fromAccount的锁，再获得toAccount的锁，
如果我们这样去调用：

```java
A:transferMoney(myAccount, yourAccount, 10);
B:transferMoney(yourAccount, myAccount, 20);
```

很明显，这样会有发生死锁的风险，有可能出现的情况是，两个线程同时调用``transferMoney``，一个X向Y转账，一个Y向X转账，也就会发生A已经获得了myAccount的锁，
尝试获取yourAccount的锁，B已经获得了yourAccount的锁，尝试获取myAccount的锁，这样就发生了死锁。

为了消除这种死锁的风险，需要保证所有线程以固定的顺序来获得锁，针对上面的情况《Java并发编程实战》中给的方案为：

```java
//比较hash值的大小来确定获取锁的顺序，如果hash值相同，那么使用一个全局锁。消除了发生死锁的可能性
private static final Object tieLock = new Object();

public void transferMoney(final Account fromAcct, final Account toAcct, final DollarAmount amount) throws InsufficientFundsException {
    
    class Helper {
        public void transfer() {
            //transfer money
        }
    }

    int fromHash = System.identityHashCode(fromAcct);
    int toHash = System.identityHashCode(toAcct);

    if (fromHash < toHash) {
        synchronized(fromAcct) {
            synchronized(toAcct) {
                new Helper().transfer();
            }
        }
    } else if (fromHash > toHash) {
        synchronized(toHash) {
            synchronized(fromAcct) {
                new Helper().transfer();
            }
        }
    } else {
        synchronized(tieLock) {
            synchronized(fromAcct) {
                synchronized(toAcct) {
                    new Helper().transfer();
                }
            }
        }
    }

}
```

## 状态依赖性管理

当使用条件队列时，必须先获得对象上的锁。这是因为"等待由状态构成的条件"与"维护状态一致性"这两种机制必须被紧密地绑定在一起：
只有能对状态进行检查时，才能在某个条件上等待，并且只有能够修改状态时，才能从条件等待中释放另外一个线程。

Object.wait会自动释放锁，并请求操作系统挂起当前线程，从而使其它线程能够获得这个锁并修改对象的状态。当被挂起的线程醒来时，
它将在返回之前重新获取锁。

```java
public class BoundedBuffer<V> {
    
    //调用条件队列上的方法，先持有内部锁
    //阻塞并直到: not-full
    public synchronized void put(V v) throws InterruptedException {
        while(isFull()) {
            wait();
        }
        doPut(v);
        notifyAll();
    }

    //调用条件队列上的方法，先持有内部锁
    //阻塞并直到:not-empty
    public synchronized V doTake() throws InterruptedException {
        while(isEmpty()) {
            wait();
        }
        V v = doTake();
        notifyAll();
        return v;
    }
}
```

等待条件的标准形式：

1. 通常都有一个谓词——包括一些对象状态的测试，线程在执行前必须首先通过这些测试。
2. 在调用``wait``之前测试条件谓词，并且从``wait``中返回时再次测试。
3. 在一个循环中调用``wait``。
4. 确保使用与条件队列相关的锁来保护构成条件谓词的各个状态变量。
5. 当调用``wait``、``notify``或``notifyAll``等方法时，一定要持有与条件队列相关的锁。
6. 在检查条件谓词之后以及开始执行相应的操作之前，不要释放锁。

```java
void stateDependentMethod() throws InterruptedException {
    synchronized(lock) {
        while(!conditionPredicate()) {
            lock.wait();
        }
    }
}
```

优先使用``notifyAll``。只有同时满足以下两个条件时，才使用单一的``notify``而不是``notifyAll``：

1. 所有等待线程的类型相同。只有一个条件谓词与条件队列相关，并且每个线程在``await``返回之后将执行相同的操作。
2. 单进单出。在条件变量上的每次通知，最多只能唤醒一个线程来执行。

## 显式的``Condition``对象

相比较使用``wait``和``notifyAll``的组合。使用``Condition``对象能实现更精准的等待与唤醒。在JDK实现的线程池中，
也是通过使用``Condition``对象来等待与唤醒的。

与内置锁与条件队列一样，当使用显式的``Lock``和``Conditon``对象时，也必须满足锁、条件谓词和条件变量之间的三元关系。
在条件谓词中包含的变量必须由``Lock``来保护，并且在检查条件谓词及调用``await``和``signal``时，必须持有``Lock``对象。

```java
public class ConditionBoundedBuffer<T> {
    protected final Lock lock = new ReentrantLock();
    private final Condition notFull = lock.newCondition();
    private final Condition notEmpty = lock.newCondition();
    
    private final T[] items = (T[])new Object[10];
    private int tail, head, count;

    public void put(T x) throws InterruptedException {
        lock.lock();
        try {
            while(count = items.lenth) {  //持有锁保护条件谓词中的变量
                notFull.await();
            }
            items[tail] = x;
            if (++tail == items.length) {
                tail = 0;
            }
            ++count;
            notEmpty.signal();
        } finally {
            lock.unlock();
        }
    }

    public T take() throws InterruptedException {
        lock.lock();
        try {
            while(count == 0) {
                notEmpty.await();
            }
            T x = items[head];
            items[head] = null;
            if (++head == items.length) {
                head = 0;
            }
            --count;
            notFull.signal();
            return x;
        } finally {
            lock.unlock();
        }
    }
}
```

以上就是在学习Java并发编程过程中的一些Tips，主要来自与《Java并发编程实战》这本书中，不得不说经典就是经典，
个人认为看了这本书之后可以对Java并发编程的理解提高一个层次，强烈推荐。