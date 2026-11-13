#include <stdio.h>
#include <stdlib.h>
#include "../src/player.h"

typedef struct MockFloor {
    fx_t surface_y;
    int angle;
    int probe_below;
} MockFloor;

static ColInfo mock_floor_at(void *ud, fx_t x, fx_t y) {
    (void)x;
    MockFloor *f = (MockFloor *)ud;
    ColInfo c = {0};
    fx_t max_y = f->surface_y + FX_FROM_PX(64);
    if (!f->probe_below) {
        if (y >= f->surface_y) {
            c.hit = 1;
            c.surface = f->surface_y;
            c.angle = f->angle;
        }
        return c;
    }
    if (y >= f->surface_y && y <= max_y) {
        c.hit = 1;
        c.surface = f->surface_y;
        c.angle = f->angle;
    }
    return c;
}

static ColInfo mock_no_ceiling(void *ud, fx_t x, fx_t y) {
    (void)ud;
    (void)x;
    (void)y;
    return (ColInfo){0};
}

static ColInfo mock_no_wall(void *ud, fx_t x, fx_t y, int dir) {
    (void)ud;
    (void)x;
    (void)y;
    (void)dir;
    return (ColInfo){0};
}

static ColWorld mock_col(MockFloor *f) {
    ColWorld col;
    col.ud = f;
    col.floor_at = mock_floor_at;
    col.ceiling_at = mock_no_ceiling;
    col.wall_at = mock_no_wall;
    return col;
}

static Input input_right(void) {
    Input in = {0};
    in.right = 1;
    return in;
}

static Input input_empty(void) {
    Input in = {0};
    return in;
}

static int test_acceleration(void) {
    MockFloor floor = { .surface_y = FX_FROM_PX(100), .angle = 0 };
    ColWorld col = mock_col(&floor);
    Player p;
    player_init(&p, FX_FROM_PX(50), floor.surface_y);

    Input right = input_right();
    int frames = 0;
    while (p.gsp < 1536 && frames < 200) {
        player_tick(&p, &right, &col);
        frames++;
    }
    if (p.gsp != 1536) {
        fprintf(stderr, "accel: expected top speed 1536, got %d after %d frames\n", (int)p.gsp,
                frames);
        return 1;
    }
    if (frames != 128) {
        fprintf(stderr, "accel: expected 128 frames to top speed, got %d\n", frames);
        return 1;
    }
    return 0;
}

static int test_jump_height(void) {
    MockFloor floor = { .surface_y = FX_FROM_PX(100), .angle = 0 };
    ColWorld col = mock_col(&floor);
    Player p;
    player_init(&p, FX_FROM_PX(50), floor.surface_y);

    Input jump = {0};
    jump.jump = 1;
    jump.jump_pressed = 1;
    player_tick(&p, &jump, &col);

    fx_t start_y = p.y;
    fx_t peak = start_y;
    jump.jump_pressed = 0;

    for (int i = 0; i < 120; i++) {
        player_tick(&p, &jump, &col);
        if (p.y < peak)
            peak = p.y;
        if (p.on_ground && i > 2)
            break;
    }

    fx_t rise = start_y - peak;
    /* Full held jump on flat: ~100 px (25560 subpixels) per SPG gravity integration */
    fx_t expect_min = FX_FROM_PX(98);
    fx_t expect_max = FX_FROM_PX(101);
    if (rise < expect_min || rise > expect_max) {
        fprintf(stderr, "jump: rise %d subpx (%.2f px), expected ~100 px\n", (int)rise,
                rise / 256.0);
        return 1;
    }
    return 0;
}

static int test_spindash_faster_than_run(void) {
    MockFloor floor = { .surface_y = FX_FROM_PX(100), .angle = 0 };
    ColWorld col = mock_col(&floor);
    Player p;
    player_init(&p, FX_FROM_PX(50), floor.surface_y);

    Input charge = {0};
    charge.down = 1;
    for (int i = 0; i < 8; i++) {
        charge.jump_pressed = 1;
        player_tick(&p, &charge, &col);
        charge.jump_pressed = 0;
    }

    charge.down = 0;
    player_tick(&p, &charge, &col);

    fx_t dash = p.gsp >= 0 ? p.gsp : -p.gsp;
    if (dash <= 1536) {
        fprintf(stderr, "spindash: release speed %d should exceed top run %d\n", (int)dash, 1536);
        return 1;
    }
    if (dash != 3072) {
        fprintf(stderr, "spindash: full charge expected 3072 ($C00), got %d\n", (int)dash);
        return 1;
    }
    return 0;
}

static int test_slope_changes_speed(void) {
    MockFloor flat = { .surface_y = FX_FROM_PX(100), .angle = 0 };
    ColWorld col_flat = mock_col(&flat);
    Player a;
    Input right = input_right();
    player_init(&a, FX_FROM_PX(50), flat.surface_y);
    for (int i = 0; i < 60; i++)
        player_tick(&a, &right, &col_flat);

    /* $20 = gentle downward slope to the right (SPG angle units) */
    MockFloor slope = { .surface_y = FX_FROM_PX(100), .angle = 0x20 };
    ColWorld col_slope = mock_col(&slope);
    Player b;
    player_init(&b, FX_FROM_PX(50), slope.surface_y);
    b.angle = 0x20;
    for (int i = 0; i < 60; i++)
        player_tick(&b, &right, &col_slope);

    if (b.gsp <= a.gsp) {
        fprintf(stderr, "slope: downhill gsp %d should exceed flat %d after 60 frames\n", (int)b.gsp,
                (int)a.gsp);
        return 1;
    }
    return 0;
}

static int test_gravity_each_frame(void) {
    MockFloor floor = { .surface_y = FX_FROM_PX(200), .angle = 0, .probe_below = 0 };
    ColWorld col = mock_col(&floor);
    Player p;
    player_init(&p, FX_FROM_PX(50), FX_FROM_PX(50));

    Input jump = {0};
    jump.jump = 1;
    jump.jump_pressed = 1;
    player_tick(&p, &jump, &col);
    jump.jump_pressed = 0;

    /* In air above floor — no landing */
    Input empty = input_empty();
    for (int i = 0; i < 5; i++)
        player_tick(&p, &empty, &col);

    for (int step = 0; step < 5; step++) {
        fx_t before = p.vy;
        player_tick(&p, &empty, &col);
        if (p.on_ground)
            break;
        if (p.vy - before != 56) {
            fprintf(stderr, "gravity: frame %d vy delta %d, expected +56\n", step, (int)(p.vy - before));
            return 1;
        }
    }
    return 0;
}

int main(void) {
    struct {
        const char *name;
        int (*fn)(void);
    } tests[] = {
        { "acceleration_to_top_speed", test_acceleration },
        { "jump_height", test_jump_height },
        { "spindash_faster_than_run", test_spindash_faster_than_run },
        { "slope_speed", test_slope_changes_speed },
        { "gravity_per_frame", test_gravity_each_frame },
    };
    int failed = 0;
    for (size_t i = 0; i < sizeof(tests) / sizeof(tests[0]); i++) {
        int r = tests[i].fn();
        if (r != 0) {
            fprintf(stderr, "FAIL: %s\n", tests[i].name);
            failed++;
        } else {
            printf("PASS: %s\n", tests[i].name);
        }
    }
    return failed ? EXIT_FAILURE : EXIT_SUCCESS;
}
