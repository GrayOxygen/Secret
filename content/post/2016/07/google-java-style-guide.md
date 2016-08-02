+++
date = "2016-07-25T22:32:42+08:00"
description = "[译]Google Java编程风格指南"
draft = false
tags = ["Java","Style Guide","Google"]
title = "[译]Google Java编程风格指南"
topics = ["Google Java Style Guide"]

+++

## 目录

1. 介绍
2. 源文件基础
3. 源文件结构
4. 格式
5. 命名
6. 编程实践
7. Javadoc

## 1 介绍

这份文档是Google Java编码规范的完整定义。当且仅当一个Java源文件符合此文档中的规则， 我们才认为它符合Google的Java编程风格。<!--more-->

与其它的编程风格指南一样，这里所讨论的不仅覆盖格式化美观的问题，同时也包括其它约定和编码规范。然而，这份文档主要关注的是我们普遍遵守的规则，对于显然不是可执行的将避免给出建议。

### 1.1 术语说明

在这份文档中，除非另外声明：

1. 术语**class**表示包括一个普通类，枚举类，接口或者注解类型(@interface)。
2. 术语**comment**总是用来指代**实现(implementation)**注释。我们不使用“文档注释”一词，而是使用术语“Javadoc”。

其它的术语说明会偶尔在文档中出现。

### 1.2 指南说明

文档中的示例代码是**非规范**的。这就是说，虽然示例是Google风格的，但这不代表是代码风格的唯一方式。示例中的格式选择不应该被强制用来作为标准。

## 2 源文件基础

### 2.1 文件名

源文件名以其包含的顶级类(只有一个)名字来命名，且是大小写敏感的，文件扩展名为``.java``。

### 2.2 文件编码：UTF-8

源文件以UTF-8作为编码格式。

### 2.3 特殊字符

#### 2.3.1 空白字符

除了换行符序列，ASCII编码的水平空格字符(0x20)是唯一允许在源文件任意位置出现的空白字符。这意味着：

1. 所有其它的字符串中的空白字符和字符字面量都会被转义。
2. 制表符不用于缩进。

#### 2.3.2 特殊转义序列

