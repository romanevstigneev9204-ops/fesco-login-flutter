/* sonic2/src/fixed.h */
#ifndef SONIC2_FIXED_H
#define SONIC2_FIXED_H
#include <stdint.h>
typedef int32_t fx_t;
#define FX_ONE 256
#define FX_FROM_PX(px) ((fx_t)(px) * FX_ONE)
#endif
