//! Core Matrix type and pure-integer operations.
//! Zero floating-point. Fully deterministic.

const std = @import("std");
const Allocator = std.mem.Allocator;
const fixed = @import("fixed.zig");

pub const Scale = i32;
pub const Element = i64;
pub const Wide = i128;

pub const Error = error{
    DimensionMismatch,
    ScaleMismatch,
    OutOfMemory,
    Singular,
    Overflow,
    InvalidArgument,
};

/// Dense row-major matrix of Elements sharing a common scale factor.
pub const Matrix = struct {
    rows: usize,
    cols: usize,
    scale: Scale,
    data: []Element,
    allocator: Allocator,

    /// Create a zero matrix with the given dimensions and scale.
    pub fn init(allocator: Allocator, rows: usize, cols: usize, scale: Scale) Error!Matrix {
        if (rows == 0 or cols == 0) return Error.InvalidArgument;
        const data = try allocator.alloc(Element, rows * cols);
        @memset(data, 0);
        return Matrix{
            .rows = rows,
            .cols = cols,
            .scale = scale,
            .data = data,
            .allocator = allocator,
        };
    }

    /// Create an identity matrix of size n x n.
    pub fn identity(allocator: Allocator, n: usize, scale: Scale) Error!Matrix {
        var m = try Matrix.init(allocator, n, n, scale);
        const one = fixed.fromInt(1, scale);
        var i: usize = 0;
        while (i < n) : (i += 1) {
            m.setUnchecked(i, i, one);
        }
        return m;
    }

    pub fn deinit(self: *Matrix) void {
        self.allocator.free(self.data);
        self.* = undefined;
    }

    pub fn index(self: Matrix, row: usize, col: usize) usize {
        return row * self.cols + col;
    }

    pub fn get(self: Matrix, row: usize, col: usize) Error!Element {
        if (row >= self.rows or col >= self.cols) return Error.InvalidArgument;
        return self.data[self.index(row, col)];
    }

    pub fn set(self: *Matrix, row: usize, col: usize, value: Element) Error!void {
        if (row >= self.rows or col >= self.cols) return Error.InvalidArgument;
        self.data[self.index(row, col)] = value;
    }

    pub fn setUnchecked(self: *Matrix, row: usize, col: usize, value: Element) void {
        self.data[self.index(row, col)] = value;
    }

    pub fn getUnchecked(self: Matrix, row: usize, col: usize) Element {
        return self.data[self.index(row, col)];
    }

    /// Element-wise addition. Requires identical dimensions and scale.
    pub fn add(self: Matrix, other: Matrix, allocator: Allocator) Error!Matrix {
        if (self.rows != other.rows or self.cols != other.cols) return Error.DimensionMismatch;
        if (self.scale != other.scale) return Error.ScaleMismatch;

        var result = try Matrix.init(allocator, self.rows, self.cols, self.scale);
        var i: usize = 0;
        while (i < self.data.len) : (i += 1) {
            result.data[i] = self.data[i] +% other.data[i];
        }
        return result;
    }

    /// Element-wise subtraction.
    pub fn sub(self: Matrix, other: Matrix, allocator: Allocator) Error!Matrix {
        if (self.rows != other.rows or self.cols != other.cols) return Error.DimensionMismatch;
        if (self.scale != other.scale) return Error.ScaleMismatch;

        var result = try Matrix.init(allocator, self.rows, self.cols, self.scale);
        var i: usize = 0;
        while (i < self.data.len) : (i += 1) {
            result.data[i] = self.data[i] -% other.data[i];
        }
        return result;
    }

    /// Matrix multiplication. Result scale = self.scale + other.scale.
    /// Uses Wide intermediates.
    pub fn mul(self: Matrix, other: Matrix, allocator: Allocator) Error!Matrix {
        if (self.cols != other.rows) return Error.DimensionMismatch;

        const out_rows = self.rows;
        const out_cols = other.cols;
        const result_scale: Scale = self.scale + other.scale;

        var result = try Matrix.init(allocator, out_rows, out_cols, result_scale);

        var i: usize = 0;
        while (i < out_rows) : (i += 1) {
            var j: usize = 0;
            while (j < out_cols) : (j += 1) {
                var acc: Wide = 0;
                var k: usize = 0;
                while (k < self.cols) : (k += 1) {
                    const a: Wide = @as(Wide, self.getUnchecked(i, k));
                    const b: Wide = @as(Wide, other.getUnchecked(k, j));
                    acc += a * b;
                }
                result.setUnchecked(i, j, @truncate(acc));
            }
        }
        return result;
    }

    /// Transpose. Scale preserved.
    pub fn transpose(self: Matrix, allocator: Allocator) Error!Matrix {
        var result = try Matrix.init(allocator, self.cols, self.rows, self.scale);
        var i: usize = 0;
        while (i < self.rows) : (i += 1) {
            var j: usize = 0;
            while (j < self.cols) : (j += 1) {
                result.setUnchecked(j, i, self.getUnchecked(i, j));
            }
        }
        return result;
    }

    /// Integer determinant for small matrices (1x1, 2x2, 3x3).
    pub fn detSmall(self: Matrix) Error!Element {
        if (self.rows != self.cols) return Error.DimensionMismatch;
        switch (self.rows) {
            1 => return self.getUnchecked(0, 0),
            2 => {
                const a = self.getUnchecked(0, 0);
                const b = self.getUnchecked(0, 1);
                const c = self.getUnchecked(1, 0);
                const d = self.getUnchecked(1, 1);
                const ad: Wide = @as(Wide, a) * @as(Wide, d);
                const bc: Wide = @as(Wide, b) * @as(Wide, c);
                return @truncate(ad - bc);
            },
            3 => {
                const a = self.getUnchecked(0, 0);
                const b = self.getUnchecked(0, 1);
                const c = self.getUnchecked(0, 2);
                const d = self.getUnchecked(1, 0);
                const e = self.getUnchecked(1, 1);
                const f = self.getUnchecked(1, 2);
                const g = self.getUnchecked(2, 0);
                const h = self.getUnchecked(2, 1);
                const i = self.getUnchecked(2, 2);

                const term1: Wide = @as(Wide, a) * (@as(Wide, e) * @as(Wide, i) - @as(Wide, f) * @as(Wide, h));
                const term2: Wide = @as(Wide, b) * (@as(Wide, d) * @as(Wide, i) - @as(Wide, f) * @as(Wide, g));
                const term3: Wide = @as(Wide, c) * (@as(Wide, d) * @as(Wide, h) - @as(Wide, e) * @as(Wide, g));
                return @truncate(term1 - term2 + term3);
            },
            else => return Error.InvalidArgument,
        }
    }

    /// Create a deep copy.
    pub fn clone(self: Matrix, allocator: Allocator) Error!Matrix {
        const result = try Matrix.init(allocator, self.rows, self.cols, self.scale);
        @memcpy(result.data, self.data);
        return result;
    }
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

test "matrix init and identity" {
    const allocator = std.testing.allocator;
    var m = try Matrix.identity(allocator, 3, 0);
    defer m.deinit();

    try std.testing.expectEqual(@as(usize, 3), m.rows);
    try std.testing.expectEqual(@as(Element, 1), m.getUnchecked(0, 0));
    try std.testing.expectEqual(@as(Element, 0), m.getUnchecked(0, 1));
    try std.testing.expectEqual(@as(Element, 1), m.getUnchecked(2, 2));
}

test "matrix mul 2x2" {
    const allocator = std.testing.allocator;

    var a = try Matrix.init(allocator, 2, 2, 0);
    defer a.deinit();
    a.setUnchecked(0, 0, 1);
    a.setUnchecked(0, 1, 2);
    a.setUnchecked(1, 0, 3);
    a.setUnchecked(1, 1, 4);

    var b = try Matrix.init(allocator, 2, 2, 0);
    defer b.deinit();
    b.setUnchecked(0, 0, 5);
    b.setUnchecked(0, 1, 6);
    b.setUnchecked(1, 0, 7);
    b.setUnchecked(1, 1, 8);

    var c = try a.mul(b, allocator);
    defer c.deinit();

    // [[1,2],[3,4]] * [[5,6],[7,8]] = [[19,22],[43,50]]
    try std.testing.expectEqual(@as(Element, 19), c.getUnchecked(0, 0));
    try std.testing.expectEqual(@as(Element, 22), c.getUnchecked(0, 1));
    try std.testing.expectEqual(@as(Element, 43), c.getUnchecked(1, 0));
    try std.testing.expectEqual(@as(Element, 50), c.getUnchecked(1, 1));
    try std.testing.expectEqual(@as(Scale, 0), c.scale);
}

test "matrix transpose" {
    const allocator = std.testing.allocator;
    var a = try Matrix.init(allocator, 2, 3, 4);
    defer a.deinit();
    a.setUnchecked(0, 0, 1);
    a.setUnchecked(0, 1, 2);
    a.setUnchecked(0, 2, 3);
    a.setUnchecked(1, 0, 4);
    a.setUnchecked(1, 1, 5);
    a.setUnchecked(1, 2, 6);

    var t = try a.transpose(allocator);
    defer t.deinit();

    try std.testing.expectEqual(@as(usize, 3), t.rows);
    try std.testing.expectEqual(@as(usize, 2), t.cols);
    try std.testing.expectEqual(@as(Element, 1), t.getUnchecked(0, 0));
    try std.testing.expectEqual(@as(Element, 4), t.getUnchecked(0, 1));
    try std.testing.expectEqual(@as(Element, 3), t.getUnchecked(2, 0));
    try std.testing.expectEqual(@as(Scale, 4), t.scale);
}

test "det 2x2" {
    const allocator = std.testing.allocator;
    var m = try Matrix.init(allocator, 2, 2, 0);
    defer m.deinit();
    m.setUnchecked(0, 0, 4);
    m.setUnchecked(0, 1, 3);
    m.setUnchecked(1, 0, 2);
    m.setUnchecked(1, 1, 1);
    // det = 4*1 - 3*2 = -2
    const d = try m.detSmall();
    try std.testing.expectEqual(@as(Element, -2), d);
}
