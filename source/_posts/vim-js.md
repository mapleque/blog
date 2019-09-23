---
title: 【vim】使用vim作为开发js的IDE
tags:
  - Vim
categories:
  - 工具
  - Vim
date: 2019-09-19 17:14:04
description:
---

{% note info %}
本文中将直接使用基本设置已经使用的配置，如需了解，请阅读[【vim】基本设置](/posts/tool/vim/vim-start/)。
{% endnote %}

基本设置
====

创建`~/.vim/ftplugin/javascript.vim`文件来配置用于js文件的设置。

```vim
" 缩进2字符
set tabstop=2
set softtabstop=2
set shiftwidth=2
set expandtab

" 设置代码每行最大宽度标尺
set tw=118

```

支持jsx语法高亮
====

让vim支持jsx语法高亮，使用[vim-jsx](https://github.com/mxw/vim-jsx)插件。

通过Vundle安装，在.vimrc中添加：

```vim
Plugin 'pangloss/vim-javascript'
Plugin 'mxw/vim-jsx'
```

在vim中执行命令：
```
:PluginInstall
```

ESLint检查
====

使用eslint官方推荐的[syntastic](https://github.com/vim-syntastic/syntastic)插件来执行`eslint`。

通过Vundle安装syntastic插件，在vim下执行下面命令：

```
:PluginInstall syntastic
```

成功后，在`~/.vimrc`中添加：
```vim
Plugin 'syntastic'

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_javascript_checkers = [ 'eslint' ]
```

完成后，vim中就可以通过执行系统的`eslint`命令来检查当前文件的错误了。

{% note info %}
注意：上面的配置，将会使syntastic在保存文件和打开文件的时候自动执行。
{% endnote %}

ESLint自动修复
====

使用自研插件[vim-eslint-fix](https://github.com/mapleque/vim-eslint-vim)来执行`eslint --fix`。

通过Vundle安装vim-eslint-fix插件，在vim下执行下面命令：

```
:PluginInstall mapleque/vim-eslint-fix
```

成功后，在`~/.vimrc`中添加：
```vim
Plugin 'mapleque/vim-eslint-fix'
```

在`~/.vim/ftplugin/javascript.vim`中添加：
```vim
"如果没有设置过mapleader，请先自行设置
"let mapleader=","
noremap <Leader>f :EslintFix<CR>

"如果需要在保存文件时候自动修复，添加下面这行
"autocmd BufwritePost *.js EslintFix
```

完成后，当需要eslint自动修复错误的时候，在命令模式下输入`,f`即可。

React新组件模板
====

创建模板文件`~/.vim/templates/react.js`:
```js
import React, { Component } from 'react'
class Index extends Component {
  constructor (props) {
    super(props)
  }

  state = {}

  render() {
    return (
      <div>tbd</div>
    )
  }
}

export default Index
```

编辑`~/.vimrc`文件，增加：
```
autocmd BufNewFile *.js 0r ~/.vim/templates/react.js
```
