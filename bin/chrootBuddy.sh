#! /bin/bash

set -eu;

VERBOSE=false
HELP=false
PREFIX="$(pwd)/chroot"
NAME="debian"
RELEASE="testing"
ARCH="amd64"
USER="root"
GROUP="chroot"
SYSTEM="debian"

me=$(readlink -f "$0" | cut -d \. -f 1)
share=$(echo $me | sed -e "s/bin/share/g")
packages="$share.packages"

while true; do
	case "${1:-unset}" in
		-v | --verbose) VERBOSE=true; shift ;;
		-h | --help) HELP=true; shift ;;
		-p | --prefix) PREFIX=$(readlink -f "$2"); shift 2;;
		-n | --name) NAME=$2; shift 2;;
		-u | --user) USER=$2; shift 2;;
		-r | --release) RELEASE=$2; shift 2;;
		-a | --arch) ARCH=$2; shift 2;;
		-P | --packages) PACKAGES_LIST+=" $2"; shift 2;;
		-e | --extra) EXTRA_LIST=$2; shift 2;;
		-g | --group) GROUP=$2; shift 2;;
		-s | --system) SYSTEM=$2; shift 2;;
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
	$0 - Generate a debian or ubuntu chroot with pre-installed packages

OPTIONS:
	--verbose: Generate more logs
	--help: This output messge
	--name: The name of the chroot
	--user: user authorized to use the chroot
	--group: group authorized to use the chroot
	--release: Debian release (oldstable, stable, testing, unstable)
		   Ubuntu release (17.10, 16.04, 14.04))
	--arch: chroot architecture
	--prefix: Where to install the chroot
	--extra: postinstalled packages, at next available version
	--packages: preinstalled packages (see $packages)
	--system: ubuntu|debian

EXAMPLE:
	sudo ./chrootBuddy.sh  --verbose --name enet --release stable --prefix /srv/chroot --arch amd64 --extra cuda --packages enet
	sudo ./chrootBuddy.sh  --verbose --name epoc  --release stable --prefix /srv/chroot --arch amd64 --extra "cuda extra" --packages "opencv ssd enet"
	sudo ./chrootBuddy.sh  --verbose --name ubuntu --release 14.04 --prefix /srv/chroot --arch amd64 --system ubuntu
EOF
	exit 0
}

if $HELP;
then
	help
fi

case $RELEASE in
	"oldstable") EXTRA_RELEASE="stable";;
	"stable") EXTRA_RELEASE="testing";;
	"testing") EXTRA_RELEASE="unstable";;
	"unstable") EXTRA_RELEASE="experimental";;
	"16.04") RELEASE="xenial"; EXTRA_RELEASE="artful";;
	"14.04") RELEASE="trusty"; EXTRA_RELEASE="xenial";;
	*) echo 'Error while defining the distribution'; exit 1;;
esac

# Only root can continue the execution
if [[ $EUID -ne 0 ]]; then
	echo "You must be root to run this script"
	exit 1
fi

CHROOT_ROOT="$PREFIX"
CHROOT_NAME=$NAME
CHROOT_HOME=$CHROOT_ROOT/$CHROOT_NAME
CHROOT_USER=$USER
CHROOT_CONF="/etc/schroot/chroot.d/$CHROOT_NAME.conf"
CHROOT_GROUP=$GROUP

PACKAGES=$(cat "$packages"/base.packages),
if [ "${PACKAGES_LIST:-unset}" != 'unset' ]; then
	for p in ${PACKAGES_LIST}; do
		PACKAGES+=$(cat "$packages/$p.packages")
		PACKAGES+=,
	done
fi

unset PKG_EXTRA
if [ "${EXTRA_LIST:-unset}" != 'unset' ]; then
	for p in ${EXTRA_LIST}; do
		PKG_EXTRA+=$(cat "$packages/$p.packages")
		PKG_EXTRA+=,
	done
	PKG_EXTRA=$(echo $PKG_EXTRA | sed -e "s/,/ /g")
fi

SCRIPT_2ND_STAGE=/root/2ndstage_$CHROOT_NAME

case $SYSTEM in
	"debian") MIRROR=http://ftp.fr.debian.org/debian/;;
	"ubuntu") MIRROR=http://archive.ubuntu.com/ubuntu;;
	*) echo "Unsupported system $SYSTEM"; exit 1;;
esac

echo debootstrap --include="$PACKAGES" --variant=buildd --arch="$ARCH" "$RELEASE" "$CHROOT_HOME" "$MIRROR"
read -p "Here is debootstrap command, is that ok (y/N) ?" resp

[ "$resp" != "y" ] && echo "fine .. maybe next time" && exit 1;

set -x
debootstrap --include="$PACKAGES" --arch="$ARCH" "$RELEASE" "$CHROOT_HOME" "$MIRROR"

if [ $? != 0 ]; then
log "debootstrap failed. Please check log file under $CHROOT_HOME"
exit 1
fi

if [ ! -f "$CHROOT_CONF"  ]; then
log "Creating dedicated schroot conf file $CHROOT_CONF "
cat > "$CHROOT_CONF" <<EOF
[$CHROOT_NAME]
description=$SYSTEM $RELEASE $ARCH
directory=$CHROOT_HOME
preserve-environment=true
root-groups=root
type=directory
users=$CHROOT_USER
profile=$NAME
groups=$CHROOT_GROUP

EOF

else
log "Skipping creation of dedicated schroot conf file: $CHROOT_CONF already exists "
fi

if [ ! -d "/etc/schroot/$NAME" ]; then
cp -r /etc/schroot/default "/etc/schroot/$NAME"
else
log "Skipping creation of dedicated schroot fstab file: /etc/schroot/$NAME already exists "
fi

log "Configuring fstab for shm"
sed -i  -e 's/#\/dev\/shm/\/dev\/shm/' "/etc/schroot/$NAME/fstab"

log "Configuring release sources... "
if [ $SYSTEM = "debian" ]; then

{ echo "deb $MIRROR $RELEASE main contrib non-free"; echo "deb-src $MIRROR $RELEASE main contrib non-free"; echo "deb $MIRROR $EXTRA_RELEASE main contrib non-free"; echo "deb-src $MIRROR $EXTRA_RELEASE main contrib non-free";} > "$CHROOT_HOME/etc/apt/sources.list"

else

{ echo "deb $MIRROR $RELEASE main restricted"; echo "deb $MIRROR $RELEASE-updates main restricted"; echo "deb $MIRROR $RELEASE universe"; echo "deb $MIRROR $RELEASE-updates universe"; echo "deb $MIRROR $RELEASE multiverse"; echo "deb $MIRROR $RELEASE-updates multiverse";} > "$CHROOT_HOME/etc/apt/sources.list"

fi

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

if [ $SYSTEM = "debian" ]; then
log "Configuring locales... "
sed -i  -e   's/# en_US/en_US/' "$CHROOT_HOME/etc/locale.gen"
cat >> "$CHROOT_HOME/etc/default/locale" <<EOF
LANG=en_US
LANGUAGE="en_US:en"
EOF
fi

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
apt install -y -t $EXTRA_RELEASE $PKG_EXTRA
EOF
fi

log "Executing 2nd stage script... "

schroot -u root -c "$CHROOT_NAME" sh "$SCRIPT_2ND_STAGE"
