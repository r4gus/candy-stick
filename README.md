# Candy Stick

CTAP2 firmware

```
src/
  |-ctaphid/
  | |-response.zig  (for generating CTAPHID response packets)
  | |-misc.zig      (helper functions and constants)
  | |-commands.zig  (CTAPHID commands)
  |-zigusb.zig      (entry point and USB callbacks)
```

## Build

To build the project you must have installed the [Zig](https://ziglang.org/) compiler on your system.

You also need the `arm-none-eabi` build tools. 

### Arch

```
sudo pacman -S arm-none-eabi-gcc arm-none-eabi-newlib
```

### Ubuntu

```
sudo apt install gcc-arm-none-eabi
```

> **NOTE**: Without `*-newlib` (Arch) you'll get the `fatal error: stdint.h: No such file or directory
 # include_next <stdint.h>` error.

Also make sure that you've `git` installed. Then just run `./build` from the root directory.

## Flash

To flash the firmware install [edbg](https://github.com/ataradov/edbg) and then just run `./flash` from the 
root directory.

> Note: This project targets the SAM E51 Curiosity Nano, i.e. the
> ATSAME51J20A (ARM Cortex-M4F) chip.

## Tools

To use the tools you need to install `libfido2`.

### Arch

```
sudo pacman -S libfido2
```

### Ubuntu

```
$ sudo apt install libfido2-1 libfido2-dev libfido2-doc fido2-tools
```

### Build from source
```
git clone https://github.com/Yubico/libfido2.git
cd libfido2
cmake -B build
make -C build
sudo make -C build install
```

## Important Notes

* The `ztap` library doesn't sort keys automatically (due to a bug when calling the Zig sort function - program hangs). One must make sure that the returned CBOR is in CTAP canonical CBOR encoding form, e.g. the keys have to be sorted in a specific way. Otherwise libraries like libfido2 will complain.
