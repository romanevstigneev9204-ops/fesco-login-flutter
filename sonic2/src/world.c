#include "world.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TILE_FX FX_FROM_PX(TILE_PX)
#define ANG_FLAT 0
#define ANG_SLOPE_UP 32   /* floor rises as x increases */
#define ANG_SLOPE_DOWN 224

typedef struct LevelColCtx {
    const Level *lv;
} LevelColCtx;

static int is_solid_char(char c)
{
    return c == '#' || c == '/' || c == '\\' || c == 'L' || c == 'S' || c == '=';
}

static char tile_at(const Level *lv, int tx, int ty)
{
    if (tx < 0 || ty < 0 || tx >= lv->w || ty >= lv->h)
        return '.';
    return lv->tiles[ty][tx];
}

static fx_t px_to_fx(int px) { return FX_FROM_PX(px); }

static int floor_local_y(char c, int lx, int *angle_out)
{
    /* lx: 0..TILE_PX within tile from left edge; returns surface y in px from top of tile */
    if (!is_solid_char(c)) {
        *angle_out = ANG_FLAT;
        return TILE_PX;
    }
    switch (c) {
    case '#':
    case '=':
    case 'S':
        *angle_out = ANG_FLAT;
        return 0;
    case '/':
        *angle_out = ANG_SLOPE_UP;
        return TILE_PX - lx;
    case '\\':
        *angle_out = ANG_SLOPE_DOWN;
        return lx;
    case 'L': {
        /* Inner loop floor: quarter arc along bottom of tile (custom layout, not ROM). */
        int cx = TILE_PX / 2;
        int cy = TILE_PX / 2;
        int dx = lx - cx;
        int dy = TILE_PX - 2;
        int d2 = dx * dx + dy * dy;
        int rr = (TILE_PX / 2);
        int rr2 = rr * rr;
        if (d2 <= rr2 && dy >= 0) {
            int surf = cy + rr;
            if (d2 > 0) {
                surf = cy + (rr * TILE_PX) / (TILE_PX / 2 + abs(dx));
            }
            if (surf < 0)
                surf = 0;
            if (surf > TILE_PX)
                surf = TILE_PX;
            *angle_out = ANG_FLAT;
            return surf;
        }
        *angle_out = ANG_FLAT;
        return 0;
    }
    default:
        *angle_out = ANG_FLAT;
        return 0;
    }
}

static ColInfo probe_floor(const Level *lv, fx_t x, fx_t y)
{
    ColInfo info = {0, 0, ANG_FLAT};
    int px_x = (int)(x / FX_ONE);
    int px_y = (int)(y / FX_ONE);
    int tx = px_x / TILE_PX;
    int ty = px_y / TILE_PX;
    int best_y = -1;
    int best_ang = ANG_FLAT;

    for (int row = ty; row < lv->h && row <= ty + 3; row++) {
        char c = tile_at(lv, tx, row);
        if (!is_solid_char(c))
            continue;
        int lx = px_x - tx * TILE_PX;
        if (lx < 0)
            lx = 0;
        if (lx >= TILE_PX)
            lx = TILE_PX - 1;
        int ang = ANG_FLAT;
        int local_top = floor_local_y(c, lx, &ang);
        int surf_px = row * TILE_PX + local_top;
        if (surf_px >= px_y - 2 && (best_y < 0 || surf_px < best_y)) {
            best_y = surf_px;
            best_ang = ang;
        }
    }
  /* scan upward if standing inside tile */
    for (int row = ty; row >= 0 && row >= ty - 1; row--) {
        char c = tile_at(lv, tx, row);
        if (!is_solid_char(c))
            continue;
        int lx = px_x - tx * TILE_PX;
        if (lx < 0)
            lx = 0;
        if (lx >= TILE_PX)
            lx = TILE_PX - 1;
        int ang = ANG_FLAT;
        int local_top = floor_local_y(c, lx, &ang);
        int surf_px = row * TILE_PX + local_top;
        if (surf_px >= px_y - TILE_PX && (best_y < 0 || surf_px < best_y)) {
            best_y = surf_px;
            best_ang = ang;
        }
    }

    if (best_y >= 0) {
        info.hit = 1;
        info.surface = px_to_fx(best_y);
        info.angle = best_ang;
    }
    return info;
}

