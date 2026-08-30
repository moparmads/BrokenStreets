# BS-013B — PC Configuration and Renderer Baseline

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-013B-pc-renderer-baseline`
**Base commit:** `7daaa19e26846d511a712b16c34482e35956c049`
**Roadmap milestone:** M1B — Recovery and documentation
**System docs:** N/A — project configuration and Build/Tools own this task; see `Docs/ARCHITECTURE.md` section 12 and ADR-0005

## Observable outcome

Broken Streets starts and packages only through the approved Windows PC path, opens project-owned maps by default, and has one reproducible 1080p renderer test preset. The approved test baseline is DX12/SM6, TSR, Nanite support, Virtual Shadow Maps, Software Lumen, and Substrate Blendable GBuffer, with project hardware ray tracing support disabled. A deterministic audit detects drift, unsupported platform configuration, reintroduced Android File Server secrets, or a changed benchmark preset.

This is an initial test baseline, not the final renderer, minimum hardware promise, or production optimization result. Final renderer acceptance remains gated by representative art and measurements.

## Why now

BS-011 through BS-013 created three project-owned maps and a repeatable packaged profiling fixture. The Blank/Maximum wizard still leaves an Engine template as the default map, hardware ray tracing enabled without evidence, two Windows shader paths, non-Windows target sections, and generated Android File Server configuration. BS-013B removes that ambiguity before core gameplay, clean-profile recovery, and comparative performance work.

## In scope

- set project-owned Editor, game, and server default maps;
- pin Win64 to DX12 and `PCD3D_SM6` for the current v1 baseline;
- keep Software Lumen, Virtual Shadow Maps, Nanite support, TSR, and mesh distance fields explicit;
- disable project hardware ray tracing support and its proxy path;
- keep Substrate enabled with the performance-oriented Blendable GBuffer format;
- explicitly disable the Android File Server plugin and remove its generated configuration and token;
- remove unused Linux, Mac, Android, D3D11, and SM5 target configuration from the project baseline;
- define one first-run and benchmark preset at 1920×1080, High scalability (`sg.*=2`), 100% screen percentage, VSync Off, Dynamic Resolution Off, and Frame Generation not required;
- add a deterministic configuration/preset audit and self-test;
- build, test, validate, cook, package, and record three comparable packaged runs on `L_Benchmark_Street`;
- accept ADR-0005 for this test baseline while retaining the representative-art reevaluation gate.

## Out of scope

- final Minimum, Recommended, Host, or Ultra hardware specifications;
- mandatory or optional production hardware ray tracing;
- final Low/Recommended/Ultra tuning, automatic hardware detection, or a graphics settings UI;
- DLSS, FSR, XeSS, Frame Generation, Dynamic Resolution tuning, or external plugins;
- final material complexity, Adaptive Substrate GBuffer, Nanite/LOD/HLOD asset budgets, or content import policy;
- map, material, Blueprint, mesh, texture, lighting, gameplay, networking, input, save, or Engine Source changes;
- claiming performance gains from the empty placeholder map.

## Dependencies and required decisions

- BS-011, BS-012, BS-013, and BS-013A are Done.
- Decisions 16–24 permit a non-RT Low path, upscalers, cosmetic scaling, and a provisional 1080p/60 Recommended target.
- Madalin Gavrila approved option A on August 30, 2026: DX12/SM6, Software Lumen, VSM, TSR/Nanite support, Substrate Blendable GBuffer, and hardware RT disabled for the initial baseline.
- ADR-0005 records the reversible technical boundary and the later representative-art gate.

## Allowed files/domains

- `Config/DefaultEngine.ini`;
- `Config/DefaultGameUserSettings.ini`;
- `BrokenStreets.uproject` only for the explicit Android File Server disable;
- `Tools/Renderer/**`, `Tools/BS-RendererBaseline.cmd`, and `Tools/README.md`;
- relevant documents under `Docs/` including task, status, ADR, toolchain, architecture, roadmap/index, and a compact performance report;
- no `Content/**`, `Source/**`, Engine Source, unrelated Config, plugin source, or Source Art changes.

## Authority/network impact

N/A. This task changes local renderer, platform, startup-map, and developer verification configuration. It introduces no gameplay truth, RPC, replication audience, late-join state, or reconnect behavior. The existing four-process fixture remains a regression gate only.

## Persistence/migration impact

N/A. No save format or gameplay state exists. First-run local graphics settings may be regenerated for the test preset; ignored per-user settings are not versioned truth.

## Performance budget

- The runtime update model is unchanged; this task adds no Tick, Actor, system, or network traffic.
- Test preset ID: `BS-PC-Recommended-P0`.
- Packaged Win64 Development, D3D12/SM6, 1920×1080, High scalability, 100% screen percentage, VSync Off, Dynamic Resolution Off, one standalone player, benchmark map.
- Three fresh runs, fixed warm-up and stable-frame count, with p50/p95/p99/max frame, GT, RT, GPU, hitches, working set, and available VRAM counters retained.
- Provisional informational target: limiting-pipeline p95 at or below 13.33 ms with no repeated post-warm-up 50 ms hitch and no post-warm-up 100 ms hitch.
- A PASS establishes repeatability and reports the result honestly. It does not freeze production hardware or prove final Manhattan performance.

## Blueprint/Editor impact

- No Blueprint or binary asset changes.
- Unreal Editor and Visual Studio stay closed during configuration edits and automated verification.
- The first Editor launch may rebuild renderer shaders because hardware RT support and shader targets changed.
- Creator acceptance uses the packaged benchmark map; no manual Project Settings editing is permitted.

## Acceptance criteria

1. **Given** a clean checkout, **when** the configuration audit runs, **then** all approved PC, renderer, map, plugin, and preset values match and no Android File Server token or unsupported target section exists.
2. **Given** a first-run profile, **when** Broken Streets loads defaults, **then** it selects the project-owned TestGym map and the `BS-PC-Recommended-P0` quality contract.
3. **Given** a Win64 package, **when** its staged metadata is inspected, **then** it contains the three project maps, targets D3D12/SM6, excludes project-owned SM5 output, and does not load Android File Server.
4. **Given** the benchmark launcher, **when** it runs the packaged executable, **then** the exact benchmark map and pinned renderer preset are recorded in the log before measurement.
5. **Given** three fresh captures, **when** stable samples are analyzed, **then** every required field and any threshold miss, warning, or limitation is retained in the compact baseline report.
6. **Given** Low or future preset work, **when** quality is reduced, **then** gameplay entities remain unchanged; this task changes only renderer/cosmetic configuration.
7. **Given** creator acceptance, **when** Madalin opens the packaged checkpoint, **then** the benchmark fixture is visible, responsive, and closes normally without a crash dialog or unexpected rendering defect.

## Automated verification

- Windows PowerShell 5.1 parser for every changed script;
- renderer audit self-test with both valid and deliberately invalid isolated fixtures;
- `Tools/BS-RendererBaseline.cmd Audit`;
- existing runner self-test;
- `Tools/BS.cmd All` with Build, Automation, Data Validation, and Cook gates;
- exact benchmark-map Map Check;
- Win64 Development Build/Cook/Stage/Package/Archive for the benchmark map;
- staged shader-format, plugin, map, warning, and secret audit;
- three packaged `BS-PC-Recommended-P0` captures and compact analysis;
- Git/LFS/config-secret/generated-file audit.

## Manual acceptance

Exact steps and the packaged launcher path are filled after the verified candidate exists. Madalin will compile the exact candidate in Visual Studio, launch the prepared packaged checkpoint, confirm the expected benchmark image and responsiveness, close it normally, and return the complete log or a screenshot only if the expected result differs.

## Risks and rollback

- Base: `7daaa19e26846d511a712b16c34482e35956c049`.
- Disabling hardware RT removes RT shader/runtime availability from this baseline; enabling it later requires an explicit configuration change, full shader/cook verification, fallback, and benchmark.
- Substrate remains enabled, but complex multi-slab materials may become expensive; content budgets remain a later representative-art gate.
- DX12/SM6 reduces legacy GPU compatibility; exact Minimum hardware remains unpromised until measured.
- Removing unused target configuration must not be confused with permanently rejecting future ports. A future platform task can reintroduce and verify them.
- Rollback uses `git revert` of the accepted BS-013B implementation and evidence commits, followed by Build/Test/Validate/Cook. No save or asset migration is required.

## Docs/ADR updates

- accept and narrow ADR-0005 to the initial PC test baseline plus M15 reevaluation;
- synchronize the ADR index, Architecture configuration section, Toolchain, Performance budgets/baseline, task index, Roadmap status, and STATUS;
- do not describe the placeholder as representative production art.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| | | | | | |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- implementation and audited configuration;
- exact build/test/cook/package/capture evidence and every skip;
- exact creator compile and visual acceptance steps;
- renderer limitations, rollback hash, and next task BS-007B.
