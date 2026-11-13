#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../src/objects.h"
#include "../src/player.h"
#include "../src/world.h"

static const char *special_path(void)
{
    static const char *candidates[] = {
        "levels/special_stage_1.txt",
        "../levels/special_stage_1.txt",
        NULL,
    };
    const char *from_env = getenv("SONIC2_SPECIAL");
    FILE *f;
    int i;
    if (from_env && from_env[0])
        return from_env;
    for (i = 0; candidates[i]; i++) {
        f = fopen(candidates[i], "r");
        if (f) {
            fclose(f);
            return candidates[i];
        }
    }
    return candidates[0];
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

int main(void)
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
    const char *path = special_path();

    if (!level_load(&lv, path)) {
        fprintf(stderr, "FAIL special level_load: %s\n", path);
        return 1;
    }
    if (lv.w < 40 || lv.h < 8) {
        fprintf(stderr, "FAIL special size %dx%d\n", lv.w, lv.h);
        return 2;
    }

    nobj = objects_load(objs, OBJECTS_MAX, path);
    if (nobj <= 0) {
        fprintf(stderr, "FAIL special objects_load\n");
        return 3;
    }
    ei = find_emerald(objs, nobj, &ex, &ey);
    if (ei < 0) {
        fprintf(stderr, "FAIL special emerald missing\n");
        return 4;
    }

    level_bind(&col, &lv);
    floor = col.floor_at(col.ud, lv.start_x, lv.start_y + FX_ONE);
    if (!floor.hit) {
        fprintf(stderr, "FAIL no floor under special start\n");
        return 5;
    }

    memset(&p, 0, sizeof p);
    p.alive = 1;
    p.x = ex;
    p.y = ey;
    p.facing = 1;
    objects_tick(objs, nobj, &p, &ev);
    if (!ev.emerald) {
        fprintf(stderr, "FAIL finish did not award emerald\n");
        return 6;
    }
    if (objs[ei].alive) {
        fprintf(stderr, "FAIL emerald still alive after pickup\n");
        return 7;
    }

    /* Checkpoint with 50 rings arms special entry. */
    {
        Object cp;
        memset(&cp, 0, sizeof cp);
        cp.kind = OBJ_CHECKPOINT;
        cp.alive = 1;
        cp.x = FX_FROM_PX(100);
        cp.y = FX_FROM_PX(100);
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

    printf("PASS special: pipe loads, emerald awarded, checkpoint entry ok\n");
    return 0;
}