static ColInfo probe_ceiling(const Level *lv, fx_t x, fx_t y)
{
    (void)y;
    ColInfo info = {0, 0, ANG_FLAT};
    int px_x = (int)(x / FX_ONE);
    int tx = px_x / TILE_PX;
    for (int row = 0; row < lv->h; row++) {
        char c = tile_at(lv, tx, row);
        if (!is_solid_char(c))
            continue;
        info.hit = 1;
        info.surface = px_to_fx(row * TILE_PX);
        info.angle = 0;
        break;
    }
    return info;
}

static ColInfo probe_wall(const Level *lv, fx_t x, fx_t y, int dir)
{
    ColInfo info = {0, 0, ANG_FLAT};
    int px_x = (int)(x / FX_ONE);
    int px_y = (int)(y / FX_ONE);
    int tx = px_x / TILE_PX;
    int ty = px_y / TILE_PX;
    int check_tx = tx + (dir > 0 ? 1 : -1);
    char c = tile_at(lv, check_tx, ty);
    if (!is_solid_char(c))
        return info;
    info.hit = 1;
    if (dir > 0)
        info.surface = px_to_fx(check_tx * TILE_PX);
    else
        info.surface = px_to_fx((check_tx + 1) * TILE_PX);
    info.angle = 0;
    return info;
}

static ColInfo col_floor(void *ud, fx_t x, fx_t y)
{
    const LevelColCtx *ctx = (const LevelColCtx *)ud;
    return probe_floor(ctx->lv, x, y);
}

static ColInfo col_ceiling(void *ud, fx_t x, fx_t y)
{
    const LevelColCtx *ctx = (const LevelColCtx *)ud;
    return probe_ceiling(ctx->lv, x, y);
}

static ColInfo col_wall(void *ud, fx_t x, fx_t y, int dir)
{
    const LevelColCtx *ctx = (const LevelColCtx *)ud;
    return probe_wall(ctx->lv, x, y, dir);
}

static void trim_line(char *s)
{
    size_t n = strlen(s);
    while (n > 0 && (s[n - 1] == '\n' || s[n - 1] == '\r' || isspace((unsigned char)s[n - 1]))) {
        s[n - 1] = '\0';
        n--;
    }
    /* skip leading spaces for map rows */
    char *p = s;
    while (*p && isspace((unsigned char)*p))
        p++;
    if (p != s)
        memmove(s, p, strlen(p) + 1);
}

static int parse_start_px(const char *line, fx_t *sx, fx_t *sy)
{
    int px, py;
    if (sscanf(line, "start %d %d", &px, &py) == 2) {
        *sx = FX_FROM_PX(px);
        *sy = FX_FROM_PX(py);
        return 1;
    }
    return 0;
}

int level_load(Level *lv, const char *path)
{
    FILE *f = fopen(path, "r");
    char line[LEVEL_MAX_W + 64];
    int row = 0;
    int max_w = 0;
    int have_start = 0;

    if (!lv || !path || !f)
        return 0;
    memset(lv, 0, sizeof(*lv));
    lv->start_x = FX_FROM_PX(48);
    lv->start_y = FX_FROM_PX(240);

    while (fgets(line, sizeof(line), f)) {
        trim_line(line);
        if (line[0] == '\0')
            continue;
        if (strcmp(line, "---") == 0)
            break;
        if (strncmp(line, "start ", 6) == 0) {
            if (parse_start_px(line, &lv->start_x, &lv->start_y))
                have_start = 1;
            continue;
        }
        if (row >= LEVEL_MAX_H)
            break;
        strncpy(lv->tiles[row], line, LEVEL_MAX_W - 1);
        lv->tiles[row][LEVEL_MAX_W - 1] = '\0';
        int len = (int)strlen(lv->tiles[row]);
        if (len > max_w)
            max_w = len;
        row++;
    }
    fclose(f);

    if (row == 0 || max_w == 0)
        return 0;

    lv->w = max_w;
    lv->h = row;
    (void)have_start;
    return 1;
}

void level_bind(ColWorld *col, const Level *lv)
{
    static LevelColCtx ctx;
    if (!col || !lv)
        return;
    ctx.lv = lv;
    col->ud = &ctx;
    col->floor_at = col_floor;
    col->ceiling_at = col_ceiling;
    col->wall_at = col_wall;
}
