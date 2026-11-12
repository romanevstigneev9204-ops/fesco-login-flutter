#include "render.h"

#include <SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

extern int platform_width(void);
extern int platform_height(void);
extern uint32_t *platform_framebuffer(void);

typedef struct Img {
    int w, h;
    unsigned char *px;
} Img;

typedef struct Clip {
    Uint8 *buf;
    Uint32 len;
} Clip;

static Img g_sonic, g_tiles, g_objects, g_hud, g_title;
static char g_asset_dir[512];
static SDL_AudioDeviceID g_audio;
static SDL_AudioSpec g_audio_spec;
static Clip g_jump, g_ring, g_spindash, g_hurt, g_spring, g_goal;
static int g_assets_ok;

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

static int load_img(Img *im, const char *path)
{
    int n = 0;
    im->px = stbi_load(path, &im->w, &im->h, &n, 4);
    if (!im->px) {
        fprintf(stderr, "png: %s (%s)\n", path, stbi_failure_reason());
        im->w = im->h = 0;
        return -1;
    }
    return 0;
}

static void free_img(Img *im)
{
    if (im->px)
        stbi_image_free(im->px);
    im->px = NULL;
    im->w = im->h = 0;
}

static void blit(const Img *im, int dx, int dy, int sx, int sy, int sw, int sh, int flip)
{
    if (!im->px || sw <= 0 || sh <= 0)
        return;
    for (int j = 0; j < sh; j++) {
        int iy = sy + j;
        if (iy < 0 || iy >= im->h)
            continue;
        for (int i = 0; i < sw; i++) {
            int ix = flip ? (sx + sw - 1 - i) : (sx + i);
            if (ix < 0 || ix >= im->w)
                continue;
            const unsigned char *p = im->px + ((iy * im->w + ix) * 4);
            if (p[3] < 16)
                continue;
            pix(dx + i, dy + j, rgba(p[0], p[1], p[2]));
        }
    }
}

static void blit_full(const Img *im, int dx, int dy)
{
    blit(im, dx, dy, 0, 0, im->w, im->h, 0);
}

static int tile_index(char t)
{
    switch (t) {
    case '#':
        return 0;
    case '/':
        return 1;
    case '\\':
        return 2;
    case 'S':
        return 3;
    case '=':
        return 4;
    case 'L':
        return 5;
    default:
        return -1;
    }
}

static void anim_span(PlayerAnim anim, int *base, int *len)
{
    switch (anim) {
    case ANIM_WALK:
        *base = 1;
        *len = 6;
        break;
    case ANIM_RUN:
        *base = 7;
        *len = 4;
        break;
    case ANIM_ROLL:
    case ANIM_JUMP:
        *base = 11;
        *len = 4;
        break;
    case ANIM_SPINDASH:
        *base = 15;
        *len = 4;
        break;
    case ANIM_HURT:
        *base = 19;
        *len = 1;
        break;
    case ANIM_LOOK:
        *base = 20;
        *len = 1;
        break;
    case ANIM_CROUCH:
        *base = 21;
        *len = 1;
        break;
    case ANIM_IDLE:
    default:
        *base = 0;
        *len = 1;
        break;
    }
}

static void draw_player(const Player *p, int cam_x, int cam_y)
{
    int base = 0, len = 1;
    anim_span(p->anim, &base, &len);
    int frame = base + (len > 0 ? (p->frame % len) : 0);
    int sx = frame * 32;
    int feet_x = (int)(p->x / FX_ONE) - cam_x;
    int feet_y = (int)(p->y / FX_ONE) - cam_y;
    blit(&g_sonic, feet_x - 16, feet_y - 40, sx, 0, 32, 40, p->facing < 0);
}

static void draw_object(const Object *o, int cam_x, int cam_y, int time_frames)
{
    int x = (int)(o->x / FX_ONE) - cam_x;
    int y = (int)(o->y / FX_ONE) - cam_y;
    switch (o->kind) {
    case OBJ_RING: {
        int f = (time_frames / 4) & 7;
        blit(&g_objects, x - 8, y - 8, f * 16, 0, 16, 16, 0);
        break;
    }
    case OBJ_MONITOR: {
        int i = o->arg - 1;
        if (i < 0)
            i = 0;
        if (i > 4)
            i = 4;
        blit(&g_objects, x - 12, y - 24, i * 24, 16, 24, 24, 0);
        break;
    }
    case OBJ_SPRING: {
        int red = o->arg <= -3000;
        blit(&g_objects, x - 8, y - 24, red ? 16 : 0, 40, 16, 24, 0);
        break;
    }
    case OBJ_SPIKE:
        blit(&g_tiles, x - 8, y - 16, 3 * 16, 0, 16, 16, 0);
        break;
    case OBJ_MOTOBUG: {
        int f = (time_frames / 8) & 1;
        blit(&g_objects, x - 16, y - 24, f * 32, 64, 32, 24, o->arg < 0);
        break;
    }
    case OBJ_CHECKPOINT:
        blit(&g_objects, x - 8, y - 32, 0, 64, 16, 32, 0);
        break;
    case OBJ_GOAL:
        blit(&g_objects, x - 16, y - 32, 40, 96, 32, 32, 0);
        break;
    default:
        break;
    }
}

