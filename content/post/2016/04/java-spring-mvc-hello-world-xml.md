+++
date = "2016-04-10T21:43:05+08:00"
description = "Spring MVC Hello World Example XML"
draft = true
tags = ["Spring MVC","Hello World","XML"]
title = "Spring MVC Hello World Example XML"
topics = ["Java"]

+++

首先来看一张Spring MVC的Sequence图![GitHub Mark](http://7xsskq.com2.z0.glb.clouddn.com/spring-mvc.png "Spring MVC")

当一个请求到来的时候,在Spring MVC中由``DispatcherServlet``来担任``FrontController``的角色,它负责接收并根据具体的处理逻辑,
委派给它的下一级Controller去实现具体的Web请求处理。<!--more-->

DispatcherServlet通过HandlerMapping来找寻具体的Handler或者HandlerAdapter来处理具体的请求,也就是``Controller``,
Controller对应的是DispatcherServlet的次级控制器,它本身实现了对应某个具体的Web请求的处理逻辑。
在使用HandlerMapping查找到当前的请求对应哪个Controller的具体实例后,DispatcherServlet即可获得HandlerMapping所返回的结果,
并调用该Controller来处理相应的请求。

一般在Controller的具体处理方法中,会返回一个逻辑视图名称或者``ModelAndView``,由于Spring MVC支持多种View技术,
包括JSP、Velocity等等,所以返回的逻辑视图Spring MVC要怎样去具体处理呢,这就要借助于``ViewResolver``,
通过ViewResolver来返回具体的``View``实例,最后生成Response的渲染视图。

至此,整个DispatcherServlet的处理流程也就结束了,在知道了这些内容的情况下,就可以按照这样的流程来实现一个Spring MVC的Hello World Example,
基于XML的配置方式。