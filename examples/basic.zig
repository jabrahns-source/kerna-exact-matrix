//! Basic usage of kerna-exact-matrix
//! Demonstrates pure integer matrix multiplication and determinant.

const std = @import("std");
const kem = @import("kerna-exact-matrix");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 2x2 identity at scale 0
    var id = try kem.Matrix.identity(allocator, 2, 0);
    defer id.deinit();

    // Simple matrix
    var a = try kem.Matrix.init(allocator, 2, 2, 0);
    defer a.deinit();
    try a.set(0, 0, 2);
    try a.set(0, 1, 1);
    try a.set(1, 0, 0);
    try a.set(1, 1, 3);

    // Multiply
    var product = try a.mul(id, allocator);
    defer product.deinit();

    std.debug.print("A * I =\n", .{});
    std.debug.print("  [{d}, {d}]\n", .{ try product.get(0, 0), try product.get(0, 1) });
    std.debug.print("  [{d}, {d}]\n", .{ try product.get(1, 0), try product.get(1, 1) });

    const det = try a.detSmall();
    std.debug.print("det(A) = {d}\n", .{det});

    std.debug.print("\nAll operations used pure integer arithmetic. Zero floating point.\n", .{});
}
