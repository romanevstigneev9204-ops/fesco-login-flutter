#include "../objects.h"
#include <stdio.h>
#include <string.h>

int objects_load(Object *dst, int max, const char *path)
{
    FILE *f = fopen(path, "r");
    if (!f)
        return 0;
    char line[256];
    int in_objs = 0;
    int n = 0;
    while (fgets(line, sizeof line, f) && n < max) {
        if (!in_objs) {
            if (line[0] == '-' && line[1] == '-' && line[2] == '-')
                in_objs = 1;
            continue;
        }
        char kind[32];
        int x, y, arg = 0;
        if (sscanf(line, "%31s %d %d %d", kind, &x, &y, &arg) < 3)
            continue;
        Object *o = &dst[n++];
        o->alive = 1;
        o->timer = 0;
        o->x = FX_FROM_PX(x);
        o->y = FX_FROM_PX(y);
        o->arg = arg;
        if (strcmp(kind, "ring") == 0)
            o->kind = OBJ_RING;
        else if (strcmp(kind, "spring") == 0)
            o->kind = OBJ_SPRING;
        else if (strcmp(kind, "monitor") == 0) {
            o->kind = OBJ_MONITOR;
            o->arg = MON_RINGS;
        } else if (strcmp(kind, "motobug") == 0)
            o->kind = OBJ_MOTOBUG;
        else if (strcmp(kind, "checkpoint") == 0)
            o->kind = OBJ_CHECKPOINT;
        else if (strcmp(kind, "goal") == 0)
            o->kind = OBJ_GOAL;
        else if (strcmp(kind, "spike") == 0)
            o->kind = OBJ_SPIKE;
        else
            n--;
    }
    fclose(f);
    return n;
}

void objects_tick(Object *objs, int n, Player *p, ObjEvent *ev)
{
    memset(ev, 0, sizeof(*ev));
    for (int i = 0; i < n; i++) {
        if (!objs[i].alive)
            continue;
        fx_t dx = p->x - objs[i].x;
        fx_t dy = p->y - objs[i].y;
        if (dx < 0)
            dx = -dx;
        if (dy < 0)
            dy = -dy;
        if (dx < FX_FROM_PX(12) && dy < FX_FROM_PX(20)) {
            if (objs[i].kind == OBJ_RING) {
                objs[i].alive = 0;
                ev->rings_delta++;
                p->rings++;
            }
        }
    }
}
