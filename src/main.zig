const std = @import("std");
const ctaphid = @import("fido").ctaphid;

const auth_descriptor = @import("auth_descriptor.zig");
const auth = auth_descriptor.auth;

//--------------------------------------------------------------------+
// Extern
//--------------------------------------------------------------------+

// defined in tinyusb/src/class/hid/hid_device.h

/// Send report to host
extern fn tud_hid_n_report(instance: u8, report_id: u8, report: [*]const u8, len: u16) bool;
/// Check if the interface is ready to use
extern fn tud_hid_n_ready(instance: u8) bool;
extern fn board_millis() u32;
extern fn board_led_write(state: bool) void;
extern fn board_init() void;
extern fn tud_init(rhport: u8) bool;
/// Task function should be called in main/rtos loop, extended version of tudTask.
/// - timeout_ms: milliseconds to wait, zero = no wait, 0xffffffff = wait forever
/// - in_isr: if function is called in ISR
extern fn tud_task_ext(timeout_ms: u32, in_isr: bool) void;

const HidReportType = enum(c_int) {
    // defined in tinyusb/src/class/hid/hid.h
    invalid = 0,
    input,
    output,
    feature,
};

//--------------------------------------------------------------------+
// Wrapper
//--------------------------------------------------------------------+

fn tudHidReady() bool {
    return tud_hid_n_ready(0);
}

fn tudHidReport(report_id: u8, report: []const u8) bool {
    if (report.len > 65535) {
        return false;
    }

    // Note: the narrowing int cast is safe because of the check above.
    return tud_hid_n_report(0, report_id, report.ptr, @intCast(u16, report.len));
}

// Task function should be called in main loop.
fn tudTask() void {
    // UINT32_MAX
    tud_task_ext(0xffffffff, false);
}

//--------------------------------------------------------------------+
// Main
//--------------------------------------------------------------------+

export fn main() void {
    board_init();
    auth_descriptor.init();

    // init device stack on configured roothub port.
    _ = tud_init(0);

    while (true) {
        tudTask(); // tinyusb device task
        led_blinking_task();
    }
}

//--------------------------------------------------------------------+
// MACRO CONSTANT TYPEDEF PROTYPES
//--------------------------------------------------------------------+

/// Blink pattern
/// - 250 ms    : device not mounted
/// - 1000 ms   : device mounted
/// - 2500 ms   : device is suspended
const Blink = enum(u32) {
    not_mounted = 250,
    mounted = 1000,
    suspended = 2500,
};

var blink_interval_ms: u32 = @enumToInt(Blink.not_mounted);

//--------------------------------------------------------------------+
// Device callbacks
//--------------------------------------------------------------------+

/// Invoked when device is mounted.
export fn tud_mount_cb() void {
    blink_interval_ms = @enumToInt(Blink.mounted);
}

// Invoked when device is unmounted.
export fn tud_umount_cb() void {
    blink_interval_ms = @enumToInt(Blink.not_mounted);
}

/// Invoked when usb bus is suspended
/// remote_wakeup_en : if host allow us  to perform remote wakeup
/// Within 7ms, device must draw an average of current less than 2.5 mA from bus
export fn tud_suspend_cb(remote_wakeup_en: bool) void {
    _ = remote_wakeup_en;
    blink_interval_ms = @enumToInt(Blink.suspended);
}

// Invoked when usb bus is resumed.
export fn tud_resume_cb() void {
    blink_interval_ms = @enumToInt(Blink.mounted);
}

//--------------------------------------------------------------------+
// USB HID
//--------------------------------------------------------------------+

/// Invoked when received SET_REPORT control request or
/// received data on OUT endpoint ( Report ID = 0, Type = 0 ).
export fn tud_hid_set_report_cb(itf: u8, report_id: u8, report_type: HidReportType, buffer: [*]u8, bufsize: u16) void {
    _ = itf;
    _ = report_id;
    _ = report_type;

    //_ = tudHidReport(0, buffer[0..bufsize]);

    var b: [4098]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&b);
    const allocator = fba.allocator();

    var response = ctaphid.handle(allocator, buffer[0..bufsize], &auth);

    if (response != null) {
        while (response.?.next()) |r| {
            while (!tudHidReady()) {
                tudTask(); // TODO: might lead to strange edge cases but neccessary
                // wait until ready
            }

            _ = tudHidReport(0, r);
        }
    }
}

// Invoked when received GET_REPORT control request.
// Application must fill buffer report's content and return its length.
// Return zero will cause the stack to STALL request.
export fn tud_hid_get_report_cb(itf: u8, report_id: u8, report_type: HidReportType, buffer: [*]u8, reqlen: u16) u16 {
    _ = itf;
    _ = report_id;
    _ = report_type;
    _ = buffer;
    _ = reqlen;

    return 0;
}

//--------------------------------------------------------------------+
// BLINKING TASK
//--------------------------------------------------------------------+

export fn led_blinking_task() void {
    const S = struct {
        var start_ms: u32 = 0;
        var led_state: bool = false;
    };

    if (board_millis() - S.start_ms < blink_interval_ms) return;
    S.start_ms += blink_interval_ms;

    board_led_write(S.led_state);
    S.led_state = !S.led_state;
}
