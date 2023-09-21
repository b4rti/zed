const std = @import("std");
const TTY = @import("tty.zig").TTY;

pub const TUI = struct {
    tty: TTY,

    pub fn init(tty: TTY) TUI {
        return TUI{
            .tty = tty,
        };
    }

    pub fn deinit(self: *TUI) void {
        _ = self;
    }

    pub fn loop(self: *TUI) !void {
        var keys: [8]u8 = undefined;
        var keys_count: usize = 0;
        while (true) {
            keys_count = try self.tty.read(&keys);
            if (keys_count == 0) {
                break;
            }
            // ESC -> QUIT
            if (keys[0] == 0x1B and keys_count == 1) {
                break;
            }

            // BACKSPACE -> BACKSPACE
            if (keys[0] == 0x7F) {
                try self.tty.writeAll("\x1B[1D \x1B[1D");
                continue;
            }

            // ENTER -> NEWLINE
            if (keys[0] == 0x0D) {
                try self.tty.newLine();
                continue;
            }

            // UP -> UP
            if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x41) {
                try self.tty.moveCursorUp(1);
                continue;
            }

            // DOWN -> DOWN
            if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x42) {
                try self.tty.moveCursorDown(1);
                continue;
            }

            // RIGHT -> RIGHT
            if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x43) {
                try self.tty.moveCursorRight(1);
                continue;
            }

            // LEFT -> LEFT
            if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x44) {
                try self.tty.moveCursorLeft(1);
                continue;
            }

            // F2
            if (keys[0] == 0x1B and keys[1] == 0x4F and keys[2] == 0x51) {
                const term_size = self.tty.getTerminalSize();
                try self.tty.writeFmt(
                    "Rows: {}, Cols: {}\r\nPixel Width: {}, Pixel Height: {}\r\n",
                    .{ term_size.rows, term_size.cols, term_size.width, term_size.height },
                );
                continue;
            }

            // F4
            if (keys[0] == 0x1B and keys[1] == 0x4F and keys[2] == 0x53) {
                try self.tty.writeLine("Hello, World!");
                continue;
            }

            // F7
            if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x31 and keys[3] == 0x38 and keys[4] == 0x7E) {
                try self.tty.clearLine();
                continue;
            }

            // F8
            if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x31 and keys[3] == 0x39 and keys[4] == 0x7E) {
                try self.tty.clearScreen();
                continue;
            }

            // F9
            if (keys[0] == 0x1B and keys[1] == 0x5B and keys[2] == 0x32 and keys[3] == 0x30 and keys[4] == 0x7E) {
                try self.tty.moveCursorTo(0, 0);
                continue;
            }

            try self.tty.writeAll(keys[0..keys_count]);
        }
    }
};
