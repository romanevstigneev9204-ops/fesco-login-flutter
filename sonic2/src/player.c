#include "player.h"

/*
 * Sonic the Hedgehog 2 player physics (Sonic Physics Guide, Sonic 2 branch).
 * Constants: https://info.sonicretro.org/SPG:Running https://info.sonicretro.org/SPG:Jumping
 *            https://info.sonicretro.org/SPG:Rolling https://info.sonicretro.org/SPG:Spindash
 */

/* https://info.sonicretro.org/SPG:Running — ground acceleration $0C subpixels/frame² */
#define SONIC_ACCEL 12
/* https://info.sonicretro.org/SPG:Running — deceleration (braking) $80 */
#define SONIC_DECEL 128
/* https://info.sonicretro.org/SPG:Running — top ground speed $600 (6 px/frame) */
#define SONIC_TOP_SPEED 1536
/* https://info.sonicretro.org/SPG:Running — ground friction equals acceleration */
#define SONIC_FRICTION SONIC_ACCEL
/* https://info.sonicretro.org/SPG:Running — air acceleration $18 */
#define SONIC_AIR_ACCEL 24
/* https://info.sonicretro.org/SPG:Jumping — gravity $38 subpixels/frame² */
#define SONIC_GRAVITY 56
/* https://info.sonicretro.org/SPG:Jumping — jump velocity $680 */
#define SONIC_JUMP_SPEED 1664
/* https://info.sonicretro.org/SPG:Jumping — variable jump height cap $400 upward */
#define SONIC_JUMP_REL_CAP 1024
/* https://info.sonicretro.org/SPG:Running — slope factor while walking $20 */
#define SONIC_SLOPE_WALK 32
/* https://info.sonicretro.org/SPG:Rolling — slope factor while rolling $50 */
#define SONIC_SLOPE_ROLL 80
/* https://info.sonicretro.org/SPG:Rolling — roll friction half of acceleration $06 */
#define SONIC_ROLL_FRICTION 6
/* https://info.sonicretro.org/SPG:Rolling — minimum speed to enter roll $80 */
#define SONIC_ROLL_MIN 128
/* https://info.sonicretro.org/SPG:Spindash — charge per jump tap $200, max $800 */
#define SPINDASH_REV_STEP 512
#define SPINDASH_REV_MAX 2048
/* https://info.sonicretro.org/SPG:Spindash — release speed table $800..$C00 */
#define SPINDASH_SPEED_MIN 2048
#define SPINDASH_SPEED_STEP 128

/* 256-angle sine table (same indexing as original games: 0=0, 64=1.0). */
static const int16_t sonic_sin[256] = {
      0,    6,   13,   19,   25,   31,   38,   44,   50,   56,   62,   68,   74,   80,   86,   92,
     98,  104,  109,  115,  121,  126,  132,  137,  142,  147,  152,  157,  162,  167,  172,  177,
    181,  185,  190,  194,  198,  202,  206,  209,  213,  216,  220,  223,  226,  229,  231,  234,
    237,  239,  241,  243,  245,  247,  248,  250,  251,  252,  253,  254,  255,  255,  256,  256,
    256,  256,  256,  255,  255,  254,  253,  252,  251,  250,  248,  247,  245,  243,  241,  239,
    237,  234,  231,  229,  226,  223,  220,  216,  213,  209,  206,  202,  198,  194,  190,  185,
    181,  177,  172,  167,  162,  157,  152,  147,  142,  137,  132,  126,  121,  115,  109,  104,
     98,   92,   86,   80,   74,   68,   62,   56,   50,   44,   38,   31,   25,   19,   13,    6,
      0,   -6,  -13,  -19,  -25,  -31,  -38,  -44,  -50,  -56,  -62,  -68,  -74,  -80,  -86,  -92,
    -98, -104, -109, -115, -121, -126, -132, -137, -142, -147, -152, -157, -162, -167, -172, -177,
   -181, -185, -190, -194, -198, -202, -206, -209, -213, -216, -220, -223, -226, -229, -231, -234,
   -237, -239, -241, -243, -245, -247, -248, -250, -251, -252, -253, -254, -255, -255, -256, -256,
   -256, -256, -256, -255, -255, -254, -253, -252, -251, -250, -248, -247, -245, -243, -241, -239,
   -237, -234, -231, -229, -226, -223, -220, -216, -213, -209, -206, -202, -198, -194, -190, -185,
   -181, -177, -172, -167, -162, -157, -152, -147, -142, -137, -132, -126, -121, -115, -109, -104,
    -98,  -92,  -86,  -80,  -74,  -68,  -62,  -56,  -50,  -44,  -38,  -31,  -25,  -19,  -13,   -6,
};

