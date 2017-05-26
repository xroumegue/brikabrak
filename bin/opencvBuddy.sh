#! /bin/bash

# Neither undefined variables (-u) or error in command (-e) are allowed
set -eu;

VERBOSE=false
HELP=false
SOURCE="$(pwd)/srcs"
PREFIX="$(pwd)/sandbox"
BUILD="$(pwd)/build"
PYTHON2="/usr/bin/python2"
PYTHON3="/usr/bin/python3"


# Git remote definition
OPENCV_REMOTE="https://github.com/opencv/opencv.git"
OPENCV_CONTRIB_REMOTE="https://github.com/opencv/opencv_contrib.git"

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
	$0 - Build opencv library and install it in

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

PYTHON2_VERSION=$($PYTHON2 --version |& cut -d ' ' -f2 | cut -d '.' -f1,2)
PYTHON3_VERSION=$($PYTHON3 --version |& cut -d ' ' -f2 | cut -d '.' -f1,2)

log "Using $PYTHON2_VERSION as python2 version ..."
log "Using $PYTHON3_VERSION as python3 version ..."

log "Checking sources folder...."
if [ ! -d "$SOURCE" ]; then
	echo "$SOURCE/opencv does not exist... cloning a fresh repo";
	[ -d "$SOURCE" ] || mkdir -p "$SOURCE"
	cd $SOURCE && git clone "$OPENCV_REMOTE"
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
# shellcheck source=/dev/null
. "$PREFIX/bin/activate"
set +eu;

cd "$BUILD" || exit 1;

log "Configuring OpenCV..."

