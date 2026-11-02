# Common paths; source this from the other scripts. Every path can be set
# from the environment.
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# Absolute, since run-demo.sh runs the assets from pdu/.
BUILD=$(realpath -m "${BUILD:-$ROOT/build}")
# hakoniwa-core-pro, pinned to the commit the demo was tested with.
HAKO_REPO=${HAKO_REPO:-https://github.com/hakoniwalab/hakoniwa-core-pro.git}
HAKO_REF=${HAKO_REF:-722ce022201547eca00c7ab630392faa53f2a431}
HAKO_SRC=${HAKO_SRC:-$BUILD/hakoniwa-core-pro}
HAKO_PREFIX=${HAKO_PREFIX:-$BUILD/install}
HAKO_MMAP=${HAKO_MMAP:-$BUILD/mmap}
# QEMU with the hakoniwa-asset device (CDEF-inc/qemu).
QEMU_REPO=${QEMU_REPO:-https://github.com/CDEF-inc/qemu.git}
QEMU_REF=${QEMU_REF:-hakoniwa/v11.1}
QEMU_SRC=${QEMU_SRC:-$BUILD/qemu}
QEMU_BUILD=${QEMU_BUILD:-$QEMU_SRC/build}
QEMU_TARGETS=${QEMU_TARGETS:-rx-softmmu}
# RX cross compiler for guests/rx-baremetal.
RX_GCC=${RX_GCC:-rx-elf-gcc}
JOBS=${JOBS:-$(nproc)}

export HAKO_CONFIG_PATH=$HAKO_PREFIX/etc/cpp_core_config.json
export LD_LIBRARY_PATH=$HAKO_PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=$HAKO_PREFIX/bin:$PATH
