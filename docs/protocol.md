# Timing and PDU ordering

## The hakoniwa-asset device

QEMU option:

```
-icount shift=N,sleep=off
-device hakoniwa-asset,asset=NAME,config=custom.json,robot=ROBOT,addr=BASE,
        delta-us=STEP,in-channel=I,out-channel=O[,in-size=8,out-size=8]
```

`-icount ... sleep=off` is required: virtual time then moves only with the
instructions the guest executes (2^N ns each), never with host time.

MMIO window at `addr` (little endian, 32-bit accesses only):

| Offset | Name | |
|---|---|---|
| 0x000 | TIME_LO | Hakoniwa time in µs at the last step, low word (RO) |
| 0x004 | TIME_HI | high word (RO) |
| 0x008 | STEP | number of completed steps (RO) |
| 0x100 | IN[] | PDU read from `in-channel` at the last step (RO, up to 256 bytes) |
| 0x200 | OUT[] | PDU written to `out-channel` at the next step (RW, up to 256 bytes) |

A guest polls STEP; when it changes, IN[] holds new data, and whatever it
leaves in OUT[] is sent at the end of the step.

## Time

Every `delta-us` of virtual time a timer stops the guest: QEMU holds the
BQL until Hakoniwa time has moved on by `delta-us` and the PDUs have been
exchanged. The guest never runs ahead of Hakoniwa, and wall-clock speed
does not change what the guest sees.

## Why two half steps

Hakoniwa's world time moves from t to t + d only when every asset has
reached t and called `hako_asset_usleep()` again. That is the only barrier
in a step. If assets write and read in the same step, a reader can see a
PDU from before or after the writer's update, depending on which process
the host schedules first. Two runs of the demo then differ.

So every asset splits each step into two Hakoniwa steps of d / 2:

```
write PDUs | barrier | read PDUs | barrier | (next step) write PDUs ...
```

- No asset passes the first barrier before every asset has written, so
  every read sees the writes of this step.
- No asset passes the second barrier before every asset has read, so no
  write of the next step lands before a read of this one.

The result is an exact one-step delay between assets, and it is the same
on every run. `test/model.py` computes the demo's trace from this rule,
and `test/determinism.sh` checks QEMU against it.

Rules for every asset in the simulation:

1. The conductor and every asset other than QEMU use `delta-us / 2`.
2. In each step: write, `hako_asset_usleep(delta / 2)`, read,
   `hako_asset_usleep(delta / 2)` (see `assets/plant/plant.c`).

## Stopping

After `hako-cmd stop`, `hako_asset_usleep()` returns only once
`hako-cmd reset` follows. Until then QEMU does not exit, not even on
SIGTERM, because its main loop waits for the asset thread. Always send
`stop` and then `reset` (`scripts/run-demo.sh` does).

## Limits

- While QEMU waits for Hakoniwa, the monitor and chardevs do not run.
- One `hakoniwa-asset` per QEMU process.
