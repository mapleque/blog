---
title: hexo的研究
date: 2019-08-28 12:08:17
tags:
---

引言
----

此前，一直追求一个支持markdown渲染的纯前端组件来构建技术博客，始终不太理想。
主要面对的问题有三：

1. 渲染速度慢
    该体系下访问一个博文，需要先下载md文件和渲染器代码，然后渲染器解析md生成html，同时还需要下载必要的主题。
    这样一个流程下来，页面渲染速度通常需要几百毫秒，使用起来不能令人满意。
1. 迁移部署并不简单
    纯前端渲染markdown的思想主要是为了直接通过git管理md文件，任何地方直接下载即可部署。
    然而部署过程中还需要下载用于渲染的项目，并配置nginx进行代理，如此并没有剩下多少工作量。
1. 功能有所欠缺
    博客常用的目录、标签、搜索、归档等功能，在该体系下很难实现的很好。
    即便实现也会导致投入成本太高，且破坏了纯markdown写博客的初衷。

因此，决定尝试转变思路，探索一些通过编译构建博客的方案。

简介
----

hexo是一个基于nodejs对markdown文件进行前端编译为静态资源并发布的博客框架。
它实现了一套完整的命令行工具来支持整个博客编写过程（并没有支持编辑），甚至通过读取配置文件，可以直接发布到服务器。
当然也可以直接组织编辑文件，只使用hexo的编译生成功能（目前看来二者兼顾可能是最佳实践）。
通过主题、模板、辅助函数等功能可以实现自定义排版和索引。

在大致了解了上述功能后，笔者决定开始实践之。以下将具体讲述整个实践过程，以及中间的一些问题和解决方法。

部署
----

这里使用github pages部署，可是实现零成本建站。

需要注意的是，源代码要通过另一个repo来管理：
- https://github.com/mapleque/blog.git 管理源代码
- https://github.com/mapleque/mapleque.github.io 管理pages

配置_config.yml文件，可以实现命令行发布：
```yaml
# Deployment
## Docs: https://hexo.io/docs/deployment.html
deploy:
  type: git
  repo: git@github.com:mapleque/mapleque.github.io.git
```

这样每次写完文章，执行下面语句即可发布：
```bash
hexo g -d
```

最后还要记得将源代码提交：
```bash
git add .
git commit -m"feature: add something"
git push origin master
```

基本配置
----

通过修改_config.yml文件，可以完成大部分网站基本配置，如：title，description，keywords等。
```yaml
# Site
title: 枫枝雀自鸣
subtitle: 技术博客
description: 谈技术，看积累。这里记录的是笔者的亲身经历和反复总结。
keywords: 互联网, 研发, 计算机, 工程
```
注意，上面这些项一定要认真填写，它们是搜索引擎识别你的重要信息源。

此外，如果需要favicon，记得自行创建：
```
cp favicon.ico source/
hexo g
```

主题
----

排版
----

目录
----

标签
----

其他
----
