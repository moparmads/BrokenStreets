# BS-019 — Minimal Authority and State Debug Overlay

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-019-authority-state-overlay`
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

Detailed creator steps are finalized only after the automated candidate passes.

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

Pending candidate implementation and automated verification.

## Final handoff

- exact command, snapshot, field, bound, and Shipping-exclusion contracts;
- candidate hash/tree plus automated, Cook, Shipping, regression, and backup evidence;
- creator build, Automation, and two-player PIE overlay steps with PASS/FAIL criteria;
- skipped/N/A checks with reasons;
- rollback commit and next task BS-020.
