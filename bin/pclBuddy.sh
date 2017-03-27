#!/bin/bash
# helper to setup the pointclouds libraries
# http://www.pointclouds.org/

SOURCE="$(pwd)/srcs"
POC="$(pwd)/lidar-poc"

# Git remote definition
PCL_REMOTE="https://github.com/PointCloudLibrary/pcl.git"
PCL_DEMATHIF_REMOTE="https://github.com/demathif/pcl.git"

set -eux

function pcl_setup()
{
	echo "Checking sources folder...."
	if [ ! -d "$SOURCE"/pcl ]; then
		echo "$SOURCE/pcl does not exist... cloning a fresh repo";
		[ -d "$SOURCE" ] || mkdir -p "$SOURCE"
		cd $SOURCE && git clone "$PCL_REMOTE"
		cd "$SOURCE"/pcl
		git remote add github $PCL_DEMATHIF_REMOTE
		git update remote
		git checkout github/pcl
	fi

	cd "$SOURCE"/pcl

	echo "Building dependencies"
	bash ./.travis.sh install

	echo "Building point cloud libraries"
	export CC=clang
	export CXX=clang++
	bash ./.travis.sh build
}

pcl_setup
