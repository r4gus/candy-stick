const std = @import("std");
const regs = @import("registers.zig").registers;

const PAGE_SIZE = [_]usize{ 8, 16, 32, 64, 128, 256, 512, 1024 };

pub const Flash = struct {
    page_size: usize = 0,
    pages: usize = 0,
    max_flash: usize = 0,
    row_size: usize = 0,
    flash_address: *u32,
    flash_size: usize,

    pub fn init(self: *@This()) void {
        const ps = PAGE_SIZE[@intCast(usize, regs.NVMCTRL.PARAM.read().PSZ)];
        const p = @intCast(usize, regs.NVMCTRL.PARAM.read().NVMP);
        const mf = ps * p;

        self.page_size = ps;
        self.pages = p;
        self.max_flash = mf;
        self.row_size = mf / 64;
    }

    pub fn new(base_address: usize, size: usize) @This() {
        return .{
            .flash_address = @intToPtr(*u32, base_address),
            .flash_size = size,
        };
    }

    pub fn write(self: *const @This(), data: []const u8) void {
        var p = @ptrCast([*]u32, self.flash_address);

        // Disable automatic page write
        regs.NVMCTRL.CTRLA.modify(.{ .WMODE = 0 });
        while (regs.NVMCTRL.STATUS.read().READY == 0) {}

        // Disable NVMCTRL cache while writing
        const original_CACHEDIS0 = regs.NVMCTRL.CTRLA.read().CACHEDIS0;
        const original_CACHEDIS1 = regs.NVMCTRL.CTRLA.read().CACHEDIS1;
        regs.NVMCTRL.CTRLA.modify(.{ .CACHEDIS0 = 1, .CACHEDIS1 = 1 });

        // write data in pages
        var i: usize = 0;
        while (i < ((self.flash_size + 3) / 4)) {
            // execute page buffer clear
            regs.NVMCTRL.CTRLB.modify(.{ .CMD = 0x15, .CMDEX = 0xA5 });
            while (regs.NVMCTRL.INTFLAG.read().DONE == 0) {}

            var j: usize = 0;
            while (j < (self.page_size / 4) and i < ((self.flash_size + 3) / 4)) : (j += 1) {
                var x: u32 = 0;
                x |= data[i * 4];
                x |= @intCast(u32, data[i * 4 + 1]) << 8;
                x |= @intCast(u32, data[i * 4 + 2]) << 16;
                x |= @intCast(u32, data[i * 4 + 3]) << 24;
                p[i] = x;
                i += 1;
            }

            // execute wp - write page
            regs.NVMCTRL.CTRLB.modify(.{ .CMD = 0x3, .CMDEX = 0xA5 });
            while (regs.NVMCTRL.INTFLAG.read().DONE == 0) {}
            invalidateCmccCache();
            regs.NVMCTRL.CTRLA.modify(.{
                .CACHEDIS0 = original_CACHEDIS0,
                .CACHEDIS1 = original_CACHEDIS1,
            });
        }
    }

    pub fn erase(self: *const @This()) void {
        // Before a page can be written, it must be erased.
        var p = @intCast(u32, @ptrToInt(self.flash_address));
        var s = self.flash_size;

        while (s > self.row_size) : (s -= self.row_size) {
            // Erase block
            regs.NVMCTRL.ADDR.modify(@intCast(u24, p));
            regs.NVMCTRL.CTRLB.modify(.{ .CMD = 0x1, .CMDEX = 0xA5 });
            while (regs.NVMCTRL.INTFLAG.read().DONE == 0) {}
            invalidateCmccCache();

            p += @intCast(u32, self.row_size);
        }
        // Erase block
        regs.NVMCTRL.ADDR.modify(@intCast(u24, p));
        regs.NVMCTRL.CTRLB.modify(.{ .CMD = 0x1, .CMDEX = 0xA5 });
        while (regs.NVMCTRL.INTFLAG.read().DONE == 0) {}
        invalidateCmccCache();
    }

    pub fn read(self: *const @This(), data: []u8) void {
        const p = @ptrCast([*]u8, self.flash_address);
        std.mem.copy(u8, data[0..], p[0..data.len]);
    }

    /// Invalidate all CMCC cache entries if CMCC cache is enabled
    fn invalidateCmccCache() void {
        if (regs.CMCC.SR.read().CSTS != 0) {
            regs.CMCC.CTRL.modify(.{ .CEN = 0 });
            while (regs.CMCC.SR.read().CSTS != 0) {}
            regs.CMCC.MAINT0.modify(.{ .INVALL = 1 });
            regs.CMCC.CTRL.modify(.{ .CEN = 1 });
        }
    }
};
