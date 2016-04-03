+++
date = "2016-03-12T17:24:48+08:00"
description = "Servlet&JSP学习"
draft = false
tags = ["Servlet","JSP"]
title = "Servlet&JSP学习"
topics = ["Java"]
+++

在进行Java Web开发的时候,我们会使用各种框架,比如Spring、Struts2等等。框架的封装非常完善,隐藏了许多底层的细节,
让开发人员可以不用去关注这些细节,专注于业务的开发。但是作为一个Java Web的初学者,如果一上来就接触这些框架,往往会被这些
框架表面上的一些东西迷惑,看不到底层实现的原理。这就会造成如果下次换了一个框架,又要从头开始学,做不到举一反三,融汇贯通。<!--more-->

最原始的Java Web开发是使用Servlet和JSP,所以我们应该从Servlet和JSP开始学起,当然,前提是你必须已经有了一定的Java编程语言的基础。
这里我也对我这段时间学习Servlet和JSP进行一些总结。

## 准备

1. IDE。现在使用比较多的有IDEA,Eclipse等。推荐使用IDEA,非常强大。

2. 容器。Java Web应用是要在容器里运行的,目前使用比较多的有Tomcat,Jetty等。我使用的是Tomcat。

3. 构建。构建并不是必须的,但是进行Java Web的开发,使用构建工具是非常有必要的,我使用的构建工具是Maven。
Maven是Apache官方出品的构建工具,可以处理编译、测试、打包、部署、依赖管理等等各项工作,而且使用Maven的Tomcat插件可以直接使用Maven命令
运行Java Web项目,而不需要每次都要打包然后放到Tomcat中。不建议使用IDE自带的Maven,可能会碰到各种奇怪的问题,
建议下载使用Apache官方的Maven,目前Maven最新的版本是3.3.9。

## Servlet和容器

servlet本质上就是一个普通的Java类,那么为什么它能成为一个servlet呢,原因就是它实现了Servlet接口。
一般我们在编写自己的servlet的时候,一般不会直接去实现Servlet接口,而是扩展HttpServlet抽象类,并且覆盖它的doGet()或doPost()等方法,
这些方法是用来处理不同的Http请求的。下面是一个简单的servlet类
```
package com.listenzhangbin.web

public class ServletTest extends HttpServlet{
    @Override
    public void doGet(HttpServletRequest request,HttpServletResponse response)throws IOException,ServletException{
        //这里是处理逻辑
    }
}
```
这个类扩展了HttpServlet抽象类,并覆盖了其中的doGet()方法,说明这个servlet只支持GET请求,不支持其他的HTTP请求。
doGet()方法有两个参数,HttpServletRequest和HttpServletResponse,这是非常重要的两个接口,它们是对HTTP的请求和响应
的封装,可以通过HttpServletRequest来获取有关请求的信息,包括Cookie,Body,Header等等参数,而HttpServletResponse用来
产生HTTP响应,应该熟练使用这两个接口的API。

可以看到servlet类没有构造函数,因为我们只需要用编译器提供的默认无参构造器即可。servlet类也没有main方法,
这是因为servlet是由容器来调用的,因此不需要main方法,当请求到来时,容器会根据请求调用不同的servlet,那么容器是
怎么知道什么情况调用什么servlet呢,这需要在部署描述文件(DD)web.xml中配置声明
```
<servlet>
    <servlet-name>Foo</servlet-name>
    <servlet-class>com.listenzhangbin.web.ServletTest</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>Foo</servlet-name>
    <url-pattern>/serv</url-pattern>
</servlet-mapping>
```
每个servlet都需要在web.xml中,当请求/serv的URL时,容器就会去调用ServletTest类。
配置完后可以使用Maven的tomcat插件运行,Maven插件配置
```
<plugin>
    <groupId>org.apache.tomcat.maven</groupId>
    <artifactId>tomcat6-maven-plugin</artifactId>
    <version>${tomcat.version}</version>
</plugin>
<plugin>
    <groupId>org.apache.tomcat.maven</groupId>
    <artifactId>tomcat7-maven-plugin</artifactId>
    <version>${tomcat.version}</version>
</plugin>
```
使用Maven命令在tomcat中运行应用
```
mvn tomcat7:run
```
然后在localhost:1313/{YouAppName}/serv就能看到实际的效果了。

有了servlet配置,容器就能根据请求中的URL找到正确的servlet,为这个请求创建或分配一个线程,并把请求和响应对象传递给这个servlet线程,
然后容器调用servlet的service()方法,根据请求的不同类型,service()方法会调用doGet()或doPost()或其它方法,doGet()方法会生成
响应或把请求转发到JSP,最后生成响应内容返回给用户,容器删除请求和响应对象。

servlet的生命周期的三个重要时刻:

+ ``init()``
+ ``service()``
+ ``destroy()``

当请求到来时,Web容器加载Servlet类,运行构造函数初始化servlet,构造函数只需要使用编译器提供的默认构造函数即可,
接下来容器调用init()方法,这个方法在servlet的一生中只调用一次,而且必须在容器调用service()之前完成,
然后调用service()方法,处理用户请求,每个请求都在一个单独的线程中运行,servlet生命周期大部分时间都在这里度过,
处理完成后调用destroy()方法在servlet被杀死之前有机会清理资源,destroy()方法也只能调用一次。

## Session(会话)

由于HTTP协议是没有状态的,因此要借助Session来记录用户的状态,实现Session的方式有两种:cookie和URL重写。
容器会帮助我们处理会话,以Tomcat为例:

+ 获取JSessionID,如果没有就生成一个cookie,使用``request.getSession()``方法。
+ 如果发现用户浏览器不支持cookie,则使用URL重写,使用``response.encodeURL("session")``方法。
+ 拿到HttpSession对象,这个时候就可以把它最为一个属性存放``setAttribute("attrName",Obj)``。
+ 可以通过``getAttribute("attrName")``获取属性。

默认的cookie是关闭浏览器窗口就自动失效的,使用``cookie.setMaxAge()``方法可以设置过期时间,这个方法需要一个参数,
表示失效的时间间隔,单位为秒。也可以在web.xml中配置会话的过期时间
```
<session-config>
    <session-timeout>15</session-timeout>
</session-config>
```
注意这里的单位是分钟,这个配置表示如果用户15分钟没有对这个会话做任何请求,那么就让这个会话过期。

在分布式的系统中,应用可能会运行在多个JVM中,每个VM中都有一个ServletContext,每个VM上的servlet都有一个ServletConfig,
但是对于每个Web应用中给定ID的会话,只有一个HttpSession对象,而不论分布在多少个VM上。

## Filter(过滤拦截器)

过滤器可以在请求到达servlet前过滤请求,在可以在servlet返回响应后过滤。Filter类要实现Filter接口,
实现Filter接口的三个方法
```
package com.listenzhangbin.filter;

import javax.servlet.*;
import javax.servlet.http.HttpServletRequest;
import java.io.IOException;

public class FilterTest implements Filter {
    private FilterConfig fc;

    @Override
    public void init(FilterConfig config) throws ServletException {
        this.fc = config;
    }

    @Override
    public void doFilter(ServletRequest req, ServletResponse resp, FilterChain chain) throws ServletException, IOException {
        HttpServletRequest httpReq = (HttpServletRequest) req;
        String name = httpReq.getRemoteUser();
        if (name != null) {
            fc.getServletContext().log("User " + name + " is updating");
        }
        chain.doFilter(req, resp);
    }

    @Override
    public void destroy() {
    }
}
```
``chain.doFilter()``方法把Request和Response传递给过滤器链的下一个过滤器或者servlet。

Filter也必须在web.xml中配置
```
<filter>
    <filter-name>BeerRequest</filter-name>
    <filter-class>com.listenzhangbin.filter.BeerRequestFilter</filter-class>
    <init-param>
        <param-name>LogFileName</param-name>
        <param-value>UserLog.txt</param-value>
    </init-param>
</filter>

<filter-mapping>
    <filter-name>BeerRequest</filter-name>
    <url-pattern>*.do</url-pattern>
</filter-mapping>

<filter-mapping>
    <filter-name>BeerRequest</filter-name>
    <servlet-name>BeerParamTests</servlet-name>
</filter-mapping>
```
其中,``<url-pattern>``或``<servlet-name>``元素这二者中必须有一个。满足``<url-pattern>``的所有过滤器都会
得到调用,也就是过滤器链,执行顺序会根据在web.xml中声明的顺序执行,``<url-pattern>``总是在``<servlet-name>``之前。

对于通过请求分派请求的Web资源声明的过滤器配置有所不同
```
<filter-mapping>
    <filter-name>FilterTest</filter-name>
    <url-pattern>*.do</url-pattern>
    <dispatcher>REQUEST</dispatcher>
    <dispatcher>INCLUDE</dispatcher>
    <dispatcher>FORWARD</dispatcher>
    <dispatcher>ERROR</dispatcher>
</filter-mapping>
```
可以有0-4个``<dispatcher>``元素,REQUEST值表示对客户请求启用过滤器。如果没指定``<dispatcher>``元素，则默认为REQUEST。
INCLUDE值表示对由一个include()调用分派来的请求启用过滤器。FORWARD值表示对由一个forward()调用分派来的请求启用过滤器。
ERROR值表示对错误处理器调用的资源启用过滤器。

上面都是对于Request请求的过滤拦截,如果要对Response请求进行过滤,比如压缩响应的数据,那么要使用包装器类,有4个包装器类

+ ServletRequestWrapper
+ HttpServletRequestWrapper
+ ServletResponseWrapper
+ HttpServletResponseWrapper

一般通过扩展以上的类来编写自己的包装器类,过滤处理Response响应,然后把包装器类传递给``chain.doFilter(req,wrapperResponse)``方法。

## JSP

在MVC的模式中,servlet用来做控制层,那么JSP一般用来做视图层。每个JSP其实也就是一个servlet,容器会帮我们把JSP编译成一个
servlet,在Tomcat中这个编译后的类会出现在work/目录下,不需要去关注编译后的代码,但是我们要知道容器把JSP编译为servlet的规则。
比如说,下面这种形式
```
<% int count = 0; %>
```
这实际上是声明了一个局部变量,如果要声明一个域要用声明的形式
```
<%! int count = 0; %>
```
还有在使用
```
<%= val+"<br>" %>
```
表达式形式的时候,不要使用分号,因为``<%= %>``中间的值会作为``out.println()``的参数。

JSP中的一些概念:

+ 指令
+ 表达式
+ 声明
+ EL表达式
+ JSTL
+ 定制标记
+ TLD配置

## 其他

还有一些没有提到的,但是也是非常重要的还有

+ 属性(属性作用域):``ServletContext``、``HttpSession``、``HttpServletRequest``、``pageContext``
+ 监听者(listener)和一些事件
+ Web应用部署
+ Web应用安全

## 最后

以上就是一个Java Web新手对这段时间学习Servlet&JSP的一些总结,可能会有些遗漏,有些错误,欢迎指正!