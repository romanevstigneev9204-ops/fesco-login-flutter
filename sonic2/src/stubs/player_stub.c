#include "../player.h"

void player_init(Player *p, fx_t x, fx_t y)
{
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

void player_tick(Player *p, const Input *in, const ColWorld *col)
{
    (void)col;
    if (!p->alive)
        return;
    if (in->left)
        p->vx = -FX_FROM_PX(2);
    else if (in->right)
        p->vx = FX_FROM_PX(2);
    else
        p->vx = 0;
    p->x += p->vx;
    if (in->jump_pressed && p->on_ground) {
        p->vy = -FX_FROM_PX(6);
        p->on_ground = 0;
        p->mode = PLAYER_AIR;
        p->anim = ANIM_JUMP;
    }
    if (!p->on_ground) {
        p->vy += FX_ONE / 8;
        p->y += p->vy;
        if (col && col->floor_at) {
            ColInfo f = col->floor_at(col->ud, p->x, p->y);
            if (f.hit && p->y >= f.surface) {
                p->y = f.surface;
                p->vy = 0;
                p->on_ground = 1;
                p->mode = PLAYER_GROUND;
                p->anim = ANIM_IDLE;
            }
        }
    }
}
