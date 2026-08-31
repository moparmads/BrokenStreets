# BS-019 — Minimal Authority and State Debug Overlay

**Status:** Done
**Owner:** Madalin Gavrila
**Branch:** `main`
**Base commit:** `01d80424a2a567a42b80260f69e39b8ac219fab6`
**Roadmap milestone:** M2 — Minimum core and observability
**System docs:** `Docs/Systems/Core.md`

## Observable outcome

Broken Streets has one local, read-only Development overlay that identifies the current world, network mode, local player controller, possessed pawn, actor roles, and bounded diagnostic state. It is off by default, can be enabled explicitly with `bs.Debug.AuthorityStateOverlay 1`, and does not exist in Shipping.

## Why now

BS-014 through BS-018 established stable IDs, bounded diagnostics, compatibility, result, command, and asset-loading contracts. BS-019 adds the smallest practical authority view before replicated gameplay state exists, so later network work can distinguish host-server, host-client, remote-client, and standalone observations without inventing a gameplay framework.

## In scope

- add one pure snapshot/formatting boundary for local authority diagnostics;
- observe the current world, local player controller, possessed pawn, network mode, local role, remote role, controller state, and bounded local object identity;
- draw a compact read-only overlay through Unreal's debug canvas only when explicitly enabled;
- expose `bs.Debug.AuthorityStateOverlay 0|1` only in non-Shipping builds;
- emit one bounded structured log when the overlay changes state, including owner, authority, and diagnostic ID;
- add deterministic Automation coverage for stable names, snapshot construction, and output bounds;
- prove that the overlay command, renderer, and Automation code are absent from Shipping;
- synchronize task, Core, roadmap, status, task index, and test documentation.

## Out of scope

- RPCs, replication, authorization, ownership mutation, gameplay commands, inventory, save data, or persistence;
- a universal debug registry, service locator, remote telemetry, network transport, replay capture, or production UI;
- Blueprint widgets, UMG/CommonUI assets, maps, input mappings, plugins, Engine Source, or external dependencies;
- permanent Tick, timers, global Actor scans, polling, or synchronous loads;
- stable gameplay identity for PlayerController or Pawn before a real gameplay owner exists;
- enabling debug output by default or exposing debug tooling in Shipping.

## Dependencies and required decisions

- BS-014 through BS-018 are Done on `main` at base commit `01d80424a2a567a42b80260f69e39b8ac219fab6`.
- Reversible default: the first consumer is the current local PlayerController/Pawn view. No generic producer registry is added.
- Reversible default: the command is a process-local console variable and defaults to zero. One PIE command enables every local viewport in that process.
- Reversible default: `object_id` is explicitly a bounded, process-local diagnostic identifier from Unreal, not a StableId, save key, network identity, or authority proof.
- Reversible default: the overlay renders through `UDebugDrawService` under the standard `Game` show flag and performs no work while disabled.
- No ADR is required because the feature is Development-only, read-only, isolated, and removable without save, network, content, or compatibility migration.

## Allowed files/domains

- `Source/BrokenStreets/Public/Core/Debug/**`;
- `Source/BrokenStreets/Private/Core/Debug/**`;
- `Source/BrokenStreets/Tests/**`;
- `Source/BrokenStreets/BrokenStreets.cpp` for Development-only registration and shutdown;
- `Docs/**` files directly affected by BS-019.

Forbidden: `Content/**`, `Config/**`, `.uproject`, plugins, Engine Source, renderer/input/map settings, backup tooling, generated project files, and unrelated gameplay domains.

## Authority/network impact

The overlay observes authority; it never grants or changes authority. It reads the local view only and cannot prove permission, ownership, authenticity, compatibility, persistence, or server acceptance. Network traffic, replicated properties, RPCs, bandwidth, relevance, dormancy, reconnect, and late join remain unchanged.

## Persistence/migration impact

BS-019 writes no save data and changes no schema. `object_id` is deliberately process-local and must never be serialized. Save/load, migration, corruption, receipt, and crash-recovery tests are N/A.

## Performance budget

