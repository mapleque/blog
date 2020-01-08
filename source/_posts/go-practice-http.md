---
title: 【开始用go】
tags:
  - golang
categories:
  - 实践
  - 开始用go
date: 2019-12-17 17:00:35
description:
---

配置加载
----

服务在启动的时候通常都需要一些配置来提供启动参数，如：监听端口，其他服务连接密钥等。

这里建议所有配置都通过环境变量读取，这样做的原因有以下几点：
1. 生产环境的系统配置可能较为复杂，可以根据不同环境调整配置不同参数
1. 生产环境密钥应在运维范畴保密，不应透露到开发者层面
1. 开发环境更为复杂，开发者可以根据自己的环境灵活配置启动

go标准包`os`中提供了获取环境变量的方法：
```go
package main

import (
  "os"
)

func main() {
	port := os.Getenv("UC_LISTEN_PORT")
  // ...
}
```

服务定义和启动
----

为了避免全局变量的失控，我们通常会为服务定义一个实例，然后通过实例接口让其在main中被加载和启动。

那么对于一个http服务，我们需要为其实现http.Handler接口：

```go
// Service impement http.Handler interface
// which can be initialized in a http server.
type Service struct{}

func New() *Service {
	return &Service{}
}

func (s *Service) ServeHTTP(w http.ResponseWriter, req *http.Request) {
  // TODO ...
}
```

然后，在main中实例化我们定义的服务，然后就可以通过标准包`net/http`提供的方法启动了：

```go
package main

import (
	"net/http"
	"os"

	uc "github.com/mapleque/gostart/ms/uc/service"
)

func main() {
	port := os.Getenv("UC_LISTEN_PORT")
	s := uc.New()
	server.ListenAndServe("0.0.0.0:"+port, s)
}
```

路由和处理函数
----

依据标准包`net/http`的实现，所有请求最终都会经过`ServeHTTP`方法处理，并且每个请求的处理都是一个单独的协程。

所以在`ServeHTTP`方法中，我们主要实现的就是为当前请求分配处理函数。这里也可以直接使用标准包`net/http`中的`ServeMux`实现：

```go
// Service implement http.Handler interface
// which can be initialized in a http server.
type Service struct {
	mux *http.ServeMux
}

// ServeHTTP implement http.Handler interface.
func (s *Service) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	s.mux.ServeHTTP(w, req)
}
```

很明显，要让

```go
func (s *Service) signin(w http.ResponseWriter, req *http.Request) {
  // TODO deal with /signin request
}

func (s *Service) signout(w http.ResponseWriter, req *http.Request) {
  // TODO deal with /signout request
}

func (s *Service) userinfo(w http.ResponseWriter, req *http.Request) {
  // deal with /userinfo request
  switch req.Method {
    case http.MethodGet:
      s.getUserinfo(w, req)
    case http.MethodPost:
      s.postUserinfo(w, req)
    default:
      // return 405
      w.WriteHeader(http.StatusMethodNotAllowed)
  }
}

func (s *Service) getUserinfo(w http.ResponseWriter, req *http.Request) {
  // TODO deal with GET /userinfo request
}

func (s *Service) postUserinfo(w http.ResponseWriter, req *http.Request) {
  // TODO deal with POST /userinfo request
}
```

参数定义和校验
----

```go
type SigninParam struct {
  Username string `json:"username"`
  Password string `json:"password"`
}

func bindAndValid(req *http.Request, obj interface{}) error {
  if req == nil || req.Body == nil {
    return fmt.Errorf("invalid request")
  }
  decoder := json.NewDecoder(req)
  if err := decoder.Decode(obj); err != nil {
    return err
  }
  // use github.com/go-playground/validator/v10
  return validate.Struct(obj)
}

func (s *Service) signin(w http.ResponseWriter, req *http.Request) {
  param := SigninParam{}
  if err := bindAndValid(req, &param); err != nil {
    // TODO response param-check error message
    return
  }
  // TODO do login
  // TODO response successful data
}
```

处理返回
----

```go
type Response struct {
  Status int `json:"status"`
  Data interface{} `json:"data"`
  Message interface{} `json:"message"`
}

type UserinfoResponse struct {
  Token string `json:"token"`
}

```

```go
func response(w, resp interface{}) {
  encoder := json.NewEncoder(w)
  err := encoder.Encode(resp)
  if err != nil {
    panic(err)
  }
}
```

```go
func (s *Service) signin(w http.ResponseWriter, req *http.Request) {
  param := SigninParam{}
  if err := bindAndValid(req, &param); err != nil {
    // response param-check error message
    //
    // To custom with the error message,
    // use https://github.com/go-playground/universal-translator
    // see example at: https://github.com/go-playground/validator/blob/master/_examples/translations/main.go#L105
    response(w, Response{StatusInvalidParam, nil, MessageInvalidParam}
    return
  }
  // ... do login
  // response successful data
  response(w, Response{StatusSuccess, UserinfoResponse{token}, nil})
}

```

调用其他服务
----

这里以使用mysql服务为例，使用[`github.com/go-sql-driver/mysql`包](https://github.com/go-sql-driver/mysql)。

首先，想要在handle中使用mysql服务，就需要能够获取mysql的连接，通常我们会将服务连接池初始化放在服务初始化时进行：

```go
type Service struct {
  mux *http.ServeMux
  // add a db property
  db *sql.DB
}


```

日志输出
----

