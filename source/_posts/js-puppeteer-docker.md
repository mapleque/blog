---
title: 在nodejs中使用puppeteer并通过docker部署
tags: [ nodejs, puppeteer, docker ]
categories: [ 程序语言, js ]
date: 2019-08-29 16:22:23
description: 在Node中使用Puppeteer包实现爬虫，然后通过Docker进行部署，其中一些问题记录在这里，以免走弯路
---

[Puppeteer](https://github.com/GoogleChrome/puppeteer#readme)是Google基于Chromium开发的一个Node库。

用户通过调用Puppeteer的Api，可以做到任何Chrome浏览器能做到的事情。

因此，其应用领域可能包括：
- 网页截图生成报告
- 服务端渲染
- 面向网页应用的自动化测试
- 更接近真实情况的探针监控
- 需要处理复杂逻辑的爬虫

开发环境
----

安装puppeteer包：

```bash
npm i puppeteer --save
```

{% note info %}
这里仅介绍基本用法以保证快速进入开发，高阶用法请参考[官方文档](https://github.com/GoogleChrome/puppeteer#readme)。
{% endnote %}

编写代码：
```javascript example.js
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto('https://example.com');
  await page.screenshot({path: 'example.png'});

  await browser.close();
})();
```

执行脚本：

```bash
node example.js
```

生产环境
----

如果是专用的带有node环境的linux机器，正常安装puppeteer包即可使用。

这里特别介绍一下在Docker环境下安装部署的过程。

我们通过创建一个装好了puppeteer包的镜像来提供部署环境：

```Dockerfile Dockerfile
# node-chrome-10.16
FROM node:10.16-alpine

ENV APP_PATH /app
WORKDIR ${APP_PATH}

# Change mirrors to tsinghua
RUN echo http://mirrors.tuna.tsinghua.edu.cn/alpine/edge/main > /etc/apk/repositories && \
    echo http://mirrors.tuna.tsinghua.edu.cn/alpine/edge/community >> /etc/apk/repositories && \
    echo http://mirrors.tuna.tsinghua.edu.cn/alpine/edge/testing >> /etc/apk/repositories && apk update

# Setting timezone
RUN apk add tzdata openssh-client git
RUN cp -r -f /usr/share/zoneinfo/Hongkong /etc/localtime

# Installs cnpm
RUN npm install -g cnpm --registry=https://registry.npm.taobao.org

# Installs latest Chromium (73) package.
RUN apk add --no-cache \
      curl \
      make \
      gcc \
      g++ \
      python \
      linux-headers \
      binutils-gold \
      gnupg \
      libstdc++ \
      udev \
      chromium=~73.0.3683.103 \
      nss \
      freetype \
      freetype-dev \
      harfbuzz \
      ttf-freefont \
      wqy-zenhei

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

# Puppeteer v1.12.2 works with Chromium 73.
RUN yarn add puppeteer@1.12.2

RUN apk del --no-cache make gcc g++ python binutils-gold gnupg libstdc++

# Add user so we don't need --no-sandbox.
#RUN addgroup -S pptruser && adduser -S -g pptruser pptruser \
#    && mkdir -p /home/pptruser/Downloads /app \
#    && chown -R pptruser:pptruser /home/pptruser \
#    && chown -R pptruser:pptruser /app
#
## Run everything after as non-privileged user.
#USER pptruser

CMD ['/bin/sh']
```

{% note info %}
上面代码中注释掉了给puppeteer创建用户运行的部分，如果你的docker服务是在root下启动的，上面的镜像可以正常工作。
否则就需要给执行该镜像的用户开通一些权限，可以在后面执行的时候注意输出错误日志以获取所需权限。
{% endnote %}

在上面的环境中使用puppeteer，需要在初始化的时候进行一些特别的配置：
```javascript
const puppeteer = require('puppeteer')
(async () => {
  const browser = await puppeteer.launch({
    args: [
      '--disable-dev-shm-usage',
      '--no-sandbox'
    ],
    executablePath: '/usr/bin/chromium-browser'
  })
  const page = await browser.newPage();
  await page.goto('https://example.com');
  await page.screenshot({path: 'example.png'});

  await browser.close();
})();
```

最后，在上面Docker环境下执行代码，或者部署项目即可。

这里给出一个egg项目部署的Dockerfile作为参考：

```Dockerfile Dockerfile
FROM mapleque/node-chrome:10.16

ENV APP_PATH /app

WORKDIR ${APP_PATH}

# COPY --chown=pptruser:pptruser . ${APP_PATH}
COPY . ${APP_PATH}

RUN cnpm install --production

ENTRYPOINT NODE_ENV=production EGG_SERVER_ENV=${EGG_SERVER_ENV} npx egg-scripts start --port=${APP_PORT} --workers=1
```

{% note info %}
同样需要注意的是，这里启动项目的用户要与环境中授权puppeteer的用户保持一致。
{% endnote %}
