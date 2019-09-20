---
title: 基于Kerberos实现内部系统员工账号单点登录
tags: [ Kerberos ]
categories: [ 实践, 用户认证 ]
date: 2019-08-29 15:19:01
description: 介绍如何实现Kerberos协议并在内部系统中使用该协议实现员工账号单点登录
---

{% blockquote What is Kerberos? http://web.mit.edu/kerberos %}
Kerberos is a network authentication protocol. It is designed to provide strong authentication for client/server applications by using secret-key cryptography.
{% endblockquote %}

Kerberos工作原理和应用场景如下图所示：

{% mermaid sequenceDiagram %}
participant u as User
participant client as Client
participant server as Server
participant kdc as Kerberos

u ->> client: username, password
client ->> client: cache(username, password)
client ->> kdc: (to AS) username
kdc ->> kdc: CTSK = rand
kdc ->> kdc: TGT = {CTSK, username, expired}
kdc ->> kdc: password = findBy(username)
kdc ->> kdc: EncCTSK = enc(CTSK, password)
kdc ->> kdc: TGSSecretKey = const
kdc ->> kdc: EncTGT = enc(TGT, TGSSecretKey)
kdc ->> client: EncCTSK, EncTGT
client ->> client: password = loadCache()
client ->> client: CTSK = decrypt(EncCTSK, password)
client ->> client: cache(CTSK)
client ->> client: Authenticator = {username, timestamp}
client ->> client: cache(Authenticator)
client ->> client: CTSKEncAuthenticator = enc(Authenticator, CTSK)
client ->> kdc: (to TGS) EncTGT, AppID, CTSKEncAuthenticator
kdc ->> kdc: TGSSecretKey = const
kdc ->> kdc: TGT = decrypt(EncTGT, TGSSecretKey)
kdc ->> kdc: valid(TGT.expired)
kdc ->> kdc: CTSK = TGT.CTSK
kdc ->> kdc: Authenticator = decrypt(CTSKEncAuthenticator, CTSK)
kdc ->> kdc: username = Authenticator.username
kdc ->> kdc: AppSecretKey = findBy(AppID)
kdc ->> kdc: CSSK = rand
kdc ->> kdc: ST = {CSSK, username, expired}
kdc ->> kdc: EncST = enc(ST, AppSecretKey)
kdc ->> kdc: EncCSSK = enc(CSSK, CTSK)
kdc ->> client: EncST, EncCSSK
client ->> client: CTSK = loadCache()
client ->> client: CSSK = decrypt(EncCSSK, CTSK)
client ->> client: cache(CSSK)
client ->> client: Authenticator = loadCache()
client ->> client: CSSKEncAuthenticator = enc(Authenticator, CSSK)
client ->> server: EncST, CSSKEncAuthenticator
server ->> server: AppSecretKey = const
server ->> server: ST = decrypt(EncST, AppSecretKey)
server ->> server: valid(ST.expired)
server ->> server: CSSK = ST.CSSK
server ->> server: Authenticator = descrypt(CSSKEncAuthenticator, CSSK)
server ->> server: valid(Authenticator.username == ST.username)
server ->> server: Token = rand
server ->> server: EncToken = enc(Token, CSSK)
server ->> client: EncToken
client ->> client: CSSK = loadCache()
client ->> client: Token = decrypt(EncToken, CSSK)
client ->> client: cache(Token)
u ->>+ client: action
client ->>+ server: request, Token
server ->>- client: response data
client ->>- u: view

{% endmermaid %}

其中：

- User -- 用户
- Client -- 应用客户端
- Server -- 应用服务端
- Kerberos -- 认证授权服务，包含AS,TGS等
- AS -- 认证服务(Authentication Service)
- TGS -- 票据授权服务(Ticket Granting Service)
- username -- 用户输入的用户名
- password -- 用户输入的密码
- EncCTSK -- 通过AS上的用户password加密的CTSK
- CTSK -- 用于Client与TGS通信的密钥(Client TGS Session Key)
- EncTGT -- 通过TGSSecretKey加密的TGT
- TGT -- 授权票据(Ticket Granting Ticket)，包含CTSK、username和expired
- Authenticator -- 将username和timestamp包装为一个Authenticator
- CTSKEncAuthenticator -- 通过CTSK加密的Authenticator
- AppID -- 唯一标识一个应用服务提供方，应用服务可能包含Client和Server
- TGSSecretKey -- TGS自己的维护的密钥
- EncST -- 通过AppSecretKey加密的ST
- AppSecretKey -- 应用服务提供方在TGS上注册的密钥，一个AppID对应一个TGSSecretKey
- ST -- 应用票据(Service Ticket)
- EncCSSK -- 通过CTSK加密的CSSK
- CSSK -- 用于Client与Server通信的密钥Client Server Session Key
- Token -- 用于Client与Server通信的会话标识，由应用实现，可以是Cookie，Session，HTTP Header等

从上图中可以看出，整个过程分成三个部分：
- 认证 -- 确认用户身份和客户端是否可信
- 授权 -- 授权用户访问指定服务
- 登录 -- 用户凭借授权去登录服务，建立会话

这里有两个特点需要强调：
- 应用服务与认证授权服务在整个认证过程中没有直接通信
- 用户密码在整个认证过程中没有在网络上传播

上面的认证授权服务在实际应用上，还欠缺了两部分：
- 管理用户密码 -- 需要给用户提供线上服务
- 管理应用密钥 -- 需要给开发者提供线上(可离线)服务
