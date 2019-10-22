---
title: 【vim】使用vim作为开发go的IDE
tags:
  - Vim
categories:
  - 工具
  - Vim
date: 2019-08-29 13:03:19
description: 主要介绍使用vim作为开发go项目的IDE所需的配置
---

{% note info %}
本文中将直接使用基本设置已经使用的配置，如需了解，请阅读[【vim】基本设置](/posts/tool/vim/vim-start/)。
{% endnote %}

基本设置
====

创建`~/vim/ftplugin/go.vim`文件类配置用于go文件的设置。

```vim
set tw=78
```

安装vim-go
====

[vim-go](https://github.com/fatih/vim-go/)是Go语言官方推荐的vim插件。

通过Vundle安装，在.vimrc中添加：

```vim
Plugin 'fatih/vim-go'
```

在vim中执行命令：
```
:PluginInstall
```

然后需要根据需求安装go相关插件，参考文章[【开始用go】在MacOS上搭建开发环境](/posts/practice/go/go-workspace/)。
