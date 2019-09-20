---
title: 【vim】基本配置
tags:
  - Vim
categories:
  - 工具
  - Vim
date: 2019-09-19 17:08:43
description:
---

基本配置
====

在`~/.vimrc`中添加：

```vim
"基本配置

syntax on "语法高亮

let mapleader="," "快捷键配置
" 如此，可以在后面配置快捷键时候使用`<Leader>`标识符。

set nu "显示行号
set ruler "显示当前行状态
set cursorline "显示当前行标尺
set cursorcolumn "显示当前列标尺

set autoindent "自动缩进
set smartindent "智能缩进

set showmatch "显示括号配对
set incsearch "高亮搜索内容
set hlsearch "高亮搜索内容

set tabstop=4 "tab等效字符数
set softtabstop=4 "tab等效字符数
set shiftwidth=4 "tab字符数
set expandtab "tab转成空格

set list "显示制表符
set listchars=tab:>-,trail:- "制表符和空格显示样式

colorscheme desert "配色方案

"每行最大字符数标尺
set cc=+1,+2,+3  " highlight three columns after 'textwidth'
hi ColorColumn ctermbg=lightgrey guibg=lightgrey
set textwidth=80

"状态行设置
set laststatus=2 "在倒数第二行显示状态行
set statusline=%<%1*\ %f%m%r%h%w\ %= "左侧显示文件名和文件状态
set statusline+=%2*\ %y\ %* "文件类型
set statusline+=%3*\ %{&ff}\ \|\ %{\"\".(&fenc==\"\"?&enc:&fenc).((exists(\"+bomb\")\ &&\ &bomb)?\",B\":\"\").\"\ \|\"}\ %-14.(%l:%c%V%)%* "文件格式|文件编码|当前光标所处行列
set statusline+=%4*\ %-5.(%p%%%)%* "当前光标所处文件百分比
"设置状态行配色
hi User1 cterm=None ctermfg=251 ctermbg=240
hi User2 cterm=None ctermfg=183 ctermbg=239
hi User3 cterm=None ctermfg=208 ctermbg=238
hi User4 cterm=None ctermfg=246 ctermbg=237

```

代码折叠
====

在`~/.vimrc`中添加配置：
```vim
set foldenable "允许折叠
set foldmethod=indent "按缩进折叠
```

在vim中执行命令查看手册：
```
:h Folding
```

常用命令：
- za 打开或关闭光标所在折叠（一层）
- zA 打开或关闭光标所在折叠（所有）
- [z 移动到当前折叠开始处
- ]z 移动到当前折叠结尾处
- zj 移动到下一个折叠开始处
- zk 移动到上一个折叠开始处

Vundle插件管理工具
====

下载Vundle：
```sh
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

在`~/.vimrc`中添加：
```vim
set nocompatible
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
" Plugins
"这里添加自己的插件列表，例如：
" Plugin 'scrooloose/nerdtree'
call vundle#end()
filetype plugin on
```

以后安装插件，先在`~/.vimrc`中`Plugins`后面添加：
```vim
Plugin 'scrooloose/nerdtree'
```

再在vim中执行：
```
:PuginInstall
```

文件类型扩展配置
====
可以通过单独的配置文件来修改指定类型文件的vim配置，如不同的缩进、代码宽度、插件命令等。

如果安装了Vundle，那么在安装过程中已经开启了文件类型扩展配置，可以直接使用。

如果没有安装Vundle，可以在`~/.vimrc`中添加：
```vim
filetype off
filetype plugin on
```

配置完成后，创建文件夹`~/.vim/ftplugin`，然后在文件夹中添加以文件类型命名的配置文件即可自动加载，如`~/.vim/ftplugin/javascript.vim`。

NERDTree左侧菜单插件
====

[NERDTree](https://github.com/scrooloose/nerdtree)是一款实现了左侧导航菜单的插件。
这里提供使用Vundle安装的方法。

在`~/.vimrc`中，`Plugins`的位置，添加：
```vim
Plugin 'scrooloose/nerdtree'
```

然后在vim中执行：
```
:PluginInstall
```

在`~/.vimrc`中添加相关配置：
```vim
" nerdtree配置
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
map <C-n> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
```

上面的配置实现了三个功能：
- 使用CTRL+n可以开启或关闭左侧导航栏
- 如果当前打开的文件是文件夹，则自动开启左侧导航栏，否则默认不开启
- 当关闭文件时，只剩下导航栏窗口，则自动关闭窗口，退出vim

