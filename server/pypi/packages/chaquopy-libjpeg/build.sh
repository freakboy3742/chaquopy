#!/bin/bash
set -eu

# SIMD is only available for x86, so disable for consistency between ABIs.
./configure --host=$CHAQUOPY_TRIPLET --build=$BUILD_TRIPLET --without-turbojpeg --without-simd
make -j $CPU_COUNT
make install prefix=$PREFIX

rm -r $PREFIX/{bin,doc,man}
mv $PREFIX/lib?? $PREFIX/lib  # lib32 or lib64
# mv $PREFIX/lib/libjpeg.so $PREFIX/lib/libjpeg_chaquopy.so  # See patches/soname.patch
# rm -r $PREFIX/lib/{*.a,*.la,pkgconfig}
rm -r $PREFIX/lib/{*.la,pkgconfig}
