---
title: 使用openvpn管理办公网络
tags: [ vpn ]
categories: [ 工具, openvpn ]
date: 2019-08-29 15:06:23
description: 本文提供了一套使用openvpn管理办公网络的方案，兼顾安全性和便捷性
---

使用openvpn管理办公网络，可以做到：
- 以证书作为客户端认证标识，通过颁发证书管理用户接入网络的权限
- 每个证书指定固定ip，在网络上可以监控ip行为，对应到用户
- 通过对用户分配不同ip段的ip，来控制用户在网络中的权限
- 推送内网域名解析，复杂内网路由保证复杂内网连通性

服务端
====

主服务
----

- [github.com/OpenVPN/openvpn](https://github.com/OpenVPN/openvpn)
- [官网文档openvpn.net](https://openvpn.net/community-resources/how-to/)(需要翻墙)
- [一键安装脚本](https://github.com/Nyr/openvpn-install)

配置文件样例：
```conf
verb 3 # LOG等级
dev tun  # 隧道设备名
port 1194

# 如果上层使用udp, vpn使用tcp, 丢包后vpn会就会重传上层的udp报文, vpn使用udp协议, 这样可以让上层应用自己决定使用tcp还是udp
proto udp

topology subnet # 此模式下所有客户端在一个子网里

# keys
ca /etc/openvpn/pki/ca.crt
key /etc/openvpn/pki/private/vpn.mapleque.com.key
cert /etc/openvpn/pki/issued/vpn.mapleque.com.crt
crl-verify /etc/openvpn/pki/crl.pem
dh /etc/openvpn/pki/dh.pem
tls-auth /etc/openvpn/pki/ta.key

key-direction 0
keepalive 10 60

# 超时重连接时不会重载key和tun
persist-key
persist-tun

status /var/log/openvpn/status.log
log /var/log/openvpn/log.log
management localhost 7505

client-config-dir /etc/openvpn/ccd

client-to-client # 允许client之间通信

user vpn
group vpn

# vpn进程启动后给本机添加该路由(不需要有客户端连接), 可以配置多条
route 172.31.0.0 255.255.0.0 192.168.232.20

# 启动server模式, 隧道使用该网段, 并占用第一个地址用作本机隧道的IP, nopool表示不将此网段用作dhcp
server 192.168.224.0 255.255.240.0 nopool

# 单独配置dhcp pool
ifconfig-pool 192.168.224.2 192.168.225.254 255.255.240.0

push "dhcp-option DNS 192.168.224.1"

push "route 192.168.16.0 255.255.240.0 vpn_gateway"
```

systemd启动配置样例：
```service
# This service is actually a systemd target,
# but we are using a service since targets cannot be reloaded.
# /lib/systemd/system/openvpn.service

[Unit]
Description=OpenVPN service
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/openvpn --daemon ovpn --cd /etc/openvpn --config /etc/openvpn/vpn.conf
ExecReload=/bin/kill -HUP $MAINPID
WorkingDirectory=/etc/openvpn

[Install]
WantedBy=multi-user.target
```

证书颁发
----

可以考虑使用easyrsa签发证书。

客户端
====

安装vpn客户端有风险，注意看好官方客户端版本。大部分客户端下载都需要翻墙，请自行检索解决方案。

- [IOS](https://itunes.apple.com/us/app/openvpn-connect/id590379981?mt=8)
- [Android](https://play.google.com/store/apps/details?id=net.openvpn.openvpn)
- [MacOS](https://openvpn.net/downloads/openvpn-connect-v3-macos.dmg)
- [Linux](https://openvpn.net/vpn-server-resources/connecting-to-access-server-with-linux/)
- [Windows](https://openvpn.net/downloads/openvpn-connect-v3-windows.msi)

