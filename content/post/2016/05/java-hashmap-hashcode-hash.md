+++
date = "2016-05-25T23:10:44+08:00"
description = "理解Java中HashMap的工作原理"
draft = false
tags = ["Hash","HashMap"]
title = "理解Java中HashMap的工作原理"
topics = ["Java"]

+++

Java中的HashMap使用散列来高效的查找和存储值。HashMap内部使用``Map.Entry``的形式来保存key和value,
使用``put(key,value)``方法存储值,使用``get(key)``方法查找值。

## 理解hashCode()

Java中的``hashCode()``方法,是顶层对象``Object``中的方法,因此Java中所有的对象都会带有``hashCode()``方法。
在各种最佳实践中,都会建议在编写自己的类的时候要同时覆盖``hashCode()``和``equals()``方法,
但是在使用散列的数据结构时(``HashMap``,``HashSet``,``LinkedHashSet``,``LinkedHashMap``),
如果不为键覆盖``hashCode()``和``equals()``方法,将无法正确的处理该键。<!--more-->

``hashCode()``方法返回一个int值,这个int值就是用这个对象的``hashCode()``方法产生的hash值。

## HashMap的工作原理

在散列表中查找一个值的过程为,先通过键的``hashCode()``方法计算hash值,然后使用hash值产生下标并使用下标查找数组,
这里为什么要用数组呢,因为数组是存储一组元素最快的数据结构,因此使用数组来表示键的信息。

由于数组的容量(也就是表中的桶位数)是固定的,所以不同的键可以产生相同的下标,也就是说,可能会有冲突,
因此数组多大就不重要了,任何键总能在数组中找到它的位置。

数组并不直接保存值,因为不同的键可能产生相同的数组下标,数组保存的是LinkedList,因此,
散列表的存储结构外层是一个数组,容量固定,数组的每一项都是保存着``Entry Object``(同时保存key和value)的LinkedList。

由于下标的冲突,不同的键可能会产生相同的``bucket location``,在使用``put(key,value)``时,
如果两个键产生了相同的``bucket location``,由于LinkedList的长度是可变的,
所以会在该LinkedList中再增加一项``Entry Object``,其中保存着key和value。

键使用``hashCode()``方法产生hash值后,利用hash值产生数组的下标,找到值在散列表中的**桶位(bucket)**,
也就是在哪一个LinkedList中,如果该桶位只有一个的Object,则返回该Value,如果该桶位有多个Object,
那么再对该LinkedList中的``Entry Object``的键使用``equals()``方法进行线性的查询,最后找到该键的值并返回。

最后对LinkedList进行线性查询的部分会比较慢,但是,如果散列函数好的话,数组的每个位置就只有较少的值,
因此不是查询整个LinkedList,而是快速地跳到数组的某个位置,只对很少的元素进行比较,这就是``HashMap``会如此快的原因。

在知道了散列的原理后我们可以自己实现一个简单的``HashMap``(例子来源于《Java编程思想(第四版)》)

