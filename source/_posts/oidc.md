---
title: 实现OIDC协议
tags: [ OIDC, jwt, Kubernates ]
categories: [ 实践, 用户认证 ]
date: 2019-08-29 15:57:39
description: 介绍如何实现OIDC协议
---

{% blockquote OpenID Connect https://openid.net/connect/%}
OpenID Connect 1.0 is a simple identity layer on top of the OAuth 2.0 protocol. It allows Clients to verify the identity of the End-User based on the authentication performed by an Authorization Server, as well as to obtain basic profile information about the End-User in an interoperable and REST-like manner.
{% endblockquote %}

OIDC工作原理和应用场景如下图所示：

{% mermaid sequenceDiagram %}
participant u as user
participant app as oidc-app
participant oidc as oidc-server

app ->>+ oidc: 获取oidc配置
Note over app,oidc: .well-known/oepnid-configuration
oidc ->> app: 返回oidc配置
app ->>+ oidc: 获取密钥
Note over app,oidc: conf.jwks_uri
oidc ->>- app: 返回jwks并缓存

u ->>+ app: 未登录用户请求
app ->>- u: 跳转登录页

u ->>+ oidc: 登录并授权
Note over app,oidc: conf.authorization_endpoint
Note over oidc: 生成授权码code
oidc ->>- u: 返回授权码code

u ->>+ app: 提交授权码code
app ->>+ oidc: 申请token
Note over app,oidc: conf.token_endpoint

Note over oidc: 生成jwt-token
oidc ->>- app: 返回jwt-token
app ->>- u: 返回服务token，可以直接使用jwk-token
u ->>+ app: 带jwt-token请求
Note over app: 解密jwt-token
Note over app: 验证权限
app ->>- u: 返回请求结果

{% endmermaid %}

其中，用户请求应用，需要把jwt-token放在请求Header中：`Authorization: Bearer <jwt-token>`。

应用通过缓存的jwks解析jwt-token获取用户信息并验证相关权限。

