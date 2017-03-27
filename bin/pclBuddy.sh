#!/bin/bash
# helper to setup the pointclouds libraries
# http://www.pointclouds.org/

green='\e[0;32m'
nc='\e[0m'
WORK="$HOME"

set -eux

dep_setup()
{
	sudo apt-get update

	# dependencies from ci: https://travis-ci.org/PointCloudLibrary/pcl/jobs/137554758/config
	sudo apt-get install -y cmake libboost1.55-all-dev libeigen3-dev libgtest-dev doxygen-latex dvipng libusb-1.0-0-dev

	# dependencies implied by travis.sh install
	sudo apt-get install -y bison unzip flex libqt4-opengl-dev libxt-dev clang ssh
}

pcl_setup()
{
	cd "$WORK"
	PCL="$WORK/pcl"
	if [ ! -d "$PCL/.git" ]
	then
		echo -e "${green}cloning pcl...${nc}"
		git clone https://github.com/PointCloudLibrary/pcl.git
		cd "$PCL"
		git remote add github https://github.com/demathif/pcl.git
	else
		cd "$PCL"
		echo -e "${green}checkout pcl-1.8-0...${nc}"
		git update remote
		git checkout github/pcl
	fi

	echo -e "${green}Building pcl...${nc}"
	export CC=clang
	source ./.travis.sh install

	if [ ! -d "$PCL/build" ]
	then
		bash ./.travis.sh build
	fi
}

poc_setup()
{
	cd "$WORK"
	POC="$WORK/pcl-poc"
	if [ ! -d "$POC/.git" ]
	then
		echo -e "${green}cloning pcl-poc...${nc}"
		git clone ssh://git.mordor/pcl.git "$POC"
	else
		cd "$POC"
		git update remote
		git checkout origin/master
	fi

	cd "$POC"
	cmake .
	make
}

#dep_setup
pcl_setup
poc_setup
