---
title: 使用openswan搭建l2tp/ipsec服务
description: 本文主要介绍l2tp/ipsec搭建过程，操作系统为centos7
tags: [ vpn ]
categories: [ 工具, openswan ]
date: 2019-08-29 11:10:30
---

使用方法
----

在需要使用服务的终端上，新建VPN配置，类型选择L2TP。

- 描述 -- 随便填写
- 服务器 -- 下文中的host_ip
- 账户 -- 下文中的username
- 密码 -- 下文中的password
- 密钥 -- 下文中的key

安装
----

安装openswan和xl2tpd，ppp（其中有些系统可能已经装好）：
```
yum install -y openswan ppp xl2tpd
```

配置ipsec
----

新建ipsec配置文件/etc/ipsec.d/l2tp.conf，并确保根配置文件/etc/ipsec.conf已经include之：

```conf /etc/ipsec.d/l2tp.conf
conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT
conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    rekey=no
    ikelifetime=8h
    keylife=1h
    type=transport
    left=<host_ip>
    leftid=<host_ip>
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
    dpddelay=40
    dpdtimeout=130
    dpdaction=clear
```

注意替换其中的`<host_ip>`为公网ip，例如：123.123.123.123。

配置ppp
----

编辑ppp配置文件/etc/ppp/options.xl2tpd：
```conf /etc/ppp/options.xl2tpd
ipcp-accept-local
ipcp-accept-remote
ms-dns  8.8.8.8noccp
auth
# crtscts
idle 1800
mtu 1410
mru 1410
# nodefaultroute
debug
# lock
proxyarp
connect-delay 5000
require-mschap-v2
asyncmap 0
hide-password
name l2tpd
```

配置l2tp
----

编辑l2tp配置文件/etc/xl2tpd/xl2tpd.conf，修改global部分：
```conf /etc/xl2tpd/xl2tpd.conf
listen-addr = <host_ip>
auth file = /etc/ppp/chap-secrets
port = 1701
```

注意替换其中的`<host_ip>`为公网ip，例如：123.123.123.123。

配置密钥
----

编辑/etc/ipsec.secrets文件，增加下面内容：

```
<host_ip> %any: PSK "<key>"
```

注意替换其中的`<host_ip>`为公网ip，例如：123.123.123.123。

`<key>`为共享密钥，可以是任意字符串。

编辑/etc/ppp/chap-secrets文件，增加下面内容：
```
# client     server     secret               IP addresses
<username>          l2tpd     <password>               *
```

`<username>`为用户名，可以是任意字符串。

`<password>`为密码，可以是任意字符串。

配置系统
----

修改系统配置，执行下面命令：
```bash
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.rp_filter=0
sysctl -w net.ipv4.conf.default.rp_filter=0
sysctl -w net.ipv4.conf.eth0.rp_filter=0
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.default.send_redirects=0
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.default.accept_redirects=0
```

防火墙开放端口，新建文件/usr/lib/firewalld/services/l2tpd.xml：
```xml /usr/lib/firewalld/services/l2tpd.xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>L2TPD</short>
  <description>L2TPD Port</description>
  <port protocol="udp" port="1701"/>
</service>
```

在firewall中开启相应的服务：
```bash
firewall-cmd --permanent --add-service=l2tpd
firewall-cmd --permanent --add-service=ipsec
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload
```

启动
----

启动系统服务，并设置为开机自启动
```bash
systemctl enable ipsec xl2tpd
systemctl restart ipsec xl2tpd
```

调试
----

如果启动不成功，可以使用journal查看日志调试：
```bash
journalctl -f
```
