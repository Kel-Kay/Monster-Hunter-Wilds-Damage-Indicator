const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .windows,
        .os_version_min = .{
            .windows = .win10,
        },
    });

    const optimize = .ReleaseSmall;

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "Monster Hunter Wilds Damage Indicator",
        .root_module = exe_mod,
    });

    exe.addObjectFile(.{ .cwd_relative = "res/icon.res" });

    exe.linkLibC();
    exe.subsystem = .Console;

    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.getInstallStep());

    const run_exe_step = b.step("run", "Run the Executable");
    run_exe_step.dependOn(&run_exe.step);

    b.installArtifact(exe);
}
