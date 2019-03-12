#!/bin/bash

function process_routes() {
	src=`cat $1 | grep '>' | cut -b3- | cut -f1 -d'/'` #get all src
	src_count=`echo $src | awk -F" " '{print NF}'`

	rm /tmp/next_hoop* > /dev/null 2>&1 
#	rm /tmp/*routes* > /dev/null 2>&1

  grep -v '^$' $1 | sed 1,2d | awk -F'>' '{print $1}' |cut -f1 -d'@' | cut -b5- > /tmp/next_hoop

  x=1
  cat /tmp/next_hoop | while read line
  do 
	  if [ "$line" = "" ]
	  then
		  ((x++))
	  else 
	  	echo $line >> /tmp/next_hoop${x}
	  fi
  done

  x=1
  for src_single in $(echo $src)
  do 
	  echo $src_single >> /tmp/$1 
	  cat /tmp/next_hoop${x} >> /tmp/$1
	  echo '' >> /tmp/$1
	  ((x++))
  done 
  sed -i '$d' /tmp/$1 
}


function cmp_routes()
{
	#we just cmp the sorted string  of openr routes and fibhandler routes,so we dont care the it's src or nexthoop
	a=$#
	for((i=1;i<=a;i++))
	do	
		sort /tmp/${1}.routes -o /tmp/${1}.routes
		sort /tmp/${1}.routes.fib  -o /tmp/${1}.routes.fib
		sed -i '/^$/d' /tmp/${1}.routes
		sed -i '/^$/d' /tmp/${1}.routes.fib

    temp=`grep -vFf /tmp/${1}.routes /tmp/${1}.routes.fib`
		if [ "$temp" != "" ]
		then
				return 1	
		fi
		shift
	done
}


docker pull lmke/h3c_openr:complie
docker run -itd --name complie_openr lmke/h3c_openr:complie  bash
docker exec -it complie_openr sh -c " git clone https://github.com/facebook/openr.git"
docker cp ./build/build_openr.sh complie_openr:/openr/build/build_openr_fast.sh
docker exec -it complie_openr sh -c "cd /openr/build && chmod +x build_openr_fast.sh && \
					sed -i \"s/sudo//g\" build_openr_fast.sh &&  ./build_openr_fast.sh"
if [ $? -eq 0 ]; then 
	docker exec -t complie_openr sh -c "cd /openr && git log | head -1" 
	docker cp complie_openr:/usr/local/sbin/openr .
	docker build -f dockerfile_openr -t openr:test .
else 
	echo "fast complie openr error"
	docker exec -it complie_openr sh -c "cd /openr/build && sed -i \"s/sudo//g\" build_openr_fast.sh && ./build_openr.sh"
	
	if [ $? -eq 0 ]; then 
		docker exec -t complie_openr sh -c "cd /openr && git log | head -1"
		docker cp complie_openr:/usr/local/sbin/openr .
		docker build -f dockerfile_openr -t openr:test .
	else
		echo "complie openr error"
		exit 1
	fi
fi


#set -x
docker run -itd --name OPENRTEST10 --sysctl net.ipv6.conf.all.disable_ipv6=0 openr:test bash
docker run -itd --name OPENRTEST11 --sysctl net.ipv6.conf.all.disable_ipv6=0 openr:test bash
docker run -itd --name OPENRTEST12 --sysctl net.ipv6.conf.all.disable_ipv6=0 openr:test bash

docker network create --subnet 12.13.14.0/24  --gateway=12.13.14.1 Net1
docker network create --subnet 12.13.15.0/24  --gateway=12.13.15.1 Net2
docker network create --subnet 12.13.16.0/24  --gateway=12.13.16.1 Net3
docker network create --subnet 12.13.17.0/24  --gateway=12.13.17.1 Net4
#设置子网、网关不是必须的 所以你可以写成
#docker network create Net1
#设置IP不是必须的 所以可写成 
#docker network connetc Net1 OPENRTEST10
#注意 这些都是针对在PC端的测试环境，如果在设备上，可以认为这里的Net*就是设备中的接口，所以在设备上运行时不需要create net,connect net等
#我们需要的是指定openr的网络模式为container，即readme中所出现的命令
#所以 我们需要至少俩台设备，分别运行openr