static int32_t sonic_cos(int angle) {
    return (int32_t)sonic_sin[(angle + 64) & 0xFF];
}

static int32_t sonic_sin_i(int angle) {
    return (int32_t)sonic_sin[angle & 0xFF];
}

static void sync_ground_speed(Player *p) {
    int c = sonic_cos(p->angle);
    int s = sonic_sin_i(p->angle);
    p->vx = (fx_t)((int64_t)p->gsp * c >> 8);
    p->vy = (fx_t)((int64_t)p->gsp * s >> 8);
}

static fx_t spindash_release_speed(int rev) {
    int idx = (rev >> 8) & 0xFF;
    if (idx > 8)
        idx = 8;
    return (fx_t)(SPINDASH_SPEED_MIN + idx * SPINDASH_SPEED_STEP);
}

static void player_update_anim(Player *p) {
    fx_t spd = p->gsp >= 0 ? p->gsp : -p->gsp;
    if (!p->on_ground) {
        p->anim = ANIM_JUMP;
        return;
    }
    switch (p->mode) {
    case PLAYER_SPINDASH:
        p->anim = ANIM_SPINDASH;
        break;
    case PLAYER_ROLL:
        p->anim = ANIM_ROLL;
        break;
    case PLAYER_HURT:
        p->anim = ANIM_HURT;
        break;
    default:
        if (spd >= SONIC_TOP_SPEED - SONIC_ACCEL)
            p->anim = ANIM_RUN;
        else if (spd >= SONIC_ACCEL * 4)
            p->anim = ANIM_WALK;
        else
            p->anim = ANIM_IDLE;
        break;
    }
}

static void slope_resist(Player *p, int rolling) {
    if (p->gsp == 0)
        return;
    int factor = rolling ? SONIC_SLOPE_ROLL : SONIC_SLOPE_WALK;
    int32_t d0 = (sonic_sin_i(p->angle) * factor) >> 8;
    if (p->gsp > 0 && d0 < 0)
        d0 >>= 2;
    else if (p->gsp < 0 && d0 > 0)
        d0 >>= 2;
    p->gsp += (fx_t)d0;
}

static void apply_friction(Player *p, fx_t step) {
    if (p->gsp > 0) {
        p->gsp -= step;
        if (p->gsp < 0)
            p->gsp = 0;
    } else if (p->gsp < 0) {
        p->gsp += step;
        if (p->gsp > 0)
            p->gsp = 0;
    }
}

static void ground_move(Player *p, const Input *in, fx_t accel, fx_t top) {
    if (p->control_lock > 0)
        return;

    if (in->right) {
        p->facing = 1;
        if (p->gsp >= top) {
            if (p->gsp > top)
                p->gsp = top;
        } else {
            p->gsp += accel;
            if (p->gsp > top)
                p->gsp = top;
        }
    } else if (in->left) {
        p->facing = -1;
        if (p->gsp <= -top) {
            if (p->gsp < -top)
                p->gsp = -top;
        } else {
            p->gsp -= accel;
            if (p->gsp < -top)
                p->gsp = -top;
        }
    } else {
        apply_friction(p, SONIC_FRICTION);
    }
}

static void ground_brake(Player *p, const Input *in) {
    if (p->control_lock > 0)
        return;
    if (in->right && p->gsp < 0) {
        p->gsp += SONIC_DECEL;
        if (p->gsp > 0)
            p->gsp = SONIC_ROLL_MIN;
    } else if (in->left && p->gsp > 0) {
        p->gsp -= SONIC_DECEL;
        if (p->gsp < 0)
            p->gsp = -SONIC_ROLL_MIN;
    }
}

