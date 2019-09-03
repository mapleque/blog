---
title: 使用gitlab持续集成部署
tags: [ Gitlab ]
categories: [ 工具, Gitlab ]
date: 2019-08-29 14:11:19
description: 介绍如何使用gitlab-ci进行持续集成部署
---

创建.gitlab-ci.yml配置文件，可以提交ci任务到gitlab-runner(docker模式)。

配置文件示例：
```yaml .gitlab-ci.yml
tages:
  - test # 单元测试，集成测试，各种代码检查等。如有必要，可考虑拆分为多个阶段
  - build # 编译，打包等。如有必要，可考虑拆分为多个阶段
  - docker # 生成docker镜像，并上传到registry
  - deploy # 发布

test-example:
  stage: test
  script:
    - echo 'do some test here'

build-example:
  stage: build
  script:
    - echo 'do some build here'

docker-example:
  image: "docker:dind" # 打包docker镜像固定使用此镜像
  stage: docker
  when: on_success # 如果依赖前序任务执行，需要设置该选项，避免生成无用docker镜像
  dependencies:
    - build # 如果打包镜像时需要前序任务的atrifacts，需要设置这个依赖使artifacts能够传递下来
  only: # 设置执行该任务的分支
    # ************************
    # 注意 ** 没必要每次ci都上传镜像，设置用于发布到测试环境的分支和正式发布的branch或tag。
    # ************************
    # - /^feature.*$/ # 例如：feature/xxx等，通常是git branch
    - /^.*-release$/ # 例如：1.0.0-release等，通常是git tag
  script:
    # 定义镜像名
    # 镜像名: ${CI_PROJECT_PATH} 请务必使用该环境变量作为镜像名，否则会影响后面部署
    # 镜像tag: 注意区分测试镜像和正式镜像
    #     测试镜像tag: stage-${CI_PIPELINE_ID}，可以保证每次执行任务都生成新的镜像并上传
    #     正式镜像tag: ${CI_COMMIT_REF_NAME}，直接使用项目tag名，例如1.0.0-release
    # - export IMAGE_NAME=mapleque/${CI_PROJECT_PATH}:stage-${CI_PIPELINE_ID}
    - export IMAGE_NAME=mapleque/${CI_PROJECT_PATH}:${CI_COMMIT_REF_NAME}
    #
    # 打包生成镜像并上传
    - docker build -t ${IMAGE_NAME} <Dockerfile path> && docker push ${IMAGE_NAME}

deploy-example:
  image: "mapleque/deploy" # 发布专用镜像，实现了deploy命令，参考项目：https://github.com/mapleque/deploy
  stage: deploy
  when: on_success
  dependencies: [] # 这里注意要把dependencies设置为空，这样回滚和再次上线才能够被正常执行
  only:
    # 同docker部分
    # - /^feature.*$/ # 例如：feature/xxx等，通常是git branch
    - /^.*-release$/ # 例如：1.0.0-release等，通常是git tag
  environment:
    # 设置这个将会在gitlab上生成一个上线记录，方便以后进行回滚和重新发布操作
    # name: stage # 发布到测试环境
    name: release # 发布到正式环境
  script:
    # 通过设置Settings->CI/CD->Secret Variables，可以将保密的环境变量注入到ci中
    #
    # 集群配置
    #
    # 指定发布类型
    # 支持：kubernates, linux
    - export DEPLOY_CONFIG_TYPE=kubernates
    #
    # 指定发布目标
    # - export DEPLOY_CONFIG_TARGET=stage.example.mapleque.com # 测试环境
    - export DEPLOY_CONFIG_TARGET=example.mapleque.com # 正式环境
    #
    # 用于发布的TOKEN
    - export DEPLOY_CONFIG_TOKEN=${DEPLOY_TOKEN}
    #
    # 发布使用的镜像名，与之前上传的保持一致
    # - export DEPLOY_CONFIG_IMAGE=mapleque/${CI_PROJECT_PATH}:stage-${CI_PIPELINE_ID} # 测试环境
    - export DEPLOY_CONFIG_IMAGE=mapleque/${CI_PROJECT_PATH}:${CI_COMMIT_REF_NAME} # 正式环境
    #
    # 项目环境变量
    #   这里定义的环境变量需要使用DEPLOY_ENV_前缀
    #   注意：该前缀会在载入时被去掉，所以在服务中直接使用不要带该前缀
    #   例如： - export DEPLOY_ENV_XXX=xxx 在服务中直接使用${XXX}即可
    # - export DEPLOY_ENV_VALUE1=value1
    # - export DEPLOY_ENV_VALUE2=value2
    #
    # 项目端口
    #   项目端口需要使用DEPLOY_PORT_前缀
    #   注意：项目端口也会被导入为环境变量，且前缀会在载入时被去掉，所以不要与DEPLOY_ENV_所设置的环境变量名冲突
    #   例如： - export DEPLOY_PORT_XXX= 在服务中直接使用${XXX}即可
    # - export DEPLOY_PORT_PORT1= #这里不要填任何值
    # - export DEPLOY_PORT_PORT2= #这里不要填任何值
    #   注意：这里不要自行指定端口号，项目部署时会自动置顶端口号并设置到对应的环境变量中
    #   例如上面两个端口的设置，在项目中直接使用${PORT1}和${PORT2}就能获得系统分配的端口号
    #
    # 上线命令，不要修改
    - deploy
```
