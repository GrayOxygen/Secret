+++
date = "2016-04-03T13:48:48+08:00"
description = "Spring中的事务管理"
draft = false
tags = ["Spring","事务"]
title = "Spring中的事务管理"
topics = ["Java"]

+++

Spring中的事务管理通常有两种方式,即编程式事务管理和声明式事务管理。在学习Spring中的事务管理前,
首先需要了解几个事务中的概念。

## 关于事务的一些概念

事务本身持有4个限定属性,即**原子性(Atomicity)**、**一致性(Consistency)**、**隔离性(Isolation)**和**持久性(Durability)**,
这也就是常说的事务ACID属性。<!--more-->

关于其中的**隔离性**,一般可以分成以下4种隔离级别:

+ Read Uncommited。这是最低的隔离级别。该隔离级别的事务可以读取另一个事务没有提交的最新结果,这样就会导致以下几个问题:
 - 脏读(Dirty Read)。如果一个事务对数据进行了更新,但事务还没有提交,另一个事务就可以看到该事务没有提交的更新结果。
 这样造成的问题是,如果第一个事务回滚,那么第二个事务所看到的之前的数据就是一笔脏数据。
 - 不可重复读取(Non-Repeatable Read)。不可重复读取是指同一个事务在整个事务过程中对同一笔数据进行读取,每次读取的结果都不同。
 - 幻读(Phantom Read)。幻读是指同样一个查询在整个事务过程中多次执行后,查询所得的结果集是不一样的。幻读针对的是多笔记录。
 
+ Read Committed。通常,这是大多数数据库采用的默认隔离级别。在该隔离级别下,一个事务的更新操作结果只有在该事务提交之后,另一个
事务才可能读取到同一笔数据更新后的结果。这样可以避免脏读的问题,但是无法避免不可重复读取和幻读。

+ Repeatable Read。Repeatable Read隔离级别可以保证在整个事务的过程中,对同一笔数据的读取结果是相同的。该隔离级别避免了脏读和
无法重复读取的问题,但是无法避免幻读。

+ Serializable。这是最严格的隔离级别。所有的事务操作都必须依次顺序执行,可以避免其他隔离级别遇到的所有问题,是最为安全的隔离级别。
但是也是性能最差的隔离级别。

不同的隔离级别设置会对系统的并发性以及数据一致性造成不同的影响。总地来说,隔离级别与系统并发性成反比,与数据一致性成正比。


在事务中还需要了解的一个概念是事务的传播行为。在Spring中,针对事务的传播行为,``TransactionDefinition``提供了以下几种选择:

+ PROPAGATION_REQUIRED。如果当前存在一个事务,则加入当前事务,如果不存在任何事务,则创建一个新事务。总之,至少要保证在一个事务中运行。
PROPAGATION_REQUIRED通常作为默认的事务传播行为。

+ PROPAGATION_SUPPORTS。如果当前存在一个事务,则加入当前事务,如果当前不存在事务,则直接执行。对于一些查询方法来说,这是比较合适的传播行为。

+ PROPAGATION_MANDATORY。强制要求当前存在一个事务,如果不存在,则抛出异常。如果某个方法需要事务的支持,但本身又不管理事务提交或者回滚,那么
比较适合PROPAGATION_MANDATORY。

+ PROPAGATION_REQUIRES_NEW。不管当前是否存在事务,都会创建新的事务。如果当前存在事务,会将当前的事务挂起。
如果某个业务对象所做的事情不想影响到外层的事务,PROPAGATION_REQUIRES_NEW应该是合适的选择。

+ PROPAGATION_NOT_SUPPORTED。不支持当前事务,而是在没有事务的情况下执行。如果当前存在事务的话,当前事务原则上将被挂起,
但这要看对应的``PlatformTransactionManager``实现类是否支持事务的挂起。

+ PROPAGATION_NEVER。永远不需要当前存在事务,如果存在当前事务,则抛出异常。

+ PROPAGATION_NESTED。如果存在当前事务,则在当前事务的一个嵌套事务中执行,否则与PROPAGATION_REQUIRED的行为类似,即创建新的事务。
类似与``savePoint``。

## Spring中的编程式事务管理

