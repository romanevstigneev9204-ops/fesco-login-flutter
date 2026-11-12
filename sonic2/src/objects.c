#include "objects.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HIT_RADIUS FX_FROM_PX(12)

static MonitorKind parse_monitor(const char *s)
{
    if (!s)
        return MON_RINGS;
    if (strcmp(s, "rings") == 0)
        return MON_RINGS;
    if (strcmp(s, "shield") == 0)
        return MON_SHIELD;
    if (strcmp(s, "speed") == 0)
        return MON_SPEED;
    if (strcmp(s, "invincible") == 0)
        return MON_INVINCIBLE;
    if (strcmp(s, "life") == 0)
        return MON_LIFE;
    return MON_RINGS;
}

static fx_t parse_coord(const char *s, int as_fx)
{
    int v = 0;
    if (!s)
        return 0;
    if (sscanf(s, "%d", &v) != 1)
        return 0;
    return as_fx ? (fx_t)v : FX_FROM_PX(v);
}

static int abs_fx(fx_t v) { return v < 0 ? -v : v; }

static int overlap(Player *p, Object *o)
{
    fx_t dx = p->x - o->x;
    fx_t dy = p->y - o->y;
    return abs_fx(dx) < HIT_RADIUS && abs_fx(dy) < HIT_RADIUS;
}

int objects_load(Object *dst, int max, const char *path)
{
    FILE *f;
    char line[256];
    int n = 0;
    int in_objects = 0;

    if (!dst || max <= 0 || !path)
        return 0;

    f = fopen(path, "r");
    if (!f)
        return 0;

    while (fgets(line, sizeof(line), f)) {
        char *nl = strchr(line, '\n');
        if (nl)
            *nl = '\0';
        if (strcmp(line, "---") == 0) {
            in_objects = 1;
            continue;
        }
        if (!in_objects)
            continue;
        if (line[0] == '\0' || line[0] == '#')
            continue;

        char kind[32];
        char ax[32], ay[32], arg[32];
        int fields = sscanf(line, "%31s %31s %31s %31s", kind, ax, ay, arg);
        if (fields < 3)
            continue;
        if (n >= max)
            break;

        Object *o = &dst[n];
        memset(o, 0, sizeof(*o));
        o->alive = 1;

        o->x = parse_coord(ax, 0);
        o->y = parse_coord(ay, 0);

        if (strcmp(kind, "ring") == 0) {
            o->kind = OBJ_RING;
        } else if (strcmp(kind, "monitor") == 0) {
            o->kind = OBJ_MONITOR;
            o->arg = (int)parse_monitor(fields >= 4 ? arg : "rings");
        } else if (strcmp(kind, "spring") == 0) {
            o->kind = OBJ_SPRING;
            if (fields >= 4)
                o->arg = (int)parse_coord(arg, 1);
            else
                o->arg = -2560;
        } else if (strcmp(kind, "spike") == 0) {
            o->kind = OBJ_SPIKE;
        } else if (strcmp(kind, "motobug") == 0) {
            o->kind = OBJ_MOTOBUG;
            if (fields >= 4)
                o->arg = atoi(arg);
            else
                o->arg = 1;
        } else if (strcmp(kind, "checkpoint") == 0) {
            o->kind = OBJ_CHECKPOINT;
        } else if (strcmp(kind, "goal") == 0) {
            o->kind = OBJ_GOAL;
        } else {
            continue;
        }
        n++;
    }
    fclose(f);
    return n;
}

void objects_tick(Object *objs, int n, Player *p, ObjEvent *ev)
{
    int i;
    Object *o;

    if (!ev)
        return;
    memset(ev, 0, sizeof(*ev));
    if (!objs || n <= 0 || !p || !p->alive)
        return;

    for (i = 0; i < n; i++) {
        o = &objs[i];
        if (!o->alive)
            continue;

        switch (o->kind) {
        case OBJ_MOTOBUG:
            o->x += FX_FROM_PX(o->arg);
            if (o->timer++ > 180)
                o->arg = -o->arg;
            if (overlap(p, o) && p->invuln_timer <= 0) {
                ev->hurt = 1;
                p->hurt_timer = 90;
                p->invuln_timer = 120;
            }
            break;
        case OBJ_RING:
            if (overlap(p, o)) {
                o->alive = 0;
                ev->rings_delta += 1;
            }
            break;
        case OBJ_MONITOR:
            if (overlap(p, o) && p->vy >= 0) {
                o->alive = 0;
                switch (o->arg) {
                case MON_RINGS:
                    ev->rings_delta += 10;
                    break;
                case MON_SHIELD:
                    ev->shield = 1;
                    break;
                case MON_SPEED:
                    ev->speed_shoes = 1;
                    break;
                case MON_INVINCIBLE:
                    ev->invincible = 1;
                    break;
                case MON_LIFE:
                    ev->extra_life = 1;
                    break;
                default:
                    break;
                }
            }
            break;
        case OBJ_SPRING:
            if (overlap(p, o) && p->vy >= 0) {
                p->vy = (fx_t)o->arg;
                p->on_ground = 0;
                p->mode = PLAYER_AIR;
            }
            break;
        case OBJ_SPIKE:
            if (overlap(p, o) && p->invuln_timer <= 0) {
                if (p->rings > 0) {
                    ev->rings_delta = -p->rings;
                    p->rings = 0;
                    p->invuln_timer = 120;
                    p->hurt_timer = 90;
                } else {
                    ev->hurt = 1;
                    ev->died = 1;
                }
            }
            break;
        case OBJ_CHECKPOINT:
            if (overlap(p, o))
                o->arg = 1;
            break;
        case OBJ_GOAL:
            if (overlap(p, o))
                ev->goal = 1;
            break;
        default:
            break;
        }
    }
}
