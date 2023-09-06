#!/bin/bash
set -eu

./configure --host=$CHAQUOPY_TRIPLET --build=$BUILD_TRIPLET --disable-static --disable-openmp --disable-examples
make -j $CPU_COUNT
make install prefix=$PREFIX

rm -rf $PREFIX/{bin,share}
