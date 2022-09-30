//--------------------------------------------------------------------+
// Extern
//--------------------------------------------------------------------+

// defined in tinyusb/src/class/hid/hid_device.h
extern fn tud_hid_n_report(instance: u8, report_id: u8, report: [*]const u8, len: u16) bool;
extern fn board_millis() u32;
extern fn board_led_write(state: bool) void;

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

fn tudHidReport(report_id: u8, report: []const u8) bool {
    if (report.len > 65535) {
        return false;
    }

    // Note: the narrowing int cast is safe because of the check above.
    return tud_hid_n_report(0, report_id, report.ptr, @intCast(u16, report.len));
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

    _ = tudHidReport(0, buffer[0..bufsize]);
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