```
public class SimpleHashMap<K, V> extends AbstractMap<K, V> {
    //内部数组的容量
    static final int SIZE = 997;

    //buckets数组,内部是一个链表,链表的每一项是Map.Entry形式,保存着HashMap的值
    @SuppressWarnings("unchecked")
    LinkedList<MapEntry<K, V>>[] buckets = new LinkedList[SIZE];

    public V put(K key, V value) {
        V oldValue = null;
        //使用hashCode()方法产生hash值,使用hash值与数组容量取余获得数组的下标
        int index = Math.abs(key.hashCode()) % SIZE;
        //如果该桶位为null,则插入一个链表
        if (buckets[index] == null) {
            buckets[index] = new LinkedList<>();
        }
        //获得bucket
        LinkedList<MapEntry<K, V>> bucket = buckets[index];
               
        MapEntry<K, V> pair = new MapEntry<>(key, value);
        boolean found = false;
        
        ListIterator<MapEntry<K, V>> it = bucket.listIterator();
        while (it.hasNext()) {
            MapEntry<K, V> iPair = it.next();
            //对键使用equals()方法线性查询value
            if (iPair.getKey().equals(key)) {
                oldValue = iPair.getValue();
                //找到了键以后更改键原来的value
                it.set(pair);
                found = true;
                break;
            }
        }
        //如果没找到键,在bucket中增加一个Entry
        if (!found) {
            buckets[index].add(pair);
        }
        return oldValue;
    }
    
    //get()与put()的工作方式类似
    @Override
    public V get(Object key) {
        //使用hashCode()方法产生hash值,使用hash值与数组容量取余获得数组的下标
        int index = Math.abs(key.hashCode()) % SIZE;
        if (buckets[index] == null) {
            return null;
        }
        //使用equals()方法线性查找键
        for (MapEntry<K, V> iPair : buckets[index]) {
            if (iPair.getKey().equals(key)) {
                return iPair.getValue();
            }
        }
        return null;
    }

    @Override
    public Set<Map.Entry<K, V>> entrySet() {
        Set<Map.Entry<K, V>> set = new HashSet<>();
        for (LinkedList<MapEntry<K, V>> bucket : buckets) {
            if (bucket == null) {
                continue;
            }
            for (MapEntry<K, V> mpair : bucket) {
                set.add(mpair);
            }
        }
        return set;
    }

    public static void main(String[] args) {
        SimpleHashMap<String, String> m = new SimpleHashMap<>();
        m.putAll(Countries.capitals(25));
        System.out.println(m);
        System.out.println(m.get("ERITREA"));
        System.out.println(m.entrySet());
    }
}

```

## 编写良好的hashCode()方法

如果``hashCode()``产生的hash值能够让HashMap中的元素均匀分布在数组中,可以提高HashMap的运行效率。
一个良好的``hashCode()``方法首先是能快速地生成hash值,然后生成的hash值能使HashMap中的元素在数组中尽量均匀的分布,
hash值不一定是唯一的,因为容量是固定的,总会有下标冲突的情况产生。

《Effective Java》中给出了覆盖``hashCode()``方法的最佳实践:

1. 把某个非零的常数值,比如17,保存在一个名为result的int类型中。

2. 对于对象中的每个关键域f(指``equals()``方法中涉及的域),完成以下步骤:

  + 为该域计算int类型的散列码c,根据域的类型的不同,又可以分为以下几种情况:
  
    - 如果该域是boolean类型,则计算``(f?1:0)``
    - 如果该域是String类型,则使用该域的``hashCode()``方法
    - 如果该域是byte、char、short或int类型,则计算``(int)f``
    - 如果该域是long类型,则计算``(int)(f^>>>32)``
    - 如果该域是float类型,则计算``Float.floatToIntBits(f)``
    - 如果该域是double类型,则计算``Double.doubleToLongBits(f)``返回一个long类型的值,再根据long类型的域,生成int类型的散列码
    - 如果该域是一个对象引用,并且该类的``equals()``方法通过递归调用equals方式来比较这个域,则同样为这个域递归地调用``hashCode()``
    - 如果该域是一个数组,则要把每一个元素当作单独的域来处理,也就是说递归地应用上述原则

3. 按照公式:**result = 31 * result + c**,返回result。

写一个简单的类并用上述的规则来覆盖``hashCode()``方法

```
public class SimpleHashCode {
    private static long counter = 0;
    private final long id = counter++;
    private String name;
    
    @Override
    public int hashCode(){
        int result = 17;
        if (name != null){
            result = 31 * result + name.hashCode(); 
        }
        result = result * 31 + (int) id;
        return result;
    }
    
    @Override
    public boolean equals(Object o){
        return o instanceof SimpleHashCode && id == ((SimpleHashCode)o).id;
    }
}
```

参考:

+ Javin Paul, [How HashMap works in Java](http://javarevisited.blogspot.jp/2011/02/how-hashmap-works-in-java.html "How HashMap works in Java")
+ 机械工业出版社, [《Java编程思想(第四版)》](https://book.douban.com/subject/2061172/ "Java编程思想第四版")
+ 机械工业出版社, [《Effective Java》](https://book.douban.com/subject/3360807/ "Effective Java")
