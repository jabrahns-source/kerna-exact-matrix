# Architecture

## Goals

1. Zero floating-point operations in any matrix path.
2. Full determinism and bit-exact reproducibility.
3. High performance via pure integer ALU pipelines (shift, add, mul).
4. Explicit overflow semantics.
5. Clean separation between runtime (Zig) and specification/proof (Idris2).
6. Immediate usability as a dependency for Kerna-Ledger, VERA, GridPulse, and related substrates.

## Core Types

```zig
pub const Scale = i32;          // power-of-two preferred; documented in units
pub const Element = i64;        // primary storage type
pub const Wide = i128;          // intermediate products to reduce overflow risk

pub const Matrix = struct {
    rows: usize,
    cols: usize,
    scale: Scale,               // shared scale for all elements
    data: []Element,            // row-major
    allocator: Allocator,
};
```

All elements share a single scale factor. This keeps the representation compact and the arithmetic uniform.

## Operation Philosophy

- **Addition / Subtraction**: Require matching scales (or explicitly convert first).
- **Multiplication**: Result scale = scale_a + scale_b. Intermediate products use `Wide`.
- **Transpose**: Trivial, scale preserved.
- **Integer Determinant**: Exact for small matrices; documented overflow behavior for larger.
- **No hidden normalization**: Callers control when (and whether) to rescale.

## Formal Layer

The `proofs/` directory contains Idris2 modules that encode:

- Matrix as a dependent type indexed by dimensions.
- Associativity and distributivity of the integer operations.
- Scale arithmetic correctness.
- Determinism (same inputs produce identical outputs).

The Zig implementation is written so that the core algebraic properties are obvious and can be related to the proofs via careful correspondence or future extraction.

## Integration Points

- **GridPulse / PMU**: Integer state vectors and transition matrices.
- **Carbon / LMP curves**: Fixed-point representations of prices and intensities.
- **PSI-ALPHA process matrices**: Integer approximations or scaled exact representations of process-matrix entries.
- **VERA receipts**: Deterministic linear algebra inside receipt generation and verification.

## Future Extensions

- Modular arithmetic backend over chosen primes (for exact finite-field linear algebra).
- Sparse matrix support.
- Block algorithms and cache-friendly layouts.
- SIMD integer kernels (AVX2/AVX-512 integer instructions) while preserving the pure-integer contract.
