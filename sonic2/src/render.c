#include "render.h"
#include <SDL.h>
#include <stdio.h>
#include <string.h>

extern int platform_width(void);
extern int platform_height(void);
extern uint32_t *platform_framebuffer(void);

static uint32_t rgba(uint8_t r, uint8_t g, uint8_t b)
{
    return 0xff000000u | ((uint32_t)r << 16) | ((uint32_t)g << 8) | b;
}

static void pix(int x, int y, uint32_t c)
{
    int w = platform_width();
    int h = platform_height();
    if (x < 0 || y < 0 || x >= w || y >= h)
        return;
    platform_framebuffer()[y * w + x] = c;
}

static void fill_rect(int x, int y, int rw, int rh, uint32_t c)
{
    for (int j = 0; j < rh; j++)
        for (int i = 0; i < rw; i++)
            pix(x + i, y + j, c);
}

static uint32_t tile_color(char t)
{
    switch (t) {
    case '#':
        return rgba(32, 140, 48);
    case '/':
    case '\\':
        return rgba(48, 160, 64);
    case 'L':
        return rgba(64, 180, 80);
    case 'S':
        return rgba(180, 60, 60);
    case '=':
        return rgba(120, 90, 50);
    case '.':
    default:
        return rgba(96, 176, 224);
    }
}

static void draw_hud(int score, int time_frames, int lives)
{
    fill_rect(8, 8, 120, 10, rgba(0, 0, 96));
    char buf[64];
    snprintf(buf, sizeof buf, "SC:%d T:%d L:%d", score, time_frames / 60, lives);
    int x = 10;
    for (const char *p = buf; *p; p++) {
        fill_rect(x, 9, 5, 7, rgba(255, 255, 128));
        x += 6;
    }
}

static void draw_player_stub(const Player *p, int cam_x, int cam_y)
{
    int sx = (int)(p->x / FX_ONE) - cam_x - 8;
    int sy = (int)(p->y / FX_ONE) - cam_y - 20;
    fill_rect(sx, sy, 16, 20, rgba(40, 80, 220));
    if (p->facing < 0)
        fill_rect(sx, sy + 6, 4, 4, rgba(255, 255, 255));
    else
        fill_rect(sx + 12, sy + 6, 4, 4, rgba(255, 255, 255));
}

static void draw_object(const Object *o, int cam_x, int cam_y)
{
    int sx = (int)(o->x / FX_ONE) - cam_x - 4;
    int sy = (int)(o->y / FX_ONE) - cam_y - 4;
    uint32_t c = rgba(255, 220, 0);
    switch (o->kind) {
    case OBJ_MONITOR:
        c = rgba(200, 40, 40);
        break;
    case OBJ_SPRING:
        c = rgba(240, 200, 0);
        break;
    case OBJ_SPIKE:
        c = rgba(160, 160, 160);
        break;
    case OBJ_MOTOBUG:
        c = rgba(180, 100, 40);
        break;
    case OBJ_CHECKPOINT:
        c = rgba(80, 200, 80);
        break;
    case OBJ_GOAL:
        fill_rect(sx - 4, sy - 20, 16, 28, rgba(240, 240, 240));
        return;
    default:
        break;
    }
    fill_rect(sx, sy, 8, 8, c);
}

int render_init(const char *asset_dir)
{
    (void)asset_dir;
    return 0;
}

void render_frame(const Player *p, const Level *lv, const Object *objs, int n, int cam_x,
                  int cam_y, int hud_score, int hud_time_frames, int hud_lives)
{
    int w = platform_width();
    int h = platform_height();
    uint32_t *fb = platform_framebuffer();
    uint32_t sky = rgba(96, 176, 224);
    for (int i = 0; i < w * h; i++)
        fb[i] = sky;

    for (int ty = 0; ty < lv->h; ty++) {
        for (int tx = 0; tx < lv->w; tx++) {
            char t = lv->tiles[ty][tx];
            if (t == '.')
                continue;
            int sx = tx * TILE_PX - cam_x;
            int sy = ty * TILE_PX - cam_y;
            fill_rect(sx, sy, TILE_PX, TILE_PX, tile_color(t));
        }
    }
    for (int i = 0; i < n; i++)
        if (objs[i].alive)
            draw_object(&objs[i], cam_x, cam_y);
    draw_player_stub(p, cam_x, cam_y);
    draw_hud(hud_score, hud_time_frames, hud_lives);
}

void render_title(int blink_on)
{
    int w = platform_width();
    int h = platform_height();
    uint32_t *fb = platform_framebuffer();
    uint32_t bg = rgba(20, 48, 140);
    for (int i = 0; i < w * h; i++)
        fb[i] = bg;
    fill_rect(40, 60, 240, 40, rgba(220, 40, 40));
    fill_rect(50, 70, 220, 20, rgba(255, 200, 0));
    fill_rect(80, 120, 160, 8, rgba(255, 255, 255));
    if (blink_on)
        fill_rect(100, 150, 120, 10, rgba(255, 255, 255));
}

void render_shutdown(void) {}
