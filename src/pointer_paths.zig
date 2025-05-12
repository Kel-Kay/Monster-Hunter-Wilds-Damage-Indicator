const PointerPath = @import("util/PointerPath.zig");
const PointerPathCollection = @import("util/PointerPathCollection.zig");

const player_count = 4;
const offset_per_player = 0x78;

pub var client_damage = PointerPath.create(
    &.{ 0x13794540, 0x70, 0xE80 },
    null,
);

pub var client_weapon = PointerPath.create(
    &.{ 0x13794540, 0x1B8, 0x98, 0x60, 0x7C },
    null,
);

const first_player_damage = PointerPath.create(
    &.{ 0x13794540, 0x70, 0x1430 },
    null,
);

var players = init: {
    var ret_val: [player_count]PointerPath = undefined;

    for (0..player_count) |index| {
        ret_val[index] = PointerPath.create(
            first_player_damage.path,
            offset_per_player * index,
        );
    }

    break :init ret_val;
};

pub var player_damage = PointerPathCollection.create(&players);
