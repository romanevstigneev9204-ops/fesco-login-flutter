/* sonic2/src/world.h */
#ifndef SONIC2_WORLD_H
#define SONIC2_WORLD_H
#include "player.h"
#define TILE_PX 16
#define LEVEL_MAX_W 256
#define LEVEL_MAX_H 64
typedef struct Level {
    int w, h;
    char tiles[LEVEL_MAX_H][LEVEL_MAX_W];
    fx_t start_x, start_y;
} Level;
int level_load(Level *lv, const char *path);
void level_bind(ColWorld *col, const Level *lv);
#endif
