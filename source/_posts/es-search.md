---
title: 使用Elasticsearch实现社区内容搜索服务
tags: [ Elastic, Search ]
categories: [ 实践, Elasticsearch ]
date: 2019-08-29 13:59:33
description: 讲述基于Elasticsearch实现社区内容搜索的思路和实现全过程
---

{% blockquote Elastic Elasticsearch https://www.elastic.co/cn/products/elasticsearch %}
Elasticsearch 是一个分布式、RESTful 风格的搜索和数据分析引擎，能够解决不断涌现出的各种用例。 作为 Elastic Stack 的核心，它集中存储您的数据，帮助您发现意料之中以及意料之外的情况。
{% endblockquote %}

需求分析
====

考虑社区内容（帖子）搜索需要实现的功能有：
- 支持中文
- 根据用户输入，给出搜索建议
- 根据搜索词，给出相关内容搜索结果
- 搜索结果应按照相关性由大到小排序
- 在搜索结果中，应当优先展示近期发布的内容
- 在搜索结果中，应当优先展示质量较高的内容
- 可以屏蔽一些搜索词，让其不能出结果
- 可以屏蔽一些内容，让其永远不能出现在结果中
- 能够简单识别网络爬虫行为，并进行封禁

基本产品形态为：
- 有个搜索框，用户可以输入任何字符
- 用户在搜索框输入字符的时候根据已输入的内容，给出相关建议
- 用户可以确认搜索所输入的内容或建议的内容
- 有个结果展示区，给用户有序展示搜索结果，并支持翻页
- 有个后台能够添加屏蔽搜索词
- 有个后台能够添加屏蔽的帖子
- 有个后台能够添加屏蔽的ip
- 有个后台能够查看各时间接口请求次数（能够按照ip，搜索词分组统计）

系统设计
====

根据上面的需求，前台服务需要实现的接口有：
- 获取搜索建议 -- 输入搜索词和要获取数据条数n，返回有序的前n个搜索建议词
- 获取搜索结果 -- 输入搜索词、页码n和每页容量m，返回有序的第n页的m条搜索结果

后台服务需要实现的接口有：
- 屏蔽词的增删改查
- 屏蔽帖子的增删改查
- 屏蔽ip的增删改查
- 接口请求次数的统计（按时间区间分组，按ip分组，按搜索词分组）

实现方案
====

基于上面的系统设计，显然这里只需要提供前台接口实现方案，就可以完成全部产品需求。

整体来看，前台的两个接口都是一个搜索过程，只是搜索的目标数据有所区分：
- 搜索建议需要在**搜索建议数据**中搜索
- 搜索结果需要在**社区内容数据**中搜索

其中，搜索结果所需要的数据很明确，就是社区内容（帖子标题和正文），而搜索建议所需要的数据，则需要根据产品需求另行设计。

这里，可以考虑到的能够用于搜索建议的数据有：
- 社区内容中的一些关键词
- 用户搜索次数较多的搜索词
- 我们希望用户搜索的搜索词

当用于搜索的数据明确后，只需要在数据上建立索引，即可通过Elasticsearch提供的Api进行搜索了。

因此，这里我们需要先解决如何建立中文索引的问题，再考虑如何在两份数据上分别建立索引以支持搜索。

中文分析器
----

处理中文搜索，主要是解决中文分词的问题。Elasticsearch可以安装扩展分析器来支持多语言。

这里笔者基于一个支持中文的分析器[elasticsearch-analysis-ik](https://github.com/medcl/elasticsearch-analysis-ik)进行了配置扩展，得到了一个支持中文全文索引的是分析器fulltext_analyzer。

更进一步，由于当前主流中文输入法都是通过拼音完成输入，这里如果能考虑针对中文生成对应的拼音索引就更加完美了。

笔者在找到上面的分析器的时候，同时发现了一直个支持拼音索引的分析器[elasticsearch-analysis-pinyin](https://github.com/medcl/elasticsearch-analysis-pinyin)，于是也一并进行了扩展配置得到pinyin_analyzer，以便后续使用。

上述两个分词器配置方式如下：
```json
{
  "settings": {
    "analysis":{
      "analyzer":{
        "pinyin_analyzer":{
          "tokenizer":"pinyin_tokenizer",
          "char_filter": ["html_strip","white_strip"],
          "filter":["asciifolding"]
        },
        "fulltext_analyzer":{
          "tokenizer":"ik_max_word" ,
          "char_filter": ["html_strip","white_strip"],
          "filter":["asciifolding"]
        }
      },
      "tokenizer":{
        "pinyin_tokenizer":{
          "type":"pinyin",
          "keep_separate_first_letter" : false,
          "keep_full_pinyin" : true,
          "keep_original" : true,
          "limit_first_letter_length" : 16,
          "lowercase" : true,
          "remove_duplicated_term" : true
        }
      },
      "char_filter": {
        "white_strip": {
          "type": "pattern_replace",
          "pattern": "[\\r|\\n|\\t|\\s|[^\\u0020-\\uFFFF]|\\u007F]+",
          "replacement": ""
        }
      }
    }
  }
}
```

{% note info %}
### fulltext_analyzer
该分析器对于待处理文本，首先会进行字符过滤，过滤掉所有html标签、不可见字符、emoji等。

然后对所得文本进行分词，分词使用了最细粒度拆分原则。
例如：“中华人民共和国国歌”将被拆分为“中华人民共和国,中华人民,中华,华人,人民共和国,人民,人,民,共和国,共和,和,国国,国歌”。

最后将分词结果用于后续处理。
{% endnote %}

{% note info %}
### pinyin_analyzer
该分析器对于待处理文本，同样会进行字符过滤，处理方式同上。

然后将所得文本转化为拼音，拼音只进行单字分词，同时会增加首字母组合。
例如：“中华人民中共和国国歌”将被拆分为“zhong,hua,ren,min,gong,he,guo,guo,ge,zhrmghggg”。

最后将分词结果用于后续处理。
{% endnote %}

搜索建议数据索引及搜索
----

### 数据来源及同步

根据上面的分析，搜索建议数据可以有多个来源，这里需要做到能够从不同的来源将数据收集到Elasticsearch并保持同步。

下面分别考虑上面提到的三个来源。

#### 社区内容中的一些关键词

由于社区业务并没有考虑这部分数据的生成，因此我们需要从零开始生成这些数据。
这里笔者拍脑袋设计了社区内容关键词生成方案：
- 对内容全文进行ngram中文分词（实际应用中使用了3gram）
- 筛选词频超过阈值的词进入搜索建议词库（实际应用中阈值取3）
- 入库关键词记录词频数作为后续搜索权重
- 如果当前关键词已入库，直接把词频数相加更新

3gram分词器配置如下：
```json
{
  "settings":{
    "analysis": {
      "analyzer": {
        "phrase_3_gram": {
          "tokenizer":"ik_smart",
          "char_filter": ["html_strip","white_strip"],
          "filter":["3_gram"]
        }
      },
      "char_filter": {
        "white_strip": {
          "type": "pattern_replace",
          "pattern": "[\\r|\\n|\\t|\\s|[^\\u0020-\\uFFFF]|\\u007F]+",
          "replacement": ""
        }
      },
      "filter": {
        "3_gram": {
          "type": "shingle",
          "min_shingle_size": 1,
          "max_shingle_size": 3,
          "token_separator":" "
        }
      }
    }
  }
}
```

#### 用户搜索次数较多的搜索词

当服务上线后，可以从接口请求日志中获取用户搜索词统计。统计周期可以根据实际情况调整。

给定阈值n，在统计周期内搜索次数超过n的搜索词进入搜索建议词库，搜索次数可以作为词频累加。

#### 人工运营的搜索词

人工运营搜索建议词，可以通过后台直接添加到搜索建议词库。

为了简化搜索逻辑，可以通过调整词频大小来控制其出现的位置。

### 索引和搜索

通过上面的数据同步流程，我们可以获得一个实时更新的搜索建议词库。
下面只需要拿用户输入的搜索词在Elasticsearch进行搜索即可获得结果。
为了得到想要的效果，我们对搜索行为加以约束：
- 不分词全文前缀匹配搜索
- 不分词拼音前缀匹配搜索
- 分词全文前缀匹配搜索
- 分词拼音前缀匹配搜索
- 分词全文模糊搜索
- 考虑词频权重对搜索结果排序的影响

mapping配置如下：
```json
{
  "mappings": {
    "_doc": {
      "properties": {
        "keyword": {
          "type": "keyword",
          "fields": {
            "raw": {
              "type": "text",
              "analyzer": "whitespace",
              "search_analyzer": "whitespace"
            },
            "fulltext": {
              "type": "text",
              "analyzer": "fulltext_analyzer",
              "search_analyzer": "fulltext_analyzer"
            },
            "pinyin": {
              "type": "text",
              "store": false,
              "term_vector": "with_offsets",
              "analyzer": "pinyin_analyzer"
            }
          }
        }
      }
    }
  }

}
```

搜索模板配置如下：
```json
{
  "script": {
    "lang": "mustache",
    "source": {
      "size": "{{size}}",
      "query": {
        "function_score": {
          "functions": [
            {
              "field_value_factor": {
                "field":"word_count",
                "factor":1,
                "modifier":"linear",
                "missing":0
              }
            }
          ],
          "score_mode":"multiply",
          "query": {
            "bool": {
              "should": [
                {"prefix": {"keyword.raw": { "value": "{{query}}", "boost": 100}}},
                {"prefix": {"keyword.pinyin": { "value": "{{query}}", "boost": 50}}},
                {"match_phrase_prefix": {"keyword.fulltext": {"query": "{{query}}", "boost": 10}}},
                {"match_phrase_prefix": {"keyword.pinyin": {"query": "{{query}}", "boost": 5}}},
                {
                  "match": {
                    "keyword.fulltext": {
                      "query": "{{query}}",
                      "boost": 5,
                      "fuzziness": "AUTO",
                      "max_expansions": 10,
                      "prefix_length": 2,
                      "fuzzy_transpositions": true
                    }
                  }
                }
              ]
            }
          }
        }
      },
      "_source":[
        "keyword"
      ],
      "highlight": {
        "pre_tags" : ["<em>"],
        "post_tags" : ["</em>"],
        "fields" : {
          "keyword.fulltext" : {}
        }
      },
      "collapse": {
        "field": "keyword"
      }
    }
  }
}
```

搜索结果数据索引及搜索
----

### 数据来源及同步

社区内容数据，需要从业务数据同步，同步频率由业务需求决定。

这里需要详细说明那些影响搜索结果的字段：

{% note info %}
#### 帖子标题
帖子标题直接影响搜索内容相似度，且权重较高，标题与搜索词越相似的帖子在搜索结果中排序应该越靠前。
{% endnote %}

{% note info %}
#### 帖子正文
帖子正文对搜索内容相似度的影响仅次于帖子标题。
{% endnote %}

{% note info %}
#### 帖子评分
帖子评分是一个综合描述帖子质量的属性，评分越高代表帖子质量越高，根据产品需求它的排序应该靠前。
{% endnote %}

{% note info %}
#### 帖子创建时间
帖子创建时间是一个描述时效性的属性，根据产品需求，创建时间越近排序应该越靠前。
{% endnote %}

{% note info %}
#### 帖子状态
用于屏蔽帖子，使其不出现在搜索结果中。
{% endnote %}

### 索引和搜索

根据上面的思路，创建索引如下：
```json
{
  "mappings": {
    "_doc": {
      "properties":{
        "title":{
          "type":"keyword",
          "fields": {
            "raw":{
              "type":"text",
              "analyzer": "whitespace",
              "search_analyzer": "whitespace"
            },
            "fulltext": {
              "type":"text",
              "analyzer":"fulltext_analyzer",
              "search_analyzer":"fulltext_analyzer"
            },
            "pinyin": {
              "type": "text",
              "store": false,
              "term_vector": "with_offsets",
              "analyzer": "pinyin_analyzer"
            }
          }
        },
        "content": {
          "type":"text",
          "fields": {
            "fulltext": {
              "type":"text",
              "analyzer":"fulltext_analyzer",
              "search_analyzer":"fulltext_analyzer"
            }
          }
        }
      }
    }
  }
}

```

搜索模板如下：
```json
{
  "script": {
    "lang": "mustache",
    "source": {
      "size": "{{size}}",
      "from": "{{from}}",
      "query": {
        "function_score": {
          "functions": [
            {
              "script_score": {
                "script": {
                  "source": "2+(Math.pow(0.5,Math.pow((90-(System.currentTimeMillis() - doc['creation_time'][0].getMillis())/(1000*86400))/(double)1460,2))-1)/(1+Math.pow(Math.E,(90-(System.currentTimeMillis() - doc['creation_time'][0].getMillis())/(1000*86400))*10))"
                }
              }
            },
            {
              "field_value_factor": {
                "field":"score",
                "factor":0.0002,
                "modifier":"ln2p",
                "missing":0
              }
            }
          ],
          "score_mode":"multiply",
          "query": {
            "bool": {
              "must": [
                {
                  "term": {"status": 1}
                }
              ],
              "should": [
                {"prefix": {"title.raw": { "value": "{{query}}", "boost": 100}}},
                {"prefix": {"title.pinyin": { "value": "{{query}}", "boost": 10}}},
                {"match_phrase_prefix": {"title.fulltext": {"query": "{{query}}", "boost": 50}}},
                {"match_phrase_prefix": {"title.pinyin": {"query": "{{query}}", "boost": 5}}},
                {"match_phrase_prefix": {"content.pinyin": {"query": "{{query}}", "boost": 10}}},
                {
                  "match": {
                    "title.fulltext": {
                      "query": "{{query}}",
                      "boost": 5,
                      "fuzziness": "AUTO",
                      "max_expansions": 10,
                      "prefix_length": 2,
                      "fuzzy_transpositions": true
                    }
                  }
                },
                {
                  "match": {
                    "content.fulltext": {
                      "query": "{{query}}",
                      "boost": 5,
                      "fuzziness": "AUTO",
                      "max_expansions": 10,
                      "prefix_length": 2,
                      "fuzzy_transpositions": true
                    }
                  }
                },
                {
                  "query_string": {
                    "fields": ["title.fulltext","title.pinyin","content.fulltext"],
                    "query": "{{query}}",
                    "boost": 1,
                    "fuzziness": "AUTO",
                    "fuzzy_prefix_length": 2,
                    "fuzzy_max_expansions": 10,
                    "fuzzy_transpositions": true,
                    "allow_leading_wildcard": false
                  }
                }
              ]
            }
          }
        }
      },
      "_source":[
        "post_id",
        "creation_time",
        "score",
        "title",
        "content"
      ],
      "highlight": {
        "pre_tags" : ["<em>"],
        "post_tags" : ["</em>"],
        "fields" : {
          "title.fulltext" : {},
          "content.fulltext": {}
        }
      },
      "collapse": {
        "field": "post_id"
      }
    }
  }
}
```

其中，时间衰减函数实现思路如下：

{% note info %}

#### 时间衰减函数

这里我们以高斯函数：
`f(x)=a*e^(-(x-b)^2/(2*c^2)))`

为基础，辅以激活函数：
`f(x)=1/(1+e^(10*(b-x)))`

生成时间权重衰减函数：
`f(x) = a*(1+(e^(ln(d/a)*(x-b)^2/c^2)-1)/(1+e^(10*(b-x))))`

上面的函数可以简化为：
`f(x) = a(1+((d/a)^((b-x)/c)^2)-1)/(e^10(b-x)+1)`

其中：初始权重为a，从b天开始衰减，在第c天权重衰减到d。

假设这里取：
- a=1 表示权重范围从1衰减到0
- b=90 表示90天之内的帖子不降权
- c=1460，d=0.5 表示4年之后，帖子权重衰减50%

那么得到函数：
`f(x) = 1+(0.5^(((x-90)/1460)^2)-1)/(1+e^(10*(90-x)))`

通过该函数图像可以看出：
- 半年左右权重开始衰减
- 4年衰减到50%
- 7年多之后衰减到10%以下

{% endnote %}

人工干预
----

人工干预可以实现在Elastic服务之外，例如在请求Elasticsearch接口之前处理屏蔽词和ip黑名单。

通常这种服务会被称为Searchhub。

Searchhub除了要负责处理人工干预逻辑外，还需要处理请求参数校验以及结果数据整合等。

必要时，缓存也可以在Searchhub层添加。

Searchhub是一个简单的web服务，这里不再展开。

服务部署
====

Elasticsearch
----

- 开发环境，可以根据各自情况，参考[官方文档](https://www.elastic.co/downloads/elasticsearch)自行下载部署。

- 生产环境，建议使用[官方推荐的云服务](https://www.elastic.co/cloud/)。

- 相关工具，建议在开发环境安装[Kibana](https://www.elastic.co/downloads/kibana)以简化操作。

Searchhub
----

按照通常的方式部署一个web服务即可。

统计监控
====

搜索质量评价指标
----

量化指标可以用来评价搜索服务的价值，也有助于找到提高搜索质量的方向。

鉴于我们所面对的是垂搜领域里有限数据量的内容搜索，业界流行的搜索质量量化指标并不适合，因此需要自行设计一个搜索质量量化指标体系。

这里需要先明确我们的目标：
- 通过站内搜索，提高信息检索效率，进而提高社区活跃度。
- 通过站内搜索，增加优质内容曝光，进而提高传播率。

### 指标

结合上面提出的目标，我们提出以下两个指标进行统计：

- 搜索结果点击率：点击位置n的搜索结果/搜索次数
    该指标可以提现搜索结果的准确率，点击率越高说明准确率越高。排位越靠前，点击率应该越高。
- 搜索点击比：搜索次数/结果点击次数
    该指标可以提现搜索结果相关性，用户在一次搜索结果中点击次数越多，说明结果相关性越高。

### 采样

- 热搜词TopN：对热搜词TopN分别进行统计，可以获得每个热搜词的搜索效果。
- 长尾词随机采样：随机选取长尾词进行统计，可以获得一般内容的搜索效果。

### 实践

1. 统计每日热搜词，长尾词
    分析搜索api请求日志，统计热搜词及搜索次数，随机选取一定数量的长尾词
1. 统计热搜词对应的搜索结果点击
    分析搜索结果点击事件（打点），统计热搜词对应的搜索结果点击次数
1. 计算热词点击率和点击比
1. 长尾词与热搜词统计方法相同

服务质量监控
----

监控是了解实时服务状态和短期服务质量的最直接方式，有服务就要有监控。

### 指标

这里设计几个指标用于监控搜索服务：

- 接口请求次数、响应时间
    按周期统计接口请求次数和响应时间，有助于了解服务压力情况
- 接口正确率
    接口正确率直接反映服务运行状态，这里需要区分：无搜索结果、搜索结果少、搜索被屏蔽等情况
