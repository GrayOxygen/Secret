+++
date = "2016-05-25T23:10:44+08:00"
description = "理解Java中的hashCode()方法"
draft = true
tags = ["Hash","HashCode"]
title = "理解Java中的hashCode()方法"
topics = ["Java"]

+++

Java中的``hashCode()``方法,是Java中的顶层对象``Object``中的方法,因此Java中所有的对象都会带有``hashCode()``方法。
在各种最佳实践中,都会建议在编写自己的类的时候要同时覆盖``hashCode()``和``equals()``方法,
但是在使用散列的数据结构时(``HashMap``,``HashSet``,``LinkedHashSet``,``LinkedHashMap``),
如果不为键覆盖``hashCode()``和``equals()``方法,将无法正确的处理该键。<!--more-->

``hashCode()``方法返回一个int值,这个int值就是用这个对象的``hashCode()``方法产生的hash值。
在散列表中查找一个值的过程为,先通过键的``hashCode()``方法计算hash值,然后使用hash值产生下标并使用下标查找数组,
这里为什么要用数组呢,因为数组是存储一组元素最快的数据结构,因此使用数组来表示键的信息(也就是值)。

由于数组的容量是固定的,所以不同的键可以产生相同的下标(下标由hash值产生),也就是说,可能会有冲突,
因此数组多大就不重要了,任何键总能在数组中找到它的位置。

数组并不直接保存值,因为不同的键可能产生相同的数组下标,数组保存的是值的list,因此,
散列表的存储结构外层是一个数组,容量固定,数组的每一项都是保存着值的list,list的长度是可变的,
键使用``hashCode()``方法产生hash值后,利用hash值产生数组的下标,找到值在散列表中的**桶位(bucket)**,也就是在哪一个list中,
之后再对该list中的值使用``equals()``方法进行线性的查询,最后找到该键的值。

最后对list进行线性查询的部分会比较慢,但是,如果散列函数好的话,数组的每个位置就只有较少的值,
因此不是查询整个list,而是快速地跳到数组的某个位置,只对很少的元素进行比较,这就是``HashMap``会如此快的原因。

在知道了散列的原理后我们可以自己实现一个简单的``HashMap``(例子来源于《Java编程思想(第四版)》)

```
public class SimpleHashMap<K, V> extends AbstractMap<K, V> {
    static final int SIZE = 997;

    @SuppressWarnings("unchecked")
    LinkedList<MapEntry<K, V>>[] buckets = new LinkedList[SIZE];

    public V put(K key, V value) {
        V oldValue = null;
        int index = Math.abs(key.hashCode()) % SIZE;
        if (buckets[index] == null) {
            buckets[index] = new LinkedList<>();
        }
        LinkedList<MapEntry<K, V>> bucket = buckets[index];

        MapEntry<K, V> pair = new MapEntry<>(key, value);
        boolean found = false;
        ListIterator<MapEntry<K, V>> it = bucket.listIterator();
        while (it.hasNext()) {
            MapEntry<K, V> iPair = it.next();
            if (iPair.getKey().equals(key)) {
                oldValue = iPair.getValue();
                it.set(pair);
                found = true;
                break;
            }
        }
        if (!found) {
            buckets[index].add(pair);
        }
        return oldValue;
    }

    @Override
    public V get(Object key) {
        int index = Math.abs(key.hashCode()) % SIZE;
        if (buckets[index] == null) {
            return null;
        }
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

hashCode()good