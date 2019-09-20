---
title: 【开始用go】在MacOS上搭建开发环境
tags:
  - golang
categories:
  - 实践
  - 开始用go
date: 2019-09-06 18:33:45
description:
---

每个开发者，都有一个套适合自己的开发环境，如果你决定开始使用go语言开发，那么一定要先准备好自己的开发环境。

{% note info %}
这里所指的开发环境，不只是一个能让go跑起来的环境，而是一个可以用于日常工作的完整的工作环境。
{% endnote %}

本文将从三个方面介绍go语言开发环境的构建，并给出自己所构建的开发环境的配置：
- go安装和升级 -- go运行的基础
- 路径和环境变量 -- 更好地管理项目、依赖，并方便执行使用go安装的命令行工具
- IDE -- 一个个人熟悉的用于写go代码的编辑器

<!-- more -->

go安装和升级
====

{% note info %}
Go官方提供了详细的安装文档 https://go-zh.org/doc/install ，读者可以按需索取。
这里将要介绍的是在MacOS下，使用homebrew安装并管理Go的详细方法。
{% endnote %}

Homebrew是一个面向MacOS的包管理工具，官网 https://brew.sh/ 有详细安装使用方法说明。

在国内使用Homebrew，建议更改源：
```sh
cd "$(brew --repo)"
git remote set-url origin https://mirrors.ustc.edu.cn/brew.git 

cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git 

brew update
```

查看可用的Go版本：
```sh
brew search go
```

这里将可以看到一系列可以安装的Go版本：
```sh
go go@1.10 go@1.9 go@1.8 go@1.4
```

通常直接安装最新版本即可：
```sh
brew install go
```

安装完成后，即可在命令行执行go命令了：
```sh
go version
```

当go更新了新版本，需要升级的时候，执行：
```sh
brew upgrade go
```

这个命令将安装Homebrew所管理的最新版本的go，并替换掉原来安装的go。

路径和环境变量
====

安装完Go后，就可以开始写代码了。但是如果想要写项目，还需要更进一步的进行配置。

{% note info %}
官方文档参考： https://go-zh.org/doc/code.html 。
{% endnote %}

这里笔者给出自己在MacOS上的路径：
```
~/
├── workspace -> Documents/workspace
│   ├── gopath
│   │   ├── bin
│   │   ├── pkg
│   │   ├── src
│   │   │   ├── github.com
│   │   │   │   ├── mapleque
│   │   │   │   │   ├── gostart
│   │   │   ├── golang.org
│   │   │   │   ├── x
│   │   │   │   │   ├── tour
│   ├── github.com
│   │   ├── mapleque
│   │   │   ├── gostart -> ~/workspace/gopath/src/github.com/mapleque/gostart
```

设置环境变量：
```bash ~/.bash_profile
export GOPATH=~/workspace/gopath
export PATH=$PATH:$GOPATH/bin
```

其中，
- GOPROXY 用于`go get`时作为代理
- GOAPTH 用于原始的go依赖路径
- PATH 中增加 $GOPATH/bin 是为了让`go install`所安装的二进制文件能够直接被执行

特别的，从go1.11版本开始，Go将go module作为官方包管理工具进行支持，其中go1.11和go1.12版本需要主动开启：
```bash
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
```
其中，
- GOPROXY 用于`go get`时自动代理使用国内源

{% note info %}
关于go module的使用，可以参考官方文档：https://blog.go-zh.org/using-go-modules 。
笔者也将在另外一篇文章中详细讲述自己的使用方式，敬请期待。
{% endnote %}

编辑器
====

{% note info %}
官方推荐编辑器：https://golang.google.cn/doc/editors.html 。
{% endnote %}

笔者使用的是vim-go。
- 如何安装vim-go https://github.com/fatih/vim-go
- [如何安装vundle并配置vim](/posts/tool/vim/vim-diy/)
- 如何安装vim -- `brew install vim`

更多关于vim的配置，可以参考[【vim】使用vim作为开发go的IDE](/posts/tool/vim/vim-go/)。

{% note warning %}
注意：最新版本vim-go由于使用了gopls，所以如果使用的是vim-go的最新版本，在执行`:GoInstallBanaries`命令时，必须开启go module模式，并且在当前文件夹中有go.mod文件。
{% endnote %}

这里特别提一些值得一试vim-go命令：
- `:GoDef, :GoDefPop`或者`Ctrl+], Ctrl+t` -- 直接跳转到光标位置所指的方法或变量的定义代码
- `:GoAddTags, :GoRemoveTags` -- 给当前光标所在属性添加删除标签
- `:GoMetaLinter` -- 执行一系列代码检查
- `:GoImpl` -- 生成实现指定接口的代码
- `:GoIfErr` -- 生成错误校验的代码
- `:GoImports` -- 自动增减需要import的包

本质上讲，上面的命令都是通过调用一些go tool来实现。

{% note info %}
Go有着众多的tool，它们几乎覆盖了从代码编写、编译测试运行、到性能监控等整个开发周期。
笔者在后面的文章中，也会选择性的介绍一些tool的实战，以启发读者如何利用好这些资源来更高效的工作。
{% endnote %}
