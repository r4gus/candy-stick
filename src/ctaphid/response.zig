const std = @import("std");
const ctaphid = @import("../ctaphid.zig");
const misc = @import("misc.zig");
const command = @import("command.zig");

/// Size of a USB full speed packet
pub const PACKET_SIZE = 64;
/// Size of the initialization packet header
pub const IP_HEADER_SIZE = 7;
/// Size of the continuation packet header
pub const CP_HEADER_SIZE = 5;

pub const IP_DATA_SIZE = PACKET_SIZE - IP_HEADER_SIZE;
pub const CP_DATA_SIZE = PACKET_SIZE - CP_HEADER_SIZE;

const CMD_OFFSET = misc.CID_LENGTH;
const BCNT_OFFSET = CMD_OFFSET + command.CMD_LENGTH;
const IP_DATA_OFFSET = BCNT_OFFSET + misc.BCNT_LENGTH;
const SEQ_OFFSET = misc.CID_LENGTH;
const CP_DATA_OFFSET = SEQ_OFFSET + misc.SEQ_LENGTH;

const COMMAND_ID = 0x80;

pub const CtapHidResponseIterator = struct {
    cntr: usize,
    seq: misc.Seq,
    buffer: [PACKET_SIZE]u8,
    data: []const u8,
    cid: misc.Cid,
    cmd: command.Cmd,

    pub fn next(self: *@This()) ?[]const u8 {
        if (self.cntr < self.data.len) {
            // Zero the whole buffer
            std.mem.set(u8, self.buffer[0..], 0);

            var len: usize = undefined;
            var off: usize = undefined;
            if (self.cntr == 0) { // initialization packet
                len = if (self.data.len <= IP_DATA_SIZE) self.data.len else IP_DATA_SIZE;
                off = IP_DATA_OFFSET;

                misc.intToSlice(self.buffer[0..misc.CID_LENGTH], self.cid);
                self.buffer[CMD_OFFSET] = @enumToInt(self.cmd) | COMMAND_ID;
                misc.intToSlice(self.buffer[BCNT_OFFSET .. BCNT_OFFSET + misc.BCNT_LENGTH], @intCast(misc.Bcnt, self.data.len));
            } else {
                len = if (self.data.len - self.cntr <= CP_DATA_SIZE) self.data.len - self.cntr else CP_DATA_SIZE;
                off = CP_DATA_OFFSET;

                misc.intToSlice(self.buffer[0..misc.CID_LENGTH], self.cid);
                self.buffer[SEQ_OFFSET] = self.seq;

                self.seq += 1;
            }

            std.mem.copy(u8, self.buffer[off..], self.data[self.cntr .. self.cntr + len]);
            self.cntr += len;

            return self.buffer[0..];
        } else {
            return null;
        }
    }
};

pub fn iterator(
    cid: misc.Cid,
    cmd: command.Cmd,
    data: []const u8,
) CtapHidResponseIterator {
    return CtapHidResponseIterator{
        .cntr = 0,
        .seq = 0,
        .buffer = undefined,
        .data = data,
        .cid = cid,
        .cmd = cmd,
    };
}

test "Response Iterator 1" {
    const allocator = std.testing.allocator;
    var mem = try allocator.alloc(u8, 57);
    defer allocator.free(mem);

    std.mem.set(u8, mem[0..], 'a');

    var iter = iterator(0x11223344, command.Cmd.init, mem);

    const r1 = iter.next();
    try std.testing.expectEqualSlices(u8, "\x11\x22\x33\x44\x86\x00\x39aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", r1.?);

    try std.testing.expectEqual(null, iter.next());
    try std.testing.expectEqual(null, iter.next());
}

test "Response Iterator 2" {
    const allocator = std.testing.allocator;
    var mem = try allocator.alloc(u8, 17);
    defer allocator.free(mem);

    std.mem.set(u8, mem[0..], 'a');

    var iter = iterator(0x11223344, command.Cmd.init, mem);

    const r1 = iter.next();
    try std.testing.expectEqualSlices(u8, "\x11\x22\x33\x44\x86\x00\x11aaaaaaaaaaaaaaaaa\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", r1.?);

    try std.testing.expectEqual(null, iter.next());
}

test "Response Iterator 3" {
    const allocator = std.testing.allocator;
    var mem = try allocator.alloc(u8, 74);
    defer allocator.free(mem);

    std.mem.set(u8, mem[0..57], 'a');
    std.mem.set(u8, mem[57..74], 'b');

    var iter = iterator(0xcafebabe, command.Cmd.cbor, mem);

    const r1 = iter.next();
    try std.testing.expectEqualSlices(u8, "\xca\xfe\xba\xbe\x90\x00\x4aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", r1.?);

    const r2 = iter.next();
    try std.testing.expectEqualSlices(u8, "\xca\xfe\xba\xbe\x00bbbbbbbbbbbbbbbbb\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", r2.?);

    try std.testing.expectEqual(null, iter.next());
}
