const Self = @This();
const std = @import("std");
const imports = @import("../imports.zig");

proc_id: u32,
proc_handle: *anyopaque,
proc_base_address: usize,

pub fn open(proc_name: []const u8) !Self {
    const utf16name = try std.unicode.utf8ToUtf16LeAllocZ(std.heap.page_allocator, proc_name);
    defer std.heap.page_allocator.free(utf16name);

    const proc_info = try findProcess(utf16name.ptr);

    const proc_handle = imports.OpenProcess(imports.PROCESS_VM_READ | imports.SYNCHRONIZE, imports.FALSE, proc_info.id);

    if (proc_handle == null) {
        return error.FailedToOpenProcess;
    }

    return .{
        .proc_id = proc_info.id,
        .proc_handle = proc_handle.?,
        .proc_base_address = proc_info.base_address,
    };
}

pub fn isRunning(self: Self) bool {
    return imports.WaitForSingleObject(self.proc_handle, 0) != imports.WAIT_OBJECT_0;
}

pub fn closeHandle(self: Self) void {
    _ = imports.CloseHandle(self.proc_handle);
}

pub inline fn getHandle(self: Self) *anyopaque {
    return self.proc_handle;
}

pub inline fn getBaseAddress(self: Self) usize {
    return self.proc_base_address;
}

pub inline fn getId(self: Self) u32 {
    return self.proc_id;
}

const procInfo = struct {
    id: u32,
    base_address: usize,
};

fn findProcess(proc_name: [*:0]const u16) !procInfo {
    const snapshot = imports.CreateToolhelp32Snapshot(imports.TH32CS_SNAPPROCESS, 0);
    if (snapshot == imports.INVALID_HANDLE_VALUE) return error.FailedToCreateSnapshot;
    defer _ = imports.CloseHandle(snapshot);

    var proc_entry = std.mem.zeroes(imports.PROCESSENTRY32W);
    proc_entry.dwSize = @sizeOf(imports.PROCESSENTRY32W);

    var opt_proc_id: ?u32 = null;
    var opt_base_address: ?usize = null;

    if (imports.Process32FirstW(snapshot, &proc_entry) == imports.TRUE) {
        var has_proc = true;

        while (has_proc) {
            if (stringsEqual(@ptrCast(&proc_entry.szExeFile), proc_name)) {
                opt_proc_id = proc_entry.th32ProcessID;

                const mod_snapshot = imports.CreateToolhelp32Snapshot(imports.TH32CS_SNAPMODULE, opt_proc_id.?);
                if (mod_snapshot == imports.INVALID_HANDLE_VALUE) return error.FailedToCreateSnapshot;
                defer _ = imports.CloseHandle(mod_snapshot);

                var mod_entry = std.mem.zeroes(imports.MODULEENTRY32W);
                mod_entry.dwSize = @sizeOf(imports.MODULEENTRY32W);

                if (imports.Module32FirstW(mod_snapshot, &mod_entry) == 0) return error.FailedToGetMainModule;

                opt_base_address = @intFromPtr(mod_entry.modBaseAddr);

                break;
            }

            has_proc = imports.Process32NextW(snapshot, &proc_entry) == imports.TRUE;
        }
    }

    if (opt_proc_id != null and opt_base_address != null) {
        return .{
            .id = opt_proc_id.?,
            .base_address = opt_base_address.?,
        };
    }

    return error.FailedToFindProcess;
}

fn stringsEqual(s1: [*:0]const u16, s2: [*:0]const u16) bool {
    var index: usize = 0;
    var match = s1[index] == s2[index];

    while (match and s1[index] != 0) {
        index += 1;
        match = s1[index] == s2[index];
    }

    return match;
}
