# h3copenr
OpenR 运行在H3C设备上，包括openr和fibservice两部分，openr学习路由发送到fibservice，fibservice下发路由到H3C设备。

[![Build Status](https://www.travis-ci.org/h3copen/h3copenr.svg?branch=master)](https://www.travis-ci.org/h3copen/h3copenr) 

## openr运行  
可参考[`h3copenr/build/test.h`](https://github.com/h3copen/h3copenr/blob/master/build/test.sh)。  
1：docker pull lmke/h3c_openr:v2 拿到openr镜像

2：按以下命令启动容器  
设备端：  
docker run -it --name openr1 --network container:comware -m 1G --sysctl net.ipv6.conf.all.disable_ipv6=0 lmke/h3c_openr:v2 bash  

pc端：   
docker run -it --name openr1 --sysctl net.ipv6.conf.all.disable_ipv6=0 lmke/h3c_openr:v2 bash  
注：不管设备还是PC端，都需要至少2个openr。在PC端，要再创建一个或多个openr，只要容器名不同即可。设备端每个设备只运行一个openr，所以至少需要两台设备，而PC只需要一台。    

3：openr 的网络设置  
设备端：  
在设备端中我们在启动命令中已经设计了相应网络 --network conatine:comware
除此之外，我们至少需要两台设备，并保证两台设备间有一个物理连接，可直接ping通。在两台设备上分别运行设备端启动openr容器命令.   

pc端：
需创建docker 网络  
docker network create net1  
docker network create net2  
docker network create net3  
至少需要3个net,2个openr  
docker network connect net1 openr1  
docker network connect net2 openr1  
docker network connect net2 openr2  
docker network connect net3 openr2    

4：openr 运行  
此时已启动openr容器，之后进去openr容器（docker attach openr1），在每个openr的根目录下运行  
run_openr.sh test.cfg > openr.log 2>&1 &   
注：test.cfg在设备和PC端测试时对应内容不同，镜像中的test.cfg适用于设备环境，PC端测试环境需使用本仓库的test.cfg。设备端和PC端对应的命令相同。   

此时openr程序已经启动，log会输入到openr.log中。一部分log在/tmp目录下。
注意：opern运行后需要启动fib容器openr才能正常运行。

5：fib容器运行  
注：本文中的fib，fibhandler，fibservice，在上下文没有特殊说明时，都是指代同一事物。  
1）：创建fib容器    
本仓库h3cfibservice和comwaresdk目录中包含fib的源码，需要手动编译，生成fib程序。进入/fibservice/fibhandler 执行go build编译生成fibhanlder。之后需要拉取镜像，以ubuntu16.04为例    
docker pull ubuntu:16.04  
2）：运行  
docker run -it --name fib1 --network container:openr1 ubuntu:16.04 bash   
3）：拷入fib  
chmod +x fibhandler  
docke cp fibhanler fib1:/bin  
4）：为每个openr创建对应fib容器    
有几个openr容器，就需要几个fib容器，每个openr和fib容器对应，对应关系体现在 第2步运行命令中  
--network container:openr_name,这里填写的是对应的openr名称。命令相同，只需修改fib名称和对应的openr容器名称。创建多个fib容器，即重复2 、3步。  
5）：运行  
docker attach fib1  
进入每个fib容器，所有fib容器都要运行其fibhandler，据实际情况需配置不同ip和用户名、密码，可查看说明[`h3cfibservice/README.md`](https://github.com/h3copen/h3cfibservice/blob/master/README.md)，如pc端需要以下参数：   
./fibhandler -ac 192.168.102.18 -uc 2 -pwc 123456 -wr    
设备端：   
./fibhandler -ac 192.168.102.18 -uc 2 -pwc 123456 -ec  
PC端和设备端运行时都需要加上framed（默认已加framed）参数    
注：ac（设备ip），uc（设备用户名），pwc（设备密码），ec（开启grpc连接到设备），wr（写路由到文本，仅pc端测试使用）    

### openr相关命令
openr运行后可使用breeze 命令与其进行交互
常用的有breeze fib routes； breeze lm links等。
可输入breeze后会打印相关参数，查看具体有哪些命令。

## openr编译
### openr目录结构
在openr目录中有build和openr两个目录，在build目录中提供了build_openr.sh，运行这个脚本即可自动编译openr，注：完整编译需要环境可访问github.com。openr目录中存放的是完整的代码。

### 安装
openr会将所需的库和头文件安装到/usr/local/lib和/usr/local/include中，相关安装过程在上述脚本中会自动执行。 

## Travis-ci 编译
在顶层目录中，我们包含了一个yml文件，根据yml，travis-ci会自动拉取镜像，创建容器，在容器中下载最新代码，编译openr。此外我们还会编译fibservice，编译成功后，我们会拉取新镜像运行openr和fibservice。之后会运行测试脚本，比较openr发出的路由和fibservice接收的路由是否相同。  


# h3copenr
OpenR running on H3C device. Including openr and fibservice two parts, openr learning routes and send to fibservice, fibservice send routes to H3C device.

## run openr
(For details, please refer to [`h3copenr/build/test.h`](https://github.com/h3copen/h3copenr/blob/master/build/test.sh).)  
1：you can use the following command to get the openr image,  
docker pull lmke/h3c_openr:v2 
    
2: Then start the container by the following command
Device side:  
docker run -it --name openr1 --network container:comware --sysctl net.ipv6.conf.all.disable_ipv6=0 lmke/h3c_openr:v2 bash  
PC side:  
docker run -it --name openr1 --sysctl net.ipv6.conf.all.disable_ipv6=0 lmke/h3c_openr:v2 bash  
Note: We need at least 2 openrs regardless of the device or PC. So on the PC side, you need to create one or more openrs, as long as the container name is different. Each device on the device only runs one openr, so at least two devices are required. We only need one PC.  

3: openr's network settings   
Device side:  
In the device side, we have designed the corresponding network in the startup command. --network conatine:comware    
In addition, we need at least two devices and ensure that there is a physical connection between the two devices, which can be directly pinged. Run the device-side openopen container command on both devices.  
PC side：  
We need to create a docker network  
docker network create net1    
docker network create net2  
docker network create net3   
Need at least 3 nets, 2 openr  
docker network connect net1 openr1  
docker network connect net2 openr1  
docker network connect net2 openr2  
docker network connect net3 openr2  

4: run openr  
At this point, the openr container has been started, and then the openr container (docker attach openr1) is run, running in the root directory of each openr.    
run_openr.sh test.cfg > openr.log 2>&1 &    
Note: test.cfg is different in the test of the device and the PC. The test.cfg in the image is applicable to the device environment. The PC test environment needs to use the test.cfg of the repository. The commands corresponding to the device and PC are the same.    
At this point the openr program has been started and the log is entered into openr.log. Part of the log is in the /tmp directory.    
Note: After running opn, you need to start the fib container openr to run normally.  

5: run fib container   
Note: Generally speaking, we will say fib, fibhandler, fibservice, and refer to the same thing when there is no special description in the context.  
1): Create a fib container  
The h3cfibservice and comwaresdk directories in this repository contain the source code of fib, which needs to be compiled manually to generate the fib program. Get into directory `/fibservice/fibhandler`. The command `go build` compile source file and generate the `fibhandler`.After that, we need to pull the image. Let's take ubuntu16.04 as an example.  
docker pull ubuntu:16.04   
2): run  
docker run -it --name fib1 --network container:openr1 ubuntu:16.04 bash    
3): copy fib to container  
chmod +x fibhandler  
docke cp fibhanler fib1:/bin  
4): Create a corresponding fib container for each openr  
There are several openr containers, you need several fib containers, each openr and fib container correspond, the corresponding relationship is reflected in the second step run command   -- network container:openr_name,Filled in here is the corresponding openr name. The command is the same, just modify the fib name and the corresponding openr container name. Create multiple fib containers, that is, repeat steps 2 and 3.  
5): Run  
`docker attach fib1`  
Enter each FIB container, all FIB containers must run their fibhandler, according to the actual situation need to configure different IP address ,user name and password. Refer to [`h3cfibservice/README.md`](https://github.com/h3copen/h3cfibservice/blob/master/README.md).PC side:    
`./fibhandler -ac 192.168.102.18 -uc 2 -pwc 123456 -wr`  
device side:  
`./fibhandler -ac 192.168.102.18 -uc 2 -pwc 123456 -ec`   
Both the PC and the device must be loaded with the framed parameter(Framed by default).  
Note: ac(ip to device), uc(user name to device ), pwc(password to device), ec(enable grpc connect to device), wr(Write route to text, only pc side test used).  

### command about openr
After the openr runs, it can interact with it by using the breeze command.Commonly used are breeze fib routes; breeze lm links, etc.
After entering breeze, the relevant parameters will be printed to see which commands are available.

## Openr compilation
### Openr directory structure
There are two directories in the openr directory, build and openr. The build_openr.sh is provided in the build directory. You can compile the openr automatically by running this script. Note: The complete compilation requires the environment to access github.com. The complete code is stored in the openr directory.

### Installation  
Libraries and header files will be installed into the `/usr/local/lib` and `/usr/local/include`. Installation will be executed automatically in scripts. 

## Travis-ci Build
In the top-level directory, include a YML file. According to the yml,travis-ci will pull up the image, create the container, download the latest code in the container, compile openr and compile fibservice automatically. After the compilation is successful, pull the new image and run openr and fibsrvice. Finally，the test script is run to compare whether the routes sent by openr are the same as those received by fibservice.
