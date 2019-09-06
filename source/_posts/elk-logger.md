---
title: 使用ELK管理日志
tags: [ ELK ]
categories: [ 工具, ELK ]
date: 2019-08-29 14:07:18
description: 介绍如何使用ELK收集、存储、查询日志
---

{% mermaid graph LR %}
Filebeat1 --> Logstash
Filebeat2 --> Logstash
Filebeatn --> Logstash
Logstash --> Elasticsearch
Elasticsearch --> Kibana
{% endmermaid %}

Logstash
====

[官方文档](https://www.elastic.co/guide/en/logstash/current/index.html)

Logstash是一个数据收集服务，Java编写，内存需求量较大，处理复杂日志切分时CPU占用较高。整体来说性能一般，如果在数据收集方面有特殊的需求，建议自研。

这里介绍几种输入输出配置：

jdbc-input
----
```conf /etc/logstash/conf.d/jdbc-input.conf
input {
  jdbc {
    id => "da_label_user_transaction"
    jdbc_driver_library => "/usr/share/java/mysql-connector-java-5.1.45-bin.jar"
    jdbc_driver_class => "com.mysql.jdbc.Driver"
    jdbc_connection_string => "jdbc:mysql://host:port/dbname"
    jdbc_user => "dbuser"
    jdbc_password => "dbpassword"
    jdbc_fetch_size => 20000
    jdbc_default_timezone => "Asia/Shanghai"
    schedule => "* * * * *"
    use_column_value => true
    tracking_column => "id"
    statement => "SELECT * from table where id > :sql_last_value LIMIT 10000"
  }
}
```

filebeat-input
----

```conf /etc/logstash/conf.d/filebeat-input.conf
input {
  beats {
    port => "5044"
  }
}
```

file-output
----

```conf /etc/logstash/conf.d/log-file-output.conf
output {
  file {
    path => "/tmp/logstash-out.log"
  }
}
```

hdfs-output
----

```conf /etc/logstash/conf.d/hdfs-output.conf
output {
  webhdfs {
      host => "hdfs.mapleque.com"
      port => 9870
      path => "/user/logstash/dt=%{+YYYY-MM-dd}/%{+HH}.log
      user => "hadoop"
  }
}
```

elasticsearch-output
----

```conf /etc/logstash/conf.d/elasticsearch-output.conf
output {
    elasticsearch {
        hosts => ["es.mapleque.com:9200"]
        index => "your index name"
    }
}
```

Filebeat
====

[官方文档](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)

Filebeat主要用于从应用机器同步日志到日志服务器。

常用配置如下：

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

Elasticsearch
====

[官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)

Kibana
====

[官方文档](https://www.elastic.co/guide/en/kibana/current/index.html)

