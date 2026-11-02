"""Reference model of the rx-baremetal closed loop.

Prints the lines the plant asset prints (without the guest poll count), for
the given number of steps. In step k the plant publishes int(x_k) and the
controller publishes the u it computed from the sensor value of step k - 1
(0 in step 0): the two-phase exchange makes this one-step delay exact.

    python3 model.py [steps]
"""
import sys

steps = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
x, u_next = 0.0, 0
for k in range(steps):
    sensor = int(x)                 # C (int32_t) truncates toward zero
    u = u_next                      # actuator the plant reads in step k
    u_next = (1000 - sensor) * 4    # the guest's P controller
    x += u / 100.0
    if k % 10 == 0:
        print("t=%6d us  x=%7.2f  u=%6d" % ((k + 1) * 1000, x, u))
