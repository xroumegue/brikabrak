#! /bin/bash

set -eu;

VERBOSE=false
HELP=false
PREFIX="$(pwd)/chroot"
NAME="debian"
RELEASE="testing"
ARCH="amd64"
USER="root"

while true; do
	case "${1:-unset}" in
		-v | --verbose) VERBOSE=true; shift ;;
		-h | --help) HELP=true; shift ;;
		-p | --prefix) PREFIX=$(readlink -f "$2"); shift 2;;
		-n | --name) NAME=$2; shift 2;;
		-u | --user) USER=$2; shift 2;;
		-r | --release) RELEASE=$2; shift 2;;
		-a | --arch) ARCH=$2; shift 2;;
		-- ) shift; break;;
		*) break ;;
	esac
done

function log {
	if $VERBOSE; then
		echo "$1"
	fi
}

function help {
	cat <<EOF
NAME:
	$0 - Generate a debian chroot with pre-installed packages

OPTIONS:
	--verbose: Generate more logs
	--help: This output messge
	--name: The name of the chroot
	--user: user authorized to use the chroot
	--release: Debian release (stable, testing, unstable)
	--arch: chroot architecture
	--prefix: Where to install the chroot
EOF
	exit 0
}

if $HELP;
then
	help
fi



case $RELEASE in
	"stable") EXTRA_RELEASE="testing";;
	"testing") EXTRA_RELEASE="unstable";;
	"unstable") EXTRA_RELEASE="experimental";;
	*) echo 'Error while defining the distribution'; exit 1;;
esac

# Only root can continue the execution
if [[ $EUID -ne 0 ]]; then
	echo "You must be root to run this script"
	exit 1
fi

CHROOT_ROOT="$PREFIX"
MIRROR=http://ftp.fr.debian.org/debian/
CHROOT_NAME=$NAME
CHROOT_HOME=$CHROOT_ROOT/$CHROOT_NAME 
CHROOT_USER=$USER
CHROOT_CONF="/etc/schroot/chroot.d/$CHROOT_NAME.conf"
PKG_BASE=locales,sudo,libc6,libc6-dev,linux-libc-dev,bash,vim,cscope,exuberant-ctags,build-essential,\
git,pkg-config,cmake,zlib1g-dev,multiarch-support

PKG_ANDROID=openjdk-7-jdk,python,git-core,gnupg,flex,bison,gperf,zip,curl,zlib1g-dev,libc6-dev-i386,\
lib32ncurses5-dev,x11proto-core-dev,libx11-dev,lib32z1-dev,ccache,libgl1-mesa-dev,\
libxml2-utils,xsltproc,unzip,gcc-multilib,g++-multilib,ca-certificates

PKG_KERNEL=bc,libssl-dev

PKG_OPENCV=libgtk2.0-dev,libavcodec-dev,libavformat-dev,libswscale-dev,libavresample3,\
libtbb2,libtbb-dev,libjpeg-dev,libpng-dev,libtiff5-dev,libdc1394-22-dev,\
libv4l-dev

PKG_PYTHON=python,python-dev,python3,python3-dev,python3-venv

PKG_MATH=libatlas3-base,libatlas-base-dev,libopenblas-dev,liblapacke-dev

PACKAGES=$PKG_BASE
PKG_EXTRA=''
#PACKAGES=$PKG_BASE,$PKG_OPENCV,$PKG_PYTHON,$PKG_MATH
#PKG_EXTRA=nvidia-cuda-toolkit


SCRIPT_2ND_STAGE=/root/2ndstage_$CHROOT_NAME


set -x

debootstrap --include="$PACKAGES" --arch="$ARCH" "$RELEASE" "$CHROOT_HOME" "$MIRROR"

[ $? == 0 ] || exit 1

if [ ! -f "$CHROOT_CONF"  ]; then
log "Creating dedicated schroot conf file $CHROOT_CONF "
cat > "$CHROOT_CONF" <<EOF
[$CHROOT_NAME]
description=Debian $RELEASE $ARCH 
directory=$CHROOT_HOME
preserve-environment=true
root-groups=root
type=directory
users=$CHROOT_USER
profile=$NAME

EOF

else
log "Skipping creation of dedicated schroot conf file $CHROOT_CONF, already exists "
fi

if [ ! -d "/etc/schroot/$NAME" ]; then
cp -r /etc/schroot/default "/etc/schroot/$NAME"
fi


log "Configuring release sources... "

{ echo "deb $MIRROR $RELEASE main contrib non-free";echo "deb-src $MIRROR $RELEASE main contrib non-free"; echo "deb $MIRROR $EXTRA_RELEASE main contrib non-free"; echo "deb-src $MIRROR $EXTRA_RELEASE main contrib non-free";} > "$CHROOT_HOME/etc/apt/sources.list"


log "Configuring packets pinning... "
cat > "$CHROOT_HOME/etc/apt/preferences" <<EOF
Package: *
Pin: release a=$RELEASE
Pin-Priority: 800


Package: *
Pin: release a=$EXTRA_RELEASE
Pin-Priority: 500 

EOF

if [ "${http_proxy:-unset}" != 'unset' ]; then
log "Configuring http proxy ... "
cat >> "$CHROOT_HOME/etc/apt/apt.conf" <<EOF
Acquire::http::Proxy "$http_proxy";
EOF
fi

if [ "${ftp_proxy:-unset}" != 'unset' ]; then
log "Configuring ftp proxy ... "
cat >> "$CHROOT_HOME/etc/apt/apt.conf" <<EOF
Acquire::ftp::Proxy "$ftp_proxy";
EOF
fi

log "Configuring locales... "
sed -i  -e   's/# en_US/en_US/' "$CHROOT_HOME/etc/locale.gen"
cat >> "$CHROOT_HOME/etc/default/locale" <<EOF
LANG=en_US
LANGUAGE="en_US:en"
EOF


log "Configuring 2nd stage script... "
cat > "$CHROOT_HOME/$SCRIPT_2ND_STAGE" <<EOF
#!/bin/bash

set -x
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

apt update
apt full-upgrade -y
EOF

if [ "${PKG_EXTRA:-unset}" != 'unset' ]; then
cat >> "$CHROOT_HOME/$SCRIPT_2ND_STAGE" <<EOF
apt install -y $PKG_EXTRA
EOF
fi

log "Executing 2nd stage script... "

schroot -u root -c "$CHROOT_NAME" sh "$SCRIPT_2ND_STAGE"
