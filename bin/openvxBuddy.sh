#! /bin/bash

# Neither undefined variables (-u) or error in command (-e) are allowed
set -eu;

VERBOSE=false
HELP=false
SOURCE="$(pwd)/srcs"
PREFIX="$(pwd)/sandbox"
BUILD="$(pwd)/build"

# Git remote definition
OPENVX_CORE_REMOTE="https://github.com/xroumegue/amdovx-core.git"
OPENVX_MODULE_REMOTE="https://github.com/xroumegue/amdovx-modules.git"

while true; do
	case "${1:-unset}" in
		-v | --verbose) VERBOSE=true; shift ;;
		-h | --help) HELP=true; shift ;;
		-p | --prefix) PREFIX=$(readlink -m "$2"); shift 2;;
		-s | --source) SOURCE=$(readlink -m "$2"); shift 2;;
		-b | --build) BUILD=$(readlink -m "$2"); shift 2;;
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
	$0 - Build openvx AMD library and install it in

OPTIONS:
	--verbose: Generate more logs
	--help: This output messge
	--prefix: Where to install the library and python environment
	--source: Where to find the openvx sources
	--build: Where to build
EOF
	exit 0
}

log "Verbose: $VERBOSE"
log "Help: $HELP"
log "Prefix: $PREFIX"
log "Source: $SOURCE"
log "Build: $BUILD"

if $HELP;
then
	help
fi

[ ! -d "$SOURCE " ] || mkdir -p "$SOURCE"
[ ! -d "$BUILD" ] || mkdir -p "$BUILD"

SOURCE_CORE="$SOURCE/amdovx-core"
BUILD_CORE="$BUILD/amdovx-core"

log "Checking sources folder...."
if [ ! -d "$SOURCE_CORE" ]; then
	echo "$SOURCE_CORE does not exist... cloning a fresh repo";
	cd $SOURCE && git clone "$OPENVX_CORE_REMOTE"
	cd -
fi

log "Creating build folder..."
if [ ! -d "$BUILD_CORE" ];
then
	echo "Creating $BUILD_CORE does not exist";
	mkdir -p "$BUILD_CORE"
else
	echo "Cleaning existing build folder $BUILD_CORE"
	rm -fr "${BUILD_CORE:?}"/*
fi


if [ ! -d "$PREFIX" ];
then
	log "Creating installation folder..."
	mkdir -p "$PREFIX"
fi

set +eu;

cd "$BUILD_CORE" || exit 1;

cmake -DCMAKE_DISABLE_FIND_PACKAGE_OpenCL=TRUE  -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DCMAKE_INSTALL_PREFIX="$PREFIX" $SOURCE_CORE
make -j12
make install

log "OpenVX core build and installed Done !"

SOURCE_MODULE="$SOURCE/amdovx-modules"
BUILD_MODULE="$BUILD/amdovx-modules"

log "Checking sources folder...."
if [ ! -d "$SOURCE_MODULE" ]; then
	echo "$SOURCE_MODULE does not exist... cloning a fresh repo";
	cd $SOURCE && git clone "$OPENVX_MODULE_REMOTE"
fi

log "Creating build folder..."
if [ ! -d "$BUILD_MODULE" ];
then
	echo "Creating $BUILD_MODULE does not exist";
	mkdir -p "$BUILD_MODULE"
else
	echo "Cleaning existing build folder $BUILD_MODULE"
	rm -fr "${BUILD_MODULE:?}"/*
fi


set +eu;

cd "$BUILD_MODULE" || exit 1;

cmake -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DCMAKE_INSTALL_PREFIX="$PREFIX" $SOURCE_MODULE/vx_ext_cv
make -j12
make install

log "OpenVX module build and installed Done !"
