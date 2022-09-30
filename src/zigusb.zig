// defined in tinyusb/src/class/hid/hid_device.h
extern fn tud_hid_n_report(instance: u8, report_id: u8, report: [*]const u8, len: u16) bool;

const HidReportType = enum(c_int) {
    // defined in tinyusb/src/class/hid/hid.h
    invalid = 0,
    input,
    output,
    feature,
};

fn tudHidReport(report_id: u8, report: []const u8) bool {
    if (report.len > 65535) {
        return false;
    }

    // Note: the narrowing int cast is safe because of the check above.
    return tud_hid_n_report(0, report_id, report.ptr, @intCast(u16, report.len));
}

export fn tud_hid_set_report_cb(itf: u8, report_id: u8, report_type: HidReportType, buffer: [*]u8, bufsize: u16) void {
    _ = itf;
    _ = report_id;
    _ = report_type;
    _ = buffer;
    _ = bufsize;

    //_ = tud_hid_n_report(0, 0, buffer, bufsize);
    _ = tudHidReport(0, "fuck you bitch!");
}
