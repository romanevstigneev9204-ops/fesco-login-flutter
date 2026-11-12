#include "../world.h"
#include <stdio.h>
#include <string.h>

static const Level *g_level;

static ColInfo stub_floor(void *ud, fx_t x, fx_t y)
{
    (void)x;
    ColInfo c = {0, 0, 0};
    const Level *lv = (const Level *)ud;
    if (!lv)
        lv = g_level;
    int ty = (int)(y / FX_ONE) / TILE_PX;
    int tx = (int)(x / FX_ONE) / TILE_PX;
    if (ty < 0 || ty >= lv->h || tx < 0 || tx >= lv->w)
        return c;
    char t = lv->tiles[ty][tx];
    if (t == '#' || t == '=' || t == '/' || t == '\\' || t == 'L') {
        c.hit = 1;
        c.surface = FX_FROM_PX((ty + 1) * TILE_PX);
        c.angle = 0;
        if (t == '/')
            c.angle = 32;
        if (t == '\\')
            c.angle = 224;
    }
    return c;
}

static ColInfo stub_miss_floor(void *ud, fx_t x, fx_t y)
{
    (void)ud;
    (void)x;
    (void)y;
    ColInfo c = {0, 0, 0};
    return c;
}

static ColInfo stub_miss_wall(void *ud, fx_t x, fx_t y, int dir)
{
    (void)ud;
    (void)x;
    (void)y;
    (void)dir;
    ColInfo c = {0, 0, 0};
    return c;
}

static void level_fill_default(Level *lv)
{
    memset(lv, 0, sizeof(*lv));
    lv->w = 40;
    lv->h = 14;
    lv->start_x = FX_FROM_PX(32);
    lv->start_y = FX_FROM_PX(10 * TILE_PX - 40);
    for (int x = 0; x < lv->w; x++)
        lv->tiles[10][x] = '#';
    lv->tiles[10][5] = '/';
    lv->tiles[10][6] = '\\';
    lv->tiles[9][15] = '=';
    lv->tiles[9][16] = '=';
    lv->tiles[10][20] = 'S';
}

int level_load(Level *lv, const char *path)
{
    FILE *f = fopen(path, "r");
    if (!f) {
        level_fill_default(lv);
        g_level = lv;
        return 0;
    }
    memset(lv, 0, sizeof(*lv));
    char line[LEVEL_MAX_W + 4];
    int row = 0;
    while (row < LEVEL_MAX_H && fgets(line, sizeof line, f)) {
        if (line[0] == '-' && line[1] == '-' && line[2] == '-')
            break;
        size_t len = strlen(line);
        while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r'))
            line[--len] = '\0';
        if (len == 0)
            continue;
        if (len > (size_t)LEVEL_MAX_W)
            len = LEVEL_MAX_W;
        lv->w = (int)len > lv->w ? (int)len : lv->w;
        memcpy(lv->tiles[row], line, len);
        row++;
    }
    lv->h = row;
    lv->start_x = FX_FROM_PX(2 * TILE_PX);
    lv->start_y = FX_FROM_PX((row - 2) * TILE_PX);
    if (lv->h < 2)
        level_fill_default(lv);
    fclose(f);
    g_level = lv;
    return 0;
}

void level_bind(ColWorld *col, const Level *lv)
{
    g_level = lv;
    col->ud = (void *)lv;
    col->floor_at = stub_floor;
    col->ceiling_at = stub_miss_floor;
    col->wall_at = stub_miss_wall;
}