static void roll_move(Player *p, const Input *in) {
    if (p->control_lock > 0)
        return;
    if (in->right) {
        p->facing = 1;
        p->gsp -= SONIC_ROLL_FRICTION + 32;
        if (p->gsp < 0)
            p->gsp = 0;
    } else if (in->left) {
        p->facing = -1;
        p->gsp += SONIC_ROLL_FRICTION + 32;
        if (p->gsp > 0)
            p->gsp = 0;
    } else {
        apply_friction(p, SONIC_ROLL_FRICTION);
    }
}

static int try_roll(Player *p, const Input *in) {
    if (in->left || in->right || !in->down)
        return 0;
    fx_t spd = p->gsp >= 0 ? p->gsp : -p->gsp;
    if (spd >= SONIC_ROLL_MIN) {
        p->mode = PLAYER_ROLL;
        return 1;
    }
    return 0;
}

static void try_jump(Player *p, const Input *in) {
    if (!in->jump_pressed || !p->on_ground)
        return;
    if (p->mode == PLAYER_SPINDASH)
        return;

    int ang = p->angle;
    int c = sonic_cos(ang);
    int s = sonic_sin_i(ang);
    p->vy += (fx_t)(-(int64_t)SONIC_JUMP_SPEED * c >> 8);
    p->vx += (fx_t)(-(int64_t)SONIC_JUMP_SPEED * s >> 8);
    p->on_ground = 0;
    p->mode = PLAYER_AIR;
}

static void spindash_tick(Player *p, const Input *in) {
    if (!in->down) {
        fx_t spd = spindash_release_speed(p->spindash_rev);
        p->gsp = p->facing * spd;
        p->spindash_rev = 0;
        p->mode = PLAYER_ROLL;
        sync_ground_speed(p);
        return;
    }
    p->spindash_rev -= p->spindash_rev >> 5;
    if (p->spindash_rev < 0)
        p->spindash_rev = 0;
    if (in->jump_pressed) {
        if (p->spindash_rev == 0 && p->mode != PLAYER_SPINDASH)
            p->mode = PLAYER_SPINDASH;
        p->spindash_rev += SPINDASH_REV_STEP;
        if (p->spindash_rev > SPINDASH_REV_MAX)
            p->spindash_rev = SPINDASH_REV_MAX;
    }
}

static void spindash_start(Player *p, const Input *in) {
    if (!in->down || !in->jump_pressed || !p->on_ground)
        return;
    if (p->mode == PLAYER_SPINDASH) {
        p->spindash_rev += SPINDASH_REV_STEP;
        if (p->spindash_rev > SPINDASH_REV_MAX)
            p->spindash_rev = SPINDASH_REV_MAX;
        return;
    }
    if (p->control_lock > 0)
        return;
    p->mode = PLAYER_SPINDASH;
    p->spindash_rev = 0;
    if (in->jump_pressed)
        spindash_tick(p, in);
}

static void air_control(Player *p, const Input *in) {
    if (p->control_lock > 0)
        return;
    if (in->right) {
        p->facing = 1;
        if (p->vx < SONIC_TOP_SPEED) {
            p->vx += SONIC_AIR_ACCEL;
            if (p->vx > SONIC_TOP_SPEED)
                p->vx = SONIC_TOP_SPEED;
        }
    } else if (in->left) {
        p->facing = -1;
        if (p->vx > -SONIC_TOP_SPEED) {
            p->vx -= SONIC_AIR_ACCEL;
            if (p->vx < -SONIC_TOP_SPEED)
                p->vx = -SONIC_TOP_SPEED;
        }
    }
}

static void jump_height_clip(Player *p, const Input *in) {
    if (in->jump)
        return;
    if (p->vy < -(fx_t)SONIC_JUMP_REL_CAP)
        p->vy = -(fx_t)SONIC_JUMP_REL_CAP;
}

static int land_on_floor(Player *p, const ColWorld *col) {
    ColInfo f = col->floor_at(col->ud, p->x, p->y);
    if (!f.hit)
        return 0;
    if (p->vy < 0)
        return 0;
    if (p->y < f.surface)
        return 0;
    p->y = f.surface;
    p->angle = f.angle;
    p->on_ground = 1;
    int c = sonic_cos(p->angle);
    int s = sonic_sin_i(p->angle);
    if (c != 0 || s != 0) {
        p->gsp = (fx_t)(((int64_t)p->vx * c + (int64_t)p->vy * s) >> 8);
    } else {
        p->gsp = p->vx;
    }
    p->vy = 0;
    sync_ground_speed(p);
    if (p->mode == PLAYER_AIR)
        p->mode = PLAYER_GROUND;
    return 1;
}

