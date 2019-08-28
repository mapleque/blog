---
title: Hexo排版
date: 2019-08-28 18:47:31
description: 介绍Hexo的标签、分类、搜索的使用方法
tags: [ Hexo, tags, categories, search ]
categories: [开源软件研究和使用, Hexo]
---

Hexo有三种排版工具可供选择：

- 标签 -- 用于多维度索引一篇文章
- 分类 -- 用于单维度归类一篇文章
- 搜索 -- 用于模糊查找一篇文章

下面逐一介绍如何使用这三个工具。

标签
----

在文件头部属性中，tags用于声明当前文章的标签，例如：
```
tags: [ Hexo, 排版 ]
```
这个属性可以指定多个词语作为一篇文章的标签，把多篇文章的标签集合到一起并统计，就可以得到标签云。

事实上，Hexo已经默认做了这件事，想要看到标签云，只需要创建一个页面并进行一些配置即可：

```bash
hexo new page tags
```

上面的命令，会创建一个source/tags/index.md的文件，编辑如下内容：
```markdown source/tags/index.md
---
title: tags
date: 2019-08-28 18:42:48
type: "tags"
comments: false
---
```

最后，需要在主题配置中，放开标签页面的入口：
```yaml
menu:
  tags: /tags/ || tags
```

分类
----

分类的用法几乎同标签用法一样，例如：
```
categories: [开源软件研究和使用, Hexo]
```

这个属性，当指定多个词语时，它们是父子关系，即：
```
- 开源软件研究和使用
  - Hexo
```

同样的，Hexo也已经将每篇文章的分类进行了整合，想要看到一个分类索引的页面，创建页面并配置即可：

```bash
hexo new page categories
```

上面的命令，会创建一个source/tags/index.md的文件，编辑如下内容：
```markdown source/categories/index.md
---
title: categories
date: 2019-08-28 18:40:41
type: "categories"
comments: false
---
```

最后，需要在主题配置中，放开标签页面的入口：
```yaml
menu:
  categories: /categories/ || th
```

搜索
----

支持本地搜索（全文搜索），安装：
```bash
npm install hexo-generator-search --save
```

然后修改配置项：

```yaml
local_search:
  enable: true
```
