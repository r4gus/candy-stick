#!/bin/bash

./pull-deps.sh

# Compile the Zig part of the app
zig build-obj \
    -target thumb-freestanding-eabihf \
    -mcpu=cortex_m4 \
    -lc \
    --pkg-begin fido libs/fido2/src/main.zig \
        --pkg-begin zbor libs/fido2/libs/zbor/src/main.zig \
        --pkg-end \
    --pkg-end \
    -freference-trace \
    -OReleaseSmall \
    src/main.zig

# Build the project
make BOARD=same51curiositynano all
