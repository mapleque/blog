---
title: 【开始用go】开发HTTP服务
tags:
  - golang
categories:
  - 实践
  - 开始用go
date: 2019-09-11 11:43:14
description:
---

在互联网时代，HTTP服务是绝大多数产品的基础，如何高效的实现一个高质量的HTTP服务，各有各的说法。
这种说法，通常会被包装成一种所谓框架的东西，对开发者进行布道。
截止到目前，Github上已经有很多成熟的框架，一些框架也发展了大量的追随者。
当然，追随者也会因为框架不同而产生流派之争。
在这里，我们无意争论谁对谁错，只是提出一套自己通过实践总结出来的思路，与读者分享。

<!-- more -->

框架的意义
====

刚开始接触Go语言的时候，当时我们所面对的情况是“急需快速实现一个HTTP服务的需求“。
这种情况在国内来说，应该是大多数开发者所面对的(如果你不是已经实现了财富自由)。
而在这种情况下，只有两个选择：
- 使用能够快速上手工具，通过简单配置实现服务
- 使用从前已经掌握的工具实现服务

此时，如果你想要学习新的语言，那么只有第一条路可以走。而这种工具，其实就是所谓的框架。

一个理想的框架应该是什么样子?
- 零学习成本
- 零编码量
- 简单配置、快速上线
- 高性能
- 低消耗
- 可监控

这种说法并不夸张，仔细分析你就会发现，这不正是广大企业家、老板、产品经理等需求方所想要的效果嘛。

不幸的是，上面的要求，目前还没有哪一个框架能够全部满足。
而且放眼未来，短期之内应该也不会有能够满足要求的框架出现。
所以在选择框架上，我们只能做出取舍。

对上面所提的到要求进行简单的分析不难发现，前三项是对服务开发效率的要求，后三项是对服务质量的要求。
显然在服务质量的要求上，我们不应该放弃，那么开发效率的要求上还有余地吗？我们可以继续分析。

如果我们站在更高一个层次去看，需求方对开发效率的要求其实很直接：做得快、问题少。

试想，如果有这样一个东西，它能够告诉我一个规则，我根据规则进行配置，配置完成后就能实现一个HTTP服务需求，那么我将是一个非常优秀的开发者。
然而什么东西如何制定规则，并且解析我的配置来实现服务呢？框架可以，语言本身也可以。

这样一来，很明显我们是在通过框架解决效率问题，同时，框架又帮我们解决了质量问题。

上面提到了，框架可以解决我们的问题，语言本身也可以，那我们为什么还需要框架呢？
原因无非以下几种：
- 框架可以降低语言学习成本，用起来更快
- 框架解决了一些语言上需要额外投入精力处理的质量问题，用起来更稳妥
- 框架规定了一种工程化的开发模式，用起来更省心
- 框架实现了一些常用的逻辑和方法，用起来更方便

当然，框架毕竟是在语言上层构建起来的工具，是语言的子集，因此会有它自身的限制，例如：
- 一些特殊的需求实现起来较为复杂
- 一旦出现质量问题，影响范围较大
- 出现未知问题时，诊断和解决问题的难度都很大
- 性能上对比语言本身，一定有所降低

如此一来，我们真的需要框架吗？

{% note success %}
如果需要你花费一至两个小时的时间阅读本文，就可以不使用框架而达到使用框架的效果，你将如何选择？
{% endnote %}

{% note info %}
下面将会介绍，在没有框架帮助的情况下，如何使用go语言实现一个HTTP服务，并且保证高效率，高质量，高性能。
{% endnote %}

HTTP服务的本质
====

什么是HTTP服务，我们可以说：遵循HTTP协议标准所实现的互联网服务是HTTP服务。这种定义毫无疑义。

我们要做的事情，就是实现一个服务能够满足需求方的需求。需求五花八门，但是能通过HTTP服务实现的需求，都有一个共同的本质：
{% mermaid sequenceDiagram %}
participant user as 用户
participant service as HTTP服务
participant storage as 持久存储
user ->>+ service: 输入和动作
service ->>+ storage: 写入数据
storage ->>- service: 读取数据
service ->>- user: 输出和反馈
{% endmermaid %}

用一句话总结就是：
{% note success %}
能够与用户交互，并留下痕迹。
{% endnote %}

这里可以通过一个例子来看Go语言是怎么实现这样一个基本的服务的。

{% note info %}
例子
----
实现一个服务，能和用户打招呼，并记录该用户打招呼的次数，并告诉他。
完整代码参考： https://github.com/mapleque/gostart/blob/master/http/hello/hello.go
下面是关键代码部分。
这个例子虽然简单，但是仍然完整的展示了HTTP服务的本质。事实上，我们所开发的大部分需求，抛开产品包装之后，其核心都是这样的东西。
{% endnote %}

```go
package main

import (
	"fmt"
	"log"
	"net/http"
)

// RunHelloService run hello service as an example of gostart/http
//
// Command:
//  `go run github.com/mapleque/gostart/http/hello`
//
// Run in console:
//     curl http://localhost/hello?name=cookie
//     #> Hello, cookie，see you 1 times.
//     curl http://localhost/hello?name=cookie
//     #> Hello, cookie，see you 2 times.
//     curl http://localhost/hello?name=cookie
//     #> Hello, cookie，see you 3 times.
func RunHelloService(addr string) {
	storage := map[string]int{}
	http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
		name := r.FormValue("name")
		if _, exist := storage[name]; !exist {
			storage[name] = 0
		}
		storage[name]++
		fmt.Fprintf(w, "Hello, %s，see you %d times.", name, storage[name])
	})
	fmt.Printf("service is running on %s.\n", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}

func main() {
	RunHelloService(":80")
}
```

