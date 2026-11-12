#include "input.h"
#include "objects.h"
#include "player.h"
#include "render.h"
#include "world.h"
#include <SDL.h>
#if defined(_WIN32) || defined(__MINGW32__)
#include <SDL_main.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int platform_init(const char *title);
extern void platform_shutdown(void);
extern void platform_poll_events(void);
extern int platform_should_quit(void);
extern void platform_present(void);
extern int platform_save_ppm(const char *path);
void input_begin_frame(Input *in);
void game_sfx(const char *name);

typedef enum GameState { STATE_TITLE = 0, STATE_LEVEL } GameState;

static void camera_update(int *cam_x, int *cam_y, const Player *p, const Level *lv)
{
    int px = (int)(p->x / FX_ONE);
    int py = (int)(p->y / FX_ONE);
    int target_x = px - 96;
    int target_y = py - 112;
    if (target_x < *cam_x)
        *cam_x = target_x;
    else if (target_x > *cam_x + 16)
        *cam_x += 16;
    else if (target_x < *cam_x)
        *cam_x = target_x;
    else if (target_x > *cam_x)
        *cam_x += 8;

    int dy = target_y - *cam_y;
    if (dy > 4)
        *cam_y += dy / 4;
    else if (dy < -4)
        *cam_y += dy / 4;
    else
        *cam_y = target_y;

    int max_x = lv->w * TILE_PX - 320;
    if (max_x < 0)
        max_x = 0;
    if (*cam_x < 0)
        *cam_x = 0;
    if (*cam_x > max_x)
        *cam_x = max_x;
    int max_y = lv->h * TILE_PX - 224;
    if (max_y < 0)
        max_y = 0;
    if (*cam_y < 0)
        *cam_y = 0;
    if (*cam_y > max_y)
        *cam_y = max_y;
}

