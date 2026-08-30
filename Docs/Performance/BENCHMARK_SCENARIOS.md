# Permanent benchmark scenarios

Scenarios have stable names and fixtures so results can be compared across commits. Every report pins engine, build, hardware, driver, preset, resolution, seed, and warm-up.

## BS-PERF-001 — Empty TestGym

- nearly empty project-owned map;
- one player, then one host plus three clients;
- measures engine, project, and replication overhead without content;
- becomes the baseline for incremental cost.

## BS-PERF-002 — Representative Street

- one block or intersection with geometry, materials, lighting, decals, and props close to final categories;
- controlled day/night and weather;
- Low, Recommended, and Ultra;
- renderer, scalability, and asset budgets.

Precursors are versioned without pretending the fixture is representative:

- `P0` proved the package/capture pipeline on the original greybox defaults;
- `P1` pins the reversible PC renderer and `BS-PC-Recommended-P0` preset;
- the representative-art pass replaces both as the meaningful renderer baseline.

## BS-PERF-003 — Four Players Together

- host plus three clients at the same intersection;
- avatars, inventory summaries, interaction, and one relevant AI/job;
- contention, public relevancy, and GPU crowding.

## BS-PERF-004 — Four Corners / Four Bubbles

- four players far enough apart to require different streaming and relevancy;
- measures host CPU, memory, loaded cells, and network;
- validates server streaming/out and world-owned Actor persistence.

## BS-PERF-005 — Four Private Interiors

- four `PropertyInstanceId` values using the same or different templates;
- visual, audio, navigation, physics, replication isolation;
- visitors off for baseline, then one visitor;
- load/unload behavior and memory caps.

## BS-PERF-006 — Four High-Speed Vehicles

- one vehicle per player moving in different directions;
- network smoothing, World Partition, collision/physics, and asset streaming;
- repeated traversal in both directions.

## BS-PERF-007 — Four Concurrent Jobs

- four separate `JobInstance` values and participant groups;
- objectives, UI/read models, AI/spawn, and save receipts;
- late join and reconnect during a controlled job.

## BS-PERF-008 — Crowd + Traffic + Rain

- controlled density per tier;
- reported Full, Reduced, Representation, and Statistical counts;
- weather, wet materials, VFX, and audio;
- Low retains gameplay entities.

## BS-PERF-009 — Police + Traffic + Combat

- Incident, heat, pursuit, physical traffic, and controlled combat;
- worst normal gameplay, not an artificial unlimited spawn;
- director budgets, AI/path recovery, physics, and network.

## BS-PERF-010 — Traversal Soak

- 30 minutes on a repeatable route;
- warm-up separated from measurement;
- cell churn, I/O, hitches, shader/PSO behavior, and memory trend;
- identical route, seed, and vehicle speed.

## BS-PERF-011 — Save 10k Records

- 10,000 deterministic item-like records with controlled variation;
- capture, serialize, write, load, validate, and migrate;
- game-thread stall separated from worker and I/O time;
- kill/fault stages;
- file size, peak memory, and determinism.

## BS-PERF-012 — Multiplayer Soak

- at least three independent two-hour runs before content lock;
- host plus three clients, join/leave/reconnect, travel, jobs, autosaves, interiors, and vehicles;
- crash blockers, memory growth, network drift, duplicate transactions, and log spam.

## Common protocol

1. Check out the exact commit with a clean working tree.
2. Build the relevant packaged configuration.
3. Reset processes and hardware state according to the protocol.
4. Use a fixed warm-up.
5. Run at least three times for a performance gate.
6. Retain the trace and summary.
7. Compare against the last accepted baseline.
8. On FAIL, stop content expansion and choose a fix, fallback, or scope cut.

## Minimum metadata

```text
Scenario ID/version:
Commit/build/engine:
Machine roles:
CPU/GPU/RAM/VRAM/SSD/OS/driver:
Preset/resolution/upscaler/dynamic resolution/RT:
Map/seed/time/weather:
Players/topology/network profile:
Warm-up/duration/runs:
Expected threshold:
Metrics/results:
Trace/report:
Verdict and next action:
```
