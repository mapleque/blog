---
title: 使用google的colab进行神经网络相关开发
tags: [ nn, pytorch, colab ]
categories: [工具, corlab ]
date: 2019-10-31 16:07:21
description: 在colab上开发并运行神经网络相关任务，并将代码托管到github上。
---

[Colaboratory(简称colab)](https://colab.research.google.com/)是Google提供的一个免费的Jupyter笔记本环境，支持云端运行。
为了支持云端运行，Google还提供了强大的计算资源，如GPU、TPU和云端存储空间等，这些都可以通过浏览器免费使用。

如需全面了解colab的所提供的功能，请阅读[官方文档](https://colab.research.google.com/notebooks/welcome.ipynb)。

本文的主要目标是使你快速的能够使用colab进行神经网络相关开发。

准备
----

使用colab服务，首先需要科学上网。相关文章，请参考[标签：vpn](https://blog.mapleque.com/tags/vpn/)中的内容。

创建修改文件
----

直接访问地址： https://colab.research.google.com/ ，就可以开始代码的编辑。

打开页面时，会弹窗提示最近打开的文件，也可以选择创建文件。这个弹窗后面也可以通过顶部菜单：`文件->打开笔记本`调出。

在这个弹窗中，我们还可以看到一些其他打开文件的方式，这里重点说明GitHub选项。

点击选择GitHub选项，会出现`输入GitHub网址，或者按组织或用户搜索`的输入框。这里可以输入自己的github用户名，如：`mapleque`，点击搜索后，就会在下面代码库部分出现该用户所有的公开项目列表了（中间可能需要进行GitHub账号授权）。选择一个项目和分支，如果在项目中含有colab可以打开的文件，就会被列在下面的路径列表中，用户可以选择任意一个打开编辑。

如果是私有代码库，可以选择勾选右上角的选项，然后进行额外的授权之后，重新搜索对应的空间或项目，这时所有有权限的私有项目也会出现在列表中了。

注意：这里还有一个快捷打开GitHub文件的技巧，即输入网址：https://colab.research.google.com/github/mapleque/nnlearning/blob/master/notebooks/TensorflowMNIST.ipynb 。

观察上面的网址，可以发现`/github/`后面的路径，实际上就是文件在GitHub上预览的路径。

编辑运行
----

colab集成了丰富的nn相关资源，如tensorflow, pytorch等。所以只需要新建一个python3的记事本，就可以开始执行程序了。

注意，新建代码文件后，需要配置代码执行环境：选择顶部菜单中的`代码执行程序->更改运行时类型`选项，在弹框中选择相关设置，如：硬件加速选择GPU，最后保存。

下面以tensorflow的MNIST为例，讲解如何编辑执行代码：

1.
点击顶部菜单左上角`+代码`选项，就会在文件编辑区域出现一行带有播放图标的空白输入框，在输入框中输入代码，点击播放按钮，就可以提交执行。例如这里提交编辑代码：

```python
from __future__ import absolute_import, division, print_function, unicode_literals
import tensorflow as tf
from tensorflow import keras
import numpy as np
import matplotlib.pyplot as plt
```

点击执行，即显示执行成功。可见tensorflow，numpy和matplotlib等包都已经预置安装好了。

后面正常编辑执行MNIST例子相关代码，就可以看到自动下载数据和训练的日志输出。完整代码请参考[mapleque/nnlearning/TensorflowMNIST.ipynb](https://colab.research.google.com/github/mapleque/nnlearning/blob/master/notebooks/TensorflowMNIST.ipynb)。

colab执行结果页面，可以将图片直接展示出来。

提交到GitHub
----

colab支持直接将当前代码文件提交到GitHub。

点击顶部菜单：`文件->在GitHub中保存一份副本`选项，授权后在弹窗中选择对应的代码库、分支和路径，就可以提交了。

这里如果勾选了`包含指向Colaboratory的链接`选项，将会在GitHub的文件预览页面看到一个直接在colab中打开文件并编辑的按钮。
