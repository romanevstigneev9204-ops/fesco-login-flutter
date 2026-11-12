#include <stdio.h>
#include <string.h>

#include "../src/objects.h"
#include "../src/player.h"

static void setup_player(Player *p, fx_t x, fx_t y)
{
    memset(p, 0, sizeof(*p));
    p->x = x;
    p->y = y;
    p->alive = 1;
    p->facing = 1;
    p->mode = PLAYER_AIR;
    p->anim = ANIM_ROLL;
    p->vy = FX_FROM_PX(1);
}

int main(void)
{
    Object boss;
    Player p;
    ObjEvent ev;
    int hits;

    memset(&boss, 0, sizeof boss);
    boss.kind = OBJ_BOSS;
    boss.x = FX_FROM_PX(100);
    boss.y = FX_FROM_PX(100);
    boss.alive = 1;
    boss.arg = 8;
    boss.timer = 0;

    setup_player(&p, FX_FROM_PX(100), FX_FROM_PX(100));

    for (hits = 0; hits < 7; hits++) {
        boss.timer = 0;
        objects_tick(&boss, 1, &p, &ev);
        if (!boss.alive || ev.win) {
            fprintf(stderr, "FAIL boss died early at hit %d (arg=%d)\n", hits + 1, boss.arg);
            return 1;
        }
        if (boss.arg != 7 - hits) {
            fprintf(stderr, "FAIL after hit %d remaining=%d want %d\n", hits + 1, boss.arg, 7 - hits);
            return 2;
        }
        /* Separate for i-frames to expire in logic: force clear */
        boss.timer = 0;
        /* Nudge player away then back so continuous overlap still works */
        p.x = FX_FROM_PX(100);
        p.y = FX_FROM_PX(100);
        p.mode = PLAYER_AIR;
        p.anim = ANIM_ROLL;
    }

    boss.timer = 0;
    objects_tick(&boss, 1, &p, &ev);
    if (!ev.win || boss.alive || boss.arg > 0) {
        fprintf(stderr, "FAIL 8th hit did not win (win=%d alive=%d arg=%d)\n", ev.win, boss.alive,
                boss.arg);
        return 3;
    }

    printf("PASS boss: 8 hits -> win\n");
    return 0;
}
