# BS-015 — Core Observability and Feature Flags

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-015-core-observability`
**Base commit:** `0abb2d6e31fb8f57e11255a0cbbba5784b42725f`
**Roadmap milestone:** M2 — Minimum core and observability
**System docs:** `Docs/Systems/Core.md`

## Observable outcome

Broken Streets exposes two native log categories, a bounded structured log context, and a typed configuration-backed feature-flag query. Core diagnostics are disabled by default, malformed or unknown flags fail closed, and enabling the first diagnostic flag produces one structured module-startup message without changing gameplay state.

## Why now

BS-014 established stable identifiers and the central Core boundary. BS-016 and every later domain need consistent diagnostics and reversible rollout controls before they introduce compatibility, commands, persistence, networking, or gameplay state.

## In scope

- add native `LogBrokenStreets` and `LogBSCore` categories with documented ownership;
- add `FBSLogContext` with one required bounded operation name and optional validated `FBSDefinitionId` and `FBSInstanceId` fields;
- emit context in one deterministic, single-line, key/value order suitable for searching logs;
- add typed `EBSFeatureFlag` and `FBSFeatureFlags` configuration lookup with explicit fail-closed behavior;
- add the first real flag, `CoreVerboseDiagnostics`, defaulted to `False` and consumed only during module startup;
- add native Automation coverage for context validation/formatting, category identity, and feature-flag policy;
- synchronize Core, status, roadmap, task index, and testing documentation where required;
- run the complete existing Build/Test/Validate/Cook gate and a Shipping build/test-marker audit.

## Out of scope

- a universal logger, macro framework, telemetry pipeline, analytics service, remote configuration, console-variable override, or runtime admin UI;
- arbitrary free-form key/value fields, player display names, account data, secrets, raw network payloads, or other private data in structured context;
- dynamic flag mutation, replication, persistence in save files, per-player flags, experiments, percentages, cohorts, or backend rollout;
- results/errors and command/correlation envelopes, which belong to BS-017;
- gameplay, Blueprint, UI, map, asset, plugin, Engine Source, online, save, or renderer changes;
- defining log categories or flags for domains that do not exist yet.

## Dependencies and required decisions

- BS-014 and corrective BS-014A are Done on `main` at base commit `0abb2d6e31fb8f57e11255a0cbbba5784b42725f`.
- `Docs/SYSTEM_OWNERSHIP.md` assigns feature flags to Core and forbids Core dependencies on gameplay or UI.
- Reversible default: operation names use 1–64 lowercase ASCII letters, digits, or underscores and begin with a letter.
- Reversible default: structured fields are fixed and ordered as `operation`, `definition_id`, then `instance_id`; invalid optional IDs are rejected and never logged.
- Reversible default: flags are a closed C++ enum backed by the `[BrokenStreets.FeatureFlags]` game-config section. Missing, malformed, and unknown values resolve to disabled.
- Reversible default: flag reads happen only at startup or explicit state boundaries, never on Tick or in a hot loop.
- No ADR is required because the implementation is local, reversible, has no saved/networked compatibility, and follows the accepted Core ownership model.

## Allowed files/domains

- `Source/BrokenStreets/BrokenStreets.cpp` and `Source/BrokenStreets/BrokenStreets.h`;
- `Source/BrokenStreets/Public/Core/**` and `Source/BrokenStreets/Private/Core/**`;
- `Source/BrokenStreets/Tests/**`;
- `Config/DefaultGame.ini`;
- `Docs/Systems/Core.md`, this task packet, task index, status, roadmap, and testing/workflow docs only where synchronization is required;
- no `Content/**`, `.uproject`, Engine Source, plugin, renderer, map, save, online, or unrelated gameplay changes.

## Authority/network impact

Core owns representation and configuration lookup only. No gameplay truth, RPC, replicated object, audience, relevancy rule, or server/client mutation path is added. Late join, reconnect, disconnect, four-player separation, latency, and bandwidth are N/A because no network consumer exists.

## Persistence/migration impact

Feature-flag defaults live in project configuration metadata only. No save store, schema, migration, player profile, world save, or recovery path changes. Structured log context is ephemeral and is never serialized as authoritative state.

## Performance budget

- no Tick, Actor, UObject, subsystem, task, thread, scan, network traffic, or asset load;
- operation validation is bounded to 64 characters and optional identifiers reuse the BS-014 bounded types;
- formatted context is created only at a log boundary;
- feature flags are read only at startup or another explicit low-frequency boundary, not per frame;
- disabled startup diagnostics emit no message and allocate no formatted context.

## Blueprint/Editor impact

- the API is C++ only; no Blueprint nodes, assets, Project Settings panel, or manual configuration are added;
- Unreal Editor must be closed for the structural C++ build and opened only for Automation acceptance;
- the creator does not edit config, code, Content, maps, or Engine files.

## Acceptance criteria

1. **Given** a canonical operation and optional valid BS-014 identifiers, **when** a log context is formatted, **then** it produces one deterministic single-line string in the fixed field order.
2. **Given** empty, uppercase, whitespace, punctuation, digit-leading, newline, or overlong operation input, **when** context creation runs, **then** it fails and clears the output.
3. **Given** an invalid optional identifier, **when** it is assigned to a valid context, **then** the assignment fails and no stale identifier remains in the context.
4. **Given** the default project configuration, **when** `CoreVerboseDiagnostics` is queried, **then** it is disabled; explicit valid true/false values resolve correctly, while malformed and unknown flags resolve disabled.
5. **Given** the Broken Streets module starts with diagnostics disabled, **when** the Editor or game boots, **then** there is no new routine log spam; when the flag is explicitly enabled, exactly one structured startup diagnostic is eligible to emit.
6. **Given** a Shipping target, **when** the module compiles, **then** no Automation implementation, test name, or developer-only dependency enters Shipping.

## Automated verification

- `BrokenStreets.Core.Observability.Context`;
- `BrokenStreets.Core.Observability.Categories`;
- `BrokenStreets.Core.FeatureFlags.Policy`;
- existing `BrokenStreets.Core` and project smoke tests;
- PowerShell runner self-test;
- `Tools/BS.cmd All` for Generate, Development Editor Build, Automation, Data Validation, and Cook;
- Win64 Shipping build and test-name/class-marker audit;
- `git diff --check`, changed/generated-file audit, secrets scan, Git/LFS status, and `git lfs fsck`.

## Manual acceptance

Goal: confirm the exact C++ candidate builds on the creator workstation and every Core test passes in Unreal Editor.

Applications needed: Visual Studio 2026 and Unreal Editor 5.8.2.

Unreal Editor state: Closed before build; Open only after build succeeds.

Visual Studio state: Open for build; it may be closed before the Editor test.

Expected duration: 5–10 minutes.

Files/assets created or modified manually: none.

Do not touch: Engine Source, Project Settings, config files, Blueprints, maps, Content, or code.

1. Open `F:\BrokenStreets\BrokenStreets.sln` in Visual Studio.
   Expected: the `BrokenStreets` solution finishes loading.
2. Set `Solution Configurations` to `Development Editor` and `Solution Platforms` to `Win64`.
   Expected: the top bar shows both exact values.
3. In `Solution Explorer`, expand `Games`, right-click `BrokenStreets`, and click `Build`.
   Expected: `Output` ends with `Build: 1 succeeded, 0 failed` or an up-to-date success with zero errors.
4. Close Visual Studio if desired, then open `F:\BrokenStreets\BrokenStreets.uproject`.
   Expected: Unreal Editor opens directly in UE 5.8 without an engine-selection, module-rebuild, or crash dialog.
5. Click `Tools` > `Session Frontend`, open the `Automation` tab, and enter `BrokenStreets.Core` in the filter.
   Expected: the BS-014 identity/tag tests and the new BS-015 observability/feature-flag tests are listed.
6. Select every filtered test and click `Start Tests`.
   Expected: every test is green, with 0 failed and 0 skipped.

Checkpoint A

PASS if the build has zero failures and every `BrokenStreets.Core` Automation test passes with zero failures/skips and no rebuild/crash dialog.

FAIL if compilation reports any introduced error/warning, Unreal asks to choose an engine or rebuild modules, a Core test is missing, or any test is red/yellow. Stop and send the complete Visual Studio Build output or Automation Testing Log plus one screenshot. Do not edit files or settings.

## Risks and rollback

- Base/rollback: `0abb2d6e31fb8f57e11255a0cbbba5784b42725f`.
- A general-purpose logger or unbounded context could leak private data or create noise; the task permits only fixed validated fields and two owned categories.
- Repeated config lookup could become a hot-path cost; the contract forbids per-frame queries and the first consumer runs once at module startup.
- Flags can create permanent divergent behavior; the initial flag affects diagnostics only, defaults off, and no gameplay flag is introduced without its owning consumer and acceptance test.
- Before any consumer depends on BS-015, rollback is a normal `git revert` followed by Build/Test/Validate/Cook. No asset, save, or network migration is required.

## Docs/ADR updates

- update `Docs/Systems/Core.md` with the implemented categories, context grammar, feature-flag ownership, privacy, performance, and test policy;
- register this task and set STATUS/ROADMAP to active BS-015 work;
- no ADR unless implementation must depart from the reversible defaults above.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| | | | | | |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- exact log/category/context/flag contracts and defaults;
- candidate hash/tree plus automated and Shipping evidence;
- creator build and Core-test steps with PASS/FAIL criteria;
- skipped/N/A checks with reasons;
- rollback commit and next task BS-016.
