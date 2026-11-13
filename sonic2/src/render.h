/* sonic2/src/render.h */
#ifndef SONIC2_RENDER_H
#define SONIC2_RENDER_H
#include "player.h"
#include "world.h"
#include "objects.h"
int render_init(const char *asset_dir);
int render_set_tiles(const char *tiles_filename); /* relative to asset_dir */
void render_frame(const Player *p, const Level *lv, const Object *objs, int n,
                  int cam_x, int cam_y, int hud_score, int hud_time_frames,
                  int hud_lives);
void render_title(int blink_on);
void render_zone_menu(const char *const *names, int count, int selected, int blink_on);
void render_shutdown(void);
#endif
