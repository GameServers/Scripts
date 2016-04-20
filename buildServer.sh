#!/bin/bash

SERVER_GROUP="SteamLUG [UK]"

echo "checking for CURL"
if ! which curl ; then
echo "CURL not found, installing..."
	sudo apt-get install curl
fi

echo "checking for Docker"
if ! which docker ; then
echo "Docker not found, Isntalling"
	curl -fsSL https://get.docker.com/ | sh
fi

echo "Local directory for Docker Volume storage?"
echo "default ~/DockerVolumes/"
read DOCKER_VOLUME_STORE
if [ "x${DOCKER_VOLUME_STORE}" = "x" ]; then
	DOCKER_VOLUME_STORE=${HOME}/DockerVolumes/
fi

echo "Use Steamcache? [Y|N]"
read STEAMCACHE

echo "Run Windward Server? [Y|N]"
read WINDWARD_SERVER

echo "Run Fistful Of Frags Server? [Y|N]"
read FISTFUL_SERVER

echo "Run Team Fortress 2 Server? [Y|N]"
read TF2_SERVER




case $STEAMCACHE in
	y|Y|yes|Yes|YES)
		STEAMCACHE_LOCAL_DIR=${DOCKER_VOLUME_STORE}/steamcache
		echo "setting up local directories"
		if ! [ -d ${STEAMCACHE_LOCAL_DIR}/logs ]; then
			mkdir -p ${STEAMCACHE_LOCAL_DIR}/logs
			chmod 777 ${STEAMCACHE_LOCAL_DIR}/logs
		fi
		if ! [ -d ${STEAMCACHE_LOCAL_DIR}/cache ]; then
			mkdir -p ${STEAMCACHE_LOCAL_DIR}/cache
			chmod 777 ${STEAMCACHE_LOCAL_DIR}/cache
		fi

		echo "setting up local steamcache"
		if ! docker images | grep steamcache | grep -v dns ; then
			echo "pulling steamcache"
			docker run -d --name Steamcache -v ${STEAMCACHE_LOCAL_DIR}/cache:/data/cache -v ${STEAMCACHE_LOCAL_DIR}/logs:/data/logs steamcache/steamcache
			sleep 3
			CACHE_IP=`docker inspect Steamcahce | grep IPAddress | sed 's/.*: \"//;s/\",//' | tail -1`
		fi

		if ! docker images | grep steamcache-dns ; then
			echo "pulling steamcache DNS"
			docker run -d --name Steamcache-DNS -e STEAMCACHE_IP=${CACHE_IP} steamcache/steamcache-dns
			sleep 3
			DNS_IP=`docker inspect Steamcahce-DNS | grep IPAddress | sed 's/.*: \"//;s/\",//' | tail -1`
			echo "nameserver ${DNS_IP}" > /etc/resolv.conf
		fi
		;;

		
	*)
		echo "skipping Steamcache Setup"
		;;
esac

case ${WINDWARD_SERVER} in
	y|Y|Yes|yes|YES)
		echo "Running Windward Server"
		docker run -d --name "Windward-Server" -e WINDWARD_SERVER_NAME="${SERVER_GROUP}" -e WINDWARD_SERVER_WORLD="${SERVER_GROUP}" -e WINDWARD_SERVER_PORT=5127 -v ${DOCKER_VOLUME_STORE}/Windward:/data/windward -p 5128:5128 gameservers/windward:latest
		;;
	*)
		echo "skipping Windward Server"
esac
case ${FISTFUL_SERVER} in
	y|Y|Yes|yes|YES)
		echo "Running Fistful Of Frags Server"
		docker run -d --name Fistful -v ${DOCKER_VOLUME_STORE}/fof:/home/steamsrv/fof gameservers/fistfuloffrag
		;;
	*)
		echo "skipping Fistful Of Frags Server"
esac
case ${TF2_SERVER} in
	y|Y|Yes|yes|YES)
		echo "Running Team Fortress 2 Server"
		docker run -d --name TF2 -v ${DOCKER_VOLUME_STORE}/tf2:/home/steamsrv/tf2 gameservers/tf2
		;;
	*)
		echo "skipping Team Fortress 2 Server"
esac
