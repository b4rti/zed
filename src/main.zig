const std = @import("std");
const TTY = @import("tty.zig").TTY;
const TUI = @import("tui.zig").TUI;

pub fn main() !void {
    var tty = try TTY.init();
    defer tty.deinit();

    var tui = TUI.init(tty);
    defer tui.deinit();

    try tui.loop();
}
