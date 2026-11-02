/*
 * Plant asset: x' = u / 100 per step, publishes x on "sensor" and reads
 * u from "actuator". Also runs the conductor.
 */
#include "hako_asset.h"
#include "hako_conductor.h"
#include <stdint.h>
#include <stdio.h>

#define ROBOT    "RX"
#define SENSOR   0
#define ACTUATOR 1
#define DELTA_US 1000
#define HALF_US  (DELTA_US / 2)

struct sensor { int32_t x; uint32_t seq; };
struct actuator { int32_t u; uint32_t polls; };

static int on_initialize(hako_asset_context_t *ctx) { (void)ctx; return 0; }
static int on_reset(hako_asset_context_t *ctx) { (void)ctx; return 0; }

static int on_manual_timing_control(hako_asset_context_t *ctx)
{
    (void)ctx;
    double x = 0;
    struct sensor s = { 0, 0 };
    struct actuator a;

    /* Write in the first half step, read in the second (see hakoniwa.c). */
    for (;;) {
        s.x = (int32_t)x;
        hako_asset_pdu_write(ROBOT, SENSOR, (const char *)&s, sizeof(s));
        if (hako_asset_usleep(HALF_US) != 0) {
            break;
        }
        hako_asset_pdu_read(ROBOT, ACTUATOR, (char *)&a, sizeof(a));
        if (hako_asset_usleep(HALF_US) != 0) {
            break;
        }
        x += a.u / 100.0;
        if (s.seq % 10 == 0) {
            printf("t=%6llu us  x=%7.2f  u=%6d  guest polls/step=%u\n",
                   (unsigned long long)hako_asset_simulation_time(), x, a.u,
                   a.polls);
            fflush(stdout);
        }
        s.seq++;
    }
    return 0;
}

static hako_asset_callbacks_t callbacks = {
    .on_initialize = on_initialize,
    .on_manual_timing_control = on_manual_timing_control,
    .on_reset = on_reset,
};

int main(int argc, const char *argv[])
{
    if (argc != 2) {
        fprintf(stderr, "usage: %s custom.json\n", argv[0]);
        return 1;
    }
    hako_conductor_start(HALF_US, HALF_US);
    if (hako_asset_register("Plant", argv[1], &callbacks, HALF_US,
                            HAKO_ASSET_MODEL_PLANT) != 0) {
        fprintf(stderr, "hako_asset_register: %s\n", hako_asset_last_error());
        return 1;
    }
    hako_asset_start();
    hako_conductor_stop();
    return 0;
}
