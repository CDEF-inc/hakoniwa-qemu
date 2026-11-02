#!/bin/bash
# Builds hakoniwa-core-pro at HAKO_REF and installs it to HAKO_PREFIX, with
# no sudo. Python bindings, tests and examples are left out.
set -eu
. "$(dirname "$0")/env.sh"

if [ ! -d "$HAKO_SRC/.git" ]; then
  git clone -q "$HAKO_REPO" "$HAKO_SRC"
fi
git -C "$HAKO_SRC" fetch -q origin
git -C "$HAKO_SRC" checkout -q "$HAKO_REF"
git -C "$HAKO_SRC" submodule update -q --init --recursive

# The limits must match cmake/hako_build_defaults.conf (build.bash passes
# them the same way).
limits=()
while IFS='=' read -r key value; do
  case "$key" in ''|\#*) continue ;; esac
  limits+=("-D$key=$value")
done < "$HAKO_SRC/cmake/hako_build_defaults.conf"

cmake -S "$HAKO_SRC" -B "$BUILD/hakoniwa-build" \
  -DCMAKE_INSTALL_PREFIX="$HAKO_PREFIX" \
  -DHAKO_CORE_MMAP_PATH="$HAKO_MMAP" \
  -DHAKO_CORE_CONFIG_INSTALL_DIR="$HAKO_PREFIX/etc" \
  -DHAKO_BUILD_DEFAULTS_FILE="$HAKO_SRC/cmake/hako_build_defaults.conf" \
  "${limits[@]}" \
  -DHAKO_CORE_PRO_BUILD_PYTHON_BINDINGS=OFF \
  -DHAKO_ENABLE_GTEST=OFF \
  -DHAKO_CORE_PRO_BUILD_EXAMPLES=OFF
cmake --build "$BUILD/hakoniwa-build" -j "$JOBS"
cmake --install "$BUILD/hakoniwa-build"
mkdir -p "$HAKO_MMAP"
echo "hakoniwa installed in $HAKO_PREFIX"