static int hud_glyph(char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c == ':')
        return 10;
    if (c == '-')
        return 11;
    if (c == 'R')
        return 12;
    if (c == 'L')
        return 13;
    if (c == 'T')
        return 14;
    return -1;
}

static void draw_hud_text(int x, int y, const char *s)
{
    for (const char *p = s; *p; p++) {
        int g = hud_glyph(*p);
        if (g >= 0)
            blit(&g_hud, x, y, g * 8, 0, 8, 12, 0);
        x += 8;
    }
}

static void draw_hud(const Player *p, int score, int time_frames, int lives)
{
    char buf[32];
    int sec = time_frames / 60;
    if (sec > 599)
        sec = 599;
    snprintf(buf, sizeof buf, "%06d", score < 0 ? 0 : score);
    draw_hud_text(8, 8, buf);
    snprintf(buf, sizeof buf, "R%03d", p->rings < 0 ? 0 : p->rings);
    draw_hud_text(88, 8, buf);
    snprintf(buf, sizeof buf, "T%02d:%02d", sec / 60, sec % 60);
    draw_hud_text(160, 8, buf);
    snprintf(buf, sizeof buf, "L%d", lives < 0 ? 0 : lives);
    draw_hud_text(248, 8, buf);
}

static void fill_sky(void)
{
    int w = platform_width();
    int h = platform_height();
    uint32_t *fb = platform_framebuffer();
    uint32_t sky = rgba(96, 176, 224);
    for (int i = 0; i < w * h; i++)
        fb[i] = sky;
}

static int open_audio(void)
{
    SDL_AudioSpec want;
    memset(&want, 0, sizeof want);
    want.freq = 22050;
    want.format = AUDIO_S16SYS;
    want.channels = 1;
    want.samples = 1024;
    g_audio = SDL_OpenAudioDevice(NULL, 0, &want, &g_audio_spec, 0);
    if (!g_audio)
        return -1;
    SDL_PauseAudioDevice(g_audio, 0);
    return 0;
}

static int load_clip(Clip *c, const char *path)
{
    SDL_AudioSpec spec;
    Uint8 *buf = NULL;
    Uint32 len = 0;
    memset(c, 0, sizeof(*c));
    if (!SDL_LoadWAV(path, &spec, &buf, &len)) {
        fprintf(stderr, "wav: %s (%s)\n", path, SDL_GetError());
        return -1;
    }
    if (!g_audio) {
        c->buf = buf;
        c->len = len;
        return 0;
    }
    SDL_AudioCVT cvt;
    if (SDL_BuildAudioCVT(&cvt, spec.format, spec.channels, spec.freq, g_audio_spec.format,
                          g_audio_spec.channels, g_audio_spec.freq) < 0) {
        SDL_FreeWAV(buf);
        return -1;
    }
    if (cvt.needed) {
        cvt.len = (int)len;
        cvt.buf = (Uint8 *)SDL_malloc((size_t)len * (size_t)cvt.len_mult);
        if (!cvt.buf) {
            SDL_FreeWAV(buf);
            return -1;
        }
        memcpy(cvt.buf, buf, len);
        SDL_FreeWAV(buf);
        if (SDL_ConvertAudio(&cvt) < 0) {
            SDL_free(cvt.buf);
            return -1;
        }
        c->buf = cvt.buf;
        c->len = (Uint32)cvt.len_cvt;
    } else {
        c->buf = buf;
        c->len = len;
    }
    return 0;
}

static void free_clip(Clip *c)
{
    if (!c->buf)
        return;
    SDL_free(c->buf);
    c->buf = NULL;
    c->len = 0;
}

void game_sfx(const char *name)
{
    const Clip *c = NULL;
    if (!g_audio || !name)
        return;
    if (strcmp(name, "jump") == 0)
        c = &g_jump;
    else if (strcmp(name, "ring") == 0)
        c = &g_ring;
    else if (strcmp(name, "spindash") == 0)
        c = &g_spindash;
    else if (strcmp(name, "hurt") == 0)
        c = &g_hurt;
    else if (strcmp(name, "spring") == 0)
        c = &g_spring;
    else if (strcmp(name, "goal") == 0)
        c = &g_goal;
    if (!c || !c->buf || c->len == 0)
        return;
    SDL_ClearQueuedAudio(g_audio);
    SDL_QueueAudio(g_audio, c->buf, c->len);
}