- zero work while the console variable is disabled;
- at most one local controller and its current pawn are inspected for each rendered local viewport while enabled;
- no Tick, timer, Actor iterator, world scan, allocation-owning registry, synchronous load, or disk/network I/O;
- a bounded number of short overlay lines and one log only when the enabled state changes.

## Blueprint/Editor impact

C++ owns observation, stable machine names, formatting, bounds, and rendering. No Blueprint, widget, asset, map, setting, or creator-authored file is required. Unreal Editor must remain closed during structural builds and may open only after the candidate build passes.

## Acceptance criteria

1. **Given** the overlay is not explicitly enabled, **when** a game viewport renders, **then** no Broken Streets authority/state text is drawn and no per-frame log is emitted.
2. **Given** a valid local viewport, **when** `bs.Debug.AuthorityStateOverlay 1` is set in a non-Shipping build, **then** a compact overlay shows world, net mode, controller, pawn, local/remote roles, state, and bounded diagnostic identity.
3. **Given** standalone, listen-server, or client observations, **when** a snapshot is formatted, **then** network and role names are deterministic and unknown values fail to `invalid`.
4. **Given** a PlayerController with or without a Pawn, **when** the snapshot is built, **then** missing objects are explicit and no global search or gameplay mutation occurs.
5. **Given** the enabled state changes, **when** the command is processed, **then** one bounded log shows owner, authority, object ID, and enabled state without free-form player data.
6. **Given** Shipping, **when** the module compiles, **then** the command name, renderer registration, state-change log, and Automation implementation are absent.

## Automated verification

- `BrokenStreets.Core.Debug.AuthorityState.Names`;
- `BrokenStreets.Core.Debug.AuthorityState.Snapshot`;
- all existing `BrokenStreets.Core` tests and the project smoke test;
- PowerShell runner self-test;
- `Tools/BS.cmd All` for Generate, Development Editor Build, Automation, Data Validation, and Cook;
- Win64 Shipping build and string/Automation marker audit;
- renderer/config regression, changed/generated-file, English-prose, secrets, Git/LFS, reachable-object, and independent-backup audits.

## Manual acceptance

Goal: confirm the exact C++ candidate builds, all Core tests pass, and a two-player listen-server PIE session shows distinct host/client authority views.

Applications needed: Visual Studio 2026 and Unreal Editor 5.8.2.

Unreal Editor state: Closed before build; Open only after build succeeds.

Visual Studio state: Open for build; it may be closed before the Editor tests.

Expected duration: 10–15 minutes.

Files/assets created or modified manually: none.

Do not touch: Project Settings, config files, Content, maps, Blueprints, plugins, or code.

1. Open `F:\BrokenStreets\BrokenStreets.sln` in Visual Studio.
   Expected: the `BrokenStreets` solution finishes loading.
2. Set `Solution Configurations` to `Development Editor` and `Solution Platforms` to `Win64`.
   Expected: the top bar shows both exact values.
3. In `Solution Explorer`, expand `Games`, right-click `BrokenStreets`, and click `Build`.
   Expected: `Output` ends with `Build: 1 succeeded, 0 failed` or an up-to-date success with zero errors.
4. Close Visual Studio if desired, then open `F:\BrokenStreets\BrokenStreets.uproject`.
   Expected: Unreal Editor opens directly in UE 5.8 without an engine-selection, module-rebuild, or crash dialog.
5. Click `Tools` > `Session Frontend`, open the `Automation` tab, and enter `BrokenStreets.Core` in the filter.
   Expected: fifteen Core tests are listed, including `Debug.AuthorityState.Names` and `Debug.AuthorityState.Snapshot`.
6. Select every filtered test and click `Start Tests`.
   Expected: all fifteen tests are green, with 0 failed and 0 skipped.
7. Open `/Game/BS/Maps/Test/L_TestGym_Network`, open Play options from the three-dot button beside the Play controls, choose two players, `Play As Listen Server`, `Run Under One Process`, and a new Editor window.
   Expected: one listen-server view and one client view are available without changing project files.
8. In the Editor command field or Output Log, enter `bs.Debug.AuthorityStateOverlay 1`, then start PIE.
   Expected: both views show the bounded Broken Streets authority/state overlay.
