#!/usr/bin/env bash
set -e

# default values and settings
PYTHON_APPLE_SUPPORT=$(readlink -f $1)
PYTHON_VERSION=$(python --version | awk '{ print $2 }' | awk -F '.' '{ print $1 "." $2 }')
CMAKE_VERSION="3.27.4"
# dependencies to build

DEPENDENCIES="
    chaquopy-freetype \
    chaquopy-libjpeg \
    chaquopy-libogg \
    chaquopy-libpng \
    chaquopy-libxml2 \
    chaquopy-libiconv \
    chaquopy-curl \
    chaquopy-ta-lib \
    chaquopy-zbar \
    "

# build dependencies
if ! [ -d "${PYTHON_APPLE_SUPPORT}" ]; then
  echo "Couldn't find Python Apple Support folder at '${PYTHON_APPLE_SUPPORT}'"
  exit
fi

rm -rf dist/bzip2 dist/libffi dist/openssl dist/xz logs/deps toolchain/${PYTHON_VERSION}
mkdir -p dist logs/deps toolchain

ln -si ${PYTHON_APPLE_SUPPORT}/wheels/dist/bzip2 dist/bzip2
ln -si ${PYTHON_APPLE_SUPPORT}/wheels/dist/libffi dist/libffi
ln -si ${PYTHON_APPLE_SUPPORT}/wheels/dist/openssl dist/openssl
ln -si ${PYTHON_APPLE_SUPPORT}/wheels/dist/xz dist/xz

ln -si ${PYTHON_APPLE_SUPPORT}/support/${PYTHON_VERSION} toolchain/${PYTHON_VERSION}

if ! [ -d "toolchain/CMake.app" ]; then
  curl --location "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-macos-universal.tar.gz" --output cmake.tar.gz
  tar -xzf cmake.tar.gz
  mv cmake-${CMAKE_VERSION}-macos-universal/CMake.app toolchain
  rm -rf cmake-${CMAKE_VERSION}-macos-universal cmake.tar.gz
fi

rm -f "logs/success.log" "logs/fail.log"
touch "logs/success.log" "logs/fail.log"

for DEPENDENCY in ${DEPENDENCIES}; do
  printf "\n\n*** Building dependency %s ***\n\n" "${DEPENDENCY}"
  python build-wheel.py --toolchain toolchain --python "${PYTHON_VERSION}" --os iOS "${DEPENDENCY}" 2>&1 | tee "logs/deps/${DEPENDENCY}.log"

  if [ "$(ls "dist/${DEPENDENCY}" | grep -c py3)" -ge "2" ]; then
    echo "${DEPENDENCY}" >> "logs/success.log"
  else
    echo "${DEPENDENCY}" >> "logs/fail.log"
  fi
done

echo ""
echo "Packages built successfully:"
cat "logs/success.log"
echo ""
echo "Packages with errors:"
cat "logs/fail.log"
echo ""
echo "Completed successfully."
