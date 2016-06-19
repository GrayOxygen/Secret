+++
date = "2016-03-26T18:03:45+08:00"
description = "Spring中的三种依赖注入方式"
draft = false
tags = ["Spring","IoC","依赖注入"]
title = "Spring中的三种依赖注入方式"
topics = ["Java"]
+++

Spring的IoC容器是整个Spring框架的核心和基础。IoC的英文全称是Inversion Of Control,翻译过来的意思就是**控制反转**,
与IoC经常一起提到的另一个概念叫做**依赖注入(Dependency Injection)**,在Spring中这是两个类似的概念。
Spring中实现依赖注入通常有这么几种方式:<!--more-->

## 构造方法注入

顾名思义,构造方法注入,就是被注入对象可以通过在其构造方法中声明依赖对象的参数列表,让Spring的IoC容器知道它需要哪些依赖对象。
```java
public class Foo{
    private Bar bar;
    
    public Foo(Bar bar){
        this.bar = bar;    
    }
}
```
从构造方法的参数列表中可以看出,Foo类依赖Bar类,那么我们可以在Spring的XML配置文件进行Bean的配置
```xml
<bean id="barClass" class="...Bar" />

<bean id="fooClass" class="...Foo">
    <constructor-arg ref="barClass"/>
</bean>
```
也可以使用注解的形式
```java
@Component
public class Foo{
    private Bar bar;
    
    @Autowired
    public Foo(Bar bar){
        this.bar = bar;
    }
}
```
这样Spring就知道Foo类依赖于Bar类,因此在实例化Foo类的时候Spring会把Bar类注入到Foo类中。
``<constructor-arg>``元素的``ref``属性表示依赖的是一个引用类型,如果依赖的是一个简单类型的值,则使用``value``,
并且如果构造方法有多个参数,那么可以使用``type``或者``index``属性加以区分。

## setter方法注入

对于JavaBean对象来说,通常会通过``setXXX()``和``getXXX()``方法来访问对应的属性。这些``setXXX()``方法统称为``setter``方法,
``getXXX()``方法统称为``getter``方法。在Spring中也可以使用``setter``方法来将依赖的对象注入到被注入对象中。
```java
public class SetterInjection{
    private Injection injection;
    
    public SetterInjection(){}
    
    public void setInjection(Injection injection){
        this.injection = injection;
    }
    
    public Injection getInjection(){
        return injection;
    }
}
```
从``setter``方法可以将SetterInjection类依赖的Injection对象注入进来
```xml
<bean id="foo" class="...Injection"/>

<bean id="setInj" class="...SetterInjection">
    <property name="injection" ref="foo"/>
</bean>
```
使用注解的形式
```java
@Component("setterInjection")
public class SetterInjection{
    private Injection injection;
    
    public SetterInjection(){}
    
    @Autowired
    public void setInjection(Injection injection){
        this.injection = injection;
    }
    
    public Injection getInjection(){
        return injection;
    }
}
```
可以看到,setter方法注入的Bean配置形式与构造方法注入是比较类似的,如果通过``setter``方法注入的是简单类型的值,
那么使用``value``属性。这里需要注意的是被``setter``方法注入的类必须有一个公共的默认无参构造器。

构造方法注入和``setter``方法注入是可以一起使用的
```java
public class MockBean{
    private String dependency1;
    private String dependency2;
    
    public MockBean(String dependency){
        this.dependency1 = dependency;
    }
    
    public void setDependency2(String dependency2){
        this.dependency2 = dependency2;
    }
    ...
}
```
```xml
<bean id="mockBean" class="...MockObject">
    <constructor-arg value="hello">
    <property name="dependency2" value="good"/>
</bean>
```
使用注解的形式
```java
@Component
public class MockBean{
    private String dependency1;
    private String dependency2;
    
    @Autowired
    public MockBean(String dependency){
        this.dependency1 = dependency;
    }
    
    @Autowired
    public void setDependency2(String dependency2){
        this.dependency2 = dependency2;
    }
    ...
}
```

## 方法注入

比起前面的两种依赖注入方式,方法注入的使用场景比较特别。我们知道Spring Bean的默认``scope``是``singleton``,也就是单例,
对该Bean对象的每一个请求,Spring都会返回一个相同的对象实例,如果我们想要每次对该类型的对象请求都返回一个新的实例,比如说在
一个对象是有状态的时候,这是非常必须的,那么可以将该Bean的``scope``配置为``prototype``。

那么在使用了``prototype``之后就真的每次都会得到一个全新的对象了吗,看看下面这个例子
```java
public class MockPrototype {
    private NewsBean newsBean;

    public void persistNews() {
        System.out.println("persist news" + getNewsBean());
    }

    public NewsBean getNewsBean() {
        return newsBean;
    }

    public void setNewsBean(NewsBean newsBean) {
        this.newsBean = newsBean;
    }
}
```
配置为:
```xml
<bean id="news" class="...NewsBean" scope="prototype"/>

<bean id="mockPro" class="...MockPrototype">
    <property name="newsBean" ref="news"/>
</bean>
```
在``main``中多次调用``persistNews()``方法
```java
public class Main {
    public static void main(String[] args) {
        ApplicationContext ctx = new ClassPathXmlApplicationContext("spring.xml");
        MockPrototype bean = (MockPrototype)ctx.getBean("mockPro");
        bean.persistNews();
        bean.persistNews();
    }
}
```
输出:
```
persist ...NewsBean@239963d8
persist ...NewsBean@239963d8
```
从返回结果可以看到返回的``NewsBean``对象的内存地址是相同的,也就是说是同一个对象。问题出在虽然NewsBean拥有``prototype``类型
的scope,但当容器将一个NewsBean的实例注入MockPrototype之后,MockPrototype就会一直持有这个NewsBean实例的引用,虽然每次都
调用了``getNewsBean()``方法返回一个NewsBean的实例,但实际上每次都是返回的第一次注入时的实例,为了解决这个问题,可以使用方法注入。
```
<public|protected> [abstract] <return-type> theMethodName(no-arguments);
```
只要方法符合上面的形式,就可以在容器配置为注入方法。
```xml
<bean id="news" class="...NewsBean" scope="prototype"/>

<bean id="mockPro" class="...MockPrototype">
    <lookup-method name="getNewsBean" bean="news"/>
</bean>
```
通过``<lookup-method>``的``name``属性指定需要注入的方法名,``bean``属性指定需要注入的对象,当``getNewsBean``方法被调用的时候,
容器可以每次都返回一个新的``NewsBean``类型的实例。