9. Inspect both views.
   Expected: the host shows `net_mode=listen_server` with authoritative controller/pawn local roles; the client shows `net_mode=client` with autonomous-proxy controller/pawn local roles. Both views show world, state, and non-zero local diagnostic object IDs.
10. Enter `bs.Debug.AuthorityStateOverlay 0` if desired, stop PIE, and close Unreal Editor without saving.
    Expected: the overlay disappears when disabled and no Content, map, Blueprint, configuration, or project setting is modified.

Checkpoint A

PASS if the Visual Studio build has zero failures, all fifteen filtered Core tests pass with zero failures/skips, the two-player PIE views show the expected distinct authority states, and no engine-selection, rebuild, or crash dialog appears.

FAIL if compilation reports any introduced error/warning, an expected test is missing or fails/skips, either overlay is missing, host/client net mode or roles are wrong, or Unreal presents an engine-selection, rebuild, or crash dialog. Stop and send the complete Build output or Automation Testing Log plus one screenshot. Do not edit files or settings.

Checkpoint A result: PASS on August 31, 2026. Madalin Gavrila supplied Visual Studio evidence showing `Build: 1 succeeded, 0 failed` for `Development Editor | Win64`, Unreal Editor Session Frontend evidence showing all fifteen filtered `BrokenStreets.Core` tests green with 15 passed, 0 failed, and 0 skipped, and two-player PIE evidence from `L_TestGym_Network`. The listen-server view reported authoritative local controller and pawn roles, while the client view reported autonomous-proxy local controller and pawn roles; both displayed bounded state and non-zero local diagnostic object IDs. Unreal Editor was closed normally without saving project changes.

## Risks and rollback

- Base/rollback: `01d80424a2a567a42b80260f69e39b8ac219fab6`.
- Debug UI can accidentally become production behavior; every registration, command, renderer, and state-change log is compiled out of Shipping and audited.
- Local diagnostic identity can be mistaken for durable identity; labels and docs explicitly define `object_id` as process-local and non-persistent.
- Overlay work can become a hidden frame cost; disabled is the default and the enabled path is bounded to one local controller/pawn pair per viewport.
- Rollback is a normal revert plus Build/Test/Validate/Cook and Shipping audit. No asset, config, save, or network migration is required.

## Docs/ADR updates

- update Core observability, tests, manual acceptance, rollout, and verification evidence;
- register BS-019 and synchronize STATUS, ROADMAP, indexes, and test strategy;
- no ADR unless implementation requires production UI, remote transport, persistent identity, a generic registry, or Shipping exposure.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| 2026-08-31 | `12e6f0ba5b79467e16f337dce12db2a7f35fe857` | tree `f8b781343b2da07c57c649e7ee3100134974104b`; Source `92457bc02ee9c61ca36049890677b7e5ebff8020`; unchanged Config `12d196629107bd334cdcc86e568d4525caa837ac`; unchanged Content `41343e24397b32d46f6f51c4fc5269c8005c6fdb`; unchanged `.uproject` blob `81b3ab16e37113b3dde101f341110349cf238899` | Generate/Build PASS with zero warnings; Automation 16/16 total including Core 15/15; Data Validation 3/3; Cook 514/521 plus 7 classified Engine-only omissions and zero project omissions/warnings; Win64 Shipping Build PASS; 16 Automation paths and 4 BS-019 debug markers audited with 0 found; renderer/config 52/52; default-off audit 0 overlay logs; explicit-on runtime check exactly 1 bounded structured enable log with owner, authority, object ID, state, and standalone net mode; Git/LFS/scope/static audits; candidate generations `20260831T163653Z-26548-d762bd94`, `20260831T164440Z-19924-8a9584ab`, and accepted checkpoint `20260831T165357Z-4564-956ff1bc`, each with 37 refs and all 3 LFS objects; creator Visual Studio Development Editor Build 1 succeeded/0 failed; creator Unreal Editor Automation 15/15; creator two-player listen-server/client PIE overlay PASS | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
| 2026-08-31 | merge `40fd9a9066f50cd7059f7b1aaa7c14bb908b39c1` | tree `89deeb9851f92abc80f8b62f48f44f04e6d447df`; accepted Source `92457bc02ee9c61ca36049890677b7e5ebff8020`; unchanged Config `12d196629107bd334cdcc86e568d4525caa837ac`; unchanged Content `41343e24397b32d46f6f51c4fc5269c8005c6fdb`; unchanged `.uproject` blob `81b3ab16e37113b3dde101f341110349cf238899` | post-merge Generate/Build PASS; Automation 16/16 total including Core 15/15; Data Validation 3/3; Cook 514/521 plus 7 classified Engine-only omissions with zero project omissions/warnings; renderer/config 52/52; integration generation `20260831T170058Z-27824-d9d07c06` captured 37 refs and all 3 LFS objects | PASS; implemented on local `main`, GitHub synchronization awaiting explicit publication approval | Madalin Gavrila and Codex |

