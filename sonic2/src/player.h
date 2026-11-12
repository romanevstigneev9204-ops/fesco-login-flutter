/* sonic2/src/player.h */
#ifndef SONIC2_PLAYER_H
#define SONIC2_PLAYER_H
#include "fixed.h"
#include "input.h"
typedef enum PlayerMode {
    PLAYER_GROUND = 0,
    PLAYER_AIR,
    PLAYER_ROLL,
    PLAYER_SPINDASH,
    PLAYER_HURT,
    PLAYER_DEAD
} PlayerMode;
typedef enum PlayerAnim {
    ANIM_IDLE = 0,
    ANIM_WALK,
    ANIM_RUN,
    ANIM_ROLL,
    ANIM_SPINDASH,
    ANIM_JUMP,
    ANIM_HURT,
    ANIM_LOOK,
    ANIM_CROUCH
} PlayerAnim;
typedef struct ColInfo {
    int hit;
    fx_t surface; /* y for floor/ceiling, x for walls */
    int angle;    /* 0..255 */
} ColInfo;
typedef struct ColWorld {
    void *ud;
    ColInfo (*floor_at)(void *ud, fx_t x, fx_t y);
    ColInfo (*ceiling_at)(void *ud, fx_t x, fx_t y);
    ColInfo (*wall_at)(void *ud, fx_t x, fx_t y, int dir); /* dir -1 left, +1 right */
} ColWorld;
typedef struct Player {
    fx_t x, y;
    fx_t vx, vy;
    fx_t gsp;
    int angle;
    PlayerMode mode;
    PlayerAnim anim;
    int frame;
    int facing; /* +1 right, -1 left */
    int on_ground;
    int rings;
    int hurt_timer;
    int invuln_timer;
    int spindash_rev;
    int control_lock;
    int alive;
} Player;
void player_init(Player *p, fx_t x, fx_t y);
void player_tick(Player *p, const Input *in, const ColWorld *col);
#endif