int render_init(const char *asset_dir)
{
    char path[640];
    const char *dir = asset_dir && asset_dir[0] ? asset_dir : "assets";
    snprintf(g_asset_dir, sizeof g_asset_dir, "%s", dir);
    g_assets_ok = 1;

    snprintf(path, sizeof path, "%s/sonic.png", dir);
    if (load_img(&g_sonic, path) != 0)
        g_assets_ok = 0;
    snprintf(path, sizeof path, "%s/tiles.png", dir);
    if (load_img(&g_tiles, path) != 0)
        g_assets_ok = 0;
    snprintf(path, sizeof path, "%s/objects.png", dir);
    if (load_img(&g_objects, path) != 0)
        g_assets_ok = 0;
    snprintf(path, sizeof path, "%s/hud.png", dir);
    load_img(&g_hud, path);
    snprintf(path, sizeof path, "%s/title.png", dir);
    load_img(&g_title, path);

    if (open_audio() != 0)
        fprintf(stderr, "audio: %s\n", SDL_GetError());
    snprintf(path, sizeof path, "%s/sfx/jump.wav", dir);
    load_clip(&g_jump, path);
    snprintf(path, sizeof path, "%s/sfx/ring.wav", dir);
    load_clip(&g_ring, path);
    snprintf(path, sizeof path, "%s/sfx/spindash.wav", dir);
    load_clip(&g_spindash, path);
    snprintf(path, sizeof path, "%s/sfx/hurt.wav", dir);
    load_clip(&g_hurt, path);
    snprintf(path, sizeof path, "%s/sfx/spring.wav", dir);
    load_clip(&g_spring, path);
    snprintf(path, sizeof path, "%s/sfx/goal.wav", dir);
    load_clip(&g_goal, path);
    return g_assets_ok ? 0 : -1;
}

void render_frame(const Player *p, const Level *lv, const Object *objs, int n, int cam_x,
                  int cam_y, int hud_score, int hud_time_frames, int hud_lives)
{
    fill_sky();
    if (g_tiles.px) {
        for (int ty = 0; ty < lv->h; ty++) {
            for (int tx = 0; tx < lv->w; tx++) {
                int ti = tile_index(lv->tiles[ty][tx]);
                if (ti < 0)
                    continue;
                int sx = tx * TILE_PX - cam_x;
                int sy = ty * TILE_PX - cam_y;
                if (sx <= -TILE_PX || sy <= -TILE_PX || sx >= platform_width() ||
                    sy >= platform_height())
                    continue;
                blit(&g_tiles, sx, sy, ti * 16, 0, 16, 16, 0);
            }
        }
    }
    for (int i = 0; i < n; i++) {
        if (objs[i].alive)
            draw_object(&objs[i], cam_x, cam_y, hud_time_frames);
    }
    if (p->alive && (p->invuln_timer <= 0 || ((p->invuln_timer / 4) & 1) == 0))
        draw_player(p, cam_x, cam_y);
    if (g_hud.px)
        draw_hud(p, hud_score, hud_time_frames, hud_lives);
}

void render_title(int blink_on)
{
    int w = platform_width();
    int h = platform_height();
    if (g_title.px && g_title.w == w && g_title.h == h) {
        blit_full(&g_title, 0, 0);
        if (!blink_on) {
            for (int y = 186; y < 204 && y < h; y++) {
                for (int x = 70; x < 250 && x < w; x++) {
                    uint32_t c = platform_framebuffer()[y * w + x];
                    uint8_t r = (uint8_t)(((c >> 16) & 0xff) / 3);
                    uint8_t g = (uint8_t)(((c >> 8) & 0xff) / 3);
                    uint8_t b = (uint8_t)((c & 0xff) / 3);
                    platform_framebuffer()[y * w + x] = rgba(r, g, b);
                }
            }
        }
        return;
    }
    uint32_t *fb = platform_framebuffer();
    uint32_t bg = rgba(20, 48, 140);
    for (int i = 0; i < w * h; i++)
        fb[i] = bg;
    fill_rect(40, 60, 240, 40, rgba(220, 40, 40));
    if (blink_on)
        fill_rect(100, 150, 120, 10, rgba(255, 255, 255));
}

void render_shutdown(void)
{
    free_img(&g_sonic);
    free_img(&g_tiles);
    free_img(&g_objects);
    free_img(&g_hud);
    free_img(&g_title);
    free_clip(&g_jump);
    free_clip(&g_ring);
    free_clip(&g_spindash);
    free_clip(&g_hurt);
    free_clip(&g_spring);
    free_clip(&g_goal);
    if (g_audio) {
        SDL_CloseAudioDevice(g_audio);
        g_audio = 0;
    }
}
