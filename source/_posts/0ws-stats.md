---
title: 【互联网产品的诞生和演化】统计数据收集展示和系统监控
tags:
  - Web
categories:
  - 实践
  - 互联网产品的诞生和演化
date: 2019-12-11 14:57:09
description: 统计和监控可以让你对产品了如指掌，进而看清未来发展方向。
---

互联网产品在线上之前，就要考虑统计数据和监控。

初期，为了节省成本，数据统计可以直接使用第三方平台提供的服务，如：百度统计、谷歌统计等。

这些第三方平台提供了丰富多彩的统计服务，唯一缺陷就是数据在第三方，我们自己无法随心所欲使用数据，只能受限于第三方可用功能。

系统监控可以考虑直接监控服务器错误日志。

当第三方数据服务已经无法满足我们的要求时，就需要考虑自建数据平台了。

一个典型的数据平台架构如下：

{% mermaid graph LR %}
source[数据源]
collection[数据收集]
storage[数据存储]
analysis[数据分析]
showing[数据展示]

source --> collection
collection --> storage
storage --> analysis
analysis --> storage
storage --> showing
{% endmermaid %}

这里边，数据存储是核心。

数据存储
----

影响数据存储选型的因素有很多，需要重点考虑的核心因素有三：
- 数据规模
- 数据结构
- 数据使用方式

对于不同的选型，上述三个因素的取舍各不相同：

- MySQL

  MySQL是互联网时代最常用的数据库之一，适用于100w数量级以下的结构化数据存储，使用SQL操作数据，通常用于存储业务数据和展示数据。
  在数据平台中，如果总数据量不大，并且增长不快，可以直接使用MySQL作为数据存储，这种存储的使用成本应该是最低的。

- HDFS

  HDFS是Hadoop架构下的分布式文件存储系统，适用于100w数据级以上的数据存储，使用MapReduce查询数据或通过上层中间件（如：HBase，HIVE，Spark等）操作数据，通常应用于离线数据计算和查询。
  在数据平台中，使用HDFS至少需要3个节点以上的集群进行部署，同时还要部署和维护所需中间件以及数据访问权限，运维复杂度极高，非专业团队不建议使用。

- Elasticsearch

  Elasticsearch是ElasticStack中的基于Luence实现的搜索引擎，得益于其高效的全文搜索功能和数据统计功能，也可以将其用作数据平台的一种存储。
  结合使用Kibana，可以将其作为系统监控的核心系统。
  Kibana通过封装Elasticsearch的api，实现了数据查询、聚集以及可视化展示等功能，并且支持按条件触发事件和发送报告。
  由于其基于Luence实现，因此不适合作为复杂的数据分析工具使用，强行使用会影响系统稳定性。

- TiDB

  TiDB是PingCAP开发的一款支持MySQL协议，并且可以水平扩展的分布式关系数据库。
  由于其对MySQL协议的支持，大大降低了使用成本和维护成本。
  其在大数据量下的表现有待考量，据笔者经验，在亿级数据量下复杂分组查询可以实现秒级返回。

- Kafka

  Kafka可以被看作实时一种数据存储，由于流计算需求的存在，使得Kafka成为一个不可替代的存储选型。

事实上，在实际应用中，根据不同需求，可以将不同存储组合使用。例如：
- 将需要展示的数据，计算后存储到MySQL中
- 将冷数据归档到HDFS中
- 在Elasticsearch中仅保留一定规模的热数据用于问题跟踪和系统监控
- TiDB仅用于数据分析，不用于业务服务和数据展示

数据源
----

从技术角度来讲，统计和监控都依赖于日志数据的收集和汇总，所需的日志通常有：
- 前端和客户端行为打点日志
- 前端和客户端错误上报日志
- 后端接口请求日志
- 后端异常错误日志
- 探针日志

以上日志，都可以作为数据源进行收集，并进一步处理。

数据收集
----

由于我们的数据源都是日志，因此可以使用filebeat部署到日志服务器进行收集。

这里建议filebeat的消费端使用Kafka以使服务器的filebeat不发生阻塞也不需要回滚。

{% note warning %}
注意：logstash非常耗费资源，如果资源并出充足，建议自行脚本实现从Kafka消费到数据存储的流程。
{% endnote %}

filebeat的安装命令：

```sh
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-6.3.1-amd64.deb
sudo dpkg -i filebeat-6.3.1-amd64.deb
sudo systemctl start filebeat
sudo systemctl enable filebeat
```

filebeat的配置示例如下：

```yaml /etc/filebeat/filebeat.yml
filebeat.prospectors:
# 根据情况自行配置需要收集哪些log
- type: log
  paths:
    - <log_path>

output.kafka:
  enable: true
  hosts: ['<kafka_ip>']

  topic: '<string>'
  compression: gzip
  max_message_bytes: 1000000

queue.mem:
  events: 512
  flush.min_events: 256
  flush.timeout: 5s

# 监控可不配置
xpack.monitoring:
  enabled: true
  elasticsearch:
    hosts: ["<es_ip>"]
    username: <string>
    password: "<string>"

```

数据分析
----

数据分析是对现有数据的再加工过程，通常涉及：变形，关联，统计等。目前最适合进行数据分析的语言应该是Python，上文中的数据存储，都可以原生支持Python。

数据展示
----

数据展示的基本形式是图表，图可以将数据特征更直观的展示出来，[G2Plot](https://github.com/antvis/G2Plot)提供了图表的完整封装，通过简单的前端项目构建和后端接口查询，即可做到优雅的数据可视化展示。

注意，不要在数据展示期间进行数据计算。

当然，想要展示实时数据，可以考虑尝试使用TiDB。
