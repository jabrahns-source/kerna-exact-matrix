//! Fixed-point helpers and scale arithmetic.
//! All operations remain pure integer.

const std = @import("std");
const matrix = @import("matrix.zig");

pub const Scale = matrix.Scale;
pub const Element = matrix.Element;
pub const Wide = matrix.Wide;

/// Convert an integer value into a scaled fixed-point representation.
/// result = value * (1 << scale)   when scale >= 0
/// result = value / (1 << -scale)  when scale < 0 (truncating)
pub fn fromInt(value: i64, scale: Scale) Element {
    if (scale >= 0) {
        // Checked shift would be safer for large scales; for now we document the limit.
        const shift: u6 = @intCast(@min(scale, 62));
        return value << shift;
    } else {
        const shift: u6 = @intCast(@min(-scale, 62));
        return value >> shift;
    }
}

/// Convert a scaled value back to an integer (truncating toward zero).
pub fn toInt(value: Element, scale: Scale) i64 {
    if (scale >= 0) {
        const shift: u6 = @intCast(@min(scale, 62));
        return value >> shift;
    } else {
        const shift: u6 = @intCast(@min(-scale, 62));
        return value << shift;
    }
}

/// Multiply two scaled values. Result scale = scale_a + scale_b.
/// Uses Wide intermediate to reduce overflow risk.
pub fn mulScaled(a: Element, scale_a: Scale, b: Element, scale_b: Scale) struct { value: Element, scale: Scale } {
    const product: Wide = @as(Wide, a) * @as(Wide, b);
    // For now we truncate to Element; callers that need full range should use mulWide.
    const result: Element = @truncate(product);
    return .{ .value = result, .scale = scale_a + scale_b };
}

/// Safe multiplication returning Wide.
pub fn mulWide(a: Element, b: Element) Wide {
    return @as(Wide, a) * @as(Wide, b);
}

test "fromInt / toInt roundtrip (positive scale)" {
    const v: i64 = 42;
    const s: Scale = 8;
    const scaled = fromInt(v, s);
    const back = toInt(scaled, s);
    try std.testing.expectEqual(v, back);
}

test "mulScaled basic" {
    const a = fromInt(3, 2); // 3 * 4 = 12
    const b = fromInt(5, 1); // 5 * 2 = 10
    const res = mulScaled(a, 2, b, 1);
    // 12 * 10 = 120, scale = 3
    try std.testing.expectEqual(@as(Element, 120), res.value);
    try std.testing.expectEqual(@as(Scale, 3), res.scale);
}
