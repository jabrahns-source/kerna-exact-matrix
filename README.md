# kerna-exact-matrix

**Production-ready zero-floating-point exact / fixed-point matrix algebra**  
for Kerna-Ledger, VERA Substrata, GridPulse, PSI-ALPHA, and related deterministic substrates.

**Even The Odds Foundry / Jacarri Sanders**

[![CI](https://github.com/jabrahns-source/kerna-exact-matrix/actions/workflows/ci.yml/badge.svg)](https://github.com/jabrahns-source/kerna-exact-matrix/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zig](https://img.shields.io/badge/Zig-0.13+-orange.svg)](https://ziglang.org)
[![Zero FPU](https://img.shields.io/badge/Floating%20Point-None-success.svg)](docs/ZERO_FPU.md)

---

## Why this exists

Floating-point matrix math is a source of non-determinism:

- Platform differences (x87 vs SSE/AVX)
- Rounding-mode sensitivity
- Non-associativity
- Difficulty of bit-exact cryptographic commitments and audit trails

For systems that must produce **identical results on every node** (CAISO data processing, SB 253 emissions receipts, sovereign consent logs, MEV-resistant settlement, process-matrix evaluation), floating point is unacceptable.

`kerna-exact-matrix` uses **only integer arithmetic**.

- Element type: `i64` (with `i128` intermediates)
- Explicit scale factors (power-of-two preferred)
- Pure integer addition, subtraction, multiplication, transpose, and small integer determinants
- No `f32` / `f64` anywhere in the matrix paths

Result: bit-exact reproducibility, straightforward formal reasoning, and audit-friendly code.

---

## Core guarantees

| Property                    | Status                          |
|----------------------------|---------------------------------|
| Zero floating-point ops    | Enforced by construction        |
| Determinism                | Bit-identical across platforms  |
| Explicit scale factors     | Yes                             |
| Overflow awareness         | Documented; Wide intermediates  |
| Formal specification       | Idris2 sketch in `proofs/`      |
| Production Zig runtime     | Yes                             |
| CI                         | GitHub Actions                  |

---

## Quick start

```bash
git clone https://github.com/jabrahns-source/kerna-exact-matrix.git
cd kerna-exact-matrix
zig build test
zig build
./zig-out/bin/basic
./zig-out/bin/grid_lmp_scale
```

### Minimal example

```zig
const kem = @import("kerna-exact-matrix");

var a = try kem.Matrix.init(allocator, 2, 2, 0);
defer a.deinit();
try a.set(0, 0, 1); try a.set(0, 1, 2);
try a.set(1, 0, 3); try a.set(1, 1, 4);

var b = try kem.Matrix.identity(allocator, 2, 0);
defer b.deinit();

var c = try a.mul(b, allocator);
defer c.deinit();
// c is exactly [[1,2],[3,4]] — pure integer, scale 0
```

---

## Repository layout

```
kerna-exact-matrix/
├── src/
│   ├── root.zig          # Public API surface
│   ├── matrix.zig        # Core Matrix type + pure integer ops
│   └── fixed.zig         # Scale helpers, fromInt / toInt / mulScaled
├── proofs/
│   └── Matrix.idr        # Idris2 dependent-type specification + property targets
├── docs/
│   ├── ARCHITECTURE.md
│   └── ZERO_FPU.md
├── examples/
│   ├── basic.zig
│   └── grid_lmp_scale.zig
├── .github/workflows/ci.yml
├── build.zig
├── LICENSE
├── SECURITY.md
└── CONTRIBUTING.md
```

---

## Design highlights

### Scale factor model

Every matrix carries a single `scale: i32`.  
All elements are interpreted as `value * 2^scale` (when scale ≥ 0) or the corresponding right-shift when negative.

Multiplication produces a result whose scale is the sum of the input scales.  
This keeps arithmetic uniform and avoids per-element metadata.

### Wide intermediates

Matrix multiplication accumulates in `i128` before truncating back to `i64`.  
This dramatically reduces intermediate overflow risk for moderate-sized integer matrices.

### Explicit error model

```zig
pub const Error = error{
    DimensionMismatch,
    ScaleMismatch,
    OutOfMemory,
    Singular,
    Overflow,
    InvalidArgument,
};
```

Callers decide how to handle scale mismatches and dimension errors. There is no silent coercion.

---

## Formal layer (Idris2)

See `proofs/Matrix.idr`.

The module encodes:

- Dimension-indexed matrix type
- Pure integer operations
- Target properties: associativity, distributivity, identity laws, scale correctness, determinism

The Zig implementation is deliberately written so that these properties remain obvious. Full machine-checked proofs of the five core algebraic properties are the next formal milestone.

---

## Integration with the Even The Odds stack

| Component              | How this library helps                                      |
|------------------------|-------------------------------------------------------------|
| **Kerna-Ledger / VCI** | Deterministic linear algebra inside verifiable compute      |
| **VERA**               | Exact receipt generation and verification                   |
| **GridPulse**          | Integer state / transition matrices for PMU FSMs            |
| **PSI-ALPHA**          | Scaled integer process-matrix evaluation                    |
| **phi-boundary**       | Compatible with integer ALU / golden-ratio pipelines        |

---

## Roadmap (forward-thinking)

1. Complete Idris2 proofs of the five core algebraic properties.
2. Checked / saturating arithmetic variants for safety-critical callers.
3. Modular (finite-field) backend for exact linear algebra over primes.
4. Sparse matrix support.
5. SIMD integer kernels (AVX2 / AVX-512) while preserving the pure-integer contract.
6. Extraction / correspondence proofs linking Idris2 specs to Zig runtime.

---

## Author

**Jacarri Sanders**  
Even The Odds Foundry LLC  
Founder of Kerna-Ledger / VERA Substrata  

Built under extreme constraints (solo, zero capital, Chromebook-class hardware) with an absolute requirement for determinism and auditability.

---

## License

MIT — see [LICENSE](LICENSE).

---

**Zero floating point. Full determinism. Production ready.**
