//! Example: Fixed-point representation of a simple LMP / carbon intensity matrix.
//! Demonstrates scale factors and pure integer arithmetic suitable for
//! deterministic CAISO-style processing.

const std = @import("std");
const kem = @import("kerna-exact-matrix");
const fixed = kem.fixed;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Represent prices / intensities with scale = 4  (units of 1/16)
    // Example: 42.5  →  42.5 * 16 = 680
    const scale: kem.Scale = 4;

    var prices = try kem.Matrix.init(allocator, 2, 2, scale);
    defer prices.deinit();

    // Node A peak / off-peak, Node B peak / off-peak (illustrative)
    try prices.set(0, 0, fixed.fromInt(45, scale)); // 45.0
    try prices.set(0, 1, fixed.fromInt(28, scale)); // 28.0
    try prices.set(1, 0, fixed.fromInt(51, scale)); // 51.0
    try prices.set(1, 1, fixed.fromInt(33, scale)); // 33.0

    // Simple scaling matrix (e.g. a demand or weight factor)
    var weights = try kem.Matrix.init(allocator, 2, 2, 0); // scale 0 = integer weights
    defer weights.deinit();
    try weights.set(0, 0, 2);
    try weights.set(0, 1, 1);
    try weights.set(1, 0, 1);
    try weights.set(1, 1, 3);

    // Weighted combination (result scale = 4 + 0 = 4)
    var weighted = try prices.mul(weights, allocator);
    defer weighted.deinit();

    std.debug.print("Deterministic fixed-point LMP-style matrix (scale={d}):\n", .{scale});
    std.debug.print("  [{d}, {d}]\n", .{ try weighted.get(0, 0), try weighted.get(0, 1) });
    std.debug.print("  [{d}, {d}]\n", .{ try weighted.get(1, 0), try weighted.get(1, 1) });
    std.debug.print("\nAll values are exact integers. No floating-point rounding occurred.\n", .{});
    std.debug.print("This pattern is suitable for cryptographically committed receipts.\n", .{});
}
