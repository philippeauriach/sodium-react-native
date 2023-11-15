#!/bin/bash

# get current dir of the build script
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $script_dir

source_file='libsodium-1.0.19-stable.tar.gz'
source_dir='libsodium-stable'
build_dir='build'

# delete local source files
rm -f $source_file
rm -f $source_file.minisig

# download and verify the source
curl https://download.libsodium.org/libsodium/releases/$source_file > $source_file
curl https://download.libsodium.org/libsodium/releases/$source_file.minisig > $source_file.minisig
minisign -Vm $source_file -p libsodium.org.minisign.pub || exit 1

# extract source from previous builds
rm -rf $source_dir
# extract tar
tar -xzf $source_file
cd $source_dir

current_platform=`uname`

if [ "$current_platform" == 'Darwin' ]; then
  LIBSODIUM_FULL_BUILD=1 IOS_VERSION_MIN=10.0.0 dist-build/apple-xcframework.sh
fi

LIBSODIUM_FULL_BUILD=1 NDK_PLATFORM=android-21 dist-build/android-armv7-a.sh
LIBSODIUM_FULL_BUILD=1 NDK_PLATFORM=android-21 dist-build/android-armv8-a.sh
LIBSODIUM_FULL_BUILD=1 NDK_PLATFORM=android-21 dist-build/android-x86.sh
LIBSODIUM_FULL_BUILD=1 NDK_PLATFORM=android-21 dist-build/android-x86_64.sh

cd ..

# move compiled libraries
mkdir -p $build_dir
rm -rf $build_dir/*

if [ "$current_platform" == 'Darwin' ]; then
  mv $source_dir/libsodium-apple $build_dir/
fi

for dir in $source_dir/libsodium-android-*
do
  mv $dir $build_dir/
done

# create library archive
tar -cvzf build.tgz $build_dir

# cleanup downloaded source
rm $source_file
rm -rf $source_dir