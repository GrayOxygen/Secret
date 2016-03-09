+++
date = "2016-03-08T17:29:46+08:00"
draft = false
title = "使用Hugo搭建个人博客"
tags = ["Go","Hugo","Blog"]
description = "使用Hugo搭建个人博客"
keywords = ["Go","Hugo","Blog"]
author = "listen"
+++

Hugo是一个用Go语言编写的静态博客生成工具,使用Hugo可以非常方便的生成个人的静态博客站点。

## 安装Hugo

Hugo的安装有几种方法:

1. 直接下载编译后的二进制分发包。Hugo在Github上的项目地址是:https://github.com/spf13/hugo ,可以去下载编译后的二进制分发包。
截至目前,最新的版本是0.15,根据自己的操作系统环境下载编译完后的压缩包。<!--more-->下载完成后可以解压在任意的位置,比如说解压在~/Hugo下:
```
tar xvf hugo_0.15_linux_amd64.tar.gz -C ~/Hugo
```
解压完成后会有一个可执行文件hugo,将这个文件所在路径加到环境变量中,方便我们使用:
```
export PATH=~/Hugo:$PATH
```
不要忘了加上最后的$PATH,否则会把原来的环境变量覆盖。至此,我们已经安装好了Hugo,并且可以在任何位置在命令行中使用Hugo命令。

2. 源码安装。如果你熟悉Go语言,那么可以直接从源码安装,具体的安装过程与普通的Go语言项目是一样的,注意设置好$GOPATH环境变量即可。
```
export GOPATH=$HOME/go
go get -v -u github.com/spf13/hugo
```
在安装的过程中可能会出现有几个依赖的package go get不到的情况,原因是原来托管在golang.org官网上的package貌似已经
被移走了,解决方法是可以到Go语言的官方Github仓库里,有相关package的镜像仓库,可以从镜像手动下载依赖的package,并按package的路径要求手动copy即可。
安装完成后在$GOPATH/bin目录下就是Hugo工具,可以把它加到环境变量中,方便使用,加的方法同上,这里就不多说了。

3. 如果使用的是Mac OSX系统,可以直接使用HomeBrew安装,非常的简单,只要一行命令:
```
brew update && brew install hugo
```
使用brew安装完后不需要手动添加环境变量,直接在命令行中使用hugo命令即可使用。

## 生成博客

安装完成后,就可以来生成博客了。
```
hugo new site path/to/site
```
进入博客目录
```
cd path/to/site
```
这个时候可以看到初始的博客项目结构已经生成了,包含这么几个目录:
```
+ archetypes/
+ content/
+ data/
+ layouts/
+ static/
config.toml
```
config.toml目录是hugo博客的配置文件,所有的全局配置都要放在这个文件中。接下来创建内容,
```
hugo new about.md
```
执行完后在content目录下会出现about.md文件。打开about.md文件,在文件上面可以看到这么几行:
```
+++
date = "2015-01-08T08:36:54-07:00"
draft = true
title = "about"

+++
```
单篇博客的配置在+++内配置。title就是博客的标题,draft=true表示这是一篇草稿,Hugo默认是不会渲染草稿状态的博客的,完成博客后使用
```
hugo undraft content/about.md
```
命令可以改变博客的draft状态,或者手动到文件中修改。

正文的内容写在+++区域的下面,使用markdown的语法。比如:
```
## 我是一个标题

放一些内容
```
一般为了便于管理,不会直接将posts放在content文件下,可以在content目录内新建一个post目录:
```
hugo new post/first.md
```
可以看到在content/post/下产生了一个first.md文件。

## 安装主题

接下来安装主题,我们直接使用Hugo推荐的一些主题。比如说我使用的是blackburn这个主题:
```
git clone https://github.com/yoshiharuyamashita/blackburn.git themes/blackburn
```
将主题git clone到themes/blackburn目录下,在config.toml中配置:
```
theme = "blackburn"
```
这样主题就安装好了。

## 启动Hugo

终于到了看实际效果的时候了,在博客的项目根目录下运行:
```
hugo server --buildDrafts --theme=blackburn
```
如果在配置文件中已经配置了theme的话就不需要再指定\-\-theme参数了,\-\-buildDrafts参数的意思是渲染所有的post包括
draft=true状态的。

