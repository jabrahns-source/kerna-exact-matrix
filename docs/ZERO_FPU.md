# Why Zero Floating-Point Matrix Math

## The Problem with Floating Point in Verifiable Systems

Floating-point arithmetic (`f32` / `f64`) introduces:

- Platform-dependent rounding (x87 80-bit intermediates vs SSE/AVX)
- Non-associativity: `(a + b) + c ≠ a + (b + c)` in general
- Rounding-mode sensitivity
- Denormal / flush-to-zero differences
- Difficulty of bit-exact replay across machines and compilers

For systems that must produce **identical cryptographic commitments, audit trails, and settlement outcomes** on every node (CAISO data processing, SB 253 emissions receipts, sovereign consent logs, MEV-resistant finality), floating point is an unacceptable source of non-determinism.

## Design Choice

`kerna-exact-matrix` uses only integer arithmetic:

- Element type: `i64` (or `i128` for intermediate products)
- Explicit scale factors (power-of-two preferred for shift-based conversion)
- All matrix operations (add, sub, mul, transpose, integer determinant, etc.) are pure integer
- Overflow is either checked or saturating; the choice is explicit in the API

This guarantees:

1. Bit-identical results on every platform that implements two's-complement integers correctly.
2. Straightforward formal reasoning (Idris2 / Lean / Coq can treat the operations as pure mathematical functions over integers).
3. No hidden FPU state or control-register dependencies.

## Trade-offs

- Dynamic range is limited by the chosen integer width and scale.
- Division and inversion require careful handling (exact division only when it divides evenly, or fixed-point approximation with documented error bounds).
- Performance is competitive with well-written integer kernels and often better than naively ported floating-point code that must also pay for determinism wrappers.

For the Kerna-Ledger / VERA / GridPulse / PSI-ALPHA stack, the trade-off is correct: **determinism and auditability outrank the convenience of IEEE-754**.
