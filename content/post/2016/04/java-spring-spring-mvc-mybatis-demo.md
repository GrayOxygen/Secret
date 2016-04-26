+++
date = "2016-04-24T13:43:06+08:00"
description = "Spring + Spring MVC + MyBatis搭建一个简单的项目"
draft = true
tags = ["Spring","Spring MVC","MyBatis"]
title = "Spring + Spring MVC + MyBatis搭建一个简单的项目"
topics = ["Java"]

+++

在我的[上一篇博客](http://listenzhangbin.com/post/2016/04/java-spring-mvc-hello-world-xml/ "Spring MVC Hello World")里
介绍了如何搭建一个Spring MVC的Hello World Example,在这篇博客里将会在上一次的例子的基础上整合**MyBatis**,
搭建一个简单的**Spring + Spring MVC + MyBatis**的项目Demo。<!--more-->

## 环境

+ JDK 1.8
+ Spring MVC 4.2.5.RELEASE
+ Spring 4.2.5.RELEASE
+ MyBatis 3.3.1

## 项目结构

![Spring Spring MVC MyBatis Project](http://7xsskq.com2.z0.glb.clouddn.com/blog/spring-spring-mvc-mybatis/spring-spring-mvc-mybatis.png "Project structure")

## 项目配置

这里只列出MyBatis的相关配置,关于Spring MVC与Spring的相关配置就不在这里重复列出了,
有需要的朋友可以查看我的[上一篇博客](http://listenzhangbin.com/post/2016/04/java-spring-mvc-hello-world-xml/ "Spring MVC Hello World")

**pom.xml**

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
    <dependency>
      <groupId>mysql</groupId>
      <artifactId>mysql-connector-java</artifactId>
      <version>5.1.38</version>
    </dependency>
    <dependency>
      <groupId>org.mybatis</groupId>
      <artifactId>mybatis</artifactId>
      <version>3.3.1</version>
    </dependency>
    <dependency>
      <groupId>org.mybatis</groupId>
      <artifactId>mybatis-spring</artifactId>
      <version>1.3.0</version>
    </dependency>
    <dependency>
      <groupId>org.springframework</groupId>
      <artifactId>spring-jdbc</artifactId>
      <version>4.2.5.RELEASE</version>
    </dependency>
    <dependency>
      <groupId>log4j</groupId>
      <artifactId>log4j</artifactId>
      <version>1.2.17</version>
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

**applicationContext.xml**

```
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tx="http://www.springframework.org/schema/tx"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx.xsd">

    <bean id="dataSource" class="org.springframework.jdbc.datasource.DriverManagerDataSource">
        <property name="url" value="jdbc:mysql://localhost:3306/test"/>
        <property name="username" value="root"/>
        <property name="password" value=""/>
        <property name="driverClassName" value="com.mysql.jdbc.Driver"/>
    </bean>

    <bean id="sessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
        <property name="dataSource" ref="dataSource"/>
        <!--<property name="configLocation" value="classpath:mybatis-config.xml"/>-->
    </bean>

    <bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
        <property name="basePackage" value="com.listenzhangbin.web.mapper"/>
    </bean>

    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/>
    </bean>


    <tx:annotation-driven transaction-manager="transactionManager"/>

</beans>
```

**log4j.properties**

```
### Global logging configuration
log4j.rootLogger=DEBUG,Console

### Console output...
log4j.appender.Console=org.apache.log4j.ConsoleAppender
log4j.appender.Console.layout=org.apache.log4j.PatternLayout
log4j.appender.Console.layout.ConversionPattern=%d [%t] %-5p [%c] - %m%n
log4j.logger.org.apache=INFO
```

**数据库设计**

```
CREATE TABLE `message` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `command` varchar(16) DEFAULT NULL,
  `description` varchar(32) DEFAULT NULL,
  `content` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
```

### 创建一个Model对象

**User.java**

```
package com.listenzhangbin.web.model;

public class User {
    private String id;
    private String command;
    private String description;
    private String content;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getCommand() {
        return command;
    }

    public void setCommand(String command) {
        this.command = command;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    @Override
    public String toString() {
        return "User{" +
                "id='" + id + '\'' +
                ", command='" + command + '\'' +
                ", description='" + description + '\'' +
                ", content='" + content + '\'' +
                '}';
    }
}
```

### 创建一个Mapper接口

**UserMapper.java**

```
package com.listenzhangbin.web.mapper;

import com.listenzhangbin.web.model.User;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.springframework.stereotype.Component;

@Component
public interface UserMapper {
    @Select("select * from message where id = #{id}")
    public User getUserUsingId(@Param("id") int id);

    @Select("select * from message where command = #{command}")
    public User getUserUsingCommand(@Param("command") String command);
}
```

### 创建一个Service类

**UserService.java**

```
package com.listenzhangbin.web.service;

import com.listenzhangbin.web.mapper.UserMapper;
import com.listenzhangbin.web.model.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    @Autowired
    private UserMapper userMapper;

    public User getUserUsingId(String id) {
        System.out.println(userMapper.getUserUsingId(Integer.parseInt(id)).toString());
        return userMapper.getUserUsingId(Integer.parseInt(id));
    }
}
```

### 创建一个Controller类

**DefaultController.java**

```
package com.listenzhangbin.web.controller;

import com.listenzhangbin.web.model.User;
import com.listenzhangbin.web.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@Controller
public class DefaultController {

    @Autowired
    private UserService userService;

    @RequestMapping(value = "/mybatis")
    public ModelAndView indexView(@RequestParam String id, HttpServletResponse response){
        response.setCharacterEncoding("utf-8");
        User user = userService.getUserUsingId(id);
        ModelAndView modelAndView = new ModelAndView("hello");
        modelAndView.addObject("user",user);
        return modelAndView;
    }
}
```

### View

**hello.jsp**

```
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Title</title>
</head>
<body>

<h1>${user.id}</h1>
<h2>${user.command}</h2>
<h3>${user.content}</h3>
<h4>${user.description}</h4>

</body>
</html>
```

## 运行

执行命令

```
mvn tomcat7:run
```

在浏览器打开地址**http://localhost:8080/spring-mvc-xml/mybatis?id=2**,
即可看到页面上已经显示出了从数据库中查询出Id为2的数据。
