const Self = @This();
const Process = @import("Process.zig");
const imports = @import("../imports.zig");

path: []const usize,
associated_proc: ?Process = null,
cached_address: ?usize = null,
opt_additional_offset: ?usize = null,

pub fn create(path: []const usize, opt_additional_offset: ?usize) Self {
    return .{
        .path = path,
        .opt_additional_offset = opt_additional_offset,
    };
}

pub fn bindAndResolve(self: *Self, proc: Process) !void {
    self.bind(proc);
    try self.resolve();
}

pub fn bind(self: *Self, proc: Process) void {
    self.associated_proc = proc;
}

pub fn resolve(self: *Self) !void {
    if (!(self.path.len > 0)) return error.PathLenghtTooShort;

    const proc = self.associated_proc orelse return error.PathNotBound;

    var current = proc.getBaseAddress() + self.path[0];

    const last_index = self.path.len - 1;
    var index: usize = 0;
    while (index < last_index) : (index += 1) {
        current = readProcMem(usize, proc.getHandle(), current + if (index > 0) self.path[index] else 0) catch return error.FailedToResolvePointerPath;
    }

    current += self.path[last_index];

    if (self.opt_additional_offset) |additional_offset| {
        current += additional_offset;
    }

    self.cached_address = current;
}

pub fn readValue(self: *Self, comptime T: type) !T {
    const proc = self.associated_proc orelse return error.PathNotBound;

    if (self.cached_address == null) {
        try self.resolve();
    }

    const address = self.cached_address.?;

    return try readProcMem(T, proc.getHandle(), address);
}

fn readProcMem(comptime T: type, proc_handle: *anyopaque, address: usize) !T {
    var buffer: [@sizeOf(T)]u8 = undefined;

    const result = imports.ReadProcessMemory(proc_handle, @ptrFromInt(address), @ptrCast(&buffer), @sizeOf(T), null);

    if (result == 0) {
        return error.FailedToReadProcessMemory;
    }

    return @as(*align(@alignOf(u8)) T, @ptrCast(&buffer)).*;
}
