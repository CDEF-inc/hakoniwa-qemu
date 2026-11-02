# hakoniwa-qemu

Run a QEMU guest as an asset of a [Hakoniwa](https://github.com/hakoniwalab/hakoniwa-core-pro)
(箱庭) co-simulation: the guest's time advances in lock step with the
Hakoniwa simulation time, and it exchanges PDUs with the other assets
through an MMIO window.

The QEMU side is the `hakoniwa-asset` device in
[CDEF-inc/qemu](https://github.com/CDEF-inc/qemu), branch `hakoniwa/v11.1`
(QEMU v11.1.2 plus the device). This repository has the rest: the PDU
definitions, a plant asset, guests, build scripts and a determinism test.

## Demo: RX controller in the loop

```
plant (host asset, also runs the conductor)
   │  PDU "sensor"   x  →
   │  PDU "actuator" u  ←
QEMU gdbsim-r5f562n8, -icount shift=4,sleep=off
   └─ -device hakoniwa-asset,addr=0xe00000,delta-us=1000,...
        └─ guests/rx-baremetal: u = (1000 - x) * 4 once per step
```

The plant integrates `x += u / 100` every 1 ms step, and x settles at 1000.

## Build and run

Needs cmake, ninja, a host C/C++ compiler, the QEMU build dependencies,
and `rx-elf-gcc` (set `RX_GCC` if it is not on `PATH`). Everything is
built and installed under `build/`; nothing needs sudo.

```sh
scripts/build-hakoniwa.sh      # hakoniwa-core-pro, pinned in scripts/env.sh
scripts/build-qemu.sh          # CDEF-inc/qemu hakoniwa/v11.1 (QEMU_SRC=... for a local checkout)
make                           # build/plant and build/rx-baremetal.elf
scripts/run-demo.sh 3          # trace in build/run/trace.txt
test/determinism.sh 5          # 5 runs: identical, and equal to test/model.py
```

`scripts/env.sh` lists every path and version; each one can be set from
the environment.

## Timing and ordering

See [docs/protocol.md](docs/protocol.md). In short: `delta-us` is the
guest step, and every other asset and the conductor must step by
`delta-us / 2`, writing PDUs in the first half step and reading them in
the second. Then each read sees exactly the writes of the same step, and
runs are reproducible.

## Layout

| Path | What |
|---|---|
| `pdu/` | Hakoniwa robot and PDU definitions (`custom.json`, `pdutypes.json`) |
| `assets/plant/` | Host plant asset; also starts the conductor |
| `guests/rx-baremetal/` | Bare-metal RX guest: P controller polling the MMIO window |
| `scripts/` | Build and run scripts |
| `test/` | Reference model and determinism test |
| `docs/` | Protocol and device notes |
