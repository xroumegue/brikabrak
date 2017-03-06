#! /bin/bash
CHROOT_ROOT=/srv/chroot
RELEASE=testing
ARCH=amd64
MIRROR=http://ftp.fr.debian.org/debian/
#CHROOT_NAME=$RELEASE-$ARCH
CHROOT_NAME=opencv
CHROOT_HOME=$CHROOT_ROOT/$CHROOT_NAME 
EXTRA_RELEASE=unstable
CHROOT_USER=roumegue
CHROOT_CONF=/etc/schroot/schroot.conf
PKG_BASE=locales,sudo,libc6,libc6-dev,linux-libc-dev,bash,vim,cscope,exuberant-ctags,build-essential,\
git,pkg-config,cmake,zlib1g-dev,multiarch-support

PKG_ANDROID=openjdk-7-jdk,python,git-core,gnupg,flex,bison,gperf,zip,curl,zlib1g-dev,libc6-dev-i386,\
lib32ncurses5-dev,x11proto-core-dev,libx11-dev,lib32z1-dev,ccache,libgl1-mesa-dev,\
libxml2-utils,xsltproc,unzip,gcc-multilib,g++-multilib

PKG_KERNEL=bc,libssl-dev

PKG_OPENCV=libgtk2.0-dev,libavcodec-dev,libavformat-dev,libswscale-dev,libavresample3,\
libtbb2,libtbb-dev,libjpeg-dev,libpng-dev,libtiff5-dev,libdc1394-22-dev,\
libv4l-dev

PKG_PYTHON=python,python-dev,python3,python3-dev,python3-venv

PKG_MATH=libatlas3-base,libatlas-base-dev,libopenblas-dev,liblapacke-dev

PKG_CUDA=nvidia-cuda-toolkit


PACKAGES=$PKG_BASE,$PKG_OPENCV,$PKG_PYTHON,$PKG_MATH

PKG_EXTRA=libjasper1

SCRIPT_2ND_STAGE=/root/2ndstage_$CHROOT_NAME


set -x


debootstrap --include=$PACKAGES --arch=$ARCH $RELEASE $CHROOT_HOME $MIRROR

[ $? == 0 ] || exit 1

cat >> $CHROOT_CONF <<EOF


[$CHROOT_NAME]
description=Debian $RELEASE $ARCH 
directory=$CHROOT_HOME
preserve-environment=true
root-groups=root
type=directory
users=$CHROOT_USER


EOF

{ echo "deb $MIRROR $RELEASE main contrib non-free";echo "deb-src $MIRROR $RELEASE main contrib non-free"; echo "deb $MIRROR $EXTRA_RELEASE main contrib non-free"; echo "deb-src $MIRROR $EXTRA_RELEASE main contrib non-free";} > $CHROOT_HOME/etc/apt/sources.list


cat > $CHROOT_HOME/etc/apt/preferences <<EOF
Package: *
Pin: release a=$RELEASE
Pin-Priority: 800


Package: *
Pin: release a=$EXTRA_RELEASE
Pin-Priority: 500 

EOF


cat > $CHROOT_HOME/etc/apt/apt.conf <<EOF
Acquire::http::Proxy "http://proxy-mu.intel.com:911";
Acquire::ftp::Proxy "ftp://proxy-mu.intel.com:911";
EOF




sed -i  -e   's/# en_US/en_US/' $CHROOT_HOME/etc/locale.gen
cat >> $CHROOT_HOME/etc/default/locale <<EOF
LANG=en_US
LANGUAGE="en_US:en"
EOF


cat > $CHROOT_HOME/$SCRIPT_2ND_STAGE <<EOF
#!/bin/bash


set -x
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

apt update
apt full-upgrade -y
apt install -y $PKG_EXTRA 

EOF


schroot -u root -c $CHROOT_NAME sh $SCRIPT_2ND_STAGE 
