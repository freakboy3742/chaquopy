#!/usr/bin/env bash
set -e

# default values and settings

YEAR="2019"

# packages to build

PACKAGES="
    cffi \
    numpy \
    aiohttp \
    backports-zoneinfo \
    bitarray \
    brotli \
    cymem \
    cytoolz \
    editdistance \
    ephem \
    frozenlist \
    greenlet \
    kiwisolver \
    lru-dict \
    matplotlib \
    multidict \
    murmurhash \
    netifaces \
    pandas \
    pillow \
    preshed \
    pycrypto \
    pycurl \
    pynacl \
    pysha3 \
    pywavelets \
    pyzbar \
    regex \
    ruamel-yaml-clib \
    scandir \
    spectrum \
    srsly \
    statsmodels \
    twisted \
    typed-ast \
    ujson \
    wordcloud \
    yarl \
    zstandard \
    "

# parse command line

POSITIONAL=()
while [[ $# -gt 0 ]] ; do
  key="${1}"

  case "${key}" in
    --help)
      echo "Usage: make.sh options

      options
              --package package
              --year year"
      exit 0
      ;;
    --package)
      PACKAGES="${2}"
      shift
      shift
      ;;
    --year)
      YEAR="${2}"
      shift
      shift
      ;;
    *)
      POSITIONAL+=("$1") # save it in an array for later
      shift
    ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

# build packages

touch "logs/success.log" "logs/fail.log"
PYTHON_VERSION=$(python --version | awk '{ print $2 }' | awk -F '.' '{ print $1 "." $2 }')

for PACKAGE in ${PACKAGES}; do
  PACKAGE_VERSIONS="$(./versions.py --year "${YEAR}" --package "${PACKAGE}" --python "${PYTHON_VERSION}")"
  printf "\n### Attempting package %s with versions: %s ###\n" "${PACKAGE}" "${PACKAGE_VERSIONS}"

  for PACKAGE_VERSION in ${PACKAGE_VERSIONS}; do
    # edit package dependencies
    # FIXME: remove the for loop with the sed below
    # FIXME: short term workaround until we can find a better way to deal with dependencies
    # FIXME: without editing the meta.yaml file and without generating a lot of manual maintenance

    for DEPENDENCY in numpy; do
      if grep "${DEPENDENCY}" "packages/${PACKAGE}/meta.yaml" &>/dev/null; then
        sed -i '' "s/- ${DEPENDENCY}.*/- ${DEPENDENCY} $(ls -1 "dist/${DEPENDENCY}"/*"${PYTHON_VERSION/./}"* | head -1 | awk -F '-' '{ print $2 }' )/g" "packages/${PACKAGE}/meta.yaml"
      fi
    done

    mkdir -p "logs/${PYTHON_VERSION}"
    printf "\n\n*** Building package %s version %s for Python %s ***\n\n" "${PACKAGE}" "${PACKAGE_VERSION}" "${PYTHON_VERSION}"
    python build-wheel.py --toolchain toolchain --python "${PYTHON_VERSION}" --os iOS "${PACKAGE}" "${PACKAGE_VERSION}" 2>&1 | tee "logs/${PYTHON_VERSION}/${PACKAGE}.log"

    # shellcheck disable=SC2010
    if [ "$(ls "dist/${PACKAGE}" | grep "cp${PYTHON_VERSION/./}" | grep -c "${PACKAGE_VERSION}")" -ge "4" ]; then
      echo "${PACKAGE}-${PACKAGE_VERSION} with Python ${PYTHON_VERSION}" >> "logs/success.log"
    else
      echo "${PACKAGE}=${PACKAGE_VERSION} with Python ${PYTHON_VERSION}" >> "logs/fail.log"
    fi
  done
done

echo ""
echo "Packages built successfully:"
cat "logs/success.log"
echo ""
echo "Packages with errors:"
cat "logs/fail.log"
echo ""
echo "Completed successfully."
