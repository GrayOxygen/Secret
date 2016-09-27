+++
date = "2016-09-27T15:00:42+08:00"
description = "在Spring Boot框架中使用AOP"
draft = false
tags = ["Java","Spring Boot","AOP"]
title = "在Spring Boot框架中使用AOP"
topics = ["Spring Boot"]

+++

Spring Boot是基于Spring的用来开发Web应用的框架，功能与Spring MVC有点类似，但是Spring Boot的一大特点就是需要的配置非常少。Spring Boot推荐``convention over configuration``，也就是约定大于配置，因此Spring Boot会帮你做许多自动的配置，并且Spring Boot使用的是Java Config，几乎可以做到零XML文件配置。

假设现在有这样一种场景，需要统计某个接口的处理耗时，我们可以使用AOP来处理这种需求，在Spring Boot中使用AOP也非常简单，只需要一点简单的配置即可。

## 需要使用AOP的类

```java
@RestController
public class DownloadController {

    @Autowired
    private XmlDownloadService downloadService;

    @Autowired
    private XmlFileClearService clearService;

    @RequestMapping("/download")
    @Timer
    public String download() throws Exception {
        downloadService.download();
        clearService.compress();
        clearService.clearAll();
        return "ok";
    }

}
```

这是一个使用@RestController注解的Controller类，这个类会去下载一些XML文件，然后压缩，最后删除下载的XML文件。现在我们要统计整个处理过程的耗时，使用AOP来实现。在``download``上使用了一个``@Timer``注解，这是一个自定义的普通注解，用来标记这个方法作为一个切点。

## Aspect类

```java
@Aspect
@Component
public class VipAspect {

    private static final Logger logger = LoggerFactory.getLogger(VipAspect.class);

    private long start;

    //定义切点
    @Pointcut("@annotation(cn.magicwindow.mlink.content.annotation.Timer)")
    public void timer(){}

    //在方法执行前执行
    @Before("timer()")
    public void before() {
        start = System.currentTimeMillis();
    }
    
    //在方法执行后执行
    @After("timer()")
    public void after() {
        long now = System.currentTimeMillis();
        logger.info("job took time {}s in summary", (now - start) / 1000);
    }
}
```

## 配置Spring Boot支持AOP

```java
@Configuration
@EnableAspectJAutoProxy
public class Config {
}
```

只需要使用``@EnableAspectJAutoProxy``注解开启Spring Boot的AOP支持即可。

