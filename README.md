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

Then just run `./build` from the root directory.

## Flash

To flash the firmware just run `./flash` from the root directory.

> Note: This project targets the SAM E51 Curiosity Nano, i.e. the
> ATSAME51J20A (ARM Cortex-M4F) chip.

## Important Notes

* The `ztap` library doesn't sort keys automatically (due to a bug when calling the Zig sort function - program hangs). One must make sure that the returned CBOR is in CTAP canonical CBOR encoding form, e.g. the keys have to be sorted in a specific way. Otherwise libraries like libfido2 will complain.
