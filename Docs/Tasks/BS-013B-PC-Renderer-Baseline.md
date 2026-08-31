# BS-013B — PC Configuration and Renderer Baseline

**Status:** Done
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

The automated candidate is complete. Madalin performs only these steps:

1. Keep Unreal Editor closed.
2. Open `F:\BrokenStreets\BrokenStreets.sln` in Visual Studio.
3. Select `Development Editor` and `Win64`, then choose **Build > Build Solution**. Expected result: `Build: 1 succeeded, 0 failed` with no new project warning.
4. Close Visual Studio after the build.
5. Open PowerShell in `F:\BrokenStreets` and run `.\Tools\BS-RendererBaseline.cmd Visual`. Do not edit Project Settings.
6. Click the packaged game window, look around with the mouse, and move with `W A S D`. Expected result: the Benchmark Street greybox opens at 1920×1080, the floor/sky and four large block masses are visible, input is responsive, and no crash or obvious rendering defect appears.
7. Close the game once with `Alt+F4`. If the result matches, reply that it passed. If it differs, keep the message window open and send one screenshot; do not change settings.

Prepared package: `Saved/Packages/BS-013B/b646af3-20260830T210716Z/Windows/`.

Creator progress on August 31, 2026:

- Visual Studio `Development Editor | Win64` compilation passed with `1 succeeded, 0 failed, 0 up-to-date, 0 skipped`.
- The first `Visual` attempt passed the renderer audit 52/52, then stopped before launching the game because the creator PowerShell PATH did not expose `git`.
- Tool-fix commit `5fc22aa14ebd4b9933d8add4697ba42add2e3fb8` now resolves Git from the repository backup pin/bundled Codex runtime without requiring a separate installation or PATH edit. The exact `.cmd` entry point passed its Git-resolution self-test with Git deliberately absent from PATH, and the audit passed 52/52.
- The visual retry passed. Madalin inspected and traversed the exact packaged fixture, observed no rendering mismatch or crash dialog, and closed it once with `Alt+F4`. The launcher returned `0`. The retained 107,644-byte log confirms D3D12, SM6, `PCD3D_SM6`, `raytracing="0"`, exact-map play, `Alt-F4`, status-0 exit, `PreExit Game`, and `LogExit: Exiting`, with no fatal/crash marker. SHA-256: `65FA652197620E6DB4D1E31BD94AE1D459CCC71BFB8BCA232FA7416CC653C2ED`.

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
| 2026-08-31 | `b646af33b1676088adae9dbb320f01c4a9ba9d27` | tree `d0984c6f083280a62bc5d292b156b462b45cddde`; Config `67fc0de9d562f5bb87d8ca549c6ce18404161649`; Content `41343e24397b32d46f6f51c4fc5269c8005c6fdb`; Source `1b7850b3b6330e9fece6a41b8b35f34d7f9e3ec1` | parser PASS; audit 52/52; audit self-test 5/5; runner self-test 6/6; `BS.cmd All` `PASS_WITH_SKIPS`; Map Check 0/0; UAT/package PASS; three 3,000-stable-frame captures PASS | Automated PASS; owner visual pending | Codex |
| 2026-08-31 | `5fc22aa14ebd4b9933d8add4697ba42add2e3fb8` | tree `e42430f3292e5abb92a4f12eae1fcfd39152d950`; unchanged Config/Content/Source; Tools `c53a8676d798de9339fad400d5db30e01b5e9370` | creator compile 1/0; first Visual audit 52/52 then pre-launch Git-resolution failure; fixed exact `.cmd` self-test PASS with Git absent from PATH; post-fix audit 52/52; audit self-test 5/5; runner self-test 6/6 | Tool regression PASS; owner visual retry pending | Madalin Gavrila / Codex |
| 2026-08-31 | `b86a2ba5628d39dc02c7eafa5bee3f00ae796185` | tree `2a2403925eed67a0f5f4b43d47eb85318aab6bf6`; unchanged Config/Content/Source/Tools | creator `Visual` audit 52/52; exact packaged map and DX12/SM6/raytracing-off markers; normal `Alt+F4` status-0 shutdown; 107,644-byte log SHA-256 `65FA652197620E6DB4D1E31BD94AE1D459CCC71BFB8BCA232FA7416CC653C2ED` | Creator PASS | Madalin Gavrila |
| 2026-08-31 | merge `0ad6838713c5f8ecfd41800f4a1dc7d378b9bcca` | tree `82031eddfdc1074760d6dc534bbef5c84c9b1f9d` equals accepted feature tree | post-merge AST/self-test/audit 52/52; Git LFS fsck; local/GitHub `main`; recovery generation `20260830T213740Z-21976-658d5ff8` with 21 refs and 3 LFS objects | Integration and recovery PASS | Codex |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- implementation and audited configuration;
- exact build/test/cook/package/capture evidence and every skip;
- exact creator compile and visual acceptance steps;
- renderer limitations, rollback hash, and next task BS-007B.
