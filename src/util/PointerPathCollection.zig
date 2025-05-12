const Self = @This();
const Process = @import("Process.zig");
const PointerPath = @import("PointerPath.zig");

paths: []PointerPath,

pub fn create(paths: []PointerPath) Self {
    return .{ .paths = paths };
}

pub fn bindAndResolveAll(self: *Self, proc: Process) !void {
    self.bindAll(proc);
    try self.resolveAll();
}

pub fn bindAll(self: *Self, proc: Process) void {
    for (self.paths) |*path| {
        path.associated_proc = proc;
    }
}

pub fn resolveAll(self: *Self) !void {
    for (self.paths) |*path| {
        try path.resolve();
    }
}