可以直接使用``PlatformTransactionManager``或使用``TransactionTemplate``进行编程式事务管理。一般来说,推荐使用``TransactionTemplate``。
与使用Spring的Jdbc类似,``TransactionTemplate``也使用了模版设计模式的封装,我们在使用的时候,需要实现``TransactionCallback``接口或
``TransactionCallbackWithoutResult``抽象类中的一个,两者的区别就是是否需要返回执行的结果。
```java
public void service(){
    TransactionTemplate transactionTemplate = new TransactionTemplate();
    
    Object result = transactionTemplate.execute(new TransactionCallback<Object>(){
        @Override
        public void doInTransaction(TransactionStatus transactionStatus){
            Object result = null;
            //...
            return result;
        }
    });
}
```
```java
public void service(){
    TransactionTemplate transactionTemplate = new TransactionTemplate();
    
    transactionTemplate.execute(new TransactionCallbackWithoutResult(){
        @Override
        protected void doInTransactionWithoutResult(TransactionStatus transactionStatus){
            Object result = null;
            //...
        }
    });
}
```
``TransactionTemplate``会捕捉``TransactionCallback``或者``TransactionCallbackWithoutResult``事务操作中抛出的
**unchecked exception**并回滚事务,然后将**unchecked exception**抛给上层处理。如果事务处理期间没有问题,
那么``TransactionTemplate``最终会为我们提交事务。那么如果要手动回滚事务应该怎么做呢,有两种方式:

+ 抛出``unchecked exception``。
```java
public void service(){
        TransactionTemplate transactionTemplate = new TransactionTemplate();
        
        transactionTemplate.execute(new TransactionCallbackWithoutResult(){
            @Override
            protected void doInTransactionWithoutResult(TransactionStatus transactionStatus){
                try{
                    //...
                }catch(CheckedException e){
                    throw new RuntimeException(e);
                }
            }
        });
    }
```

+ 使用Callback接口公开的``TransactionStatus``将事务标记为``rollBackOnly``。
```java
public void service(){
        TransactionTemplate transactionTemplate = new TransactionTemplate();
        
        transactionTemplate.execute(new TransactionCallbackWithoutResult(){
            @Override
            protected void doInTransactionWithoutResult(TransactionStatus transactionStatus){
                boolean needRollback = false;
                //...
                if (needRollback){
                    transactionStatus.setRollbackOnly();
                }
            }
        });
}
```

两种方式可以同时使用,达到既回滚事务,又不以``unchecked exception``的形式向上层传播。
```java
public void service(){
    TransactionTemplate transactionTemplate = new TransactionTemplate();
    
    transactionTemplate.execute(new TransactionCallbackWithoutResult(){
        @Override
        protected void doInTransactionWithoutResult(TransactionStatus transactionStatus){
            try{
                //...
            }catch(CheckedException e){
                logger.warn("Transaction is rolled back!",e);
                transactionStatus.setRollbackOnly();
            }
        }
    })
}
```

还可以使用``TransactionStatus``的SavePoint机制来嵌套事务。
```java
public void service(){
    TransactionTemplate transactionTemplate = new TransactionTemplate();
    
    transactionTemplate.execute(new TransactionCallbackWithoutResult(){
        @Override
        protected void doInTransactionWithoutResult(TransactionStatus transactionStatus){
            BigDecimal transferAmount = new BigDecimal("20000");
            try{
                withdraw("WITHDRAW_ACCOUNT_ID",transferAmount);
                
                Object savePointBeforeDeposit = transactionStatus.createSavePoint();
                try{
                    deposit("MAIN_ACCOUNT_ID",transferAmount);
                }catch(Exception e){
                    transactionStatus.rollbackToSavePoint(savePointBeforeDeposit);
                    deposit("SECONDARY_ACCOUNT_ID",transferAmount);
                }finally{
                    transactionStatus.releaseSavepoint(savePointBeforeDeposit);
                }
            }catch(Exception e){
                logger.warn("failed to complete transfer operation!",e)
                transactionStatus.setRollbackOnly();
            }
        }
    })
}

```

## Spring中的声明式事务管理

首先,假设我们有一个服务接口
```java
public interface FooService{
    service getService();
    service getServiceByDateTime(DateTime dateTime);
    void saveService(Service service);
    void updateService(Service service);
    void deleteService(Service service);
}
```
以及一个服务接口的实现类
```java
public class SomeService implements FooService{
    private JdbcTemplate jdbcTemplate;
    
    @Override
    public Service getService(){
        return (Service)getJdbcTemplate().queryForObject("",new RowMapper(){
            @Override
            public Object mapRow(ResultSet rs, int row)throws SQLException{
                Service service = new Service;
                //...
                return service;
            }
        });
    }
    
    @Override
    public service getServiceByDateTime(DateTime dateTime){
        throw new NotImplementedException();
    }
    
    @Override
    public void saveService(Service service){
        throw new NotImplementedException();
    }
    
    @Override
    public void deleteService(Service service){
        throw new NotImplementedException();
    }
    
    public JdbcTemplate getJdbcTemplate(){
        return jdbcTemplate;
    }
    
    public void setJdbcTemplate(JdbcTemplate jdbcTemplate){
        this.jdbcTemplate = jdbcTemplate;
    }
}
```

