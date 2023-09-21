const std = @import("std");
const print = std.debug.print;
const tty = @import("tty.zig");

pub fn main() !void {
    var zed_tty = try tty.TTY.init();
    defer zed_tty.deinit();

    while (true) {
        var keys: [8]u8 = undefined;
        var keys_count = try zed_tty.tty.read(&keys);
        if (keys_count == 0) {
            break;
        }
        // ESC -> QUIT
        if (keys[0] == 0x1B and keys_count == 1) {
            break;
        }

        // BACKSPACE -> DELETE
        if (keys[0] == 0x7F) {
            try zed_tty.backspace();
            continue;
        }

        // ENTER -> NEWLINE
        if (keys[0] == 0x0D) {
            try zed_tty.newLine();
            continue;
        }

        // UP -> UP
        if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x41) {
            try zed_tty.moveCursorUp(1);
            continue;
        }

        // DOWN -> DOWN
        if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x42) {
            try zed_tty.moveCursorDown(1);
            continue;
        }

        // RIGHT -> RIGHT
        if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x43) {
            try zed_tty.moveCursorRight(1);
            continue;
        }

        // LEFT -> LEFT
        if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x44) {
            try zed_tty.moveCursorLeft(1);
            continue;
        }

        // F2
        if (keys[0] == 0x1B and keys[1] == 0x4F and keys[2] == 0x51) {
            const term_size = zed_tty.getTerminalSize();
            try zed_tty.writeFmt(
                "Rows: {}, Cols: {}\r\nPixel Width: {}, Pixel Height: {}\r\n",
                .{ term_size.rows, term_size.cols, term_size.width, term_size.height },
            );
            continue;
        }

        // F4
        if (keys[0] == 0x1B and keys[1] == 0x4F and keys[2] == 0x53) {
            try zed_tty.writeLine("Hello, World!");
            continue;
        }

        // F7
        if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x31 and keys[3] == 0x38 and keys[4] == 0x7E) {
            try zed_tty.clearLine();
            continue;
        }

        // F8
        if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x31 and keys[3] == 0x39 and keys[4] == 0x7E) {
            try zed_tty.clearScreen();
            continue;
        }

        // F9
        if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x32 and keys[3] == 0x30 and keys[4] == 0x7E) {
            try zed_tty.moveCursorTo(0, 0);
            continue;
        }

        try zed_tty.writeAll(keys[0..keys_count]);
    }
}
