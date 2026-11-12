#include <SDL.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SONIC_W 320
#define SONIC_H 224
#define SONIC_SCALE 3

static SDL_Window *g_win;
static SDL_Renderer *g_ren;
static SDL_Texture *g_tex;
static uint32_t g_framebuf[SONIC_W * SONIC_H];
static int g_quit;
static int g_initialized;

int platform_width(void) { return SONIC_W; }
int platform_height(void) { return SONIC_H; }

uint32_t *platform_framebuffer(void) { return g_framebuf; }

int platform_init(const char *title)
{
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        fprintf(stderr, "SDL_Init: %s\n", SDL_GetError());
        return -1;
    }
    g_win = SDL_CreateWindow(
        title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SONIC_W * SONIC_SCALE,
        SONIC_H * SONIC_SCALE, SDL_WINDOW_SHOWN);
    if (!g_win) {
        fprintf(stderr, "SDL_CreateWindow: %s\n", SDL_GetError());
        return -1;
    }
    g_ren = SDL_CreateRenderer(g_win, -1, SDL_RENDERER_ACCELERATED);
    if (!g_ren) {
        fprintf(stderr, "SDL_CreateRenderer: %s\n", SDL_GetError());
        return -1;
    }
    SDL_RenderSetIntegerScale(g_ren, SDL_TRUE);
    SDL_RenderSetLogicalSize(g_ren, SONIC_W, SONIC_H);
    g_tex = SDL_CreateTexture(g_ren, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
                              SONIC_W, SONIC_H);
    if (!g_tex) {
        fprintf(stderr, "SDL_CreateTexture: %s\n", SDL_GetError());
        return -1;
    }
    memset(g_framebuf, 0, sizeof g_framebuf);
    g_quit = 0;
    g_initialized = 1;
    return 0;
}

void platform_poll_events(void)
{
    SDL_Event ev;
    while (SDL_PollEvent(&ev)) {
        if (ev.type == SDL_QUIT)
            g_quit = 1;
        if (ev.type == SDL_KEYDOWN && ev.key.keysym.sym == SDLK_ESCAPE)
            g_quit = 1;
    }
}

int platform_should_quit(void) { return g_quit; }

void platform_present(void)
{
    SDL_UpdateTexture(g_tex, NULL, g_framebuf, SONIC_W * (int)sizeof(uint32_t));
    SDL_RenderClear(g_ren);
    SDL_RenderCopy(g_ren, g_tex, NULL, NULL);
    SDL_RenderPresent(g_ren);
}

int platform_save_ppm(const char *path)
{
    FILE *f = fopen(path, "wb");
    if (!f)
        return -1;
    fprintf(f, "P6\n%d %d\n255\n", SONIC_W, SONIC_H);
    for (int y = 0; y < SONIC_H; y++) {
        for (int x = 0; x < SONIC_W; x++) {
            uint32_t px = g_framebuf[y * SONIC_W + x];
            uint8_t rgb[3] = {(uint8_t)((px >> 16) & 0xff), (uint8_t)((px >> 8) & 0xff),
                              (uint8_t)(px & 0xff)};
            fwrite(rgb, 1, 3, f);
        }
    }
    fclose(f);
    return 0;
}

const uint8_t *platform_keyboard_state(int *nkeys)
{
    SDL_PumpEvents();
    return SDL_GetKeyboardState(nkeys);
}

void platform_shutdown(void)
{
    if (!g_initialized)
        return;
    if (g_tex)
        SDL_DestroyTexture(g_tex);
    if (g_ren)
        SDL_DestroyRenderer(g_ren);
    if (g_win)
        SDL_DestroyWindow(g_win);
    SDL_Quit();
    g_initialized = 0;
}
