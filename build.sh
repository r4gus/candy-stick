#!/bin/sh

# Compile the Zig part of the app
zig build-obj \
    -target thumb-freestanding-eabihf \
    -mcpu=cortex_m4 \
    -lc \
    src/zigusb.zig

# Build the project
make BOARD=same51curiositynano all
