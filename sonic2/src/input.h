/* sonic2/src/input.h */
#ifndef SONIC2_INPUT_H
#define SONIC2_INPUT_H
typedef struct Input {
    int left, right, up, down;
    int jump;         /* held */
    int jump_pressed; /* this frame only */
} Input;
#endif