对于任何具有特殊转义序列(``\b,\t,\n,\f,\r``,``\"``,``\'``和``\\``)的字符，使用它的特殊序列，而不是相应的八进制(比如``\012``)或者Unicode(比如``\u000a``)转义。

#### 2.3.3 非ASCII字符

对于剩下的非ASCII字符，是使用实际的Unicode字符还是等价的Unicode转义字符，主要取决于哪种方式更易于阅读和理解，尽管Unicode转义的字符串字面量和注释是强烈不推荐的。

> Tip:当使用一些Unicode转义字符或是实际的Unicode字符时，写一些解释注释会非常有助于阅读。

例子：

| 例子 | 讨论 |
| ------| ------ |
| ``String unitAbbrev = "μs"; `` | 最优：即使没有注释也非常清晰 |
| ``String unitAbbrev = "\u03bcs" //"μs" `` | 允许，但是没有理由这么做 |
| ``String unitAbbrev = "\u03bcs" // Greek letter mu, "s" ``|允许，但是这样做显得笨重，并且容易出错|
| ``String unitAbbrev = "\u03bcs"; ``|糟糕：阅读的人不知道这是什么|
| ``return '\ufeff' + content; // byte order mark``|好：对于非打印字符使用转义，但是必要时需要加上注释|

> Tip:永远不要由于害怕某些程序不能处理非ASCII字符而使你的代码降低可读性。如果这种情况发生了，那么那些程序是有问题的，必须被修复(fix)。

## 3 源文件结构

一份源文件包含(按顺序的)：

1. 许可或者版权信息，如果有的话
2. Package语句
3. Import语句
4. 有且只有一个顶级类

每个部分只用一个空白行分隔。

### 3.1 许可或者版权信息，如果存在的话

如果一个文件包含许可或者版权信息，那么它应该被放在这里。

### 3.2 Package语句

package语句不换行。列限制并不适用于package语句。

### 3.3 Import语句

#### 3.3.1 不使用通配符的Import语句

含有通配符的import语句，包括静态的和非静态的，都不要使用。

#### 3.3.2 不要换行

import语句是不换行的。列限制不适用于import语句。

#### 3.3.3 顺序和空格

import语句按以下顺序：

1. 所有的静态import语句在一个单独的块(block)中。
2. 所有的非静态import语句在一个单独的块中。

如果同时有静态的和非静态的import，用一个空行来分隔两块。除此之外，在两块之间不存在其它的空白行。

在每个块中以ASCII字符进行排序。

### 3.4 类声明

#### 3.4.1 只有一个顶级类声明

一个源文件只有一个顶级类声明。

#### 3.4.2 类成员排序

类成员的顺序对易学性有很大的影响，但这也不存在唯一正确的规则。不同的类对成员的排序可能不同。重要的是类成员的排序应该是某种逻辑排序，类维护者应该能解释它的逻辑。比如说，新的方法不应该只是习惯性地放在最后，应该放弃这种按时间的排序，因为这不是逻辑排序。

##### 3.4.2.1 重载：永远不要分离

当一个类有多个构造方法，或者多个方法有相同的名字，他们应该连续的出现，没有其它方法介于中间。

## 4 格式化

术语说明：**块状结构**指的是一个类的主体，方法或者构造函数。需要注意的是，任何数组的初始化结构(initializer)可以选择性的看作是一个块状结构。

### 4.1 大括号({})

#### 4.1.1 即使在可选的地方也应该适用大括号

大括号在``if,else,for,do``和``while``语句中使用，即使主体是空的或者只有一条语句也应该使用大括号。

#### 4.1.2 非空块：K&R风格

对于非空块和块状结构，大括号遵循Kernighan和Ritchie风格：

+ 在开大括号前不换行
+ 在开大括号后换行
+ 在闭大括号前换行
+ 只有当闭大括号是一个语句，方法的主体、构造函数或者命令类的终止时，则闭大括号换行。比如说，闭大括号在``else``前或者逗号前则不换行。

例子：

```java
  return () -> {
    while (condition()) {
      method();
    }
  };

  return new MyClass() {
    @Override public void method() {
      if (condition()) {
        try {
          something();
        } catch (ProblemException e) {
          recover();
        }
      } else if (otherCondition()) {
        somethingElse();
      } else {
        lastThing();
      }
    }
  };
```

在枚举类一节中，给出了一些例外。

#### 4.1.3 空块：也许更简洁

一个空块或者块状结构或许可以在打开后马上关闭，在开闭大括号之间没有字符或者空行。如果它是一个多块状结构语句的一部分（比如说``if/else - if/else``或者``try/catch/finally``）,那么即使大括号中间没有内容也应该换行。

例子：

```java
  void doNothing() {}
```

### 4.2 块缩进：两个空格

每次开始一个新的块，缩进增加两个空格。当块结束时，缩进使用之前的缩进级别。缩进级别对代码和注释都适用。

### 4.3 一行一条语句

每个语句后要换行。

### 4.4 列限制：100

Java代码有一个100个字符的列限制。除了下面提到的，任何行只要超过了这个限制就必须换行。

例外：

1. 不可能满足列限制的行(比如说，JavaDoc中的一个长URL，或者一个长的JSNI方法参考)。
2. ``package``或者``import``语句。
3. 注释中的可能被复制到shell中的命令行。

### 4.5 自动换行

**术语说明**：当代码由于某些原因(比如列限制)而被分为多行，这种行为称作自动换行。

没有一种广泛并且准确的准则来说明在每个情况下如何进行自动换行。通常有几种有效的方法来自动换行同一段代码。

> Tip：提取一个方法或者本地变量也许可以在不换行的情况下解决代码过长的问题。

#### 4.5.1 从哪里断行

自动换行的基本准则是：更倾向于在更高语法级别的地方换行，也就是说：

1. 如果在非赋值运算符处断开，那么应该在符号之前断开。(注意，这与Google其它语言的编程风格不同，比如说C++和JavaScript)
 + 这条规则也同样适用于以下“类似运算符”的符号：点分隔符(.)，两个冒号的方法引用(::)，类型界限中的&(``<T extends Foo & Bar>``)，以及catch块中的管道符号(``catch (FooException | BarException e)``)。
2. 如果在赋值语句处断开，通常的做法是在该符号后断开(比如在=后面断开)，但是其它方式也是可以接受的。
 + 这条规则也同样适用于“类似赋值操作符”，在``foreach``中的冒号。
3. 方法名或者构造方法名与开括号(()留在同一行。
4. 逗号与前面的内容在一行。

> Note: 自动换行的目的是为了让代码看上去更清楚，不一定符合最小的代码行数。

#### 4.5.2 自动换行时至少4个空格

当自动换行时，在第一行后的每一行至少要有4个空格的缩进。

当有多个自动换行时，缩进可能超过4个空格。一般来说，两个连续行适用相同的缩进级别当且仅当它们开始于同级语法元素。

**水平对齐**一节中指出，不鼓励使用可变数目的空格来对齐前面的行。

### 4.6 空格

#### 4.6.1 垂直空格

以下情况需要一个空行：

1. 类内成员或者初始化块之间：字段，构造方法，方法，内部类，静态初始化块，实例初始化块。
+ 例外：在两个连续的字段(中间没有其它的代码)之间的空行是可选的。这种空行在需要创建字段的逻辑分组的时候使用。
+ 例外：枚举常量之间的空行在**枚举类**一节中说明。
2. 在语句间，当需要组织代码的逻辑分组时。
3. 可以在类的第一个成员前或者在最后一个成员后(既不推荐使用也不反对)。
4. 满足文档中其它部分的空行需求时(比如说在第3节，源代码结构，以及3.3节，import语句)。

多个连续的空行是允许的，但永远不是必须的(或者鼓励使用的)。

#### 4.6.2 水平空格

除了语言和其它规则的要求，并且除了字面量，注释和Javadoc，单个ASCII字符出现空格之外，空格出现并且只出现在以下地方：

1. 分隔关键字，比如说``if, for ``或者``catch``与跟在后面的开括号(()
2. 分隔关键字，比如说``else``或者``catch``与跟在后面的闭大括号(})
3. 在任何开大括号之前({)，除了以下两种例外情况：
 + ``@SomeAnnotation({a, b})``不使用括号
 + ``String[][] x = {{"foo"}};``(在{{之间没有空格，见第8条)
4. 在任何二元或者三元操作符的两侧。这条规则同样适用于下面的“类似操作符”的符号：
 + 类型界限中的&符号：``<T extends Foo & Bar>``
 + catch块中用来处理多个异常的管道符号：``catch (FooException | BarException e)``
 + foreach语句中的冒号
 + lambda表达式中的箭头：``(String str) -> str.length()``     
**不适用于**：
 + 方法引用中的两个冒号(::)，应该这么写``Object::toString``
 + .分隔符，应该这么写``object.toString()``

5. 在``,:;``或者闭括号())之后
6. 在一条行注释语句的双斜线(//)两侧。在这里，多个空格是允许的，但不是必须的。
7. 在类型和变量声明之间：``List<String> list``
8. 在数组初始化的大括号内(可选的)
 + ``new int[] {5, 6}`` and ``new int[] { 5, 6 }``都是可以的。
这条规则不应该理解为在行的开始或结束需要或禁止使用空格，只对内部空格做要求。

#### 4.6.3 水平对齐：不是必须的

**术语说明：**水平对齐是指在代码上增加一些空格使得某一行的字符能和上一行的字符对齐。

在Google style中这种做法是允许的，但不是必须的。对于已经使用了这种风格的代码也不必去维持这种风格。

这是一个未使用对齐的例子，然后是使用了对齐的例子：

```java
  private int x; // this is fine
  private Color color; // this too

  private int   x;      // permitted, but future edits
  private Color color;  // may leave it unaligned
```

> Tip:对齐有助于增加代码的可读性，但是会为未来的维护带来问题。考虑到将来我们可能只需要修改其中的一行代码。这种修改可能会使原来的非常完美对齐的代码变得不是那么对齐，这种做法是允许的。更经常地情况是它提醒程序员(也许是你)去调整被修改的行附近的空格，并且有可能会引发一系列行的重新格式化。那**修改的一行代码**造成的影响非常大。最坏的情况可能会造成一些无意义的工作，最好的情况下也仍然会污染版本历史信息，降低代码review的速度，增加合并代码冲突的可能性。

### 4.7 使用小括号来分组：推荐

除非当作者和reviewer都认为去掉小括号也不会使得代码被误解，或者是去掉小括号能使代码增加可读性时，才应该省略小括号。假定每个读代码的人都能记住Java操作符的优先级时不合理的。

### 4.8 具体的结构

#### 4.8.1 枚举类

在每个逗号后面跟着一个枚举常量，是否加换行是可选的。附加的空行(通常是一行)也是允许的。这是一种可能性：

```java
  private enum Answer {
  YES {
    @Override public String toString() {
      return "yes";
    }
  },

  NO,
  MAYBE
}
```

一个没有方法也没有常量注释的枚举类可以选择性的与一个数组初始化一样格式化。

```java
  private enum Suit { CLUBS, HEARTS, SPADES, DIAMONDS }
```

由于枚举类也是类，因此所有其它的类格式化规则全都适用。

#### 4.8.2 变量声明

##### 4.8.2.1 每次只声明一个变量

每个变量声明(字段或者局部变量)只声明一个变量：不要使用类似``int a, b;``的形式。

##### 4.8.2.2 当需要时才声明

局部变量不要习惯性地在包含它们的块或者类似块结构的开始就声明。相反的，为了最小化作用域，局部变量应该在靠近它们第一次被使用的地方声明。局部变量声明后就应该初始化，或者尽快进行初始化。

#### 4.8.3 数组

##### 4.8.3.1 数组初始化：可写成块状结构

数组初始化可以写成“块状结构”。举例来说，下面的这些方式(不是一个完整的列表)都是可行的：

```java
  new int[] {           new int[] {
    0, 1, 2, 3            0,
  }                       1,
                          2,
  new int[] {             3,
    0, 1,               }
    2, 3
  }                     new int[]
                            {0, 1, 2, 3}

```

##### 4.8.3.2 不要使用C语言风格的数组声明

方括号是类型的一部分，而不是变量：``String[] args``,不是``String args[]``。

#### 4.8.4 Switch语句

**术语说明：**switch结构大括号内的是一个或多个语句组。每个语句组由一个或多个switch标签组成(``case FOO:``或者``default:``)，后面跟着一个或多个语句。

##### 4.8.4.1 缩进

与其它的块状结构类似，switch块中的内容使用两个空格缩进。

每个switch标签后新起一行，再增加两个空格的缩进，就像一个块的开始。后续的switch标签与之前的缩进级别相同，就像一个块的结束。

##### 4.8.4.2 Fall-through注释

在一个switch块内，每个语句组要么通过``break,continue,return``或者抛出异常来终止，要么通过一个注释来表示程序将继续执行到下一个语句组中。任何能表示fall-through含义的注释都是可以的(通常使用``// fall through``)。这个特别的注释在最后的一个语句组是不需要的。例子：

```java
  switch (input) {
    case 1:
    case 2:
      prepareOneOrTwo();
      // fall through
    case 3:
      handleOneTwoOrThree();
      break;
    default:
      handleLargeNumber(input);
  }
```

注意在``case 1:``后面是不需要注释的，只有在语句组最后才需要。

##### 4.8.4.3 default情况要写出来

每个switch语句包含一个default语句组，即使它是空的。

#### 4.8.4 注解

注解紧跟在文档块后面，应用于类、方法或者构造方法上，并且每行只写一个注解。这些换行不算自动换行，因此缩进的级别没有增加。例子：

```java
  @Override
  @Nullable
  public String getNameIfPresent() { ... }
```

例外：单个没有参数的注解可以和方法签名的第一行出现在同一行，比如：

```java
  @Override public int hashCode() { ... }
```

应用于这段的注解紧随文档块的出现，但在这种情况中，多个注解(可能有参数的)可能列在同一行；比如说：

```java
  @Partial @Mock DataLoader loader;
```

对于应用在参数、局部变量、类上的注解没有特别的格式化规则。

#### 4.8.5 注释

这部分将介绍注释的实现。Javadoc将在第7部分分开介绍。

##### 4.8.6 块注释风格

块注释与周围的代码保持相同的缩进级别。它们可以是``/* ... */``风格或者``// ...``风格。对于多行注释，后面的行必须以``*``开头并且与前面的行的``*``对齐。

```java
  /*
   - This is          // And so           /* Or you can
   - okay.            // is this.          * even do this. */
   */
```

注释不要包含在由星号或者其它字符组成的框内。

> Tip: 当在写多行注释时，如果你希望代码格式化程序在必要时能自动重新换行，那么使用``/* ... */``风格的注释。大部分的格式化程序对于``// ...``风格的注释不会重新自动换行。

#### 4.8.7 修饰符

如果存在类或者成员修饰符，按Java语言指定的顺序排序：

```java
  public protected private abstract default static final transient volatile synchronized native strictfp
```

#### 4.8.8 数字字面量

``long``类型的整型字面量使用大写的``L``作为后缀，不要使用小写的(避免与数字1混淆)。比如说，使用``3000000000L``要好于``3000000000l``。

## 5 命名

### 5.1 对所有标示符都通用的规则

标示符只使用ASCII字母或者数字，在少数情况下使用下面提到的下划线。这样每个有效的的标示符名字可以被正则表达式``\w+``匹配到。

在Google Style中不使用那些特殊的前缀或者后缀，像那些例子里的``name_, mName, s_name``和``kName``。

### 5.2 标示符类型的规则

#### 5.2.1 包名

包名应该全部使用小写，连续的单词只是简单的拼接起来(不使用下划线)。比如说，``com.example.deepspace``,不是``com.example.deepSpace``或者``com.example.deep_space``。

#### 5.2.2 类名

类名使用大写的驼峰命名法。

类名通常是名词或者名次短语。比如说，``Character``或者``ImmutableList``。接口名字可能是名词或者名词短语(例如：``List``)，有时候也会使用形容词或者形容词短语(例如：``Readable``)。

对于注解的命名没有特定的规则甚至没有完善的约定。

测试类的命名以被测试的类的名字开头，以``Test``结尾。比如说，``HashTest``或者``HashIntegrationTest``。

#### 5.2.3 方法名

方法名使用小写的驼峰命名法。

方法名通常使用动词或动词短语。比如说，``sendMessage``或``stop``。

下划线可能出现在JUnit测试方法名称中用以分隔名称的逻辑组件。一个典型的模式是``test<MethodUnderTest>_<state>``，比如说``testPop_emptyStack``。并不存在唯一正确的方式来命名测试的方法。

#### 5.2.4 常量名

常量名的命名模式为``CONSTANT_CASE``：全部使用大写字母，单词之间使用下划线分隔。但是，到底什么才是一个常量？

每个常量是一个static final的字段，但不是所有的static final的字段都是常量。在决定一个字段是否是常量前，先考虑这个字段是否真的感觉是一个常量。比如说，如果任何一个该实例观测到的状态是可以改变的，那么几乎可以确定它不是一个常量。仅仅只是打算不改变对象是不够的。例子：

```java
  // Constants
  static final int NUMBER = 5;
  static final ImmutableList<String> NAMES = ImmutableList.of("Ed", "Ann");
  static final Joiner COMMA_JOINER = Joiner.on(','); // because Joiner is immutable
  static final SomeMutableType[] EMPTY_ARRAY = {};
  enum SomeEnum { ENUM_CONSTANT }

  // Not constants
  static String nonFinal = "non-final";
  final String nonStatic = "non-static";
  static final Set<String> mutableCollection = new HashSet<String>();
  static final ImmutableSet<SomeMutableType> mutableElements = ImmutableSet.of(mutable);
  static final Logger logger = Logger.getLogger(MyClass.getName());
  static final String[] nonEmptyArray = {"these", "can", "change"};
```

这些名字通常是名词或者名次短语。

#### 5.2.5 非常量字段名

非常量字段名(静态或者非静态的)使用小写的驼峰命名法。

这些名字通常是名词或者名字短语。例如：``computedValues``或``index``。

#### 5.2.6 参数名

参数名使用小写的驼峰命名法。

public方法中应该避免使用一个字符的参数名。

#### 5.2.7 局部变量名

局部变量名使用小写的驼峰命名法。

局部变量即使是final并且是不可变的，也不应该把它作为常量或者当作常量来对待。

#### 5.2.8 类型变量名

每个类型变量命名使用下面两种风格中的一种：

+ 一个大写字母，后面可以跟一个数组(例如：``E, T, X, T2``)
+ 以类命名方式，后面跟一个大些的字母T(例如：``RequestT, FooBarT``)

### 5.3 驼峰命名法

有时候有不止一个理由将英语短语转换成驼峰命名法的形式，比如说存在首字母缩略词或者一些不常见的结构像“IPv6”或者“iOS”。Google Style指定以下方案：

名字以``prose form``形式开始：

1. 把短语转换为纯ASCII编码字符并且删除任何省略符号。比如说，“"Müller's algorithm”应该转换为“Muellers algorithm”。
2. 把这个结果切分为单词，在空格或其它标点符号处(通常是-)分隔开。
 + 推荐：如果某个单词已经有了常用的驼峰表现形式，按它的组成把它分隔开(例如："AdWords"变为"ad words")。注意“iOS”并不是一个真正的驼峰命名法形式，因此该推荐对它并不适用。
3. 现在把所有字母都变为小写(包括首字母缩略词)，然后把下列情况下的单词的第一个字母改为大写：
 + 每个单词的首字母都大写，得到大写的驼峰命名法。
 + 除了第一个单词的每个单词，得到小写的驼峰命名法。
4. 最终，将所有的单词连接起来的到一个标示符。

注意，原单词的大小写几乎都是忽略的。例子：

| Prose form | Correct | Incorrect |
| ------| ------ | ------ |
| "XML HTTP request" | XmlHttpRequest | XMLHTTPRequest |
| "new customer ID" | newCustomerId | newCustomerID |
| "inner stopwatch" |innerStopwatch| innerStopWatch |
| "supports IPv6 on iOS?" |supportsIpv6OnIos|supportsIPv6OnIOS|
| "YouTube importer" |YouTubeImporter or YoutubeImporter*| |

> Note: 在英语中，某些含有连字符的单词形式不唯一：例如“nonempty”和“non-empty”都是正确的，所以方法名“checkNonempty”和“checkNonEmpty”也都是正确的。

## 6 编程实践

### 6.1 总是使用``@Override``

只要是合法的，方法就应该标注``@Override``注解。这包括子类覆盖基类的方法，类实现接口的方法，以及一个接口中的方法重新指定父接口的方法。

例外：当基类中的方法已经被标注为``@Deprecated``,可以省略``@Override``注解。

### 6.2 异常捕获：不要忽略

除了下面的说明，对捕获的异常不做响应的行为是极少正确的。(通常的响应是把它作为log打印出来，或者它被认为是不可能的，当作一个``AssertionError``重新抛出)

当它确实是在catch块中不需要做任何响应，应该在注释中说明正当的理由。

```java
  try {
    int i = Integer.parseInt(response);
    return handleNumericResponse(i);
  } catch (NumberFormatException ok) {
    // it's not numeric; that's fine, just continue
  }
  return handleTextResponse(response);
```

例外：在测试中，一个捕获的异常的名字以``expected``开头，那么它会被忽略并且没有注释。下面是一种非常常见的情形，用以确保测试中抛出一个期望中的异常，所以在这里注释不是必须的。

```java
  try {
    emptyStack.pop();
    fail();
  } catch (NoSuchElementException expected) {
  }
```

### 6.3 静态成员：使用类进行调用

使用类名调用静态类成员，而不是类的引用或者表达式：

```java
  Foo aFoo = ...;
  Foo.aStaticMethod(); // good
  aFoo.aStaticMethod(); // bad
  somethingThatYieldsAFoo().aStaticMethod(); // very bad
```

### 6.4 Finalizers:不要使用

只有极少数情况需要覆盖``Object.finalize``。

> Tip：不要这么做。如果你必须要这么做，首先仔细阅读并理解《effective java》第7条，“Avoid Finalizers”，然后不要这么这么做。

## 7 Javadoc

### 7.1 格式化

#### 7.1.1 一般形式

Javadoc块的基本格式化形式如下所示：

```java
  /**
   * Multiple lines of Javadoc text are written here,
   * wrapped normally...
   */
  public int method(String p1) { ... }
```

或者单行注释：

```java
  /** An especially short bit of Javadoc. */
```

基本形式总是可以接受的。当注释中没有@符号并且整个Javadoc可以合并为一行时，可以使用单行注释的形式。

#### 7.1.2 段落

空行(即，只包含最左侧星号的行)会出现在段落之间和Javadoc标记(@XXX)之前(如果有的话)。 除了第一个段落，每个段落第一个单词前都有标签<p>，并且它和第一个单词间没有空格。

#### 7.2 @子句

任何标准的@子句按以下顺序使用``@param, @return, @throws, @deprecated``,并且这四种类型不会出现空的描述。当一个@子句不能放在单行中时，后续的行在@后以4个空格(或者更多)缩进。

### 7.3 摘要片段

每个类或成员的Javadoc以一个简短的摘要片段开始。这个片段是非常重要的。在某些情况下，它是唯一出现的文本，比如在类和方法索引中。

这是一个片段——一个名词或者动词短语，不是一个完整的句子。它不以``A {@code Foo} is a...``或者``This method returns...``开头，也不是一个完整的祈使句，类似``Save the record.``。然而，片段是大写的并且加了标点符号就像它是一个完整的句子。

> Tip:一个常见的错误是以``/** @return the customer ID */``的形式写简单的Javadoc。这是不正确的，应该改成``/** Returns the customer ID. */``。

### 7.3 在哪里使用Javadoc

至少每个``public``类和每个``public``或者``protected``的类成员处需要使用Javadoc，以下会说明一些例外。

额外的Javadoc内容也会存在，在**非必需的Javadoc**一节中说明。

#### 7.3.1 例外：不需要说明的方法

Javadoc对一些简单、明显的方法比如``getFoo``是可选的，这种情况下除了写"Returns the foo"确实没什么值得写了。

> 重要：使用这个例外来判断是否应该省略读者应该知道的信息是不合适的。比如说，对于名为``getCanonicalName``的方法，不因该省略它的文档(根据原理它可能只是说``/** Returns the canonical name. */``)通常读者可能不知道"canonical name"的含义。

#### 7.3.2 例外：重写(Override)

如果一个方法重写了基类中的方法，那么Javadoc不是必须的。

#### 7.3.4 可选的Javadoc

其它类或成员在需要时可以使用Javadoc。

当一条注释会被用来定义类或成员的用途或者行为的时候，该注释应该写成Javadoc(使用``/**``)。

可选的Javadoc不需要严格的遵守7.1.2，7.1.3和7.2节的格式化规则，当然，也是推荐遵守的。

## 声明

本文档由本人翻译自[Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)。
翻译过程中参考了Hawstein的博客[Google Java编程风格指南](http://www.hawstein.com/posts/google-java-style.html)，在此表示感谢。