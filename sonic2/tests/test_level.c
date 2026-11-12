#include <stdio.h>
#include <stdlib.h>

#include "../src/world.h"
#include "../src/objects.h"

#define EXPECT_START_X FX_FROM_PX(88)
#define EXPECT_START_Y FX_FROM_PX(256)
#define EXPECT_GOAL_X FX_FROM_PX(1584)
#define EXPECT_GOAL_Y FX_FROM_PX(220)

static const char *level_path(void)
{
    const char *from_env = getenv("SONIC2_LEVEL");
    if (from_env && from_env[0])
        return from_env;
    return "../levels/emerald_hill_act1.txt";
}

static int find_goal(const Object *objs, int n, fx_t *gx, fx_t *gy)
{
    int i;
    for (i = 0; i < n; i++) {
        if (objs[i].alive && objs[i].kind == OBJ_GOAL) {
            *gx = objs[i].x;
            *gy = objs[i].y;
            return 1;
        }
    }
    return 0;
}

int main(void)
{
    Level lv;
  ColWorld col;
    Object objs[OBJECTS_MAX];
    int nobj;
    fx_t gx = 0, gy = 0;
    ColInfo floor;
    const char *path = level_path();

    if (!level_load(&lv, path)) {
        fprintf(stderr, "FAIL level_load: %s\n", path);
        return 1;
    }
    if (lv.w < 80 || lv.h < 8) {
        fprintf(stderr, "FAIL bad size %dx%d\n", lv.w, lv.h);
        return 2;
    }
    if (lv.start_x != EXPECT_START_X || lv.start_y != EXPECT_START_Y) {
        fprintf(stderr, "FAIL start got (%d,%d) want (%d,%d)\n",
                (int)lv.start_x, (int)lv.start_y, (int)EXPECT_START_X, (int)EXPECT_START_Y);
        return 3;
    }

    nobj = objects_load(objs, OBJECTS_MAX, path);
    if (nobj <= 0) {
        fprintf(stderr, "FAIL objects_load\n");
        return 4;
    }
    if (!find_goal(objs, nobj, &gx, &gy)) {
        fprintf(stderr, "FAIL goal missing\n");
        return 5;
    }
    if (gx != EXPECT_GOAL_X || gy != EXPECT_GOAL_Y) {
        fprintf(stderr, "FAIL goal got (%d,%d) want (%d,%d)\n", (int)gx, (int)gy,
                (int)EXPECT_GOAL_X, (int)EXPECT_GOAL_Y);
        return 6;
    }

    level_bind(&col, &lv);
    floor = col.floor_at(col.ud, lv.start_x, lv.start_y + FX_ONE);
    if (!floor.hit) {
        fprintf(stderr, "FAIL no floor under start\n");
        return 7;
    }
    if (floor.surface > lv.start_y + FX_FROM_PX(4)) {
        fprintf(stderr, "FAIL floor too far below start (surface=%d)\n", (int)floor.surface);
        return 8;
    }

    printf("PASS level test: %dx%d start ok goal ok floor ok\n", lv.w, lv.h);
    return 0;
}
