#include "input.h"
#include <SDL.h>
#include <string.h>

extern const uint8_t *platform_keyboard_state(int *nkeys);

static int s_jump_was;

void input_begin_frame(Input *in)
{
    memset(in, 0, sizeof(*in));
    int nkeys = 0;
    const uint8_t *ks = platform_keyboard_state(&nkeys);
    in->left = ks[SDL_SCANCODE_LEFT] || ks[SDL_SCANCODE_A];
    in->right = ks[SDL_SCANCODE_RIGHT] || ks[SDL_SCANCODE_D];
    in->up = ks[SDL_SCANCODE_UP] || ks[SDL_SCANCODE_W];
    in->down = ks[SDL_SCANCODE_DOWN] || ks[SDL_SCANCODE_S];
    in->jump = ks[SDL_SCANCODE_SPACE] || ks[SDL_SCANCODE_Z] || ks[SDL_SCANCODE_RETURN];
    in->jump_pressed = in->jump && !s_jump_was;
    s_jump_was = in->jump;
}
