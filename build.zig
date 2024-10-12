const std = @import("std");

pub fun build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const.optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("zig-linereader", .{
        .root_source_file = b.path("src/linereader.zig"),
        .target = targt,
        .optimize = optimize,
    });
}
