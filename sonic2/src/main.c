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

typedef enum GameState { STATE_TITLE = 0, STATE_ZONE_MENU, STATE_LEVEL } GameState;

typedef struct ZoneInfo {
    const char *name;
    const char *level_path;
    const char *tiles_file;
} ZoneInfo;

static const ZoneInfo ZONES[] = {
    {"Emerald Hill", "levels/emerald_hill_act1.txt", "tiles.png"},
    {"Chemical Plant", "levels/chemical_plant_act1.txt", "tiles_chemical_plant.png"},
    {"Aquatic Ruin", "levels/aquatic_ruin_act1.txt", "tiles_aquatic_ruin.png"},
    {"Casino Night", "levels/casino_night_act1.txt", "tiles_casino_night.png"},
    {"Hill Top", "levels/hill_top_act1.txt", "tiles_hill_top.png"},
    {"Mystic Cave", "levels/mystic_cave_act1.txt", "tiles_mystic_cave.png"},
    {"Oil Ocean", "levels/oil_ocean_act1.txt", "tiles_oil_ocean.png"},
    {"Metropolis", "levels/metropolis_act1.txt", "tiles_metropolis.png"},
    {"Sky Chase", "levels/sky_chase_act1.txt", "tiles_sky_chase.png"},
    {"Wing Fortress", "levels/wing_fortress_act1.txt", "tiles_wing_fortress.png"},
    {"Death Egg", "levels/death_egg_act1.txt", "tiles_death_egg.png"},
};
static const int ZONE_COUNT = (int)(sizeof ZONES / sizeof ZONES[0]);

static const ZoneInfo SPECIALS[] = {
    {"Special", "levels/special_stage_1.txt", "tiles_special.png"},
    {"Special", "levels/special_stage_2.txt", "tiles_special.png"},
    {"Special", "levels/special_stage_3.txt", "tiles_special.png"},
};
static const int SPECIAL_COUNT = (int)(sizeof SPECIALS / sizeof SPECIALS[0]);
static const int MENU_SPECIAL_INDEX = ZONE_COUNT; /* last menu row */
static const int MENU_COUNT = ZONE_COUNT + 1;

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

static void shot_camera(int *cam_x, int *cam_y, const Player *p, const Level *lv)
{
    *cam_x = (int)(p->x / FX_ONE) - 120;
    *cam_y = (int)(p->y / FX_ONE) - 160;
    int max_x = lv->w * TILE_PX - 320;
    int max_y = lv->h * TILE_PX - 224;
    if (max_x < 0)
        max_x = 0;
    if (max_y < 0)
        max_y = 0;
    if (*cam_x < 0)
        *cam_x = 0;
    if (*cam_y < 0)
        *cam_y = 0;
    if (*cam_x > max_x)
        *cam_x = max_x;
    if (*cam_y > max_y)
        *cam_y = max_y;
}

static void save_level_shot(const char *path, const Player *pl, const Level *lv, const Object *objs,
                            int nobj, int time_frames)
{
    int cam_x, cam_y;
    shot_camera(&cam_x, &cam_y, pl, lv);
    render_frame(pl, lv, objs, nobj, cam_x, cam_y, pl->rings * 100, time_frames, 3);
    platform_present();
    if (platform_save_ppm(path) != 0)
        fprintf(stderr, "warning: could not write %s\n", path);
}

static int load_level(Level *lv, ColWorld *col, Object *objs, int *nobj, Player *pl,
                      const ZoneInfo *z, int keep_rings)
{
    int rings = keep_rings ? pl->rings : 0;
    if (!level_load(lv, z->level_path)) {
        fprintf(stderr, "failed to load level: %s\n", z->level_path);
        return -1;
    }
    level_bind(col, lv);
    *nobj = objects_load(objs, OBJECTS_MAX, z->level_path);
    if (render_set_tiles(z->tiles_file) != 0)
        fprintf(stderr, "warning: tiles %s missing, keep previous\n", z->tiles_file);
    player_init(pl, lv->start_x, lv->start_y);
    if (keep_rings)
        pl->rings = rings;
    return 0;
}

