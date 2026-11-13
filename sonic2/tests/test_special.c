#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../src/objects.h"
#include "../src/player.h"
#include "../src/world.h"

#define SPECIAL_STAGES 7

static int resolve_stage_path(int stage, char *out, size_t out_sz)
{
    const char *patterns[] = {
        "levels/special_stage_%d.txt",
        "../levels/special_stage_%d.txt",
    };
    size_t i;
    for (i = 0; i < sizeof patterns / sizeof patterns[0]; i++) {
        snprintf(out, out_sz, patterns[i], stage);
        FILE *f = fopen(out, "r");
        if (f) {
            fclose(f);
            return 1;
        }
    }
    return 0;
}

static int find_emerald(const Object *objs, int n, fx_t *ex, fx_t *ey)
{
    int i;
    for (i = 0; i < n; i++) {
        if (objs[i].alive && objs[i].kind == OBJ_EMERALD) {
            *ex = objs[i].x;
            *ey = objs[i].y;
            return i;
        }
    }
    return -1;
}

static int finish_stage_gives_emerald(const char *path)
{
    Level lv;
    ColWorld col;
    Object objs[OBJECTS_MAX];
    Player p;
    ObjEvent ev;
    fx_t ex = 0, ey = 0;
    int nobj;
    int ei;
    ColInfo floor;

    if (!level_load(&lv, path)) {
        fprintf(stderr, "FAIL special level_load: %s\n", path);
        return 0;
    }
    if (lv.w < 40 || lv.h < 8) {
        fprintf(stderr, "FAIL special size %dx%d (%s)\n", lv.w, lv.h, path);
        return 0;
    }

    nobj = objects_load(objs, OBJECTS_MAX, path);
    if (nobj <= 0) {
        fprintf(stderr, "FAIL special objects_load: %s\n", path);
        return 0;
    }
    ei = find_emerald(objs, nobj, &ex, &ey);
    if (ei < 0) {
        fprintf(stderr, "FAIL special emerald missing: %s\n", path);
        return 0;
    }

    level_bind(&col, &lv);
    floor = col.floor_at(col.ud, lv.start_x, lv.start_y + FX_ONE);
    if (!floor.hit) {
        fprintf(stderr, "FAIL no floor under special start: %s\n", path);
        return 0;
    }

    memset(&p, 0, sizeof p);
    p.alive = 1;
    p.x = ex;
    p.y = ey;
    p.facing = 1;
    objects_tick(objs, nobj, &p, &ev);
    if (!ev.emerald) {
        fprintf(stderr, "FAIL finish did not award emerald: %s\n", path);
        return 0;
    }
    if (objs[ei].alive) {
        fprintf(stderr, "FAIL emerald still alive after pickup: %s\n", path);
        return 0;
    }
    return 1;
}

int main(void)
{
    char path[128];
    int stage;
    int emeralds = 0;
    const char *single = getenv("SONIC2_SPECIAL");

    if (single && single[0]) {
        if (!finish_stage_gives_emerald(single))
            return 1;
        emeralds = 1;
    } else {
        for (stage = 1; stage <= SPECIAL_STAGES; stage++) {
            if (!resolve_stage_path(stage, path, sizeof path)) {
                fprintf(stderr, "FAIL missing special_stage_%d.txt\n", stage);
                return 1;
            }
            if (!finish_stage_gives_emerald(path))
                return 2;
            emeralds++;
        }
    }

    if (emeralds != SPECIAL_STAGES && !(single && single[0])) {
        fprintf(stderr, "FAIL expected %d emeralds, got %d\n", SPECIAL_STAGES, emeralds);
        return 3;
    }

    /* Checkpoint with 50 rings arms special entry. */
    {
        Object cp;
        Player p;
        ObjEvent ev;
        memset(&cp, 0, sizeof cp);
        memset(&p, 0, sizeof p);
        cp.kind = OBJ_CHECKPOINT;
        cp.alive = 1;
        cp.x = FX_FROM_PX(100);
        cp.y = FX_FROM_PX(100);
        p.alive = 1;
        p.x = cp.x;
        p.y = cp.y;
        p.rings = SPECIAL_RING_THRESHOLD;
        objects_tick(&cp, 1, &p, &ev);
        if (!ev.special_enter) {
            fprintf(stderr, "FAIL checkpoint with %d rings did not enter special\n",
                    SPECIAL_RING_THRESHOLD);
            return 8;
        }
    }

    printf("PASS special: %d finishes -> %d emeralds, checkpoint entry ok\n", emeralds, emeralds);
    return 0;
}