docker network connect Net1 --ip 12.13.14.2 OPENRTEST10
docker network connect Net2 --ip 12.13.15.2 OPENRTEST10
docker network connect Net2 --ip 12.13.15.3 OPENRTEST11
docker network connect Net3 --ip 12.13.16.3 OPENRTEST11
docker network connect Net3 --ip 12.13.16.4 OPENRTEST12
docker network connect Net4 --ip 12.13.17.4 OPENRTEST12
docker network disconnect bridge OPENRTEST10
docker network disconnect bridge OPENRTEST11
docker network disconnect bridge OPENRTEST12
#docker cp  test.cfg OPENRTEST10:/
#docker cp  test.cfg OPENRTEST11:/
#docker cp  test.cfg OPENRTEST12:/

docker exec -itd OPENRTEST10 sh -c "run_openr.sh test.cfg > openr.log 2>&1 "
docker exec -itd OPENRTEST11 sh -c "run_openr.sh test.cfg > openr.log 2>&1 "
docker exec -itd OPENRTEST12 sh -c "run_openr.sh test.cfg > openr.log 2>&1 "

docker run -itd --name FIBTEST10 --network container:OPENRTEST10 fib:test bash
docker run -itd --name FIBTEST11 --network container:OPENRTEST11 fib:test bash
docker run -itd --name FIBTEST12 --network container:OPENRTEST12 fib:test bash

docker exec -itd FIBTEST10 sh -c "fibhandler -framed -wr > fib.log 2>&1 "
docker exec -itd FIBTEST11 sh -c "fibhandler -framed -wr > fib.log 2>&1 "
docker exec -itd FIBTEST12 sh -c "fibhandler -framed -wr > fib.log 2>&1 "

echo "now wating for openr ready "

while :
do 
	docker exec OPENRTEST10 sh -c "breeze fib routes > 10.routes"
	docker cp OPENRTEST10:/10.routes .
        #docker exec OPENRTEST10 sh -c "breeze lm links  > 10.links"
	#docker exec OPENRTEST10 sh -c "breeze tech-support  > 10.tech"
	#docker cp OPENRTEST10:/10.links .
	#docker cp OPENRTEST10:/10.tech .
	#cat 10.links
	#cat 10.tech
	cat 10.routes
	
	grep "No routes found" 10.routes > /dev/null
	if [ $? -eq 0 ]
	then 
		echo "openr not ready"
		sleep 1
	else
		echo "openr ready" 
		docker exec OPENRTEST11 sh -c "breeze fib routes > 11.routes"
		docker exec OPENRTEST12 sh -c "breeze fib routes > 12.routes"
		docker cp OPENRTEST11:/11.routes .
		docker cp OPENRTEST12:/12.routes .
		break
	fi		
done

echo "put fromat routes to /tmp/*routes"
#source func.sh
process_routes 10.routes 
process_routes 11.routes 
process_routes 12.routes 

echo "waiting fib routes"
sleep 3
docker cp FIBTEST10:/routes.txt /tmp/10.routes.fib
docker cp FIBTEST11:/routes.txt /tmp/11.routes.fib
docker cp FIBTEST12:/routes.txt /tmp/12.routes.fib
cmp_routes 10 11 12

if [ $? -ne 0 ]
then
	echo "the routes is not the same,error"
	exit 1
fi

echo "now we test del routes,stop one openr"
docker stop OPENRTEST10

while :
do 
	docker exec OPENRTEST11 sh -c "breeze fib routes > 11.routes.del"
	docker cp OPENRTEST11:/11.routes.del .
	temp=`cmp 11.routes.del 11.routes`
	if [ "$temp" = "" ]
	then
		echo "openr not ready"
		sleep 1
	else
		echo "openr ready"	
		docker exec OPENRTEST12 sh -c "breeze fib routes > 12.routes"
		docker cp OPENRTEST12:/12.routes .
		rm 11.routes
		mv 11.routes.del 11.routes
		break
	fi 
done

process_routes 11.routes 
process_routes 12.routes 

echo "waiting fib routes"
sleep 3
docker cp FIBTEST11:/routes.txt /tmp/11.routes.fib
docker cp FIBTEST12:/routes.txt /tmp/12.routes.fib
cmp_routes 11 12

if [ $? -ne 0 ]
then
	echo "the routes is not the same,error"
	return 1
fi
