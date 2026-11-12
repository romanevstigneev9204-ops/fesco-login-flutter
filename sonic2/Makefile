# sonic2 — runtime Makefile (stubs used until real player/world/objects .c exist)
CC_LINUX ?= gcc
CC_WIN   ?= x86_64-w64-mingw32-gcc
BUILD    ?= build
SRC      := src
STUB     := $(SRC)/stubs

UNAME_S := $(shell uname -s 2>/dev/null)
LINUX_CFLAGS  := $(shell pkg-config --cflags sdl2 2>/dev/null)
LINUX_LDFLAGS := $(shell pkg-config --libs sdl2 2>/dev/null)

ifdef SONIC2_MINGW_PREFIX
MINGW_CFLAGS  := -I$(SONIC2_MINGW_PREFIX)/include/SDL2
MINGW_LDFLAGS := -L$(SONIC2_MINGW_PREFIX)/lib -lmingw32 -lSDL2main -lSDL2 -mwindows -static-libgcc
else
MINGW_CFLAGS  := -I/usr/x86_64-w64-mingw32/include/SDL2
MINGW_LDFLAGS := -L/usr/x86_64-w64-mingw32/lib -lmingw32 -lSDL2main -lSDL2 -mwindows -static-libgcc
endif

RUNTIME_SRCS := $(SRC)/main.c $(SRC)/platform.c $(SRC)/render.c $(SRC)/input.c

ifeq ($(wildcard $(SRC)/player.c),)
PLAYER_SRC := $(STUB)/player_stub.c
else
PLAYER_SRC := $(SRC)/player.c
endif

ifeq ($(wildcard $(SRC)/world.c),)
WORLD_SRC := $(STUB)/world_stub.c
else
WORLD_SRC := $(SRC)/world.c
endif

ifeq ($(wildcard $(SRC)/objects.c),)
OBJECTS_SRC := $(STUB)/objects_stub.c
else
OBJECTS_SRC := $(SRC)/objects.c
endif

ALL_SRCS := $(RUNTIME_SRCS) $(PLAYER_SRC) $(WORLD_SRC) $(OBJECTS_SRC)

.PHONY: all linux win clean shots dirs

all: linux

dirs:
	@mkdir -p $(BUILD)

linux: dirs $(BUILD)/sonic2

$(BUILD)/sonic2: $(ALL_SRCS)
	$(CC_LINUX) -std=c11 -Wall -Wextra -O2 -I$(SRC) -Ithird_party $(LINUX_CFLAGS) -o $@ $(ALL_SRCS) $(LINUX_LDFLAGS) -lm

win: dirs $(BUILD)/sonic2.exe

$(BUILD)/sonic2.exe: $(ALL_SRCS)
	$(CC_WIN) -std=c11 -Wall -Wextra -O2 -I$(SRC) -Ithird_party $(MINGW_CFLAGS) -o $@ $(ALL_SRCS) $(MINGW_LDFLAGS) -lm

shots: linux
	@cd $(SRC)/.. && ./build/sonic2 --shot

clean:
	rm -f $(BUILD)/sonic2 $(BUILD)/sonic2.exe
