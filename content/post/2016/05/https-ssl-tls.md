+++
date = "2016-05-04T21:46:00+08:00"
description = "简单说说HTTPS的运行机制"
draft = false
tags = ["SSL","TLS"]
title = "简单说说HTTPS的运行机制"
topics = ["HTTPS"]

+++

本文主要介绍HTTPS的运行机制,不涉及具体实现的细节,如果想了解这方面的内容,可参考[RFC文档](https://tools.ietf.org/html/rfc5246 "RFC文档")。

HTTPS是身披SSL/TLS外壳的HTTP,是为了解决HTTP在数据传输时有以下缺点而设计的。

+ 通信使用明文(不加密),内容可能会被窃听。

+ 不验证通信方的身份,因此有可能遭遇伪装。

+ 无法证明报文的完整性,所以有可能已遭篡改。<!--more-->

为了解决以上三大风险,HTTPS分别对应使用了以下三种方法:

+ 加密通信,防止被窃听。

+ 使用证书,验证身份。

+ 提供认证,一旦被篡改,双方会立刻发现。

因此,就可以得出,HTTPS=HTTP+加密+认证+完整性保护。

## HTTPS加密

SSL/TLS采用的是一种叫做**公开密钥加密**的方式,在了解公开密钥加密方式之前,先来了解一个与公开密钥加密方式相关的加密方式,
叫做**共享密钥加密**,也叫**对称密钥加密**。
共享密钥加密方式加密和揭秘是共享使用相同的密钥,因此在加密时就必须把密钥发送给对方,这就会造成一个问题,
如何才能把密钥安全地转交呢?如果密钥落入攻击者的手中,那么密钥也就失去了意义。

使用公开密钥加密方式避免了共享密钥加密方式的密钥转发的问题。公开密钥加密使用一对非对称的密钥,
一把叫做**公开密钥**(public key),一把叫做**私有密钥**(private key)。私有密钥不能让任何其他人知道,
而公开密钥则可以随意发布。

使用公开密钥加密方式的基本流程是,客户端向服务端索要公钥,然后客户端使用公钥加密数据,发送至服务端,
服务端使用自己的私钥再进行解密。这里会产生的两个问题是:

1. 如何确保服务端拿到的公钥是货真价实的公钥,而不是在转交的过程中已经被篡改了?

2. 由于加密解密都需要计算,因此会消耗CPU,那么如何确保服务端处理的性能呢?

针对以上两个问题,HTTPS的解决方案是:

1. 使用证书的机制。

2. HTTPS采用混合加密的方式,组合多种加密方式,在交换密钥环节使用公开密钥加密,建立了安全的连接后,
使用共享密钥加密的方式进行通信,提高处理请求的性能。

## 数字证书

数字证书的引入是为了解决服务端拿到的公钥的的确确就是服务端发出的,也就是能够确认服务端的身份。
数字证书一般由**数字证书认证机构**(CA,Certificate Authority)和其相关机构办法。

数字证书的认证过程为,首先服务器运营人员提出申请,把自己的公钥登录至数字证书认证机构,
数字证书认证机构在验证了申请者的身份之后,使用自己的私钥对服务器的公钥做数字签名,并颁发数字证书,
也就是公钥证书,并且与申请的公钥绑定。

在与客户端通信的时候,服务端会将公钥证书发送至客户端,客户端使用数字证书认证机构的公开密钥,
对收到的公钥证书进行验证,以确认服务器的公钥的真实性。

这里会产生的一个问题是,怎样才能安全获得数字认证机构的公开密钥呢?其实在大多数浏览器中都已经内置了一些权威的数字证书认证机构的公钥,
这些证书称为**根证书**(Root Certificate)。

![Root Certificate](http://7xsskq.com2.z0.glb.clouddn.com/blog/https-ssl-tls/root-certificate.png "Root Certificate")

当然,如果使用OpenSSL开源程序,那么我们自己可以给自己颁发证书,这种由自认证机构颁发的证书称为自签名证书,
但是自签名证书似乎并没有什么用途,浏览器无法识别自签名的证书,因此在访问使用自签名证书的站点时,会弹出安全警告。

## HTTPS的通信过程

在了解了HTTPS所采用的一些机制后,再来看一下HTTPS的整个通信过程。

客户端与服务器建立SSL/TLS连接的阶段称为**握手阶段**(handshake)。握手阶段的通信过程是这样的:

![HTTPS](http://7xsskq.com2.z0.glb.clouddn.com/blog/https-ssl-tls/https%202.png "HTTPS")

握手阶段主要涉及四次通信,我们一个一个详细地来看。

1. 客户端发送Client Hello报文开始SSL/TLS通信。报文中包含以下信息。

    + 客户端支持的SSL/TLS协议版本。
    + 加密组件(Cipher Suite)列表(所使用的加密算法及密钥长度等)。
    + 一个客户端生成的随机数。
 
2. 服务器以Server Hello报文作为回应。和客户端一样,在报文中包含SSL版本、加密组件及服务端生成的随机数。
服务器的加密组件内容是从接收到的客户端加密组件内筛选出来的。

    服务器发送Certificate报文。报文中包含公钥证书。如果服务器需要确认客户端的身份,就会再包含一项请求,
    要求客户端提供**客户端证书**。比如金融机构往往只允许认证用户连入自己的网络,就会向客户提供USB密钥,
    里面包含了一张客户端证书。

    服务器发送Server Hello Done报文通知客户端,最初阶段的SSL/TLS握手协商部分结束。

3. SSL/TLS第一次握手结束后,客户端验证服务器发送的证书的有效性,并取出公钥。
客户端以Client Key Exchange报文作为回应。报文包含通信加密中使用的一种被称为**Pre-master secret**的随机密码串,
并且该报文已经使用步骤3中的公钥加密。此外,如果前一步要求客户端证书,客户端会在这一步发送证书。

    服务器收到Pre-master secret后,服务端和客户端会基于之前总共生成的三个随机数生成Master Secret和本次的**会话密钥**。
    客户端发送Change Cipher Spec报文。该报文会提示服务器,在此报文之后的通信会采用会话密钥加密及Hash。

    客户端发送Finished报文。该报文包含前面发送的所有内容的Hash值,用来供服务器校验。

4. 服务器接收到Change Cipher Spec报文后同样发送Change Cipher Spec报文,并且之后使用会话密钥来进行对称加密,
服务器发送Finished报文。

至此,整个握手阶段结束,服务器与客户端的安全连接已经建立,之后所有的通信全部使用HTTP,只不过会使用会话密钥加密。

## SSL与TLS

SSL与TLS的关系,这里贴一段[MSDN](https://msdn.microsoft.com/en-us/library/windows/desktop/aa380515(v=vs.85).aspx "MSDN")上的原文

> TLS is a standard closely related to SSL 3.0, and is sometimes referred to as "SSL 3.1". 
TLS supersedes SSL 2.0 and should be used in new development. 
Applications that require a high level of interoperability should support SSL 3.0 and TLS. 
Because of the similarities between these two protocols, SSL details are not included in this documentation, except where they differ from TLS.
The following is from RFC 2246: "The differences between this protocol and SSL 3.0 are not dramatic, 
but they are significant enough that TLS 1.0 and SSL 3.0 do not interoperate (although TLS 1.0 does incorporate a mechanism by which a TLS implementation can back down to SSL 3.0)."

总的来说就是,TLS是一个与SSL3.0版本密切相关的标准,TLS是以SSL为原型开发的,有时候被称为SSL3.1。

参考:

+ MSDN,[TLS Handshake Protocol](https://msdn.microsoft.com/en-us/library/windows/desktop/aa380513(v=vs.85).aspx "TLS Handshake Protocol")
+ 阮一峰,[SSL/TLS协议运行机制的概述](http://www.ruanyifeng.com/blog/2014/02/ssl_tls.html "SSL/TLS协议运行机制的概述")
+ 人民邮电出版社,《[图解HTTP](https://book.douban.com/subject/25863515/ "图解HTTP")》