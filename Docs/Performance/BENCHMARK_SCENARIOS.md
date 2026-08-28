# Scenarii permanente de benchmark

Scenariile au nume și fixtures stabile pentru comparație între commituri. Fiecare raport fixează engine/build/hardware/driver/preset/resolution/seed/warm-up.

## BS-PERF-001 — Empty TestGym

- project-owned map aproape goală;
- 1 player, apoi 1 host + 3 clients;
- măsoară overhead-ul de engine/proiect/replication fără content;
- devine baseline pentru costul incremental.

## BS-PERF-002 — Representative Street

- un bloc/intersecție cu geometrie, materiale, lighting, decals și props apropiate de categoria finală;
- zi/noapte și vreme controlate;
- Low/Recommended/Ultra;
- renderer/scalability/asset budgets.

## BS-PERF-003 — Four Players Together

- host + 3 clienți în aceeași intersecție;
- avatars, inventory summaries, interaction, un AI/job relevant;
- contention, relevancy public și GPU crowding.

## BS-PERF-004 — Four Corners / Four Bubbles

- cei patru jucători în zone suficient de depărtate pentru streaming/relevancy diferit;
- măsoară host CPU/memory/loaded cells/network;
- validate server streaming/out și world-owned actor persistence.

## BS-PERF-005 — Four Private Interiors

- patru PropertyInstanceIds cu același/diferite templates;
- visual/audio/nav/physics/replication isolation;
- visitors off pentru baseline, apoi un visitor;
- load/unload și memory caps.

## BS-PERF-006 — Four High-Speed Vehicles

- un vehicul per player, direcții diferite;
- network smoothing, World Partition, collision/physics și asset streaming;
- traversare repetată în ambele sensuri.

## BS-PERF-007 — Four Concurrent Jobs

- patru JobInstances, participanți separați;
- objectives, UI/read models, AI/spawn și save receipts;
- late join/reconnect într-un job controlat.

## BS-PERF-008 — Crowd + Traffic + Rain

- densitate controlată pe tier;
- Full/Reduced/Representation/Statistical counts raportate;
- vreme, wet materials/VFX/audio;
- Low păstrează entitățile gameplay.

## BS-PERF-009 — Police + Traffic + Combat

- Incident, heat, pursuit, physical traffic și combat controlat;
- worst normal gameplay, nu spawn nelimitat artificial;
- director budgets, AI/path recovery, physics/network.

## BS-PERF-010 — Traversal Soak

- 30 minute de rută repetabilă;
- warm-up separat de măsurare;
- cell churn, IO, hitches, shader/PSO și memory trend;
- aceeași rută/seed/vehicle speed.

## BS-PERF-011 — Save 10k Records

- 10.000 item-like records deterministe cu variații controlate;
- capture, serialize, write, load, validate și migration;
- game-thread stall separat de worker/I/O;
- kill/fault stages;
- file size, memory peak și determinism.

## BS-PERF-012 — Multiplayer Soak

- minimum trei rulări independente a câte două ore înainte de content lock;
- host + 3 clients, join/leave/reconnect, travel, jobs, autosaves, interiors și vehicles;
- crash blocker, memory growth, network drift, duplicate transactions și log spam.

## Protocol comun

1. checkout commitul exact și clean working tree;
2. build packaged relevant;
3. restart procese/hardware state conform protocolului;
4. warm-up fix;
5. minimum trei runs pentru performance gate;
6. păstrează trace și summary;
7. compară cu ultimul baseline acceptat;
8. dacă FAIL, oprește content expansion și alege fix/fallback/scope cut.

## Metadata minimă

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
