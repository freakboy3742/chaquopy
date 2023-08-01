#!/usr/bin/env bash
set -e

# shellcheck source=/dev/null
. environment.sh


# packages to build

#PACKAGES="
#    cffi \
#    numpy \
#    aiohttp \
#    backports-zoneinfo \
#    bitarray \
#    brotli \
#    cymem \
#    cytoolz \
#    editdistance \
#    ephem \
#    frozenlist \
#    greenlet \
#    kiwisolver \
#    lru-dict \
#    matplotlib \
#    multidict \
#    murmurhash \
#    netifaces \
#    pandas \
#    pillow \
#    preshed \
#    pycrypto \
#    pycurl \
#    pynacl \
#    pysha3 \
#    pywavelets \
#    pyzbar \
#    regex \
#    ruamel-yaml-clib \
#    scandir \
#    spectrum \
#    srsly \
#    statsmodels \
#    twisted \
#    typed-ast \
#    ujson \
#    wordcloud \
#    yarl \
#    zstandard \
#    "
PACKAGES="
    cffi \
    aiohttp \
    frozenlist \
    multidict \
    pillow \
    pycrypto \
    yarl \
    "

PYTHON_VERSION=$(python --version | awk '{ print $2 }' | awk -F '.' '{ print $1 "." $2 }')


for PACKAGE in ${PACKAGES}; do
    python build-wheel.py --toolchain "${TOOLCHAINS}" --python "${PYTHON_VERSION}" --os iOS "${PACKAGE}"  2>&1 | tee "${LOGS}/${PYTHON_VERSION}/${PACKAGE}.log"
done

echo ""
echo "Packages built successfully:"
cat "${LOGS}/success.log"
echo ""
echo "Packages with errors:"
cat "${LOGS}/fail.log"
echo ""
echo "Completed successfully."
