---
title: 部署并使用shadowsocks
tags: [ vpn ]
categories: [ 工具, shadowsocks ]
date: 2019-10-22 16:46:13
description: 本文主要介绍shadowsocks的部署和使用
---

[Shadowsocks](https://shadowsocks.org)(通常简称为ss)是一个基于socks5协议实现的网络管理服务。
通常我们用它来做网络流量转发，因此这里简单介绍一下如何方便安全的部署并使用它。

本文将基于ss的go版本部署实现，可能需要一些计算机开发基础知识。如不具备，请自行搜索其他教程。

准备vps
----

部署和使用ss，需要先有一个用于转发流量的vps。

{% note info %}
笔者目前使用的vultr服务，$3.50/mo, 500GB。
通过这个推广链接注册并购买，可以获得一定的优惠。
https://www.vultr.com/?ref=7147137
{% endnote %}

下面将以CentOS7x64为例进行部署。

申请ip
----

想要进行流量转发，必须要有一个能够访问的ip。由于一些不明原因，并不是所有ip都能访问，所以在一定在申请ip的时候注意选择。

如果是使用vultr，可以通过多购置几台vps进行尝试，遇到可用ip后再将其他的退掉。

编译安装
----

shadowsocks的代码，全部托管在github上，这里建议使用golang实现版本：https://github.com/shadowsocks/go-shadowsocks2 。

该版本可以提供跨平台(windows, linux, MacOS)支持。

登录所购买的vps，然后安装开发环境：


```sh
yum install -y git golang
```

下载代码并编译安装（这里之所以自己下载代码编译，是因为go-shadowsocks2的release版本落后master很多，居然还不支持plugin）：

```sh
go get -u -v github.com/shadowsocks/go-shadowsocks2
```

部署服务
----

通过上面的步骤下载完成后，应该就已经自动编译好了一个当前系统的可执行文件了。

执行下面的命令启动服务：
```sh
$GOPATH/bin/shadowsocks2 -s 'ss://AES-256-GCM:your_password@0.0.0.0:8488' -verbose
```

对于CentOS7，还需要设置防火墙。这里通过创建一个防火墙服务来实现：

```sh
vim /usr/lib/firewalld/services/socks.xml
```

```xml /usr/lib/firewalld/services/socks.xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Socks</short>
  <description>Socks Port</description>
  <port protocol="tcp" port="8488"/>
</service>
```

```sh
firewall-cmd --permanent --add-service=socks
firewall-cmd --reload
```

编译客户端
----

该版本shadowsocks提供了多平台的客户端，可以直接通过原代码编译生成：
```sh
make
```

然后到bin路径下找对应的客户端可执行文件下载。

启动客户端
----

客户端支持多种代理模式，这里以在MacOS上执行socks模式为例：
```sh
shadowsocks2-macos -c 'ss://AES-256-GCM:your_password@ip:8488' -verbose -socks :1080 -u
```

注意将上面的ip文本替换为vps的ip。

使用服务
----

在MacOS上，可以通过内置的网络组件直接连接socks代理：

系统偏好设置->网络->高级->代理->socks

在代理服务器中填上localhost:1080，然后点击：

好->应用

即完成了机器全部网络流量的转发。

此时可以尝试访问https://google.com 以检验是否成功。

使用其他客户端
----

经过了上面的步骤，你应该已经能在MacOS上访问shadowsocks官网了。
此时你会发现，官网上推荐了多种可以在不同平台使用的客户端，这里将重点介绍以下outline。

IOS上的outline客户端目前可以在AppStore上免费下载。

启动outline客户端，你会发现要求输入的是secretKey。
按照outline官方的要求，你需要下载并部署outline管理服务来生成并管理secretKey。
但这个管理工具不仅增加了一些统计逻辑实现，还收集了服务器信息，因此对于个人用户不推荐使用（尽管客户端也可能收集了一些数据）。
这里可以通过下面网址自行生成secretKey并链接：
https://shadowsocks.org/en/config/quick-guide.html

