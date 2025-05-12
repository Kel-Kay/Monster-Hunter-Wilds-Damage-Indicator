const std = @import("std");
const imports = @import("../imports.zig");

pub fn print(comptime fmt: []const u8, args: anytype) void {
    const out = std.io.getStdOut().writer();
    out.print(fmt, args) catch {};
}

pub fn write(bytes: []const u8) void {
    const out = std.io.getStdOut().writer();
    _ = out.write(bytes) catch {};
}

var foregroundColor = ForegroundColors.White;
pub fn setForegroundColor(color: ForegroundColors) void {
    const result = imports.SetConsoleTextAttribute(
        imports.GetStdHandle(imports.STD_OUTPUT_HANDLE),
        @intFromEnum(color),
    );

    if (result != 0) {
        foregroundColor = color;
    }
}

pub fn getForegroundColor() ForegroundColors {
    return foregroundColor;
}

fn getCursorPos(axis: enum { X, Y }) u16 {
    var buffer_info: imports.CONSOLE_SCREEN_BUFFER_INFO = undefined;
    const result = imports.GetConsoleScreenBufferInfo(imports.GetStdHandle(imports.STD_OUTPUT_HANDLE), &buffer_info);

    if (result == 0) {
        return 0;
    }

    return switch (axis) {
        .X => @bitCast(buffer_info.dwCursorPosition.X),
        .Y => @bitCast(buffer_info.dwCursorPosition.Y),
    };
}

pub fn setCursorVisible(visible: bool) void {
    var cursor_info: imports.CONSOLE_CURSOR_INFO = undefined;

    const out_handle = imports.GetStdHandle(imports.STD_OUTPUT_HANDLE);
    const result = imports.GetConsoleCursorInfo(out_handle, &cursor_info);

    if (result != 0) {
        cursor_info.bVisible = @intFromBool(visible);
        _ = imports.SetConsoleCursorInfo(out_handle, &cursor_info);
    }
}

pub fn setTitle(title: []const u8) void {
    const wide = std.unicode.utf8ToUtf16LeAllocZ(std.heap.page_allocator, title) catch return;
    defer std.heap.page_allocator.free(wide);

    _ = imports.SetConsoleTitleW(wide.ptr);
}

pub inline fn getCursorX() u16 {
    return getCursorPos(.X);
}

pub inline fn getCursorY() u16 {
    return getCursorPos(.Y);
}

pub inline fn setCursorY(y: u16) void {
    setCursorPos(getCursorPos(.X), y);
}

pub inline fn setCursorX(x: u16) void {
    setCursorPos(x, getCursorPos(.Y));
}

pub inline fn setCursorXY(x: u16, y: u16) void {
    setCursorPos(x, y);
}

fn setCursorPos(x: u16, y: u16) void {
    _ = imports.SetConsoleCursorPosition(
        imports.GetStdHandle(imports.STD_OUTPUT_HANDLE),
        .{
            .Y = @bitCast(y),
            .X = @bitCast(x),
        },
    );
}

pub const ForegroundColors = enum(u8) {
    Black = 0,
    DarkBlue = 1,
    DarkGreen = 2,
    DarkCyan = 3,
    DarkRed = 4,
    DarkMagenta = 5,
    DarkYellow = 6,
    Gray = 7,
    DarkGray = 8,
    Blue = 9,
    Green = 10,
    Cyan = 11,
    Red = 12,
    Magenta = 13,
    Yellow = 14,
    White = 15,
};
