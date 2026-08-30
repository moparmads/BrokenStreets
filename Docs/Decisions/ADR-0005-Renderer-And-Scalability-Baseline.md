# ADR-0005 — Renderer and Scalability Baseline

**Status:** Accepted
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** BS-013B test baseline / M15 representative benchmark final
**Supersedes:** none
**Superseded by:** none

## Context

The Blank/Maximum project wizard enabled Ray Tracing and Substrate. Those settings are not a measured product decision. The product targets high visual realism, but frame rate, stability, and an accessible Low preset take priority.

## Alternatives

1. Software/Lumen baseline without mandatory hardware RT.
2. Hardware RT as an optional High/Ultra feature.
3. Mandatory hardware RT for every preset.
4. Full or selective Substrate versus the classic material pipeline.

## Decision

- The initial PC baseline is Win64, DX12, and Shader Model 6.
- Software Lumen, Virtual Shadow Maps, Nanite support, and TSR form the initial renderer path.
- Hardware ray tracing project support is disabled. A later High/Ultra option requires a representative benchmark, fallback, and full shader/cook verification.
- Substrate remains enabled with Blendable GBuffer. Complex multi-slab materials require explicit content budgets and representative measurement.
- `BS-PC-Recommended-P0` is a reproducible 1920×1080 High-scalability test preset with 100% screen percentage, VSync Off, and Dynamic Resolution Off. It is not the final player-facing preset.
- Minimum/Low never depends on hardware ray tracing or Frame Generation.
- Gameplay entities remain identical across presets; only cosmetic and ambient density may decrease.
- Final values and hardware specifications do not freeze before testing a workload close to final art.

Madalin Gavrila approved this initial reversible direction on August 30, 2026. BS-013B supplies the first configuration and evidence; the M15 representative-art gate may retain it or supersede this ADR.

## Gate

For every preset and hardware target, record:

- driver, resolution/internal scale, and build;
- p50/p95/p99/max GT/RT/GPU;
- VRAM and working set;
- shader/PSO/streaming hitches;
- comparison image and visible defects;
- a target of 20% headroom in the normal scenario where feasible.

## Immediate task

BS-013B converts accidental defaults into an explicit PC-only test configuration and records the initial result on the existing project-owned fixtures. Final renderer acceptance happens after the M15 Representative Street contains relevant art.
