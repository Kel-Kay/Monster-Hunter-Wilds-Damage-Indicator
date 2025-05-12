const std = @import("std");

const decimal_seperator = ',';
const thousand_seperator = '.';

pub fn formatFloat(number: f32, buffer: []u8) []const u8 {
    var formated_num_buf: [0xFF]u8 = undefined;
    const formated_num = std.fmt.bufPrint(&formated_num_buf, "{d:.2}", .{number}) catch unreachable;

    @memcpy(
        @as([*]u8, @ptrCast(&buffer[buffer.len - 2])),
        formated_num[formated_num.len - 2 ..],
    );

    buffer[buffer.len - 3] = decimal_seperator;

    const last_fmt_index = formated_num.len - 4;
    var out_index = buffer.len - 3;

    var index: usize = 0;
    var count: usize = 0;

    while (index <= last_fmt_index) : (index += 1) {
        const reverse = last_fmt_index - index;
        if (count == 3 and formated_num[reverse] != '-') {
            out_index -= 1;
            buffer[out_index] = thousand_seperator;
            count = 0;
        }

        out_index -= 1;
        buffer[out_index] = formated_num[reverse];
        count += 1;
    }

    return buffer[out_index..];
}
