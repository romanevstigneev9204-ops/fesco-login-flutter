/* sonic2/src/objects.h */
#ifndef SONIC2_OBJECTS_H
#define SONIC2_OBJECTS_H
#include "player.h"
#define OBJECTS_MAX 512
typedef enum ObjKind {
    OBJ_RING = 1,
    OBJ_MONITOR,
    OBJ_SPRING,
    OBJ_SPIKE,
    OBJ_MOTOBUG,
    OBJ_CHECKPOINT,
    OBJ_GOAL,
    OBJ_BOSS,
    OBJ_EMERALD
} ObjKind;
#define SPECIAL_RING_THRESHOLD 50
typedef enum MonitorKind {
    MON_RINGS = 1,
    MON_SHIELD,
    MON_SPEED,
    MON_INVINCIBLE,
    MON_LIFE
} MonitorKind;
typedef struct Object {
    ObjKind kind;
    fx_t x, y;
    int arg; /* monitor kind, spring power in fx per frame, facing */
    int alive;
    int timer;
} Object;
typedef struct ObjEvent {
    int rings_delta;
    int hurt;
    int died;
    int goal;
    int shield;
    int speed_shoes;
    int invincible;
    int extra_life;
    int win; /* boss defeated */
    int special_enter; /* checkpoint with enough rings */
    int emerald;       /* chaos emerald collected in special stage */
} ObjEvent;
int objects_load(Object *dst, int max, const char *path);
void objects_tick(Object *objs, int n, Player *p, ObjEvent *ev);
#endif
