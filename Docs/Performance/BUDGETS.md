# Performance budgets

**Status:** provisional; the P1 renderer test baseline exists, but representative art and reference PCs do not.
**Rule:** `TBD` is more accurate than an invented number. Values are frozen through a task or ADR after measurement.

## 1. Target profiles

| Profile | Provisional target | Conditions |
|---|---|---|
| Minimum/Low | stable 1080p, 30 FPS | SSD, 16 GB RAM, upscaling allowed, no required Frame Generation |
| Recommended | stable 1080p, 60 FPS | 32 GB RAM recommended; exact hardware TBD |
| Host Recommended | same quality with CPU/RAM reserve | one host plus three clients in four bubbles |
| Ultra | visual realism for powerful hardware | does not change gameplay; RT may become optional after ADR |

## 2. Frame budgets

| Target | Frame interval | Working p95 target with ~20% reserve | Status |
|---|---:|---:|---|
| 60 FPS | 16.67 ms | 13.33 ms for the limiting pipeline in the normal scenario | Provisional |
| 30 FPS | 33.33 ms | 26.67 ms | Provisional |

Report GT, RT, and GPU separately; the slowest limits FPS. p50/p95/p99/max and hitches are required; an average alone is insufficient.

## 3. Provisional hitch budgets

- no repeated hitches above 50 ms during normal traversal;
- no hitch above 100 ms during normal post-warm-up cell entry;
- loading and interior-transition targets remain provisional until reference hardware exists;
- shader, PSO, and asset-streaming hitches are classified separately.

## 4. Runtime invariants

- no reliable RPC every frame;
- no repeated global Actor scan in gameplay;
- no synchronous load in a normal hot path;
- no global hard reference that loads an entire catalog;
- economy, ownership, save, and job transitions are event-driven;
- needs and other infrequent systems do not run every frame;
- distant traffic or crowds do not retain full Actors and physics;
- UI uses events and invalidation, not Blueprint polling;
- Tick is disabled by default and has an owner, frequency, budget, and evidence when required.

## 5. Budgets to measure

| Area | Metric | Low | Recommended/Host | Freeze gate |
|---|---|---:|---:|---|
| CPU | GT/RT p95/p99 | TBD | TBD | Benchmark Street/four bubbles |
| GPU | GPU p95/p99 | TBD | TBD | representative art benchmark |
| Memory | process working set | TBD | TBD | four-bubble soak |
| VRAM | peak/resident/evictions | TBD | TBD | renderer ADR |
| Streaming | loaded cells, I/O, load/unload time | TBD | TBD | WP spike |
| Network | bandwidth/client/total | TBD | TBD | replication spike |
| Network | initial snapshot/late join | TBD | TBD | replicated feature gate |
| Actors | full/reduced/representation counts | TBD | TBD | population/traffic benchmark |
| AI | active/reduced/statistical | TBD | TBD | AI/Police gate |
| Physics | bodies/vehicles/collision cost | TBD | TBD | vehicle/combat gate |
| Save | snapshot size/capture/serialize/write | TBD | TBD | 10k-record test |
| Content | material slots/texture/mesh/LOD | per-category TBD | per-category TBD | representative asset kit |

## 6. Scalability contract

Low may reduce:

- ambient crowd and traffic density;
- shadow, reflection, and lighting quality;
- cosmetic props, VFX, decals, and draw distance;
- animation and update quality for ambient entities.

Low may not remove or change:

- relevant police or AI;
- witnesses or detectors used by gameplay;
- objectives, loot, interactables, and important collision;
- visibility essential to stealth or combat;
- job outcomes, economy, save, or simulation rules.

## 7. Before/after report

```text
Scenario/version:
Commit/build/engine:
Hardware/OS/driver:
Preset/resolution/upscaler:
Topology/map/seed/weather:
Warm-up/runs:
GT p50/p95/p99/max:
RT p50/p95/p99/max:
GPU p50/p95/p99/max:
Hitches:
Working set/VRAM:
Loaded cells/actors/AI/physics:
Bandwidth/snapshot:
Change versus baseline:
PASS/FAIL and fallback:
Trace path:
```

A change is not called an “optimization” without this minimum context.

## 8. Current renderer precursor

`BS-PERF-002-P1` records the `BS-PC-Recommended-P0` configuration and capture pipeline on the greybox Benchmark Street fixture. On the creator RTX 3090 machine, all three runs met the fixture-only 13.33 ms limiting-pipeline p95 marker and recorded no post-warm-up frame above 50 or 100 ms.

This does not fill the TBD production budgets above. The fixture lacks representative art, streaming, population, vehicles, weather, multiplayer, and gameplay load. See `Docs/Performance/Baselines/BS-PERF-002-P1.md`.
