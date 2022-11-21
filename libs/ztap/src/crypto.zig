const std = @import("std");
const cbor = @import("zbor");

pub const ecdsa = @import("ecdsa.zig");
const EcdsaP256Sha256 = ecdsa.EcdsaP256Sha256;

// https://www.iana.org/assignments/cose/cose.xhtml
pub const CoseId = enum(i16) {
    /// ECDSA P-256 SHA-256
    ES256 = -7,
};

pub const EcdsaPubKey = struct {
    /// kty: Key type
    @"1": u8 = 2,
    /// alg: Algorithm
    @"3": CoseId = CoseId.ES256, // ES256
    /// crv: Identifier of the curve
    @"-1": u8 = 1, // P-256
    /// x-coordinate
    @"-2_b": [32]u8,
    /// y-coordinate
    @"-3_b": [32]u8,

    pub fn new(k: EcdsaP256Sha256.PublicKey) @This() {
        const xy = k.toUncompressedSec1();
        return .{
            .@"-2_b" = xy[1..33].*,
            .@"-3_b" = xy[33..65].*,
        };
    }
};

test "serialize EcdsaP256Key" {
    const k = EcdsaPubKey.new(try EcdsaP256Sha256.PublicKey.fromSec1("\x04\xd9\xf4\xc2\xa3\x52\x13\x6f\x19\xc9\xa9\x5d\xa8\x82\x4a\xb5\xcd\xc4\xd5\x63\x1e\xbc\xfd\x5b\xdb\xb0\xbf\xff\x25\x36\x09\x12\x9e\xef\x40\x4b\x88\x07\x65\x57\x60\x07\x88\x8a\x3e\xd6\xab\xff\xb4\x25\x7b\x71\x23\x55\x33\x25\xd4\x50\x61\x3c\xb5\xbc\x9a\x3a\x52"));

    const allocator = std.testing.allocator;
    var str = std.ArrayList(u8).init(allocator);
    defer str.deinit();

    try cbor.stringify(k, .{ .enum_as_text = false }, str.writer());

    try std.testing.expectEqualStrings("\xa5\x01\x02\x03\x26\x20\x01\x21\x58\x20\xd9\xf4\xc2\xa3\x52\x13\x6f\x19\xc9\xa9\x5d\xa8\x82\x4a\xb5\xcd\xc4\xd5\x63\x1e\xbc\xfd\x5b\xdb\xb0\xbf\xff\x25\x36\x09\x12\x9e\x22\x58\x20\xef\x40\x4b\x88\x07\x65\x57\x60\x07\x88\x8a\x3e\xd6\xab\xff\xb4\x25\x7b\x71\x23\x55\x33\x25\xd4\x50\x61\x3c\xb5\xbc\x9a\x3a\x52", str.items);
}
