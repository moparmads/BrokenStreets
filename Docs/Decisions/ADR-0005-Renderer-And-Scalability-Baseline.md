# ADR-0005 — Renderer and Scalability Baseline

**Status:** Proposed
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

## Proposed recommendation

- Minimum/Low does not depend on hardware Ray Tracing or Frame Generation.
- High/Ultra may enable RT only when a benchmark justifies it and a clear fallback exists.
- Measure Lumen, VSM, Nanite, Substrate, TSR, and alternatives on the same representative street.
- Gameplay entities remain identical across presets; only cosmetic and ambient density may decrease.
- Do not freeze values before testing a workload close to final art.

## Gate

For every preset and hardware target, record:

- driver, resolution/internal scale, and build;
- p50/p95/p99/max GT/RT/GPU;
- VRAM and working set;
- shader/PSO/streaming hitches;
- comparison image and visible defects;
- a target of 20% headroom in the normal scenario where feasible.

## Immediate task

BS-011 creates the first project-owned map. BS-013B converts accidental defaults into an explicit PC-only test configuration and records the initial result. Final renderer acceptance happens after the M15 Representative Street contains relevant art.
