---
title: 通过日志实现监控和报警
tags: [ ELK ]
categories: [ 工具, ELK ]
date: 2019-08-29 14:20:49
description: 介绍kibana-dashboard和watcher的使用方法
---

上篇文章[使用ELK管理日志](/posts/practice/elastic/elk-logger)中，介绍了如何部署ELK并开始收集日志。

本文将继续介绍如何使用收集上来的日志。

这里我们主要讨论通过Kibana连接Elasticsearch后，可以使用的一些功能。

更多功能，请参考[Kibana官方文档](https://www.elastic.co/guide/en/kibana/current/index.html)。

Visualize
====

这里介绍几种视图的应用场景，具体使用方法请自行探索。

- 折线图 -- 展示二维数据的变化情况，如每日平均接口请求次数
- 柱状图 -- 展示二维数据的绝对值和相对值，如不同接口的请求量
- 表格 -- 直接展示二维数据
- Metric -- 直接展示一维数据
- Timelion -- 展示数据随时间变化的情况以及多时间维度对比，如：请求量同比环比变化情况

Dashboard
====

Dashboard可以将多个Visualize放到一个页面内，并保存。Dashboard支持通过拖动的形式配置页面布局，以及每个Visualize的大小，当需要文字说明的时候，可以插入Markdown类型的Visualize。

注意，这里一个Dashboard的时间区间是统一的，也可以在保存Dashboard的时候指定Store time with dashboard，这样每次打开这个Dashboard，都会使用当前保存时候指定的时间区间（也支持相对值，如：Last 24 hours）。

Watcher
====

在`Management->Elasticsearch->Watcher`可以创建管理Watcher。Watcher顾名思义是一个观察者服务，可以通过配置触发机制、输入数据、触发条件、执行动作等四个参数，来实现监控报告等功能。

Monitoring
----

通过监控是否有错误日志，实现错误报警。

下面的配置每分钟查一次http_log中前30分钟的ERROR类型日志，如果有就发邮件报警。一旦发过邮件就静默30分钟。
```json
{
  "trigger": {
    "schedule": {
      "interval": "1m"
    }
  },
  "input": {
    "search": {
      "request": {
        "search_type": "query_then_fetch",
        "indices": [
          "http_log"
        ],
        "types": [],
        "body": {
          "query": {
            "bool": {
              "filter": [
                {
                  "range": {
                    "@timestamp": {
                      "from": "{{ctx.trigger.scheduled_time}}||-30m",
                      "to": "{{ctx.trigger.triggered_time}}"
                    }
                  }
                },
                {
                  "match": {
                    "log_flag.keyword": {
                      "query": "ERROR"
                    }
                  }
                }
              ]
            }
          }
        }
      }
    }
  },
  "condition": {
    "script": {
      "source": "if (ctx.payload.hits.total > 0) {return true}return false;",
      "lang": "painless"
    }
  },
  "actions": {
    "email": {
      "transform": {
        "script": {
          "source": "String body; body = '<div>'+ctx.payload.hits.total+' ERROR in http.log @'+ctx.trigger.triggered_time+'</div>'; for (item in ctx.payload.hits.hits) { body += '<div><h3>'+item._source.group+'/'+item._source.project+'</h3><p>'+item._source.source+'</p><pre>'+item._source.message+'</pre></div>' } return [ 'body': body ]",
          "lang": "painless"
        }
      },
      "email": {
        "profile": "standard",
        "to": [
          "monitof@mapleque.com"
        ],
        "subject": "[alert]ERROR in http.log",
        "body": {
          "html": "{{ctx.payload.body}}"
        }
      }
    }
  },
  "throttle_period_in_millis": 1800000
}
```

Reporting
----

定期发送报告。

Dashboard提供了api支持实时生成pdf报告，配合watcher可以将该报告以邮件的事实发送。

下面的配置，每天早晨8点，发送报告。
```json
{
  "trigger": {
    "schedule": {
      "daily": {
        "at": [
          "8:00"
        ]
      }
    }
  },
  "input": {
    "none": {}
  },
  "condition": {
    "always": {}
  },
  "actions": {
    "send_email": {
      "email": {
        "profile": "standard",
        "attachments": {
          "a_example_reporting.pdf": {
            "reporting": {
              "url": "<reporting_url>",
              "retries": 20,
              "interval": "5s"
            }
          }
        },
        "to": [
          "monitor@mapleque.com"
        ],
        "subject": "[report]a example reporting",
        "body": {
          "html": "Some content in email body"
        }
      }
    }
  }
}
```

其中，reporting_url由Dashboard生成（点击指定的Dashboard右上角Reporting按钮，可以获得生成pdf的链接）。
