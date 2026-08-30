# BS-013 — Benchmark Street Placeholder

**Status:** Needs Owner Verification
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-013-benchmark-street`
**Base commit:** `3f157cbf0a65937af7dbd6813136e9c2298fb3dc`
**Roadmap milestone:** M1 — Recoverable baseline and project memory
**System docs:** [Performance budgets](../Performance/BUDGETS.md), [Benchmark scenarios](../Performance/BENCHMARK_SCENARIOS.md), [Test strategy](../Testing/TEST_STRATEGY.md)

## Observable outcome

`/Game/BS/Maps/Benchmark/L_Benchmark_Street` is a small deterministic greybox street-intersection fixture made only from the existing Basic Level environment and Engine basic cubes. A packaged Win64 Development build loads the explicit map, supports a clear 80-metre straight traversal, and produces the first retained Unreal Insights trace plus a versioned provisional performance summary on the creator's current PC.

This task proves the capture and comparison pipeline. It does not claim that an empty greybox represents final Manhattan performance or that any current renderer setting is accepted for production.

## Why now

BS-011 and BS-012 established project-owned maps, content validation, packaging, Git LFS, and local multiprocess verification. BS-013 adds the smallest permanent rendering/traversal fixture and proves that a packaged build can generate reproducible CPU, render-thread, GPU, hitch, and memory evidence before BS-013B changes renderer/scalability configuration and BS-021 establishes a formal profiling baseline.

## In scope

- one new map at `Content/BS/Maps/Benchmark/L_Benchmark_Street.umap`, saved from `L_TestGym_Core` through Unreal Editor;
- the unchanged Basic Level floor, sky, fog, clouds, and lighting;
- one deterministic PlayerStart, four Engine-cube building masses, and two non-rendering TargetPoint route markers;
- a clear straight route from X `-4000` to X `4000` through the intersection at world origin;
- no Level Blueprint gameplay, Tick, scripting, navigation, AI, traffic, vehicles, decals, custom materials, production assets, or Source Art;
- Build, Automation, Data Validation, Cook, Map Check, explicit-map package, packaged boot/traversal, and creator evidence;
- three comparable packaged profiling runs on the same machine and settings;
- retained raw trace/CSV evidence under ignored `Saved/Performance/BS-013/` and a small English baseline summary under `Docs/Performance/Baselines/`;
- Git LFS lock, pointer, object, push, post-merge audit, backup/restore, and unlock.

## Out of scope

- a visually representative final street, copied NYC layout, landmark, facade, sign, brand, reference-game asset, or extracted content;
- final material, texture, triangle, Nanite, LOD, HLOD, lighting, reflection, shadow, VRAM, streaming, or World Partition budgets;
- changing Ray Tracing, Substrate, renderer, scalability, target hardware, default map, plugins, Config, or `.uproject`; BS-013B owns those decisions;
- custom camera, character, input, benchmark controller, C++, Blueprint, Sequencer, or automated traversal;
- multiplayer, four streaming bubbles, Replication Graph/Iris, Steam, network bandwidth, AI, physics, population, or traffic;
- performance comparison against production art or a declaration that the project is optimized;
- committing raw `.utrace`, CSV, logs, packaged output, or generated profiling files.

## Dependencies and required decisions

- BS-009 through BS-012 are Done on `main`;
- the final pre-task independent backup is generation `20260830T131515Z-38296-72bec3b7` at source commit `3f157cbf0a65937af7dbd6813136e9c2298fb3dc`;
- `BS-PERF-002 — Representative Street` remains the permanent scenario; this task records precursor fixture version `BS-PERF-002-P0`, which is deliberately not representative art;
- the reversible layout, actor count, route, capture duration, and profiling channels defined here are task defaults, not product decisions;
- current renderer and project defaults are measured as found and remain unapproved; no material decision is required before this capture-pipeline task.

## Allowed files/domains

- `Content/BS/Maps/Benchmark/L_Benchmark_Street.umap`;
- `Docs/Tasks/BS-013-Benchmark-Street.md`, `Docs/Tasks/README.md`, and `Docs/STATUS.md`;
- `Docs/Performance/Baselines/BS-PERF-002-P0.md` after measured evidence exists;
- generated packages, traces, CSV files, screenshots, summaries, and launch helpers only under ignored `Saved/` output;
- no tracked C++, Config, plugin, `.uproject`, Source Art, production Content, Engine Source, or unrelated documentation change.

## Authority/network impact

N/A. The fixture introduces no Broken Streets gameplay truth, replicated property, RPC, network topology, session, or audience rule. The packaged profiling scenario is one local standalone player. BS-012 remains the empty four-process network baseline.

## Persistence/migration impact

N/A. The map and profiling output create no save, profile, schema, migration, record, transaction, or durable gameplay state. Raw evidence is disposable local output; the small versioned summary identifies its exact candidate and trace hashes.

## Performance budget

- source map remains below 5 MiB and contains exactly 14 actors: the eight copied Basic Level actors, four cube masses, and two TargetPoints;
- no Blueprint or C++ Tick and no dynamic gameplay workload;
- package and profiling use Win64 Development, the explicit benchmark map, `1920×1080` windowed, VSync off, 100% screen percentage, and all `sg.*` groups pinned to quality level `3` through runtime commands only;
- Ray Tracing, RHI, driver, OS, CPU, GPU, RAM, VRAM, and storage are recorded exactly as observed;
- three independent packaged runs use the same command line and retain CPU, Frame, GPU, Bookmark, LoadTime, File, RenderCommands, and RHICommands trace channels plus CSV GPU statistics;
- each accepted run must load the exact map, produce a non-empty trace and CSV, end normally, and supply a stable post-load sample; p50/p95/p99/max GT, RT, GPU, and frame time, hitches above 50/100 ms, process working set, and run-to-run spread are reported when present;
- no FPS or frame-time threshold is used to pass this placeholder. PASS means reproducible evidence, not production performance. The provisional 13.33 ms/26.67 ms working targets remain informational until representative content and BS-013B/BS-021.

## Blueprint/Editor impact

Madalin creates the binary map through Unreal Editor 5.8.2 only after Codex pushes the preparation commit and acquires the planned-path Git LFS lock. The map is saved from `L_TestGym_Core`; the core and network fixtures must remain byte-identical. Only Engine `/Engine/BasicShapes/Cube` meshes and TargetPoint actors are added. No asset, material, Blueprint, Level Blueprint, Project Setting, plugin, Config file, or Engine Source file is created or changed.

The required fixture actors are:

| Actor label | Class/source | Location (X, Y, Z) | Rotation (Pitch, Yaw, Roll) | Scale (X, Y, Z) |
|---|---|---:|---:|---:|
| `PS_Benchmark_Start` | existing PlayerStart | `-4000, 0, 120` | `0, 0, 0` | `1, 1, 1` |
| `SM_Benchmark_Mass_NW` | Engine Basic Cube | `-2500, 2500, 1500` | `0, 0, 0` | `20, 20, 30` |
| `SM_Benchmark_Mass_NE` | Engine Basic Cube | `2500, 2500, 2000` | `0, 0, 0` | `20, 20, 40` |
| `SM_Benchmark_Mass_SW` | Engine Basic Cube | `-2500, -2500, 1250` | `0, 0, 0` | `20, 20, 25` |
| `SM_Benchmark_Mass_SE` | Engine Basic Cube | `2500, -2500, 1750` | `0, 0, 0` | `20, 20, 35` |
| `TP_Benchmark_Intersection` | TargetPoint | `0, 0, 120` | `0, 0, 0` | `1, 1, 1` |
| `TP_Benchmark_End` | TargetPoint | `4000, 0, 120` | `0, 0, 0` | `1, 1, 1` |

## Acceptance criteria

1. **Given** the locked planned path **When** the creator saves the fixture **Then** exactly one new project-owned package exists at `/Game/BS/Maps/Benchmark/L_Benchmark_Street`, and both TestGym maps remain byte-identical.
2. **Given** the saved fixture **When** its actors are inspected **Then** it contains exactly the eight copied Basic Level actors plus the six new actors and renamed PlayerStart described above, with the required labels/transforms and no Level Blueprint gameplay.
3. **Given** the greybox layout **When** the standalone player spawns and travels along positive X **Then** the 80-metre route crosses the clear intersection without collision obstruction or falling through the floor.
4. **Given** the saved map **When** Map Check and Data Validation run **Then** the package has zero errors and no unexplained warning.
5. **Given** the staged map **When** Git inspects it **Then** it is a valid LFS pointer, its payload exists locally, the lock belongs to the task owner, and no unrelated asset changed.
6. **Given** the exact candidate **When** `Tools/BS.cmd All` runs **Then** Build and Automation pass, all three project maps validate, and Cook reports no project-owned omission or new warning.
7. **Given** the explicit-map Win64 Development package **When** it launches **Then** it loads `L_Benchmark_Street`, brings the world up for play, accepts traversal, and exits normally without crash or map-load failure.
8. **Given** three identical packaged profiling runs **When** evidence is inspected **Then** each run produces a non-empty trace and CSV with exact metadata, a stable post-load sample, no fatal/error marker, and a versioned provisional summary without presenting the placeholder as a production target.
9. **Given** the creator checkpoint **When** Madalin inspects the packaged fixture **Then** the four building masses form a readable intersection, the route is clear, and the window remains responsive.
10. **Given** accepted integration **When** Git, GitHub, Git LFS, and backup are audited **Then** local and remote `main` agree, the map object is recoverable without GitHub, and the lock is released only after the verified push and restore.

## Automated verification

- preserve SHA-256 values for `L_TestGym_Core` and `L_TestGym_Network` and prove neither changed;
- inspect changed paths, map size, LFS attributes, lock owner, staged pointer, `git lfs status`, `git lfs ls-files`, and `git lfs fsck --pointers HEAD`;
- run exact-map Map Check and project Data Validation;
- run the runner self-test and `Tools/BS.cmd All` on the exact candidate;
- build, cook, stage, package, and archive Win64 Development with `/Game/BS/Maps/Benchmark/L_Benchmark_Street` explicitly selected;
- boot the packaged map, retain its log, verify exact-map load and normal shutdown, and scan for fatal, crash, load, and rendering failures;
- run the three pinned profiling captures, hash the raw evidence, extract the required provisional metrics, and write `Docs/Performance/Baselines/BS-PERF-002-P0.md` in English;
- audit that no custom gameplay, Blueprint, Config, plugin, `.uproject`, Source Art, external asset, or Engine Source change entered the task.

## Manual acceptance

### Checkpoint A — create the placeholder fixture

**Goal:** Save the Core TestGym as `L_Benchmark_Street` and build the exact 14-actor greybox layout.
**Applications needed:** Unreal Editor 5.8.2.
**Unreal Editor state:** Closed at the start; open only for the issued numbered steps; closed after Checkpoint A.
**Visual Studio state:** Not needed.
**Expected duration:** 12–15 minutes.
**Files/assets created or modified:** `/Game/BS/Maps/Benchmark/L_Benchmark_Street` only.
**Do not touch:** either TestGym map, Level Blueprint, copied floor/lighting/sky actors, materials, Project Settings, Config, plugins, other Content folders, Source Art, or engine association.

Codex issues exact numbered Editor steps only after the preparation commit is pushed and the planned map path is locked. The creator returns one screenshot showing the map name, Content Browser path, all required fixture labels in World Outliner, and one selected mass transform, then saves and closes Unreal Editor.

### Checkpoint B — packaged visual/traversal acceptance

After automated verification and profiling pass, Codex provides one ignored packaged launcher. PASS requires the expected intersection and four masses, a responsive window, a clear path from start through the intersection toward the end marker, and normal close. This is layout/capture-pipeline acceptance, not an art-quality or final-FPS approval.

## Risks and rollback

- **Base:** `3f157cbf0a65937af7dbd6813136e9c2298fb3dc`.
- A greybox with Engine cubes cannot predict production Manhattan GPU, VRAM, streaming, AI, physics, or network cost; its numbers are explicitly provisional and must not drive hardware requirements.
- Startup, shader, DDC, background applications, clocks, thermals, driver state, and current unapproved renderer defaults can distort the first runs; metadata and three repeats expose but do not eliminate those effects.
- The map is binary; strict path, hashes, actor setup, validation, cook, package, LFS, and screenshot checks reduce accidental-content risk.
- Rollback requires the map and packaged process closed, then a public-history revert after merge. Never delete, move, or rename the map in File Explorer.
- No save, gameplay, network protocol, or compatibility impact exists.

## Docs/ADR updates

- update the task index and STATUS with verified facts;
- create the measured provisional baseline report only after raw evidence exists;
- keep performance budgets provisional and do not freeze renderer/scalability values;
- create no system document or ADR because this task introduces no gameplay owner or hard-to-reverse architecture.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| August 30, 2026 | `a25a7621f4b91b6dc3c405f78d11f6abce46f498` | `88ae8e05d294d7846048b7fcc182cdd0a5a9bf0b` | Creator Checkpoint A: saved the 14-actor fixture at the exact path, showed the required labels/layout and one selected mass transform, then closed Unreal Editor. Core and Network maps remained byte-identical. | PASS | Madalin Gavrila |
| August 30, 2026 | `a25a7621f4b91b6dc3c405f78d11f6abce46f498` | `88ae8e05d294d7846048b7fcc182cdd0a5a9bf0b` | Runner self-test 6/6; `Tools/BS.cmd All` `PASS_WITH_SKIPS`; Automation 1/1; Validation 3/3; Cook with no project omission/warning; exact Map Check 0/0; UAT package exit 0; three 3,600-frame CSV/trace captures; Run 01 Insights CPU/GPU analysis completed. See [BS-PERF-002-P0](../Performance/Baselines/BS-PERF-002-P0.md). | AUTOMATED PASS; creator Checkpoint B pending. Allocation trace and unattended outer exit-code caveats retained in the report. | Codex |
| August 30, 2026 | `a25a7621f4b91b6dc3c405f78d11f6abce46f498` | `88ae8e05d294d7846048b7fcc182cdd0a5a9bf0b` | Creator Checkpoint B: Madalin completed the ignored packaged visual/traversal check without reporting a mismatch and supplied the launcher result. The retained log loaded the exact map, recorded `Alt-F4`, requested status `0`, completed `PreExit` and engine shutdown, and closed with no fatal/crash marker. Launcher exit code `0`; log SHA-256 `C296C735551CE131715D7502713CCDFC20F7A7A95791089C4C02D58CDE256390`. | PASS | Madalin Gavrila |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later task/status/evidence-only commit may reference the unchanged tree.

## Final handoff

BS-013 has passed the asset, runner, Map Check, package, three-run CSV/trace, first Unreal Insights, and both creator checkpoints on the exact candidate. The remaining gates are integration, independent backup/restore, remote audit, and final LFS unlock. The task remains **Needs Owner Verification** until those recovery and repository gates pass.