static void ground_snap(Player *p, const ColWorld *col) {
    ColInfo f = col->floor_at(col->ud, p->x, p->y);
    if (f.hit && p->y >= f.surface) {
        p->y = f.surface;
        p->angle = f.angle;
        p->on_ground = 1;
    } else {
        p->on_ground = 0;
        p->mode = PLAYER_AIR;
    }
}

void player_init(Player *p, fx_t x, fx_t y) {
    p->x = x;
    p->y = y;
    p->vx = 0;
    p->vy = 0;
    p->gsp = 0;
    p->angle = 0;
    p->mode = PLAYER_GROUND;
    p->anim = ANIM_IDLE;
    p->frame = 0;
    p->facing = 1;
    p->on_ground = 1;
    p->rings = 0;
    p->hurt_timer = 0;
    p->invuln_timer = 0;
    p->spindash_rev = 0;
    p->control_lock = 0;
    p->alive = 1;
}

static void tick_ground(Player *p, const Input *in, const ColWorld *col) {
    spindash_start(p, in);

    if (p->mode == PLAYER_SPINDASH) {
        spindash_tick(p, in);
        sync_ground_speed(p);
        p->x += p->vx;
        p->y += p->vy;
        ground_snap(p, col);
        p->frame++;
        player_update_anim(p);
        return;
    }

    try_jump(p, in);
    if (p->mode == PLAYER_AIR) {
        p->frame++;
        player_update_anim(p);
        return;
    }

    int rolling = (p->mode == PLAYER_ROLL);

    slope_resist(p, rolling);
    if (rolling)
        roll_move(p, in);
    else {
        ground_move(p, in, SONIC_ACCEL, SONIC_TOP_SPEED);
        ground_brake(p, in);
        if (!try_roll(p, in) && p->mode == PLAYER_ROLL && !in->down) {
            fx_t spd = p->gsp >= 0 ? p->gsp : -p->gsp;
            if (spd < SONIC_ROLL_MIN)
                p->mode = PLAYER_GROUND;
        }
    }

    sync_ground_speed(p);
    p->x += p->vx;
    p->y += p->vy;
    ground_snap(p, col);
    p->frame++;
    player_update_anim(p);
}

static void tick_air(Player *p, const Input *in, const ColWorld *col) {
    jump_height_clip(p, in);
    air_control(p, in);
    p->x += p->vx;
    p->y += p->vy;
    p->vy += SONIC_GRAVITY;
    if (land_on_floor(p, col)) {
        p->frame++;
        player_update_anim(p);
        return;
    }
    if (col->floor_at(col->ud, p->x, p->y).hit == 0)
        p->on_ground = 0;
    p->frame++;
    player_update_anim(p);
}

void player_tick(Player *p, const Input *in, const ColWorld *col) {
    if (!p->alive || p->mode == PLAYER_DEAD)
        return;
    if (p->hurt_timer > 0) {
        p->hurt_timer--;
        if (p->hurt_timer == 0 && p->mode == PLAYER_HURT)
            p->mode = p->on_ground ? PLAYER_GROUND : PLAYER_AIR;
    }
    if (p->invuln_timer > 0)
        p->invuln_timer--;
    if (p->control_lock > 0)
        p->control_lock--;

    if (p->mode == PLAYER_HURT) {
        p->x += p->vx;
        p->y += p->vy;
        p->vy += SONIC_GRAVITY;
        land_on_floor(p, col);
        p->frame++;
        return;
    }

    if (p->on_ground && (p->mode == PLAYER_GROUND || p->mode == PLAYER_ROLL || p->mode == PLAYER_SPINDASH))
        tick_ground(p, in, col);
    else {
        if (p->mode == PLAYER_GROUND || p->mode == PLAYER_ROLL || p->mode == PLAYER_SPINDASH)
            p->mode = PLAYER_AIR;
        tick_air(p, in, col);
    }
}
