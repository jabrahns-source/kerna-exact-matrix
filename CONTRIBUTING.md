# Contributing to kerna-exact-matrix

Thank you for your interest. This repository is maintained by Jacarri Sanders / Even The Odds Foundry under extreme resource constraints. High-signal contributions are welcome.

## Core Invariants (Do Not Break)

1. **Zero floating-point matrix math**. No `f32`, `f64`, or any floating type in matrix paths.
2. **Determinism**. Same inputs → same outputs on every platform and every run.
3. **Auditability**. Prefer explicit, readable Zig over clever micro-optimizations that obscure intent.
4. **Overflow awareness**. Every arithmetic operation must document or handle potential overflow.

## Preferred Contribution Areas

- Additional exact algorithms (integer QR, integer SVD approximations, exact inverse via adjugate, etc.)
- Stronger Idris2 proofs
- Cross-platform CI matrix expansion
- Performance benchmarks against BLAS-style baselines (while remaining pure integer)
- Documentation improvements and worked examples tied to CAISO / SB 253 / process-matrix use cases

## Process

1. Open an issue first for non-trivial changes.
2. Keep PRs focused and small.
3. All new code must include tests.
4. Run `zig build test` before submitting.
5. Update relevant docs.

## Style

- Zig style as enforced by `zig fmt`.
- Prefer `i64` / `i128` with explicit scale factors over modular fields unless the use case demands finite fields.
- Document the scale factor and units in every public API that carries fixed-point semantics.
