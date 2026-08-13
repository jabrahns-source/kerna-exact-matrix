const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("kerna-exact-matrix", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "kerna-exact-matrix",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // Unit tests
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run library unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // Example: basic
    const basic_example = b.addExecutable(.{
        .name = "basic",
        .root_source_file = b.path("examples/basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    basic_example.root_module.addImport("kerna-exact-matrix", lib_mod);
    b.installArtifact(basic_example);

    // Example: grid scale demo
    const grid_example = b.addExecutable(.{
        .name = "grid_lmp_scale",
        .root_source_file = b.path("examples/grid_lmp_scale.zig"),
        .target = target,
        .optimize = optimize,
    });
    grid_example.root_module.addImport("kerna-exact-matrix", lib_mod);
    b.installArtifact(grid_example);
}
