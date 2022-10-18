#!/bin/sh

# Compile the Zig part of the app
zig build-obj \
    -target thumb-freestanding-eabihf \
    -mcpu=cortex_m4 \
    -lc \
    --pkg-begin ztap libs/ztap/src/main.zig \
        --pkg-begin zbor libs/ztap/libs/zbor/src/main.zig \
        --pkg-end \
    --pkg-end \
    -freference-trace \
    src/zigusb.zig

# Build the project
make BOARD=same51curiositynano all
