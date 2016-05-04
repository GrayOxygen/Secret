+++
date = "2016-05-02T22:48:28+08:00"
description = "HTTP Request Header中的If-xxx字段"
draft = false
tags = ["Request Header","If-xxx"]
title = "HTTP Request Header中的If-xxx字段"
topics = ["HTTP"]

+++

在HTTP的Request Header中经常会出现**If-xxx**形式的字段,带这些字段的请求称为条件请求,
服务器在接收到这些请求后,只有判断指定条件为真时,才会执行请求。

在说这些If-xxx的字段之前,首先需要了解一个会出现在Response Header中的字段——**ETag**,
它是一种可将资源以字符串形式做唯一性标识的方式。服务器会为每份资源分配对应的ETag值。
当资源更新时,ETag值也需要更新。<!--more-->

ETag可分为强ETag值和弱ETag值。强ETag值表示不论发生多么细微的变化都会改变其值。
```
Etag:"f03e5a3bf534f4a738bc350631fd05bd"
```
弱ETag值只用于提示资源是否相同,只有资源发生了根本改变,产生差异时才会改变ETag值,并会在字段最开始处附加W/。
```
Etag:W/"f03e5a3bf534f4a738bc350631fd05bd"
```

## If-Match和If-None-Match

If-Match和If-None-Match是一对条件相反的请求头部字段,只要知道了其中的一个含义,
另一个取相反的含义即可。

```
If-Match:"3f05a51a1e5260f4179db8ca65307a6a"
```

If-Match字段的值是一个ETag值,只有当这个ETag值与所请求的服务器上资源的ETag值相同时,
服务器才会处理这个请求,并且这时服务器无法使用弱ETag值。如果两者不同,则返回状态码``412 Precondition Failed``的响应。

```
If-None-Match:W/"3f05a51a1e5260f4179db8ca65307a6a"
```

If-None-Match的含义正好与If-Match相反,只有当请求的ETag值与服务器上资源的ETag值不同时,服务器才接收这个请求。
这个字段可以用来获取最新的资源。

## If-Modified-Since和If-Unmodified-Since

这也是一对条件相反的请求头部字段。

```
If-Modified-Since:Wed, 18 Mar 2015 08:46:53 GMT
```

表示在If-Modified-Since字段指定的日期时间之后,资源发生了更新,服务器会接收请求。
如果在If-Modified-Since字段值的日期之后没有更新过资源,返回状态码``304 Not Modified``。
If-Modified-Since用于确认代理或客户端拥有本地资源的有效性。可通过**Last-Modified**字段来获取资源的更新时间。

```
If-Unmodified-Since:Thu, 03 Jul 2012 08:46:53 GMT
```

If-Unmodified-Since表示指定的资源只有在字段值内指定的日期之后,未发生更新的情况下,才能处理请求。
如果在指定日期之后发生了更新,返回状态码``412 Precondition Failed``作为响应返回。

## If-Range

```
If-Range:"9a108ac6ff91842e143af3a243fb5ea3"
Rage:bytes=5001-10000
```

If-Range字段的值也是一个ETag值,如果If-Range字段的值与请求的资源的ETag值相同,那么就作为范围请求处理,
范围由Range头部字段指定,返回状态码``206 Partial Content``,反之,则返回全部资源,状态码为``200 OK``。

好了,以上就是对HTTP Request Header中If-xxx形式的字段的简单介绍。