### 使用**TransactionProxyFactoryBean**

在XML配置文件中进行相关配置
```xml
    <bean id="dataSource" class="org.springframework.jdbc.datasource.DriverManagerDataSource">
        <property name="driverClassName" value="com.mysql.jdbc.Driver"/>
        <property name="url" value="jdbc:mysql://localhost:3306/test"/>
        <property name="username" value="root"/>
        <property name="password" value=""/>
    </bean>

    <bean id="jdbcTemplate" class="org.springframework.jdbc.core.JdbcTemplate">
        <property name="dataSource" ref="dataSource"/>
    </bean>

    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/>
    </bean>
    
    <bean id="serviceTarget" class="...SomeService">
        <property name="jdbcTemplate" ref="jdbcTemplate"/>
    </bean>
    
    <bean id="someService" class="org.springframework.transaction.interceptor.TransactionProxyFactoryBean">
        <property name="transactionManager" ref="transactionManager"/>
        <property name="target" ref="serviceTarget"/>
        <property name="transactionAttributes">
            <props>
                <prop key="getService*">PROPAGATION_SUPPORTS,readOnly,timeout_10</prop>
                <prop key="saveService">PROPAGATION_REQUIRED</prop>
                <prop key="updateService">PROPAGATION_REQUIRED</prop>
                <prop key="deleteService">PROPAGATION_REQUIRED</prop>
            </props>
        </property>
    </bean>
        
    <!--最后将代理对象注入到client中使用-->
    <bean id="client" class="...SomeServiceClient">
        <property name="someService" ref="someService"/>
    </bean>
```

### 使用**tx**命令空间

使用Spring中AOP的配置方式来声明事务管理。
```xml
<tx:advice id="txAdvice" transaction-manager="transactionManager">
    <tx:attributes>
        <tx:method name="getService" propagation="SUPPORTS" read-only="true" timeout="20"/>
        <tx:method name="saveService"/>
        <tx:method name="updateService"/>
        <tx:method name="deleteService"/>
    </tx:attributes>
</tx:advice>

<aop:config>
    <aop:pointcut id="txServices" expression="execution(* ...SomeService(..))"/>
    <aop:advisor pointcut-ref="txServices" advice-ref="exAdvice"/>
</aop:config>

<!--省略了相同的dataSource、transactionManager、jdbcTemplate的配置-->

<bean id="someService" class="...SomeService">
    <property name="jdbcTemplate" ref="jdbcTemplate"/>
</bean>

<bean id="client" class="...SomeServiceClient">
    <property name="someService" ref="someService"/>
</bean>
```

### 使用注解

```java
@Transactional
@Component
public class SomeService implements FooService{
    private JdbcTemplate jdbcTemplate;
    
    @Override
    @Transactional(propagation=Propagation.SUPPORTS,readOnly=true,timeout=20)
    public Service getService(){
        return (Service)getJdbcTemplate().queryForObject("",new RowMapper(){
            @Override
            public Object mapRow(ResultSet rs, int row)throws SQLException{
                Service service = new Service;
                //...
                return service;
            }
        });
    }
    
    @Override
    @Transactinoal(propagation=Propagation.SUPPORTS,readOnly=true,timeout=20)
    public service getServiceByDateTime(DateTime dateTime){
        throw new NotImplementedException();
    }
    
    @Override
    public void saveService(Service service){
        throw new NotImplementedException();
    }
    
    @Override
    public void deleteService(Service service){
        throw new NotImplementedException();
    }
    
    public JdbcTemplate getJdbcTemplate(){
        return jdbcTemplate;
    }
    
    public void setJdbcTemplate(JdbcTemplate jdbcTemplate){
        this.jdbcTemplate = jdbcTemplate;
    }
}
```
需要在XML中加上以下配置通过反射来获取注解的信息
```xml
<tx:annotation-driven transaction-manager="transactionManager"/>

<!--注入声明了事务管理的someService类-->
<bean id="client" class="...SomeServiceClient">
    <property name="someService" ref="someService"/>
</bean>
```