## Final handoff

- exact command, snapshot, field, bound, and Shipping-exclusion contracts;
- candidate hash/tree plus automated, Cook, Shipping, regression, and backup evidence;
- creator build, Automation, and two-player PIE overlay steps with PASS/FAIL criteria;
- skipped/N/A checks with reasons;
- rollback commit and next task BS-020.

BS-019 is Done on local `main` at merge `40fd9a9066f50cd7059f7b1aaa7c14bb908b39c1`. The accepted Source, Config, Content, and `.uproject` identities remained exact through integration, and the complete post-merge gate passed. The next task is BS-020. GitHub synchronization is an external publication step and is recorded separately when approved and completed.

Retained local evidence:

- complete gate: `Saved/Automation/BS-009/20260831T163715Z-18348-32164e08/run.json`, SHA-256 `3B1C4D97AE00F68C5D44888D20156E0D70860E51FA37419636BD45AC72ED191D`;
- Automation report: `Saved/Automation/BS-009/20260831T163715Z-18348-32164e08/Steps/04-Test/TestReport/index.json`, SHA-256 `0754E62ECAF79C48B1B6E9C7A5467D6460EA6B98B38245AD40AFC1775754699C`;
- Shipping build: `Saved/Verification/BS-019/12e6f0b/ShippingBuild/UnrealBuildTool.log`, SHA-256 `B65C3503C2C1FA4BFB5932273F907C25A040CE3FFAB0F99B11CA7DA769F11691`;
- Shipping executable: `Binaries/Win64/BrokenStreets-Win64-Shipping.exe`, SHA-256 `A08925B2E2F6B6A922EF55A1943945D68C32E41D0972E40D89211EB3956FD5B3`;
- explicit-on runtime log: `Saved/Verification/BS-019/12e6f0b/RuntimeOverlay/Unreal.log`, SHA-256 `4295D18EFC39DD95B2F890981834EF0ABD9BA7850C31ED59F6B3576396CD0247`;
- renderer/config audit: `Saved/Verification/BS-013B/20260831T164216Z-12432/renderer-audit.json`, SHA-256 `67699B53323F8320FF1D1B92C0926ED57EAF284C14D9C58AFC254E8E5CA6E8D2`;
- accepted-checkpoint repository generation: `E:/BrokenStreets_RepositoryBackup/Generations/20260831T165357Z-4564-956ff1bc`, with 37 refs and all 3 LFS objects.
- post-merge complete gate: `Saved/Automation/BS-009/20260831T165917Z-32528-ba060479/run.json`, SHA-256 `CF9BE637C83967DC5D0F6F85BC58D43B6344770B7F1EE56EE731D3F775C641E9`;
- post-merge Automation report: `Saved/Automation/BS-009/20260831T165917Z-32528-ba060479/Steps/04-Test/TestReport/index.json`, SHA-256 `8216B970604863B9FF0F10E96F24AE4F53B44AA4E63FD7198EE7F29C24BADCF0`;
- post-merge repository generation: `E:/BrokenStreets_RepositoryBackup/Generations/20260831T170058Z-27824-d9d07c06`, with 37 refs and all 3 LFS objects.
