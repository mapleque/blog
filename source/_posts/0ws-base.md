---
title: 【互联网产品的诞生和演化】独立应用的基本架构
tags:
  - Web
categories:
  - 实践
  - 互联网产品的诞生和演化
date: 2019-11-29 18:19:30
description:
   一个完整的产品技术架构，不只是客户端和服务端，需要考虑的细节还很多，这些都将在本文中一一阐述。
---

{% note info %}
一个新的互联网产品研发并不简单，当你不确定产品形态是否可行时，请先想办法验证，不要盲目进入开发。
如何进行低成本验证，请参考上一篇文章：[产品的最简模型](/posts/practice/0ws/0ws-simple)。
{% endnote %}

得益于移动互联网时代的飞速发展，开发一个互联网产品已经成为人尽可谈的话题。

然而在这样的话题的讨论中，通常得到的结果都是：我们的点子非常好，就是缺一个开发。

不可否认，任何一个想法，如果能把它做成一个App、一个网站或者一个小程序，多半情况下它都是可用的，想想就很兴奋。

但是想要真正将这个开发过程付诸实施，还有一个完整的开发团队的距离。

简单来说，一个完整的开发团队，需要以下配置具有以下特殊技能的人员：
设计、前端开发、客户端开发、后端开发、测试、运维。
{在后面[技能需求](#技能需求)章节有对这些技能应用在何处的详细说明。）

当然，不排除有些人是具有多种技能的综合型人才。

如果运气好，上面所有人员都能胜任，那么至少可以开发出一个初始版本的系统了，接下来考虑线上部署，需要采购并长期维护以下资源：
域名（备案）、ssl证书、云主机实例、云数据库实例、cdn服务。
{在后面[资源需求](#资源需求)章节有对这些资源应用在何处的详细说明。}

至此，开发一个崭新的互联网服务的必备条件已经完全具备了，最后我们需要考虑的就是项目周期。

{% note info %}
项目开发周期=每个成员完成任务所需要的时间+成员间沟通所需时间-可并行时间
{% endnote %}
很明显，根据上面公式来看，想要缩短开发时间，只有两条路可以走：
- 选择能力更高的人以降低单人工作时间和沟通时间
- 通过合理规划增加可并行时间（[工作流](#工作流)章节给出了一个通常情况下的最优规划方案）

基本技术架构
----

在上文中，我们已经直接探讨了开发一个互联网产品所需要考虑的全部内容。然而为什么是这样，这就需要从基本架构先说起。

参考下图：

{% mermaid graph LR %}
fe[网站或微信小程序]
app[移动应用App]
api[后端接口]
services[后端服务]
db[数据库服务]
3rd-api[第三方服务接口]
admin[运营后台]
admin-api[后台接口]
fe --> api
app --> api
api --> services
services --> db
3rd-api --> services
services --> 3rd-api
admin --> admin-api
admin-api --> services
{% endmermaid %}

对于一个互联网产品，客户端大多会考虑实现两种形式：`网站`或`移动应用App`。其中，
- 网站 ---- 开发成本低，迭代周期快
- 移动应用App ---- 产品形象固定，用户粘性高

{% note info %}
随着`微信小程序`生态的日益完善，这类客户端形态也逐渐被大众所考虑。
微信小程序的优势在于，它兼具了网站和移动应用App两种类型客户端的优势，并且天生可以依托微信这个成熟且巨大的用户生态圈。
{% endnote %}

在客户端之后，还需要服务端来实现产品逻辑。服务端的内容，大致可以采用如下方式划分：

- 后端接口 ---- 作为用户与服务交流的通道，让用户在客户端上的操作可以得到对应的响应。
- 后端服务 ---- 实现复杂的产品逻辑，如：注册登录、购买支付、分享邀请等。
- 数据库服务 ---- 用于记录数据，包括但不限于：用户信息、用户购买信息、用户操作记录等。
- 第三方服务接口 ---- 接入其他已经实现了的互联网服务，如：微信登录、微信或支付宝支付等。
- 运营后台 ---- 运营人员维护产品数据的平台，通常是一个网站，可运营的内容可能包括产品信息价格、用户账号数据等。
- 后台接口 ---- 作为运营人员与服务交流的通道，使其能够查询管理大部分产品相关数据。

整体来讲，任何一个互联网产品，在设计开发之初，都应该考虑以上所有内容。
一些情况下，部分内容可能或有所取舍，比如：
- 不需要开发移动应用App，只要一个网站就够了
- 不需要后端接口和后端服务，因为不需要记录任何用户数据，只需要展示一些内容
- 不需要运营后台，我可以直接通过数据库查询和修改需要的数据

技能需求
----

如果按照上面所讲的基本技术架构进行开发，那么我们需要以下相关技能：

- ui&ue ---- 决定产品长相和操作方式，通常需要艺术设计专业知识
- fe
  - h5 ---- 开发pc端和移动端网页产品，需要掌握html5+javascript+css基础能力和主流框架使用经验
  - wx ---- 开发微信小程序或服务号相关产品，需要熟悉微信开放接口和微信小程序开发标准
  - admin ---- 开发运营后台，熟悉后台相关框架以及一些数据可视化技术和组件
- app
  - android ---- 开发android应用，需要相关开发经验
  - ios ---- 开发ios应用，需要相关开发经验
- server
  - buzz ---- 开发http接口服务，需要相关开发经验
  - service ---- 开发复杂应用服务和基础服务，需要相关开发经验
- other
  - test ---- 对产品进行系统全面的测试，需要相关经验
  - op ----- 发布和维护所开发的服务，应对各种突发情况（如：软硬件故障、黑客攻击，版本更新等）

资源需求
----

对于任何一个互联网产品，想要让用户能够使用，都需要购买以下资源：

- 域名，作为用户访问所使用的地址，如：www.jd.com。需要在域名运营商或者代理商处购买。
  注意在国内购买或使用的域名通常还需要备案。
- https证书，用于认证域名的安全性。需要在有资质的证书管理机构或代理商处购买。
- 云实例，用于部署和运行服务。需要在云服务商购买。
- 数据库实例，用于提供数据库相关服务。需要在云服务商购买。
- cdn，用于提供静态资源存储和访问服务。需要在云服务商购买。

工作流
----

一个合理的工作流可以让产品开发周期缩到最短。

{% mermaid graph LR %}
prd[产品需求]
uiue[视觉交互设计]
server[后端设计开发]
admin[后台设计开发]
fe[前端开发]
app[移动端开发]
test[测试]
release[发布]
prd --> uiue
prd --> server
prd --> admin
uiue --> fe
uiue --> app
server --> fe
server --> app
server --> admin
fe --> test
app --> test
admin --> test
test --> release
{% endmermaid %}

这里同样按照专业领域划分，从一个确定的产品需求开始。
- 一旦产品需求确定了，就可以开始视觉交互设计和后端设计了。
  这里边后端设计要考虑接口、逻辑和数据三个层面，对于设计人员的能力要求较高。
- 前端开发和移动端开发需要在两个设计都完成后开始。
- 后台设计开发需要在后端设计完成后开始。
- 当所有开发完成后进入测试环节。
- 最终测试通过后进行产品发布。

经过多年实践和总结，这个工作流可以最大化并行时间，也就是最优化项目开发周期。