const std = @import("std");

pub const TTY = struct {
    tty: std.fs.File,
    writer: std.fs.File.Writer,
    previous_termios: std.os.system.termios,
    current_termios: std.os.system.termios,

    pub fn init() !TTY {
        var tty_file = try std.fs.cwd().openFile("/dev/tty", .{ .mode = .read_write });

        var new_tty = TTY{
            .tty = tty_file,
            .writer = tty_file.writer(),
            .previous_termios = try std.os.tcgetattr(tty_file.handle),
            .current_termios = try std.os.tcgetattr(tty_file.handle),
        };
        new_tty.setupTermios();
        try new_tty.setupTerminal();

        return new_tty;
    }

    pub fn deinit(self: *TTY) void {
        self.undoTermios();
        self.undoTerminal();
        self.tty.close();
    }

    fn setupTermios(self: *TTY) void {
        //   ECHO: Stop the terminal from displaying pressed keys.
        // ICANON: Disable canonical ("cooked") input mode. Allows us to read inputs byte-wise instead of line-wise.
        //   ISIG: Disable signals for Ctrl-C (SIGINT) and Ctrl-Z (SIGTSTP), so we can handle them as "normal" escape sequences.
        // IEXTEN: Disable input preprocessing. This allows us to handle Ctrl-V, which would otherwise be intercepted by some terminals.
        self.current_termios.lflag &= ~(std.os.system.ECHO | std.os.system.ICANON | std.os.system.ISIG | std.os.system.IEXTEN);
        //   IXON: Disable software control flow. This allows us to handle Ctrl-S and Ctrl-Q.
        //  ICRNL: Disable converting carriage returns to newlines. Allows us to handle Ctrl-J and Ctrl-M.
        // BRKINT: Disable converting sending SIGINT on break conditions.
        //  INPCK: Disable parity checking.
        // ISTRIP: Disable stripping the 8th bit of characters.
        self.current_termios.iflag &= ~(std.os.system.IXON | std.os.system.ICRNL | std.os.system.BRKINT | std.os.system.INPCK | std.os.system.ISTRIP);
        // Disable output processing.
        self.current_termios.oflag &= ~std.os.system.OPOST;
        // Set the character size to 8 bits per byte.
        self.current_termios.cflag |= std.os.system.CS8;
        // Set the timeout, after which the syscall will return
        self.current_termios.cc[std.os.system.V.TIME] = 0;
        // Set the minimum number of bytes to read before the syscall returns
        self.current_termios.cc[std.os.system.V.MIN] = 1;
        _ = std.os.system.tcsetattr(self.tty.handle, .FLUSH, &self.current_termios);
    }

    fn undoTermios(self: *TTY) void {
        _ = std.os.system.tcsetattr(self.tty.handle, .FLUSH, &self.previous_termios);
    }

    fn setupTerminal(self: *TTY) !void {
        // Save cursor position
        try self.writer.writeAll("\x1B[s");
        // Save screen
        try self.writer.writeAll("\x1B[?47h");
        // Enable alternative buffer
        try self.writer.writeAll("\x1B[?1049h");
        // Clear screen
        try self.writer.writeAll("\x1B[2J");
        // Print something to make sure the screen is cleared
        try self.writer.writeAll(" ");
        // Move cursor to top left
        try self.writer.writeAll("\x1B[H");
        // Set style to bar blink
        try self.writer.writeAll("\x1B[5 q");
    }

    fn undoTerminal(self: *TTY) void {
        // Disable alternative buffer
        self.writer.writeAll("\x1B[?1049l") catch unreachable;
        // Restore screen
        self.writer.writeAll("\x1B[?47l") catch unreachable;
        // Restore cursor position
        self.writer.writeAll("\x1B[u") catch unreachable;
        // Show cursor
        self.writer.writeAll("\x1B[?25h") catch unreachable;
    }

    pub fn getTerminalSize(self: *TTY) TermSize {
        var size: std.os.linux.winsize = undefined;
        _ = std.os.system.ioctl(self.tty.handle, 0x5413, @intFromPtr(&size)); // TIOCGWINSZ = 0x5413
        return TermSize{
            .width = size.ws_xpixel,
            .height = size.ws_ypixel,
            .cols = size.ws_col,
            .rows = size.ws_row,
        };
    }

    pub inline fn writeByte(self: *TTY, c: u8) !void {
        try self.writer.writeByte(c);
    }

    pub inline fn writeByteAt(self: *TTY, c: u8, x: usize, y: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d};{d}H{c}", .{ x, y, c });
    }

    pub inline fn writeAll(self: *TTY, data: []const u8) !void {
        try self.writer.writeAll(data);
    }
    pub inline fn writeAllAt(self: *TTY, data: []const u8, x: usize, y: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d};{d}H{s}", .{ x, y, data });
    }

    pub inline fn writeLine(self: *TTY, data: []const u8) !void {
        try std.fmt.format(self.writer, "\x1B[K{s}\x1B[K\x1B[E", .{data});
    }

    pub inline fn writeLineAt(self: *TTY, data: []const u8, y: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d};1H\x1B[K{s}\x1B[K\x1B[E", .{ y, data });
    }

    pub inline fn writeFmt(self: *TTY, comptime fmt: []const u8, args: anytype) !void {
        try std.fmt.format(self.writer, fmt, args);
    }

    pub inline fn writeFmtAt(self: *TTY, comptime fmt: []const u8, args: anytype, x: usize, y: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d};{d}H" ++ fmt, .{ x, y } ++ args);
    }

    pub inline fn moveCursorTo(self: *TTY, x: usize, y: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d};{d}H", .{ x, y });
    }

    pub inline fn moveCursorLeft(self: *TTY, n: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d}D", .{n});
    }

    pub inline fn moveCursorRight(self: *TTY, n: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d}C", .{n});
    }

    pub inline fn moveCursorUp(self: *TTY, n: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d}A", .{n});
    }

    pub inline fn moveCursorDown(self: *TTY, n: usize) !void {
        try std.fmt.format(self.writer, "\x1B[{d}B", .{n});
    }

    pub inline fn newLine(self: *TTY) !void {
        try self.writer.writeAll("\x1B[K\x1B[E");
    }

    pub inline fn backspace(self: *TTY) !void {
        try self.writer.writeAll("\x08 \x08");
    }

    pub inline fn clearLine(self: *TTY) !void {
        try self.writer.writeAll("\x1B[K");
    }

    pub inline fn clearScreen(self: *TTY) !void {
        try self.writer.writeAll("\x1B[2J");
    }

    pub inline fn setCursorStyle(self: *TTY, style: CursorStyle) !void {
        try std.fmt.format(self.writer, "\x1B[{d} q", style);
    }
};

pub const TermSize = struct {
    width: usize,
    height: usize,
    cols: usize,
    rows: usize,
};

pub const CursorStyle = enum(u8) {
    defualt = 0,
    block_blink = 1,
    block_steady = 2,
    underline_blink = 3,
    underline_steady = 4,
    bar_blink = 5,
    bar_steady = 6,
};
