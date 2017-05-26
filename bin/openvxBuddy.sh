#! /bin/bash

# Neither undefined variables (-u) or error in command (-e) are allowed
set -eu;

VERBOSE=false
HELP=false
SOURCE="$(pwd)/srcs"
PREFIX="$(pwd)/sandbox"
BUILD="$(pwd)/build"

# Git remote definition
OPENVX_REMOTE="https://github.com/xroumegue/amdovx-core.git"

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

log "Checking sources folder...."
if [ ! -d "$SOURCE" ]; then
	echo "$SOURCE does not exist... cloning a fresh repo";
	[ -d "$SOURCE" ] || mkdir -p "$SOURCE"
	cd $SOURCE && git clone "$OPENVX_REMOTE" .
	cd -
fi

log "Creating build folder..."
if [ ! -d "$BUILD" ];
then
	echo "Creating $BUILD does not exist";
	mkdir -p "$BUILD"
else
	echo "Cleaning existing build folder $BUILD"
	rm -fr "${BUILD:?}"/*
fi


if [ ! -d "$PREFIX" ];
then
	log "Creating installation folder..."
	mkdir -p "$PREFIX"
fi

set +eu;

cd "$BUILD" || exit 1;

cmake -DCMAKE_DISABLE_FIND_PACKAGE_OpenCL=TRUE  -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DCMAKE_INSTALL_PREFIX="$PREFIX" $SOURCE
make -j12
make install

log "OpenVX build and installed Done !"
