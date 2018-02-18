#! /bin/bash

# Neither undefined variables (-u) or error in command (-e) are allowed
#set -eu;

VERBOSE=false
HELP=false
SOURCE="$(pwd)/srcs"
PREFIX="$(pwd)/sandbox"
BUILD="$(pwd)/build"
PYTHON2="/usr/bin/python2"
PYTHON3="/usr/bin/python3"

BINDIR=$(dirname $(realpath $0))
BASEDIR=$(dirname $BINDIR)

while true; do
	case "${1:-unset}" in
		-v | --verbose) VERBOSE=true; shift ;;
		-h | --help) HELP=true; shift ;;
		-p | --prefix) PREFIX=$(readlink -m "$2"); shift 2;;
		-s | --source) SOURCE=$(readlink -m "$2"); shift 2;;
		-b | --build) BUILD=$(readlink -m "$2"); shift 2;;
		--python2) PYTHON2=$(readlink -f "$2"); shift 2;;
		--python3) PYTHON3=$(readlink -f "$2"); shift 2;;
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
	$0 - Build vision (openCV, openVX) environment

OPTIONS:
	--verbose: Generate more logs
	--help: This output messge
	--prefix: Where to install the library and python environment
	--source: Where to find the opencv sources (.i.e sources/opencv, source/opencv-contrib..
	--build: Where to build
	--python2: Python2 executable
	--python3: Python3 executable
EOF
	exit 0
}

log "Verbose: $VERBOSE"
log "Help: $HELP"
log "Prefix: $PREFIX"
log "Source: $SOURCE"
log "Build: $BUILD"
log "Python2: $PYTHON2"
log "Python3: $PYTHON3"

if $HELP;
then
	help
fi

if [ ! -d "$PREFIX" ];
then
	log "Creating virtualenv folder..."
	mkdir -p "$PREFIX"
	log "Creating python3 virtualenv..."
	"$PYTHON3" -m venv "$PREFIX"
fi

if  [ ! -e $PREFIX/bin/activate ]
then
	log "Creating python3 virtualenv..."
	"$PYTHON3" -m venv "$PREFIX"
fi

log "Activating virtualenv..."

set +eu;
# shellcheck source=/dev/null
. "$PREFIX/bin/activate"
set +eu;
while read package
do
	pip3 install "$package"
done < "$BASEDIR/share/visionBuddy.packages/base.packages"

$BINDIR/opencvBuddy.sh \
	--prefix "$PREFIX" \
	--source "$SOURCE/opencv" \
	--build "$BUILD/opencv" \
	--python2 "$PYTHON2" \
	--python3 "$PYTHON3" \
	--verbose

if [ $? != 0 ]
then
	log "error while installing opencv.. exiting"
	exit 1
fi


$BINDIR/openvxBuddy.sh \
	--prefix "$PREFIX" \
	--source "$SOURCE/openvx" \
	--build "$BUILD/openvx" \
	--verbose
if [ $? != 0 ]
then
	log "error while installing openvx AMD.. exiting"
	exit 1
fi

log "Deactivating virtualenv..."
deactivate

cat > "$PREFIX/activateVisionWorld" <<EOF
# you must source this file

function deactivateVisionWorld {

	deactivate

	if [ -n "$_OLD_PKG_CONFIG_PATH" ] ;
	then
	    PKG_CONFIG_PATH="$_OLD_PKG_CONFIG_PATH"
	    export PKG_CONFIG_PATH
	    unset _OLD_PKG_CONFIG_PATH
	else
	    unset PKG_CONFIG_PATH
	fi

	if [ -n "$_OLD_LD_LIBRARY_PATH" ] ;
	then
	    LD_LIBRARY_PATH="$_OLD_LD_LIBRARY_PATH"
	    export LD_LIBRARY_PATH
	    unset _OLD_LD_LIBRARY_PATH
	else
	    unset LD_LIBRARY_PATH
	fi
}

if [ -n "$PKG_CONFIG_PATH" ] ; then
    _OLD_PKG_CONFIG_PATH=$PKG_CONFIG_PATH
fi

if [ -n "$LD_LIBRARY_PATH" ] ; then
    _OLD_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
fi

. $PREFIX/bin/activate

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig":$PKG_CONFIG_PATH
export LD_LIBRARY_PATH="$PREFIX/lib":$LD_LIBRARY_PATH

EOF

log "Done !"

echo "To enter the awesome vision world: # . $PREFIX/activateVisionWorld"
echo "To exit the awesome vision world: # deactivateVisionWorld"
