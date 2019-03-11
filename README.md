# h3copenr
OpenR running on H3C device，包括openr和fibservice两部分，openr负责学习路由，fibservice负责下发路由到H3C设备。

[![Build Status](https://www.travis-ci.org/h3copen/h3copenr.svg?branch=master)](https://www.travis-ci.org/h3copen/h3copenr) 

## openr在设备上运行
### openr运行
可直接docker pull lmke/h3c_openr:v2即可拿到openr镜像，之后按以下命令启动容器  
docker run -it --name openr1 --network container:comware --sysctl net.ipv6.conf.all.disable_ipv6=0 lmke/h3c_openr:v2 bash  
此时以启动openr容器，之后进去openr容器，在根目录下运行  
run_openr.sh test.cfg > openr.log 2>&1 &   
此时openr程序已经启动，log会输入到openr.log中。一部分log在/tmp目录下。
注意：opern运行需要启动fib容器，否则openr会等待。

### openr相关命令
openr运行后可使用breeze 命令与其进行交互
常用的有breeze fib routes； breeze lm links等。
可输入breeze后会打印相关参数，查看具体有哪些命令。

## openr编译
### openr目录结构
在openr目录中有build和openr两个目录，在build目录中提供了build_openr.sh，运行这个脚本即可自动编译openr，注：完整编译需要环境可访问github.com。openr目录中存放的是完整的代码。

### 安装
openr会将所需的库和头文件安装到/usr/local/lib和/usr/local/include中，相关安装过程在上述脚本中会自动执行。

## fibservice 
### build
fibservice将openr路由转发到H3C，cd /fibservice/fibhandler 执行go build编译生成fibhanlder，执行 ./fibhandler -h可以查看参数含义。
### run
fibservice 运行在另一个容器ubuntu16.04中，用dockerfile生成，接着为每个openr创建对应的fib容器，fib容器和对应的openr容器共享网络，可参考[`h3copenr/build/test.h`](https://github.com/h3copen/h3copenr/blob/master/build/test.sh)。

## CI 编译
在顶层目录中，我们包含了一个yml文件，在这其中，我们会拉取镜像，创建容器，在容器中下载最新代码，编译openr。此外我们还会编译fib，编译成功后，我们会拉取新镜像运行openr和fib，fib是用来接受openr发出的路由。之后会运行测试脚本，比较openr中的路由和fib中的路由是否相同。  


