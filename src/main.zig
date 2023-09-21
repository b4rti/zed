const std = @import("std");
const print = std.debug.print;
const tty = @import("tty.zig");
const tui = @import("tui.zig");

pub fn main() !void {
    var zed_tty = try tty.TTY.init();
    defer zed_tty.deinit();

    var zed_tui = tui.TUI.init(zed_tty);
    defer zed_tui.deinit();

    try zed_tui.loop();
}