打开浏览器,在地址栏中输入:http://localhost:1313, 就可以看到我们的博客了。

## 更改配置

一般来说使用默认的配置就可以了,但是要注意配置baseurl参数:
```
baseurl = "http://这里是你的域名/"
```
当我们把博客部署到服务器上的时候注意要把配置中的baseurl改成自己的域名。

主题的配置参数也是在config.toml中配置,各个主题的配置不尽相同,需要参考主题的文档,这里给一个我使用的主题的配置:
```
baseurl = "http://listenzhangbin.com/"
title = "Listen's Blog"
author = "Listen"
# Shown in the side menu
copyright = "&copy; 2016. All rights reserved."
canonifyurls = true
paginate = 10
theme = "blackburn"

[indexes]
  tag = "tags"
  topic = "topics"

[params]
  # Shown in the home page
  subtitle = "Move on"
  brand = "Menu"
  googleAnalytics = "Your Google Analytics tracking ID"
  disqus = "listenzhang"
  # CSS name for highlight.js
  highlightjs = "monokai"
  dateFormat = "02 Jan 2006, 15:04"

[menu]
  # Shown in the side menu.
  [[menu.main]]
    name = "Home"
    pre = "<i class='fa fa-home fa-fw'></i>"
    weight = 0
    identifier = "home"
    url = "/"
  [[menu.main]]
    name = "Posts"
    pre = "<i class='fa fa-list fa-fw'></i>"
    weight = 1
    identifier = "post"
    url = "/post/"
  [[menu.main]]
    name = "About"
    pre = "<i class='fa fa-user fa-fw'></i>"
    weight = 2
    identifier = "about"
    url = "/about/"
  [[menu.main]]
    name = "Contact"
    pre = "<i class='fa fa-phone fa-fw'></i>"
    weight = 3
    url = "/contact/"

[social]
  # Link your social networking accouns to the side menu
  # by entering your username or ID.

  # SNS microblogging
  twitter = "*"
  facebook = "*"
  googleplus = "*"
  weibo = "*"

  # SNS career oriented
  linkedin = "bin-zhang-347596b9"

  # SNS news
  reddit = "*"
  hackernews = "*"

  # Techie
  github = "HelloListen"
  bitbucket = "*"
  stackoverflow = "*"
```

## 版本控制
到项目的根目录下
```
git init
git commit -am "initial commit"
```
然后到Github上新建一个仓库,建好之后执行
```
git remote add origin git@github.com:YourUserName/YourProjectName.git
git push -u origin master
```

## 部署
最后一步就是部署啦,只有部署到服务器上之后别人才能看到我们的博客,Hugo博客有两种部署方式:

1. 使用Nginx,Apache等Server部署。以Nginx为例,在项目根目录下执行
```
hugo
```
Hugo会把我们的项目打包在一个public文件夹中,因为是静态的博客,所以只需要把public目录复制到服务器上,在Nginx的配置中配置
指向public目录即可。

2. 使用Hugo部署。由于Go语言本身也可以作为Server,如果博客的访问量并不是特别大的话也可以直接使用Hugo部署。
部署的方式为:从Github上clone项目到服务器上,然后在项目根目录下执行:
```
hugo server --baseURL=http://yoursite.org/ \
              --port=80 \
              --appendPort=false \
              --bind=0.0.0.0
```
由于Hugo是在开发的时候是支持热更新的,对开发比较有用,在部署的时候使用\-\-disableLiveReload=true参数禁用。  
可以使用supervisor等进程管理工具让Hugo进程跑在后台,只要在supervisor配置文件中先进入项目的根目录,然后执行上面的命令即可。

## 最后
使用主题的时候有一点要注意,由于主题一般都是使用国外的CDN,所以国内使用的时候加载会特别慢,有些使用的Google的服务还被墙了。所以建议把themes
中layouts里的CDN改成国内的CDN,可以显著的加快加载速度。这里推荐一个免费的公共CDN: http://www.bootcdn.cn/ ,上面收录了上千个开源项目,非常好用。  

嗯,这样就算初步搭建好了一个个人博客。其实还有许多的细节没有提到,有什么问题欢迎给我留言,
更详细的内容可以参考Hugo的官方文档: https://gohugo.io/ 。