cmake \
	-G"Unix Makefiles" \
	-DCMAKE_INSTALL_PREFIX="$PREFIX" \
	-DBUILD_DOCS=OFF \
	-DBUILD_PERF_TESTS=OFF \
	-DBUILD_TESTS=OFF \
	-DBUILD_WITH_DEBUG_INFO=OFF \
	-DDOWNLOAD_EXTERNAL_TEST_DATA=OFF \
	-DINSTALL_TEST=OFF \
	-DBUILD_WITH_STATIC_CRT=OFF \
	-DENABLE_COVERAGE=OFF \
	-DENABLE_FAST_MATH=ON \
	-DENABLE_IMPL_COLLECTION=OFF \
	-DENABLE_NOISY_WARNINGS=OFF \
	-DENABLE_OMIT_FRAME_POINTER=ON \
	-DENABLE_PRECOMPILED_HEADERS=OFF \
	-DENABLE_PROFILING=OFF \
	-DOPENCV3_WARNINGS_ARE_ERRORS=OFF \
	-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF \
	-DCMAKE_SKIP_RPATH=OFF \
	-DCMAKE_USE_RELATIVE_PATHS=OFF \
	-DBUILD_PACKAGE=OFF \
	-DENABLE_SOLUTION_FOLDERS=OFF \
	-DINSTALL_CREATE_DISTRIB=OFF \
	-DBUILD_opencv_androidcamera=OFF \
	-DBUILD_opencv_apps=OFF \
	-DBUILD_opencv_calib3d=ON \
	-DBUILD_opencv_core=ON \
	-DBUILD_opencv_features2d=ON \
	-DBUILD_opencv_flann=ON \
	-DBUILD_opencv_highgui=ON \
	-DBUILD_opencv_imgcodecs=ON \
	-DBUILD_opencv_imgproc=ON \
	-DBUILD_opencv_java=OFF \
	-DBUILD_opencv_ml=ON \
	-DBUILD_opencv_objdetect=ON \
	-DBUILD_opencv_photo=ON \
	-DBUILD_opencv_shape=ON \
	-DBUILD_opencv_stitching=ON \
	-DBUILD_opencv_superres=ON \
	-DBUILD_opencv_ts=ON \
	-DBUILD_opencv_video=ON \
	-DBUILD_opencv_videoio=ON \
	-DBUILD_opencv_videostab=ON \
	-DBUILD_opencv_viz=ON \
	-DBUILD_opencv_world=OFF\
	-DENABLE_AVX=ON \
	-DENABLE_AVX2=OFF \
	-DENABLE_FMA3=OFF \
	-DENABLE_POPCNT=ON \
	-DENABLE_POWERPC=OFF \
	-DENABLE_SSE=ON\
	-DENABLE_SSE2=ON\
	-DENABLE_SSE3=ON \
	-DENABLE_SSE41=ON \
	-DENABLE_SSE42=ON \
	-DENABLE_SSSE3=ON \
	-DBUILD_CUDA_STUBS=OFF \
	-DBUILD_opencv_cudaarithm=OFF \
	-DBUILD_opencv_cudabgsegm=OFF \
	-DBUILD_opencv_cudacodec=OFF \
	-DBUILD_opencv_cudafeatures2d=OFF \
	-DBUILD_opencv_cudafilters=OFF \
	-DBUILD_opencv_cudaimgproc=OFF \
	-DBUILD_opencv_cudalegacy=OFF \
	-DBUILD_opencv_cudaobjdetect=OFF \
	-DBUILD_opencv_cudaoptflow=OFF \
	-DBUILD_opencv_cudastereo=OFF \
	-DBUILD_opencv_cudawarping=OFF \
	-DBUILD_opencv_cudev=OFF \
	-DWITH_CUBLAS=OFF \
	-DWITH_CUDA=OFF \
	-DWITH_CUFFT=OFF \
	-DWITH_NVCUVID=OFF \
	-DWITH_OPENCLAMDBLAS=OFF \
	-DWITH_OPENCLAMDFFT=OFF \
	-DBUILD_WITH_DYNAMIC_IPP=OFF \
	-DWITH_INTELPERC=OFF \
	-DWITH_IPP=OFF \
	-DWITH_IPP_A=OFF \
	-DWITH_TBB=OFF \
	-DWITH_GIGEAPI=OFF \
	-DWITH_PVAPI=OFF \
	-DWITH_XIMEA=OFF \
	-DANDROID=OFF \
	-DBUILD_ANDROID_CAMERA_WRAPPER=OFF \
	-DBUILD_ANDROID_EXAMPLES=OFF \
	-DBUILD_ANDROID_SERVICE=OFF \
	-DBUILD_FAT_JAVA_LIB=OFF \
	-DINSTALL_ANDROID_EXAMPLES=OFF \
	-DWITH_ANDROID_CAMERA=OFF \
	-DWITH_AVFOUNDATION=OFF \
	-DWITH_CARBON=OFF \
	-DWITH_QUICKTIME=OFF \
	-DWITH_CSTRIPES=OFF \
	-DWITH_DSHOW=OFF \
	-DWITH_MSMF=OFF \
	-DWITH_PTHREADS_PF=ON \
	-DWITH_VFW=OFF \
	-DWITH_VIDEOINPUT=OFF \
	-DWITH_WIN32UI=OFF \
	-DBUILD_EXAMPLES=ON \
	-DBUILD_JASPER=ON \
	-DBUILD_JPEG=ON \
	-DBUILD_OPENEXR=ON \
	-DBUILD_PNG=ON \
	-DBUILD_TIFF=ON \
	-DBUILD_ZLIB=ON \
	-DINSTALL_C_EXAMPLES=ON \
	-DINSTALL_PYTHON_EXAMPLES=ON \
	-DINSTALL_TO_MANGLED_PATHS=OFF \
	-DWITH_1394=OFF \
	-DWITH_CLP=OFF \
	-DWITH_EIGEN=OFF \
	-DWITH_GDAL=OFF \
	-DWITH_GPHOTO2=OFF \
	-DWITH_MATLAB=OFF \
	-DWITH_OPENCL=ON \
	-DWITH_OPENCL_SVM=ON \
	-DWITH_OPENEXR=ON \
	-DWITH_OPENNI2=ON \
	-DWITH_OPENNI=ON \
	-DWITH_UNICAP=OFF \
	-DWITH_VA=OFF \
	-DWITH_VA_INTEL=OFF \
	-DWITH_VTK=OFF \
	-DWITH_WEBP=ON \
	-DWITH_XINE=OFF \
	-DWITH_FFMPEG=ON \
	-DWITH_GSTREAMER_0_10=OFF \
	-DWITH_GSTREAMER=OFF \
	-DWITH_GTK=ON \
	-DWITH_GTK_2_X=ON \
	-DWITH_JASPER=ON \
	-DWITH_JPEG=ON \
	-DWITH_OPENGL=OFF \
	-DWITH_OPENMP=OFF \
	-DWITH_PNG=ON \
	-DWITH_QT=OFF \
	-DWITH_V4L=ON \
	-DWITH_LIBV4L=ON \
	-DBUILD_opencv_python2=ON \
	-DBUILD_opencv_python3=ON \
	-DPYTHON3_EXECUTABLE="$(which "$PYTHON3")" \
	-DPYTHON2_EXECUTABLE="$(which "$PYTHON2")" \
	"$SOURCE"


log "Building OpenCV..."
make "-j$(nproc)"
log "Installing OpenCV..."
make install

log "Creating symbolic link on cv2 library..."
find  "$PREFIX" -iname 'cv2.cpython*.so' -execdir ln -s {} cv2.so \;


log "OpenCV build and installed Done !"
