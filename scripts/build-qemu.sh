#!/bin/bash
# Builds QEMU_REF of CDEF-inc/qemu against the hakoniwa install. Set
# QEMU_SRC to an existing checkout to build that instead of cloning.
set -eu
. "$(dirname "$0")/env.sh"

if [ ! -d "$QEMU_SRC/.git" ] && [ ! -f "$QEMU_SRC/.git" ]; then
  git clone -q --filter=blob:none --branch "$QEMU_REF" "$QEMU_REPO" \
    "$QEMU_SRC"
fi
mkdir -p "$QEMU_BUILD"
cd "$QEMU_BUILD"
"$QEMU_SRC/configure" --target-list="$QEMU_TARGETS" --disable-docs \
  --extra-cflags="-I$HAKO_PREFIX/include/hakoniwa" \
  --extra-ldflags="-L$HAKO_PREFIX/lib -Wl,-rpath,$HAKO_PREFIX/lib"
grep -q "hakoniwa.c" build.ninja ||
  { echo "configure did not find hakoniwa in $HAKO_PREFIX" >&2; exit 1; }
ninja -j "$JOBS"
