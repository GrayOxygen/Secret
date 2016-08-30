+++
date = "2016-08-30T14:05:23+08:00"
description = "Docker基本命令"
draft = false
tags = ["Docker基本命令"]
title = "Docker基本命令"
topics = ["Docker"]

+++

Docker是一个近年来非常火热的开源项目，使用Docker可以将我们的应用程序打包，非常方便。最近简单地学习了一下Docker的基本使用，在此做一个学习笔记。

## 安装

使用的第一步当然就是安装了，可以到Docker的[官网](https://www.docker.com/products/overview)上，根据不同操作系统下载安装即可。

安装完成之后可以在命令行中运行

```
docker --version
```

如果安装正确，那么会输出相应的版本信息

```
Docker version 1.12.0, build 8eab29e
```

## Docker镜像(image)命令

安装完成之后，就可以下载镜像了。类似于Github，Docker也有一个[DockerHub](https://hub.docker.com/)，当我们``pull``镜像的时候是从DockerHub上下载相应的镜像。除了可以在DockerHub检索镜像以外，还可以使用以下命令检索：

```
docker search 镜像名
```

比如搜索Redis镜像：

```
docker search redis
```

可以得到以下结果：

```
NAME                      DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
redis                     Redis is an open source key-value store th...   2626      [OK]       
sameersbn/redis                                                           33                   [OK]
torusware/speedus-redis   Always updated official Redis docker image...   30                   [OK]
bitnami/redis             Bitnami Redis Docker Image                      23                   [OK]
anapsix/redis             11MB Redis server image over AlpineLinux        6                    [OK]
webhippie/redis           Docker images for redis                         5                    [OK]
williamyeh/redis          Redis image for Docker                          3                    [OK]
clue/redis-benchmark      A minimal docker image to ease running the...   3                    [OK]
unblibraries/redis        Leverages phusion/baseimage to deploy a ba...   2                    [OK]
miko2u/redis              Redis                                           1                    [OK]
greytip/redis             redis 3.0.3                                     1                    [OK]
servivum/redis            Redis Docker Image                              1                    [OK]
kampka/redis              A Redis image build from source on top of ...   1                    [OK]
appelgriebsch/redis       Configurable redis container based on Alpi...   0                    [OK]
yfix/redis                Yfix docker redis                               0                    [OK]
cloudposse/redis          Standalone redis service                        0                    [OK]
watsco/redis              Watsco redis base                               0                    [OK]
nanobox/redis             Redis service for nanobox.io                    0                    [OK]
xataz/redis               Light redis image                               0                    [OK]
trelllis/redis            Redis Replication                               0                    [OK]
khipu/redis               customized redis                                0                    [OK]
maestrano/redis           Redis is an open source key-value store th...   0                    [OK]
rounds/10m-redis          redis for hubot brain                           0                    [OK]
higebu/redis-commander    Redis Commander Docker image. https://gith...   0                    [OK]
drupaldocker/redis        Redis for Drupal                                0                    [OK]
```
