const std = @import("std");
const console = @import("util/console.zig");
const Process = @import("util/Process.zig");
const paths = @import("pointer_paths.zig");
const formatFloat = @import("util/number_formating.zig").formatFloat;

pub fn run() !void {
    const game_proc = try Process.open("MonsterHunterWilds.exe");
    defer game_proc.closeHandle();

    paths.client_weapon.bind(game_proc);
    try paths.client_damage.bindAndResolve(game_proc);
    try paths.player_damage.bindAndResolveAll(game_proc);

    console.setTitle("MHWilds Damage Meter");
    console.setCursorVisible(false);

    while (game_proc.isRunning()) {
        var buffer: [0x100]u8 = undefined;

        //weapon can only be resolved once a character is loaded
        const weapon_resolve = paths.client_weapon.resolve();
        const client_weapon = if (weapon_resolve) paths.client_weapon.readValue(WeaponType) catch return else |_| WeaponType.Undefined;

        const client_damage = paths.client_damage.readValue(f32) catch return;

        console.setCursorXY(1, 1);
        console.setForegroundColor(.White);
        drawRow(client_weapon.toString(), formatFloat(client_damage, &buffer));

        for (0..paths.player_damage.paths.len) |index| {
            var item = paths.player_damage.paths[index];
            const player_damage = item.readValue(f32) catch return;
            const first = std.fmt.bufPrint(&buffer, "Player {d}:", .{index + 1}) catch unreachable;

            console.setCursorXY(1, 3 + @as(u16, @intCast(index)));
            console.setForegroundColor(color_coding[index]);

            drawRow(first, formatFloat(player_damage, &buffer));
        }

        std.Thread.sleep(5e+8);
    }
}

const color_coding = [_]console.ForegroundColors{ .Blue, .Green, .Magenta, .DarkYellow };

inline fn drawRow(first: []const u8, second: []const u8) void {
    console.print("{0s: <16}{1s: >14}\n", .{ first, second });
}

pub const WeaponType = enum(u8) {
    const Self = @This();

    GreatSword = 0,
    SwordAndShield = 1,
    DualBlades = 2,
    LongSword = 3,
    Hammer = 4,
    HuntingHorn = 5,
    Lance = 6,
    GunLance = 7,
    SwitchAxe = 8,
    ChargeBlade = 9,
    InsectGlaive = 10,
    Bow = 11,
    HeavyBowGun = 12,
    LightBowGun = 13,
    Undefined,

    pub fn toString(self: Self) []const u8 {
        return switch (self) {
            .GreatSword => "Great Sword",
            .SwordAndShield => "Sword and Shield",
            .DualBlades => "Dual Blades",
            .LongSword => "Long Sword",
            .Hammer => "Hammer",
            .HuntingHorn => "Hunting Horn",
            .Lance => "Lance",
            .GunLance => "Gun Lance",
            .SwitchAxe => "Switch Axe",
            .ChargeBlade => "Charge Blade",
            .InsectGlaive => "Insect Glaive",
            .Bow => "Bow",
            .HeavyBowGun => "Heavy Bowgun",
            .LightBowGun => "Light Bowgun",
            else => "???",
        };
    }
};
