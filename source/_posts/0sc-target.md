---
title: 【从零打造社区搜索推荐服务】问题的提出
tags:
  - Elasticsearch
categories:
  - 实践
  - 从零打造社区搜索推荐服务
date: 2019-09-05 17:59:01
description: 主要讨论如何定义社区搜索推荐问题的范围。
---

社区搜索推荐，是一个现代化社区所应该具有的基本功能。

从技术角度讲，一个完整的社区搜索推荐服务，需要解决以下问题：
- 对中文的处理
- 根据用户输入，结合社区内容给出相关搜索建议
- 根据搜索词给出相关社区内容的搜索结果
- 对于指定搜索词，运营人员能够控制第一页应该展示那些结果和顺序
- 可以屏蔽一些搜索词，让其不能出结果
- 可以屏蔽一些内容，让其永远不能出现在结果中
- 能够简单识别网络爬虫行为，并进行封禁

