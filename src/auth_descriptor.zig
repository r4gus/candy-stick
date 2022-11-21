const ztap = @import("ztap");
const regs = @import("atsame51j20a/registers.zig").registers;

const User = ztap.User;
const RelyingParty = ztap.RelyingParty;

pub fn enableTrng() void {
    // Enable the TRNG bus clock.
    regs.MCLK.APBCMASK.modify(.{ .TRNG_ = 1 });
}

const Impl = struct {
    pub fn rand() u32 {
        regs.TRNG.CTRLA.modify(.{ .ENABLE = 1 });
        while (regs.TRNG.INTFLAG.read().DATARDY == 0) {
            // a new random number is generated every
            // 84 CLK_TRNG_APB clock cycles (p. 1421).
        }
        regs.TRNG.CTRLA.modify(.{ .ENABLE = 0 });
        return regs.TRNG.DATA.*;
    }

    pub fn getMs() [ztap.ms_length]u8 {
        return .{ 0x11, 0x25, 0xdc, 0xed, 0x00, 0x72, 0x95, 0xa2, 0x98, 0x63, 0x68, 0x2d, 0x7b, 0x1c, 0xc3, 0x83, 0x58, 0x38, 0xcf, 0x7a, 0x19, 0x62, 0xe0, 0x90, 0x5a, 0x36, 0xb2, 0xed, 0xa6, 0x07, 0x3e, 0xe1 };
    }

    pub fn createMs() void {}

    pub fn requestPermission(user: *const User, rp: *const RelyingParty) bool {
        _ = user;
        _ = rp;
        return true;
    }
};

var versions = [_]ztap.Versions{ztap.Versions.FIDO_2_0};
const Authenticator = ztap.Auth(Impl);

pub const auth = Authenticator.initDefault(&versions, [_]u8{ 0xFA, 0x2B, 0x99, 0xDC, 0x9E, 0x39, 0x42, 0x57, 0x8F, 0x92, 0x4A, 0x30, 0xD2, 0x3C, 0x41, 0x18 });
