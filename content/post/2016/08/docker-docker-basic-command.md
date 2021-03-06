+++
date = "2016-08-30T14:05:23+08:00"
description = "Docker基本命令"
draft = false
tags = ["Docker基本命令"]
title = "Docker基本命令"
topics = ["Docker"]

+++

Docker是一个近年来非常火热的开源项目，使用Docker作为容器并将我们的应用程序运行在Docker中方便部署及测试，也利于开发环境的隔离。最近简单地学习了一下Docker的基本使用，在此做一个学习笔记。<!--more-->

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

安装完成之后，就可以下载镜像了。类似于Github，Docker也有一个[DockerHub](https://hub.docker.com/)，当我们``pull``镜像的时候是从DockerHub上下载相应的镜像。除了可以在``https://registry.hub.docker.com/``检索镜像以外，还可以使用以下命令检索：

### Docker镜像搜索

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

可以看到第一个就是官方的镜像。

### 镜像下载

检索到镜像之后就是下载镜像，还是以Redis为例：

```
docker pull redis
```

### 镜像列表

下载完成之后可以查看本地镜像

```
docker images

#output：

REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
redis               latest              50e38ce0458f        3 days ago          185 MB
```

REPOSITORY是镜像名;TAG是软件版本，latest为最新版;IMAGE ID是当前镜像的唯一标示;CREATED是当前镜像创建时间;SIZE是当前镜像的大小。

### 镜像删除

如果需要删除一个镜像，可以使用以下命令

```
docker rmi image-id
```

删除所有镜像

```
docker rmi ${docker images -q}
```

## Docker容器命令

### 容器基本操作

最简单的运行镜像为容器

```
docker run —-name container-name -d image-name
```

--name参数是为容器取的名字，-d表示detached，在后台运行容器，image-name是要使用哪个镜像来运行容器。

运行一个Redis容器

```
docker run --name test-redis -d redis
```

### 容器列表

查看运行中的容器列表

```
docker ps
```

可以看到我们之前运行的Redis容器

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
b45e490b7f99        redis               "docker-entrypoint.sh"   15 minutes ago      Up 4 seconds        6379/tcp            test-redis
```

CONTAINER ID是在启动的时候Docker生成的ID；IMAGE是该容器使用的镜像；COMMAND是容器启动时调用的命令；CREATED是容器的创建时间；STATUS是当前容器的状态；PORTS是容器系统所使用的端口号(注意，这里的端口号不是本机的端口号)，Redis默认使用6379端口；NAMES是给容器定义的名称。

查看运行和停止状态的容器

```
docker ps -a
```

### 停止和启动容器

**停止容器**

```
docker stop container-name/container-id
```

通过容器名称或者容器id来停止容器，例如停止之前的Redis容器：

```
docker stop test-redis
```

**启动容器**

```
docker start container-name/container-id
```

再次启动之前的容器

```
docker start test-redis
```

**端口映射**

Docker中运行的程序的端口是不能直接访问的，需要映射到本地，通过-p参数实现，例如将6379端口映射到本机的6378端口

```
docker run -d -p 6378:6379 —-name port-redis redis
```

运行一个名字为port-redis的容器，使用redis镜像，将Docker中的redis的6379端口映射到本机的6378端口。

映射完成之后我们就可以连接Redis进行开发等等，非常方便。

**删除容器**

删除单个容器

```
docker rm container-id
```

删除所有容器

```
docker rm ${docker ps -a -q}
```

**容器日志**

查看当前容器的日志

```
docker logs container-name/container-id
```

我们可以查看之前redis镜像的容器

```
docker logs test-redis
```

可以看到redis启动的日志

**登录容器**

运行中的容器其实就是一个完备的Linux操作系统，我们可以登录访问当前容器，登录后可以在容器中进行常规的Linux操作。

```
docker exec -it container-id/container-name bash
```

使用``exit``命令退出当前登录。
