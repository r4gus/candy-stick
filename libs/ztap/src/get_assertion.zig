const std = @import("std");
const cbor = @import("zbor");
const PublicKeyCredentialDescriptor = @import("public_key_credential_descriptor.zig").PublicKeyCredentialDescriptor;
const AuthenticatorOptions = @import("auth_options.zig").AuthenticatorOptions;

pub const GetAssertionParam = struct {
    /// rpId: Relying party identifier.
    @"1": []const u8,
    /// clientDataHash: Hash of the serialized client data collected by the host.
    @"2_b": []const u8,
    /// allowList: A sequence of PublicKeyCredentialDescriptor structures, each
    /// denoting a credential, as specified in [WebAuthN]. If this parameter is
    /// present and has 1 or more entries, the authenticator MUST only generate
    /// an assertion using one of the denoted credentials.
    @"3": ?[]const PublicKeyCredentialDescriptor = null,
    // TODO: add remaining fields (extensions 0x4)
    /// options: Parameters to influence authenticator operation.
    @"5": ?AuthenticatorOptions = null,
    /// pinAuth: First 16 bytes of HMAC-SHA-256 of clientDataHash using pinToken
    /// which platform got from the authenticator:
    /// HMAC-SHA-256(pinToken, clientDataHash).
    @"6": ?[16]u8 = null,
    /// pinProtocol: PIN protocol version selected by client.
    @"7": ?u8 = null,
};