static int special_index_for_emeralds(int emerald_count)
{
    if (emerald_count < 0)
        emerald_count = 0;
    if (emerald_count >= SPECIAL_COUNT)
        return SPECIAL_COUNT - 1;
    return emerald_count;
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
    int saved_level = 0;
    int saved_run = 0;
    demo.right = 1;
    for (int i = 0; i < 90 && (!saved_level || !saved_run); i++) {
        player_tick(&pl, &demo, &col);
        ObjEvent ev;
        objects_tick(objs, nobj, &pl, &ev);
        if (ev.rings_delta > 0)
            pl.rings += ev.rings_delta;
        int moved = (int)((pl.x - start_x) / FX_ONE);
        if (!saved_level && pl.on_ground && pl.anim == ANIM_WALK && moved >= 36) {
            save_level_shot("build/shot_level.ppm", &pl, &lv, objs, nobj, i);
            saved_level = 1;
        }
        if (!saved_run && pl.on_ground && pl.anim == ANIM_WALK && moved >= 100) {
            save_level_shot("build/shot_run.ppm", &pl, &lv, objs, nobj, i);
            saved_run = 1;
        }
    }
    if (!saved_level || !saved_run || !pl.on_ground) {
        fprintf(stderr, "ground run shot failed (anim %d grounded %d)\n", (int)pl.anim, pl.on_ground);
        render_shutdown();
        platform_shutdown();
        return 1;
    }
    demo.jump = 1;
    demo.jump_pressed = 1;
    for (int i = 0; i < 40; i++) {
        player_tick(&pl, &demo, &col);
        demo.jump_pressed = 0;
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
    int nobj = 0;
    memset(&lv, 0, sizeof lv);
    memset(objs, 0, sizeof objs);
    memset(&pl, 0, sizeof pl);

    GameState state = STATE_TITLE;
    int title_timer = 0;
    int menu_timer = 0;
    int zone_sel = 0;
    int cam_x = 0, cam_y = 0;
    int score = 0;
    int time_frames = 0;
    int lives = 3;
    int menu_nav_lock = 0;
    int emerald_count = 0;
    int in_special = 0;

    const char *menu_names[16];
    for (int i = 0; i < ZONE_COUNT; i++)
        menu_names[i] = ZONES[i].name;
    menu_names[MENU_SPECIAL_INDEX] = "Special";

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
                if (in.jump_pressed)
                    state = STATE_ZONE_MENU;
            } else if (state == STATE_ZONE_MENU) {
                menu_timer++;
                if (menu_nav_lock > 0)
                    menu_nav_lock--;
                if (menu_nav_lock == 0) {
                    if (in.up) {
                        zone_sel = (zone_sel + MENU_COUNT - 1) % MENU_COUNT;
                        menu_nav_lock = 12;
                    } else if (in.down) {
                        zone_sel = (zone_sel + 1) % MENU_COUNT;
                        menu_nav_lock = 12;
                    }
                }
                if (in.jump_pressed) {
                    int ok = 0;
                    if (zone_sel == MENU_SPECIAL_INDEX) {
                        int si = special_index_for_emeralds(emerald_count);
                        ok = load_level(&lv, &col, objs, &nobj, &pl, &SPECIALS[si], 0) == 0;
                        in_special = 1;
                    } else {
                        ok = load_level(&lv, &col, objs, &nobj, &pl, &ZONES[zone_sel], 0) == 0;
                        in_special = 0;
                    }
                    if (ok) {
                        state = STATE_LEVEL;
                        time_frames = 0;
                        cam_x = (int)(pl.x / FX_ONE) - 96;
                        cam_y = (int)(pl.y / FX_ONE) - 112;
                    }
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
                        in_special = 0;
                        state = STATE_TITLE;
                    }
                }
                camera_update(&cam_x, &cam_y, &pl, &lv);
                if (ev.special_enter && !in_special) {
                    int si = special_index_for_emeralds(emerald_count);
                    if (load_level(&lv, &col, objs, &nobj, &pl, &SPECIALS[si], 1) == 0) {
                        in_special = 1;
                        time_frames = 0;
                        cam_x = (int)(pl.x / FX_ONE) - 96;
                        cam_y = (int)(pl.y / FX_ONE) - 112;
                        game_sfx("goal");
                    }
                }
                if (ev.emerald) {
                    emerald_count++;
                    if (emerald_count > SPECIAL_COUNT)
                        emerald_count = SPECIAL_COUNT;
                    score += 1000;
                    game_sfx("goal");
                    in_special = 0;
                    state = STATE_ZONE_MENU;
                } else if (ev.goal || ev.win) {
                    game_sfx("goal");
                    in_special = 0;
                    state = STATE_ZONE_MENU;
                }
            }
        }

        if (state == STATE_TITLE)
            render_title((title_timer / 30) % 2);
        else if (state == STATE_ZONE_MENU)
            render_zone_menu(menu_names, MENU_COUNT, zone_sel, (menu_timer / 20) % 2);
        else
            render_frame(&pl, &lv, objs, nobj, cam_x, cam_y, score, time_frames, lives);

        platform_present();
    }

    render_shutdown();
    platform_shutdown();
    return 0;
}
