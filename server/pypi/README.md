# Introduction

This directory contains the build-wheel tool, which produces Android .whl files for Chaquopy,
and iOS/tvOS/watchOS .whl files for Beeware.

## Android

Android builds are only supported on Linux x86-64. However, the resulting .whls can be built
into an app on any supported Android build platform, as described in the [Chaquopy
documentation](https://chaquo.com/chaquopy/doc/current/android.html#requirements).

## iOS/tvOS/watchOS

iOS build are supported on both x86-64 and M1; however, not all packages currently build.
See the notes at the end fo this document.

# Usage

Install the requirements in `requirements.txt`, then run `build-wheel.py --help` for more
information.

# Adding a new package

Create a recipe directory in `packages`. Its name must be in PyPI normalized form (PEP 503).
Alternatively, you can create this directory somewhere else, and pass its path when calling
`build-wheel.py`.

Inside the recipe directory, add the following files.

* A `meta.yaml` file. This supports a subset of Conda syntax, defined in `meta-schema.yaml`.
* A `test.py` file (or `test` package), to run on a target installation. This should contain a
  unittest.TestCase subclass which imports the package and does some basic checks.
* For non-Python packages, a `build.sh` script. See `build-wheel.py` for environment variables
  which are passed to it.

## Android

Run `build-wheel.py` for x86_64. If any changes are needed to make the build work, edit the
package source code in the `build` subdirectory, and re-run `build-wheel.py` with the
`--no-unpack` option. Then copy the resulting wheel from `dist` to a private package repository
(edit `--extra-index-url` in `pkgtest/app/build.gradle` if necessary).

Temporarily add the new package to `pkgtest/app/build.gradle`, and set `abiFilters` to
x86_64 only.

Unless the package depends on changes in the development version, edit `pkgtest/build.gradle`
to use the current stable Chaquopy version. Then run the tests.

If this is a new version of an existing package, we should check that it won't break any
existing apps with unpinned version numbers. So temporarily edit `pkgtest/build.gradle` to
use the oldest Chaquopy version which supported this package with this Python version. If
necessary, also downgrade the Android Gradle plugin, and Gradle itself. Then run the tests.

If any changes are needed to make the tests work, increment the build number in `meta.yaml`
before re-running `build-wheel.py` as above.

Once the package itself is working, also test any packages that list it as a requirement in
meta.yaml, since these usually indicate a dependency on native interfaces which may be less
stable. Include these packages in all the remaining tests.

Once everything's working on x86_64, save any edits in the package's `patches` directory,
then run `build-wheel.py` for all other ABIs, and copy their wheels to the private package
repository.

Restore `abiFilters` to include all ABIs. Then test the app with the same Chaquopy versions
used above, on the following devices, with at least one device being a clean install:

* x86 emulator with minSdkVersion, or API 18 if "too many libraries" error occurs (#5316)
* x86_64 emulator with targetSdkVersion
* x86_64 emulator with API 21 (or 23 before Chaquopy 7.0.3)
* Any armeabi-v7a device
* Any arm64-v8a device

Move the wheels to the public package repository.

Update any GitHub issues, and notify any affected users who contacted us outside of GitHub.

## iOS/tvOS/watchOS

### Quickstart

If you don't already have it, check out the branch of the
[Python-Apple-support](https://github.com/beeware/Python-Apple-support) repository that
matches your desired Python version, and in the root of the checkout, run:

    make Python-iOS wheels

This will compile Python, plus all it's dependencies, for macOS and iOS. This could take
up to 2 hours, depending on your machine.

Then, create and activate a Python virtual environment, and run:

    ./setup-deps.sh <path to Python-Apple-support>

then go get a very large meal - this will take a while to run. When the script
finishes, it will tell you the packages that succeeded, and the packages that
failed; if there are any failures, you can investigate further.

This will ensure you have a Python support package for your selected Python
version, and will build the binary dependencies that aren't Python-specific.

### Build all packages

Having run `setup-deps.sh`, run:

    ./make.sh

Then go get an even larger meal. This will build multiple versions of all the
packages for your current Python version. Again, when the script finishes, it will tell
you the packages that succeeded, and the packages that failed.

### Individual packages

Having run `setup-deps.sh`, run:

    python build-wheel.py --toolchain toolchain --python <python version> --os iOS <package name>

For example:

    python build-wheel.py --toolchain toolchain --python 3.10 --os iOS lru-dict

would build the lru-dict package for Python 3.10.

When you run `build-wheel.py` on a recipe, it will:

* Build an iOS/tvOS arm64 wheel, or a watchOS arm64_32 wheel
* Build an iOS/tvOS/watchOS Simulator arm64 wheel
* Build an iOS/tvOS/watchOS Simulator x86_64 wheel
* Use `lipo` to merge each `.dylib` file in the Simulator wheels into a "fat" binary
* Merge the iOS and iOS simulator wheels into a single "fat" wheel.

The fat wheel will contain 2 `.dylib` files for every binary module - one for
devices, and one for the simulator.

As on macOS, an iOS/tvOS/watchOS binary module is statically linked against all
dependencies. For example, the Pillow binary modules statically link the contents of
libjpeg, libpng and libfreetype into the `.dylib` files contained in the `.whl` file.
The wheel will not contain `.dylib` files for any dependencies, nor will you need to
install any extra dependencies.

If a wheel has a dependency on any other binary library (like `libpng`), there
will be a `chaquopy-` prefixed recipe for the library. This recipe will produce
a wheel - however, this is a "build-time" wheel; it will only contain the `.a`
library, which can be used to link into the projects that use it. There is no
need to distribute the `chaquopy-*` wheels.

### Configure-based projects

If the project includes a `configure` script, you will likely need to provide
a patch for `config.sub`. `config.sub` is the tools used by `configure` to identify
the architecture and machine type; however, it doesn't currently recognize the
host triples used by Apple. If you get the error:

    checking host system type... Invalid configuration `arm64-apple-ios': machine `arm64-apple' not recognized
    configure: error: /bin/sh config/config.sub arm64-apple-ios failed

you will need to patch `config.sub`. There are several examples of patched
`config.sub` scripts in the packages contained in this repository, and in the
Python-Apple-support project; it is quite possible one of those patches can be
used for the library you are trying to compile. The `config.sub` script has
a datestamp at the top of the file; that can be used to identify which patch
you will need.

### Other known problems:

At this time, there are also problems building recipes that:

* Use Cmake in the build process
* Use Rust in the build process
* Have a dependency on libfortran or a Fortran compiler
* Have a vendored version of distutils
