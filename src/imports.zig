pub usingnamespace @cImport({
    @cDefine("WINVER", "0x0A00");
    @cDefine("WIN32_LEAN_AND_MEAN", "");
    @cInclude("windows.h");
    @cInclude("tlhelp32.h");
});

pub const L = @import("std").unicode.utf8ToUtf16LeStringLiteral;
