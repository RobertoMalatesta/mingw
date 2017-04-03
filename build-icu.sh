#!/bin/bash

set -e

MINGW=${MINGW:-x86_64-w64-mingw32}
WORKSPACE=${WORKSPACE:-$(pwd)}
BUILD_NUMBER=${BUILD_NUMBER:-0}
ARCH=${ARCH:-${MINGW%%-*}}

download=0
while test $# -gt 0; do
    case "$1" in
        (-h|--help)
            cat<<EOF
$0 [OPTIONS]

OPTIONS:

  -h, --help      show this help
  -d, --download  download sources
                  otherwise sources must be in $(pwd)

VARIABLES:

  MINGW           mingw parameter (default: $MINGW)
  WORKSPACE       workspace path (default: $WORKSPACE)
  BUILD_NUMBER    build number (default: $BUILD_NUMBER)
  ARCH            architecture (default: $ARCH)

Builds OpenSSL for Windows
EOF
            exit
            ;;
        (-d|--download) download=1;;
        (*) echo "unknown option: $1" 1>&2; exit 1;;
    esac
    shift
done

set -x

cd ${WORKSPACE}
if test $download -eq 1; then
    version=$(wget -qO- http://source.icu-project.org/repos/icu/icu/tags | sed -n 's,.*href="release-\([0-9]\+-[0-9]\+\)/".*,\1,p' | tail -1)
    source=http://source.icu-project.org/repos/icu/icu/tags/release-${version}
    svn co $source .
else
    version=$(date +'%Y-%m-%d')
fi
version=${version//-/.}
path=icu-${version}
[[ "$version" =~ ^[0-9.]+$ ]]

echo "Version: $version"
echo "Package: $path"

case ${MINGW} in
    (*i?86*)
        TARGET=mingw
        ;;
    (*x86_64*)
        TARGET=mingw64
        ;;
    (*) false;;
esac

test -d ${WORKSPACE}/build-lin || mkdir ${WORKSPACE}/build-lin
cd ${WORKSPACE}/build-lin
../source/configure
make
test -d ${WORKSPACE}/build-win || mkdir ${WORKSPACE}/build-win
cd ${WORKSPACE}/build-win
../source/configure \
    --host=${MINGW} \
    --with-cross-build=${WORKSPACE}/build-lin \
    --prefix=${WORKSPACE}/usr
make
make install

cd ${WORKSPACE}
zip -r ${path}~windows.${BUILD_NUMBER}_${ARCH}.zip usr