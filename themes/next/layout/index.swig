{% extends '_layout.swig' %}
{% import '_macro/sidebar.swig' as sidebar_template %}

{% block title %}{{ title }}{%- if theme.index_with_subtitle and subtitle %} - {{ subtitle }}{%- endif %}{% endblock %}

{#
{% block content %}
    <div class="post-block">
        <header class="post-header">
            <h2 class="post-title">特别说明</h2>
        </header>
        <div class="post-body">
            <p>由于近期重新整理博客，挖坑较多，首页文章预览暂时关闭，待坑填的差不多时候再行开放，请见谅。</p>
            <p>如有需求，请通过左侧菜单查看相关资源，也可使用站内搜索功能。<p>
        </div>
    </div>
{% endblock %}
#}
{% block content %}
  <div id="posts" class="posts-expand">
    {%- for post in page.posts %}
      {{ partial('_macro/post.swig', {is_index: true}) }}
    {%- endfor %}
  </div>

  {% include '_partials/pagination.swig' %}
{% endblock %}

{% block sidebar %}
  {{ sidebar_template.render(false) }}
{% endblock %}
