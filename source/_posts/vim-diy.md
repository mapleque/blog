---
title: 我的vim配置
description: 基本vim配置，安装NERDTree，vundle等
tags: [ vim ]
categories: [ 工具, vim ]
date: 2019-08-29 13:03:19
---

下载vundle：

```bash
mkdir -p ~/.vim/bundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

按文件类型配置：

```bash
mkdir -p ~/.vim/ftplugin
touch ~/.vim/html.vim
touch ~/.vim/javascript.vim
touch ~/.vim/json.vim
touch ~/.vim/python.vim
touch ~/.vim/yaml.vim
```

完整配置文件
```vim .vimrc
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'fatih/vim-go'
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

syntax on "语法高亮
set nu "显示行号
set ruler "显示当前行状态
set cursorline "显示当前行标尺
"set foldenable "允许折叠
"set foldmethod=indent "按缩进折叠
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
let &colorcolumn="120" "设置代码每行最大宽度标尺

let g:vim_markdown_folding_disabled = 1

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | endif
map <C-n> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
```
