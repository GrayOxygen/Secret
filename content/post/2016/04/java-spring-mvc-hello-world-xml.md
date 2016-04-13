+++
date = "2016-04-13T15:19:05+08:00"
description = "Spring MVC Hello World Example XML"
draft = false
tags = ["Spring MVC","Hello World","XML"]
title = "Spring MVC Hello World Example XML"
topics = ["Java"]

+++

首先来看一张Spring MVC的Sequence图![Spring MVC](http://7xsskq.com2.z0.glb.clouddn.com/spring-mvc.png "Spring MVC")

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

## 准备

+ IDEA(或者其他IDE)
+ JDK 1.7
+ Spring 4.2.5.RELEASE
+ Maven(或者Gradle) 3.3.9

## 项目结构

![Spring MVC Project](http://7xsskq.com2.z0.glb.clouddn.com/blog/spring-mvc-hello-world-xml/spring-mvc-hello-world-xml.png "Spring MVC Project")

## Maven配置

``pom.xml``

```
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.listenzhangbin</groupId>
  <artifactId>spring-mvc-xml</artifactId>
  <packaging>war</packaging>
  <version>1.0-SNAPSHOT</version>
  <name>spring-mvc-xml</name>
  <url>http://listenzhangbin.com</url>

  <properties>
    <spring.version>4.2.5.RELEASE</spring.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>junit</groupId>
      <artifactId>junit</artifactId>
      <version>3.8.1</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-core</artifactId>
      <version>${spring.version}</version>
    </dependency>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-beans</artifactId>
      <version>${spring.version}</version>
    </dependency>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-web</artifactId>
      <version>${spring.version}</version>
    </dependency>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-webmvc</artifactId>
      <version>${spring.version}</version>
    </dependency>
    <dependency>
      <groupId>javax.servlet</groupId>
      <artifactId>javax.servlet-api</artifactId>
      <version>3.1.0</version>
      <scope>provided</scope>
    </dependency>
  </dependencies>

  <build>
    <finalName>spring-mvc-xml</finalName>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.5.1</version>
        <configuration>
          <target>1.8</target>
          <source>1.8</source>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-resources-plugin</artifactId>
        <configuration>
          <encoding>UTF-8</encoding>
        </configuration>
        <version>2.7</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>2.19.1</version>
      </plugin>
      <plugin>
        <groupId>org.apache.tomcat.maven</groupId>
        <artifactId>tomcat7-maven-plugin</artifactId>
        <version>2.2</version>
      </plugin>
    </plugins>
  </build>
</project>
```

## Controller

``helloController.java``

```
package com.listenzhangbin.web.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
@RequestMapping(path = "/example")
public class HelloController {

    @RequestMapping(path = "/hello", method = RequestMethod.GET)
    public String welcome(Model model) {
        model.addAttribute("message", "Spring MVC Hello World!");
        return "hello";
    }
    
    @RequestMapping(path = "/name/{name}", method = RequestMethod.GET)
        public ModelAndView name(@PathVariable String name) {
            ModelAndView modelAndView = new ModelAndView();
            modelAndView.setViewName("hello");
            modelAndView.addObject("message", name);
            return modelAndView;
    }
}
```

## JSP View

``hello.jsp``

```
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Title</title>
</head>
<body>

<h1>${message}</h1>

</body>
</html>
```

## Spring XML配置

关于Spring MVC中的XML配置,会有两个层次的配置文件,一个层次是全局的ApplicationContext配置,里面注册整个应用需要用到的bean,包括Service层、DAO层、DataSource等等。
另一个层次是DispatcherServlet的配置,Spring会默认在classpath下找以``{servlet-name}-servlet.xml``命名的配置文件,这个规则也是可以配置更改的,
在DispatcherServlet的XML配置文件中,一般会注册这个DispatcherServlet的次一级Controller以及Spring中的一些基础配置。

当然,如果应用比较简单,合并为一个层次的XML配置也是可以的。

``controller-servlet.xml``

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context"
       xmlns:mvc="http://www.springframework.org/schema/mvc"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc.xsd">

    <context:component-scan base-package="com.listenzhangbin.web"/>
    <mvc:annotation-driven/>
    <mvc:resources mapping="/resources/**" location="/resources/"/>
    <!--<mvc:view-controller path="/" view-name="index"/>-->

    <bean id="viewResolver" class="org.springframework.web.servlet.view.InternalResourceViewResolver">
        <property name="prefix" value="/WEB-INF/jsp/"/>
        <property name="suffix" value=".jsp"/>
    </bean>

</beans>
```

``applicationContext.xml``(这里是一个空的Spring XML配置)

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd">


</beans>
```

然后需要在``web.xml``中注册这个``DispatcherServlet``

```
<?xml version="1.0" encoding="ISO-8859-1"?>
<web-app xmlns="http://java.sun.com/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://java.sun.com/xml/ns/javaee
                      http://java.sun.com/xml/ns/javaee/web-app_3_0.xsd"
         version="3.0"
         metadata-complete="true">

    <context-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>/WEB-INF/applicationContext.xml</param-value>
    </context-param>

    <servlet>
        <servlet-name>controller</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>/WEB-INF/spring/controller-servlet.xml</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>

    <servlet-mapping>
        <servlet-name>controller</servlet-name>
        <url-pattern>/</url-pattern>
    </servlet-mapping>

    <listener>
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>
    
    <welcome-file-list>
        <welcome-file>index.jsp</welcome-file>
    </welcome-file-list>
</web-app>
```

## 运行

由于在``pom.xml``中已经配置了**Tomcat**的Maven插件,所以只要一行命令就可以在Tomcat中运行我们的应用
```
mvn tomcat7:run
```

最后打开浏览器,访问**http://localhost:8080/spring-mvc-xml/example/hello**就可以看到结果,
注意这里path里的**spring-mvc-xml**,因为我的applicationName是**spring-mvc-xml**,所以这里需要替换为你自己的applicationName,
也就是你项目工程的名字。

至此,一个基于XML配置的Spring MVC Hello World Example就算完成了,最后附上例子的源码,
在我的[Github](https://github.com/HelloListen/Spring-MVC-Hello-World-XML "Spring MVC Hello World Example XML")上。