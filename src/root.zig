//! kerna-exact-matrix
//!
//! Production-ready zero-floating-point exact / fixed-point matrix algebra
//! for Kerna-Ledger, VERA Substrata, GridPulse, and PSI-ALPHA.
//!
//! All arithmetic is pure integer. No f32/f64 anywhere in the matrix paths.
//!
//! Author: Jacarri Sanders / Even The Odds Foundry LLC
//! License: MIT

const std = @import("std");

pub const matrix = @import("matrix.zig");
pub const fixed = @import("fixed.zig");

pub const Matrix = matrix.Matrix;
pub const Scale = matrix.Scale;
pub const Element = matrix.Element;
pub const Wide = matrix.Wide;

pub const Error = matrix.Error;

test {
    std.testing.refAllDecls(@This());
}
