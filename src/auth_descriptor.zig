const fido = @import("fido");
const regs = @import("atsame51j20a/registers.zig").registers;
const flash = @import("atsame51j20a/flash_storage.zig");

const User = fido.User;
const RelyingParty = fido.RelyingParty;

pub fn enableTrng() void {
    // Enable the TRNG bus clock.
    regs.MCLK.APBCMASK.modify(.{ .TRNG_ = 1 });
}

const base_addr: usize = 524288; // 512 KiB
pub var indicator_flash = flash.Flash.new(base_addr, 4);
const ms_addr: usize = 524292; // 512 KiB + 4
pub var master_secret_flash = flash.Flash.new(ms_addr, fido.ms_length);

pub const Data = packed struct {
    magic: u32 = 0xF1D0BABE,
    master_secret: [fido.ms_length]u8 = undefined,
    pin_hash: [32]u8 = undefined,
    sign_ctr: u32 = 0,
    retry_ctr: u8 = 8,
};

pub const Impl = struct {
    // TODO: data to be stored in flash (securely)
    // MASTER_SECRET || PIN || SIGN_COUNTER || RETRIES

    pub fn rand() u32 {
        regs.TRNG.CTRLA.modify(.{ .ENABLE = 1 });
        while (regs.TRNG.INTFLAG.read().DATARDY == 0) {
            // a new random number is generated every
            // 84 CLK_TRNG_APB clock cycles (p. 1421).
        }
        regs.TRNG.CTRLA.modify(.{ .ENABLE = 0 });
        return regs.TRNG.DATA.*;
    }

    pub fn getMs() [fido.ms_length]u8 {
        var x: [fido.ms_length]u8 = undefined;
        master_secret_flash.read(x[0..]);
        return x;
    }

    pub fn createMs() void {
        var x: [4]u8 = undefined;
        indicator_flash.read(x[0..]);
        if (!(x[0] == 0xF1 and x[1] == 0xD0 and x[2] == 0xBA and x[3] == 0xBE)) {
            indicator_flash.erase();
            indicator_flash.write("\xF1\xD0\xBA\xBE");

            var ms: [fido.ms_length]u8 = undefined;
            var i: usize = 0;
            var r: u32 = undefined;
            while (i < fido.ms_length) : (i += 1) {
                if (i % 4 == 0) {
                    // Get a fresh 32 bit integer every 4th iteration.
                    r = rand();
                }

                // The shift value is always between 0 and 24, i.e. int cast will always succeed.
                ms[i] = @intCast(u8, (r >> @intCast(u5, (8 * (i % 4)))) & 0xff);
            }
            master_secret_flash.erase();
            master_secret_flash.write(ms[0..]);
        }

        //master_secret_flash.erase();
        //master_secret_flash.write(&[_]u8{ 0x10, 0x25, 0xdc, 0xed, 0x00, 0x72, 0x85, 0xa2, 0x98, 0xaa, 0xca, 0xfe, 0x7b, 0x1c, 0xc3, 0x83, 0x58, 0x38, 0xcf, 0x7a, 0x19, 0x62, 0xe0, 0x90, 0x5a, 0x36, 0xb2, 0xed, 0xa6, 0x07, 0x3e, 0xe1 });
    }

    pub fn requestPermission(user: ?*const User, rp: ?*const RelyingParty) bool {
        _ = user;
        _ = rp;

        //var i: usize = 0;
        //while (i < 10000000) : (i += 1) {
        //    @import("std").mem.doNotOptimizeAway(i);
        //}
        return true;
    }

    pub fn getSignCount(cred_id: []const u8) u32 {
        _ = cred_id;
        // TODO: preserve this counter!
        const S = struct {
            var i: u32 = 0;
        };

        const x = S.i;
        S.i += 1;
        return x;
    }

    fn retries(s: i8) u8 {
        const S = struct {
            // TODO: make this permanent
            var i: u8 = 8;
        };

        if (s > 0) {
            S.i = 8;
        } else if (s < 0 and S.i > 0) {
            S.i -= 1;
        }

        return S.i;
    }

    pub fn getRetries() u8 {
        return retries(0);
    }

    var pin: [16]u8 = undefined;
    var pin_set: bool = false;

    pub fn getPin() ?[]const u8 {
        if (!pin_set) {
            return null;
        } else {
            return pin[0..];
        }
    }

    pub fn setPin(p: [16]u8) void {
        pin = p;
    }
};

var versions = [_]fido.Versions{fido.Versions.FIDO_2_0};
const Authenticator = fido.Auth(Impl);

pub const auth = Authenticator.initDefault(&versions, [_]u8{ 0xFA, 0x2B, 0x99, 0xDC, 0x9E, 0x39, 0x42, 0x57, 0x8F, 0x92, 0x4A, 0x30, 0xD2, 0x3C, 0x41, 0x18 });
