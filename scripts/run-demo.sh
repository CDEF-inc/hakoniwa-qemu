#!/bin/bash
# Runs the closed loop for SECONDS of wall time: the plant asset (host)
# against the RX guest's P controller in QEMU. Logs go to OUT.
#   run-demo.sh [SECONDS] [OUT]
set -u
. "$(dirname "$0")/env.sh"
seconds=${1:-3}
out=${2:-$BUILD/run}
qemu=$QEMU_BUILD/qemu-system-rx
# Absolute, since the assets run in pdu/.
mkdir -p "$out" && out=$(cd "$out" && pwd) || exit 1

for f in "$qemu" "$BUILD/plant" "$BUILD/rx-baremetal.elf" "$HAKO_PREFIX/bin/hako-cmd"; do
  [ -x "$f" ] || [ -f "$f" ] || { echo "missing $f; see README.md" >&2; exit 1; }
done
# Assets started from another run would join this one.
if pgrep -f "$BUILD/plant" > /dev/null || pgrep -f "hakoniwa-asset" > /dev/null; then
  echo "an earlier run is still alive" >&2
  exit 1
fi
hako-cmd recover > /dev/null 2>&1

cd "$ROOT/pdu"
head -c 16 /dev/zero > "$out/bios.bin"
"$BUILD/plant" custom.json > "$out/plant.log" 2>&1 &
plant=$!
sleep 1
# delta-us is the guest step; the plant and conductor use delta-us / 2.
"$qemu" -M gdbsim-r5f562n8 -bios "$out/bios.bin" -display none \
    -serial none -monitor none -icount shift=4,sleep=off \
    -device loader,file="$BUILD/rx-baremetal.elf",cpu-num=0 \
    -device hakoniwa-asset,asset=RxEcu,config=custom.json,robot=RX,addr=0xe00000,delta-us=1000,in-channel=0,out-channel=1 \
    > "$out/qemu.log" 2>&1 &
qemu_pid=$!
sleep 2
hako-cmd start > /dev/null 2>&1
sleep "$seconds"
hako-cmd stop > /dev/null 2>&1
sleep 1
# Assets return from hako_asset_usleep() only after the reset.
hako-cmd reset > /dev/null 2>&1
for i in $(seq 50); do
  kill -0 $qemu_pid 2>/dev/null || kill -0 $plant 2>/dev/null || break
  sleep 0.1
done
status=0
if kill -0 $qemu_pid 2>/dev/null || kill -0 $plant 2>/dev/null; then
  echo "assets did not exit; killing" >&2
  kill -9 $qemu_pid $plant 2>/dev/null
  status=1
fi
wait $qemu_pid
qemu_status=$?
wait $plant
plant_status=$?
if [ $qemu_status != 0 ]; then
  echo "QEMU exited with $qemu_status (see $out/qemu.log)" >&2
  status=1
fi
if [ $plant_status != 0 ]; then
  echo "plant exited with $plant_status (see $out/plant.log)" >&2
  status=1
fi
grep '^t=' "$out/plant.log" > "$out/trace.txt"
lines=$(wc -l < "$out/trace.txt")
echo "$lines trace lines in $out/trace.txt"
if [ "$lines" = 0 ]; then
  echo "no trace from the plant" >&2
  status=1
fi
exit $status