朴素的实现
====

观察HTTP服务的本质，我们可以发现，事实上需要处理的事情只有四步：
- 接收用户的输入和动作
- 写入数据
- 读取数据
- 给用户返回输出和反馈

如果将这四步带入到开发过程，将会变成：
{% mermaid graph LR%}
path_route[接口识别]
param_deal[参数提取和校验]
data_process[数据处理和持久化]
response[结果格式化返回]
path_route --找到--> param_deal
path_route --404--> response
param_deal --正常--> data_process
param_deal --错误--> response
data_process --正常/错误--> response
{% endmermaid %}

- 接口识别 -- 区分接口不同的处理逻辑
- 参数提取和校验 -- 从请求中获取用户输入数据，并校验数据是否符合协议要求
- 数据处理和持久化 -- 根据输入数据和持久化数据进行逻辑处理得到结果数据
- 结果格式化和返回 -- 将最终结果数据整理成协议的格式返回

这其中，需要开发者处理的与需求相关的只有两点：
- 接口定义和输入输出协议 -- 包括接口识别、参数校验和格式化返回
- 数据处理和持久化 -- 处理数据

因此，只要能够高效的解决这两点问题，我们就能够高效的开发HTTP服务。

接口定义和输入输出协议
----

将接口定义和输入输出协议和起来看，就是HTTP服务对外提供的接口协议（例如我们常见的API文档）。

作为开发者，我们必须要定义这些东西，并且基于定义进行开发。

{% note info %}
RESTful是一种较为流行的接口设计风格，但在这里并不提倡，具体原因不再详述，请读者在使用中自行体会。
{% endnote %}

从HTTP协议角度看，接口协议可使用的资源很多（这里仅考虑HTTP1.1，完整的协议标准请参考[rfc2616](https://tools.ietf.org/html/rfc2616)]）：
- 主机 -- 包括域名、端口等
- 请求方法 -- 包括GET、POST、PUT、DELETE等
- 请求路径 -- URL中的Path部分
- 路径参数 -- URL中的Query部分
- 请求头 -- Http Request Header
- 请求体 -- Http Request Body
- 返回状态码 -- Http Status
- 返回头 -- Http Response Header
- 返回体 -- Http Response Body

这里我们可以遵循最简化原则，使用尽可能少的定义实现接口协议，以达到降低学习成本的目的。

- 接口识别 -- 通过URL.Path完全匹配来区分不同接口（用户的动作）
- 请求参数 -- 通过JSON格式的Http Request Body来传递请求参数
- 返回数据 -- 通过JSON格式的Http Response Body返回数据

{% note info %}
这种接口协议设计风格，更像是RPC的一种实现，只不过将接口识别从数据包中单独提出来作为初始分发的依据。
{% endnote %}

在[后面的章节](#编码实现)，将给出一种代码编写方法，能够高效的实现该协议。

数据处理和持久化
----

数据处理是实现产品需求的核心，是开发者能力的体现，即便是目前比较流行的一些框架，也会将这部分留给开发者自行发挥。

数据处理的限制通常来源于语言本身，语法和生态在这个时候起到至关重要的作用。

数据持久化是对数据处理能力上的一种补充，通常需要通过额外的服务实现，如：数据库，消息队列，文件系统等。

如果你支持微服务的思想，那么数据处理部分的所有复杂逻辑都可以通过请求其他服务来解决。

{% mermaid sequenceDiagram %}
participant user as 用户
participant service as HTTP服务
participant ms1 as 微服务1
participant ms2 as 微服务2
participant ms3 as 微服务3
user ->>+ service: 输入数据
service ->>+ ms1: 输入数据
ms1->>- service: 返回数据
service ->>+ ms2: 输入数据
ms2->>- service: 返回数据
service ->>+ ms3: 输入数据
ms3->>- service: 返回数据
service ->>- user: 返回数据
{% endmermaid %}

编码实现
----

前两节通过论证，已经对开发HTTP服务过程中所需要处理的仅与需求相关两个问题定义清楚。

本节将通过一个例子来展示，在上面的定义下，如何使用Go语言高效实现HTTP服务。

{% note info %}
例子：实现一个 TODO LIST 服务。

需求描述：用户能够对要做的事情进行增删改查。

我们按照上面例子的实现方式，快速的实现这个需求。
代码参考：https://github.com/mapleque/gostart/blob/master/http/todolist/ 。

在这个项目中，我们对代码进行了拆分，通过不同的文件来区分代码的功能，以方便维护。
{% endnote %}

```
gostart/http/todolist/
├── handle.go               // 定义通用数据，实现一些通用的函数，如返回的统一数据结构和构造方法
├── handle_todo_add.go      // /todo/add接口实现
├── handle_todo_delete.go   // /todo/delete接口实现
├── handle_todo_list.go     // /todo/list接口实现
├── handle_todo_update.go   // /todo/update接口实现
├── main                    // main包，用于启动服务
│   └── main.go             // main函数，可以用来载入初始化配置，启动服务
├── model_todo.go           // 定义todo对象的数据结构，用于整个服务（接口、处理逻辑、存储等）
├── ms_storage.go           // 实现一个存储的微服务，这里仅用来维持代码完整性，通常是其他包实现
├── routers.go              // 定义接口路由
└── service.go              // 对标准库net/http包的简单封装，让服务中的函数能够使用其他微服务
```

