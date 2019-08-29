---
title: Hexo主题
description: 以NexT主题为例介绍Hexo主题的用法
tags: [ Hexo, NexT ]
categories: [ 工具, Hexo ]
date: 2019-08-28 15:45:26
---

hexo创建项目后，提供了一个默认的主题landscape。
如果没有特殊需求，直接使用即可。当然，也可以在官方网站上找自己喜欢的主题进行替换。

笔者安装了[NexT主题](https://theme-next.org/docs/getting-started/)，并对其进行了一些配置。

下面将详细讲述安装配置过程，及遇到的一些问题的解决办法。

下载安装
----

如文档所述，直接通过git下载：
```bash
git clone https://github.com/theme-next/hexo-theme-next themes/next
```

然后修改配置文件_config.yml：

```yaml _config.yml
theme: next
```

最后生成静态页面：
```bash
hexo g
```

{% note warning %}

此时按照文档的说法，应该已经可以开始使用NexT主题了，然而笔者却遇到了几个错误。

错误很明确，就是需要安装一些依赖的包：

`npm install hexo-fs hexo-util lodash --save`

{% endnote %}

配置文件
----

安装成功后，简单阅读了配置文件，发现足足1000多行。也就是说，基本上所有能想到的它都是支持配置的。

这里需要特别一提的，就是它的第一个配置项override。按照文档的说法，这个选项是为了更新主题是不把用户的配置覆盖掉，用户可以写一个_data/next.yml文件来与next/_config.yml进行merge。
这是一个不错的实践，要照做之。新建一个next.yml文件，然后在其中修改那些需要修改的配置项，其他的继续使用默认配置即可。

{% note warning %}
注意，next.yml文件要放在source_data/next.yml位置才生效。
{% endnote %}

遍历了全部配置项后，有些选项可以优先关注，下文将注意说明。

favicon
----

通过favicon的配置，可以看到NexT对不同的设备终端设置了不同的视图，用户可以按照规范制作相应的favicon文件，并编写配置项指向文件。

footer
----

网站的footer是统一的，也是完全可配的。默认配置文件中，列出了全部可配项及其说明，按照实际情况填写即可。

{% note info %}
这里强烈建议保留powered和theme两个配置项。
{% endnote %}

百度统计
----

NexT主题支持多种统计服务，这里以百度统计为例，只需要配置百度统计后台生成的appid即可：

```yaml
baidu_analytics: e0fc945f04e1f73b09770bf9d28d0627
```

rss
----

支持rss，安装：
```bash
npm install hexo-generator-feed
```

然后使用默认配置项即可：
```yaml
rss:
```

发布
----

新换的主题，发布要特别注意，先执行：`hexo clean`。

```bash
hexo clean
hexo g -d
```
