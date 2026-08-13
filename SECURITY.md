# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

This library is designed for high-assurance environments (grid compliance, emissions verification, sovereign consent, settlement).

If you discover a vulnerability that could affect determinism, overflow behavior, or cryptographic integration points:

1. **Do not** open a public issue.
2. Email: eventheoddsfoundry@gmail.com
3. Subject line: `[SECURITY] kerna-exact-matrix`

Include:
- Description of the issue
- Steps to reproduce
- Impact assessment (especially regarding determinism or integer overflow)
- Suggested fix if known

We will acknowledge within 72 hours and aim for a fix or public disclosure timeline within 14 days for critical issues.

## Design Guarantees Relevant to Security

- Zero floating-point operations → no FPU non-determinism or rounding-mode side channels.
- Explicit overflow handling (checked or saturating paths).
- Pure integer arithmetic → bit-exact reproducibility across platforms.
- No hidden allocations or control flow in hot paths where possible.
