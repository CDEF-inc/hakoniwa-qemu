/* RX guest: P controller driven by the hakoniwa-asset MMIO window. */
#include <stdint.h>

#define HAKO     ((volatile uint32_t *)0x00e00000)
#define STEP     HAKO[0x008 / 4]
#define IN(i)    HAKO[0x100 / 4 + (i)]
#define OUT(i)   HAKO[0x200 / 4 + (i)]
#define TARGET   1000

void main_loop(void)
{
    uint32_t last = 0, polls = 0;

    for (;;) {
        uint32_t step = STEP;

        polls++;
        if (step == last) {
            continue;
        }
        last = step;
        int32_t x = (int32_t)IN(0);
        OUT(0) = (uint32_t)((TARGET - x) * 4);
        OUT(1) = polls;
        polls = 0;
    }
}
