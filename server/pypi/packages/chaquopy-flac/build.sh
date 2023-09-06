#!/bin/bash
set -eu

./configure --host=$CHAQUOPY_TRIPLET --build=$BUILD_TRIPLET --prefix=$PREFIX
make -j $CPU_COUNT
make install

rm -r $PREFIX/share