static int run_shots(void)
{
    if (platform_init("Sonic 2 — screenshot") != 0)
        return 1;
    if (render_init("assets") != 0) {
        platform_shutdown();
        return 1;
    }

    render_title(1);
    platform_present();
    if (platform_save_ppm("build/shot_title.ppm") != 0)
        fprintf(stderr, "warning: could not write build/shot_title.ppm\n");

    Level lv;
    ColWorld col;
    Player pl;
    Object objs[OBJECTS_MAX];
    level_load(&lv, "levels/emerald_hill_act1.txt");
    level_bind(&col, &lv);
    int nobj = objects_load(objs, OBJECTS_MAX, "levels/emerald_hill_act1.txt");
    player_init(&pl, lv.start_x, lv.start_y);

    Input demo;
    memset(&demo, 0, sizeof demo);
    player_tick(&pl, &demo, &col);
    fx_t stood_y = pl.y;
    fx_t start_x = pl.x;
    fx_t peak_y = pl.y;
    demo.right = 1;
    for (int i = 0; i < 70; i++) {
        demo.jump = (i >= 24 && i <= 55);
        demo.jump_pressed = (i == 24);
        player_tick(&pl, &demo, &col);
        ObjEvent ev;
        objects_tick(objs, nobj, &pl, &ev);
        if (ev.rings_delta > 0)
            pl.rings += ev.rings_delta;
        if (pl.y < peak_y)
            peak_y = pl.y;
    }
    int run_px = (int)((pl.x - start_x) / FX_ONE);
    int jump_px = (int)((stood_y - peak_y) / FX_ONE);
    fprintf(stderr, "playable: run %+d px, jump %+d px, anim %d, grounded %d\n", run_px, jump_px,
            (int)pl.anim, pl.on_ground);
    if (run_px < 16 || jump_px < 12) {
        fprintf(stderr, "motion check failed (expected real player.c on the level)\n");
        render_shutdown();
        platform_shutdown();
        return 1;
    }

    int cam_x = (int)(pl.x / FX_ONE) - 140;
    int cam_y = (int)(pl.y / FX_ONE) - 150;
    int max_x = lv.w * TILE_PX - 320;
    int max_y = lv.h * TILE_PX - 224;
    if (max_x < 0)
        max_x = 0;
    if (max_y < 0)
        max_y = 0;
    if (cam_x < 0)
        cam_x = 0;
    if (cam_y < 0)
        cam_y = 0;
    if (cam_x > max_x)
        cam_x = max_x;
    if (cam_y > max_y)
        cam_y = max_y;

    render_frame(&pl, &lv, objs, nobj, cam_x, cam_y, pl.rings * 100, 70, 3);
    platform_present();
    if (platform_save_ppm("build/shot_level.ppm") != 0)
        fprintf(stderr, "warning: could not write build/shot_level.ppm\n");

    render_shutdown();
    platform_shutdown();
    return 0;
}

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--shot") == 0)
            return run_shots();
    }

    if (platform_init("Sonic 2") != 0)
        return 1;
    if (render_init("assets") != 0) {
        platform_shutdown();
        return 1;
    }

    Level lv;
    ColWorld col;
    Player pl;
    Object objs[OBJECTS_MAX];
    level_load(&lv, "levels/emerald_hill_act1.txt");
    level_bind(&col, &lv);
    int nobj = objects_load(objs, OBJECTS_MAX, "levels/emerald_hill_act1.txt");

    GameState state = STATE_TITLE;
    int title_timer = 0;
    int cam_x = 0, cam_y = 0;
    int score = 0;
    int time_frames = 0;
    int lives = 3;

    player_init(&pl, lv.start_x, lv.start_y);

    const int frame_ms = 1000 / 60;
    uint32_t acc = 0;
    uint32_t last = SDL_GetTicks();

    while (!platform_should_quit()) {
        platform_poll_events();
        Input in;
        input_begin_frame(&in);

        uint32_t now = SDL_GetTicks();
        acc += now - last;
        last = now;

        while (acc >= (uint32_t)frame_ms) {
            acc -= (uint32_t)frame_ms;
            if (state == STATE_TITLE) {
                title_timer++;
                if (in.jump_pressed) {
                    state = STATE_LEVEL;
                    player_init(&pl, lv.start_x, lv.start_y);
                    cam_x = (int)(pl.x / FX_ONE) - 96;
                    cam_y = (int)(pl.y / FX_ONE) - 112;
                }
            } else {
                time_frames++;
                int was_ground = pl.on_ground;
                PlayerMode was_mode = pl.mode;
                fx_t was_vy = pl.vy;
                player_tick(&pl, &in, &col);
                ObjEvent ev;
                objects_tick(objs, nobj, &pl, &ev);
                if (ev.rings_delta > 0) {
                    pl.rings += ev.rings_delta;
                    score += ev.rings_delta * 100;
                    game_sfx("ring");
                }
                if (was_ground && in.jump_pressed && pl.mode == PLAYER_AIR)
                    game_sfx("jump");
                if (was_mode == PLAYER_SPINDASH && pl.mode != PLAYER_SPINDASH)
                    game_sfx("spindash");
                if (!in.jump_pressed && pl.vy <= -2000 && pl.vy < was_vy)
                    game_sfx("spring");
                if (ev.extra_life)
                    lives++;
                if (ev.invincible && pl.invuln_timer < 300)
                    pl.invuln_timer = 300;
                if (ev.hurt)
                    game_sfx("hurt");
                if (ev.died) {
                    lives--;
                    if (lives > 0)
                        player_init(&pl, lv.start_x, lv.start_y);
                    else {
                        lives = 3;
                        score = 0;
                        state = STATE_TITLE;
                    }
                }
                camera_update(&cam_x, &cam_y, &pl, &lv);
                if (ev.goal) {
                    game_sfx("goal");
                    state = STATE_TITLE;
                }
            }
        }

        if (state == STATE_TITLE)
            render_title((title_timer / 30) % 2);
        else
            render_frame(&pl, &lv, objs, nobj, cam_x, cam_y, score, time_frames, lives);

        platform_present();
    }

    render_shutdown();
    platform_shutdown();
    return 0;
}
