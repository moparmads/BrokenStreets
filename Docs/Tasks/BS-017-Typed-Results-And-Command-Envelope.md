# BS-017 — Typed Results, Errors, and Command Envelope

**Status:** Needs Owner Verification
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-017-results-command-envelope`
**Base commit:** `180a9a83fd686a3414c821569db19df088265077`
**Roadmap milestone:** M2 — Minimum core and observability
**System docs:** `Docs/Systems/Core.md`

## Observable outcome

Broken Streets exposes one small, deterministic C++ boundary for future domain commands: strongly separated command and correlation identifiers, a validatable command envelope, a bounded canonical error code, and an invariant result that is either succeeded, rejected, or failed. The types do not execute, retry, authorize, replicate, persist, or display a command.

## Why now

BS-014 established stable definition/instance identity, BS-015 established bounded diagnostics, and BS-016 established compatibility decisions. Future Asset Manager, save, session, economy, inventory, and job boundaries need a shared way to identify one logical command, correlate child work, and return a machine-readable outcome without inventing incompatible strings or treating transport failure as gameplay authority. BS-017 supplies only that narrow vocabulary before BS-018 creates the first content-loading consumer.

## In scope

- add a GUID-backed `FBSCommandId` whose value identifies one logical command across retries;
- add a distinct GUID-backed `FBSCorrelationId` whose value groups a root command and explicitly created child work;
- add `FBSCommandEnvelope` with exactly one valid command ID and one valid correlation ID;
- support valid root-envelope creation, explicit child-envelope creation with a new command ID and inherited correlation ID, and strict canonical parsing for both ID types;
- add bounded `FBSErrorCode` text in exact `<domain>.<reason>` form with two lowercase ASCII snake_case segments;
- add closed `EBSResultStatus` values `Invalid`, `Succeeded`, `Rejected`, and `Failed`, with stable lowercase machine names;
- add invariant `FBSResult` construction: success contains no error; rejection/failure requires one valid error code; invalid input clears output;
- add pure Automation coverage for grammar, type separation, clearing, uniqueness, root/child correlation, result invariants, and stable names;
- synchronize Core, status, roadmap, task index, and testing documentation;
- run the complete Build/Test/Validate/Cook gate plus Win64 Shipping and test-marker audits.

## Out of scope

- RPCs, replication, connection approval, OnlineSubsystem/Steam, rate limiting, permission checks, or a concrete server command handler;
- a universal command base class, payload container, reflection registry, service locator, event bus, global dispatcher, middleware pipeline, or handler map;
- automatic retry, retry counts, timeout/deadline, wall-clock timestamps, cancellation, queueing, prioritization, or background execution;
- expected revisions, ProfileEpoch, TransactionId, receipts, deduplication stores, journals, compensation, or cross-PC commit policy;
- save bytes, serializers, schema changes, migration, archive operators, checksums, recovery, or materialization;
- free-form error details, stack traces, raw payloads, player-facing text, localization keys, toast/UI mapping, telemetry, analytics, or new log categories;
- Blueprint APIs, UObjects, Actors, subsystems, maps, assets, configuration, plugins, Engine Source, renderer, or gameplay-domain work.

## Dependencies and required decisions

- BS-014, BS-014A, BS-015, and BS-016 are Done on `main` at base commit `180a9a83fd686a3414c821569db19df088265077`.
- Accepted architecture requires typed command flow, single-writer domain ownership, explicit results, stable identity, and idempotent multi-domain operations.
- Reversible default: command and correlation IDs use distinct C++ types even though both store one non-zero GUID and use the same canonical lowercase hyphenated external form.
- Reversible default: a root envelope generates independent command and correlation IDs. A child envelope receives a new command ID and preserves only the parent's correlation ID.
- Reversible default: retrying the same logical command reuses its original command ID; creating a child or a genuinely new operation creates a new command ID. Core records no deduplication state.
- Reversible default: error codes contain exactly two 1–64 character segments separated by one dot. Each segment begins with a lowercase ASCII letter and then accepts lowercase letters, digits, or underscores.
- Reversible default: `Rejected` is a deliberate terminal refusal by a future owner; `Failed` means execution could not report success or a deliberate refusal. Neither status grants automatic retry or proves whether a future multi-step operation needs recovery.
- Reversible default: machine error codes are diagnostics/control-flow identifiers, never trusted input, authority, or player-visible English. A future consumer owns the reviewed mapping to localized presentation.
- No ADR is required because these plain value types add no persisted/replicated format or difficult-to-reverse execution framework. The first real consumer may extend its own typed payload/result without weakening these invariants.

## Allowed files/domains

- `Source/BrokenStreets/Public/Core/Commands/**` and `Source/BrokenStreets/Private/Core/Commands/**`;
- `Source/BrokenStreets/Public/Core/Results/**` and `Source/BrokenStreets/Private/Core/Results/**`;
- `Source/BrokenStreets/Tests/**`;
- `Docs/Systems/Core.md`, this task packet, task/index/status/roadmap/testing documents only where synchronization is required;
- no `Config/**`, `Content/**`, `.uproject`, Build.cs/module dependency, Engine Source, plugin, renderer, online, save, UI, or gameplay-domain changes.

## Authority/network impact

Core validates and represents immutable metadata only. The envelope never authenticates a caller, proves permission, approves a connection, applies state, or chooses a replication audience. A future server-side domain owner must still validate identity, permission, distance, state, rate limit, payload bounds, and stale/replayed input. No RPC, Actor, replicated property, packet, late-join state, reconnect behavior, or bandwidth is added, so solo/client/four-player network tests are N/A in BS-017.

## Persistence/migration impact

BS-017 creates no persistent store, archive format, schema, journal, receipt, deduplication record, migration, or recovery flow. IDs and error codes are value contracts only; their future serialization requires the owning Network/Save/transaction task to define a versioned boundary and fault evidence. Save/load/corruption/crash tests are N/A because no bytes are written.

## Performance budget

- creation and validation are constant time over at most two GUIDs or 129 error-code characters;
- no allocation occurs for GUID-only validity/equality; error parsing performs one bounded string scan;
- no Tick, scheduler, global scan, container, UObject, Actor, asset load, thread, task, RPC, or network traffic is added;
- no performance trace is required because there is no runtime loop or representative workload.

## Blueprint/Editor impact

- the API is plain C++ and deliberately not reflected before a real Blueprint or data consumer exists;
- no Blueprint nodes, assets, Project Settings, maps, tags, or manual configuration are added;
- Unreal Editor must be closed for the structural C++ build and opened only for Automation acceptance;
- the creator does not edit code, configuration, Content, maps, or Engine files.

## Acceptance criteria

1. **Given** a default, zero, malformed, uppercase, braced, or noncanonical command/correlation ID, **when** it is parsed, **then** it is rejected and prior output is cleared; canonical non-zero lowercase GUID text round-trips exactly.
2. **Given** root and child command envelopes, **when** they are created, **then** every envelope is valid, command IDs are unique, and a child preserves only the root correlation ID.
3. **Given** an error code, **when** it is parsed, **then** only exact bounded `<domain>.<reason>` text is accepted and any failure clears prior output.
4. **Given** a result, **when** it is constructed, **then** success contains no error while rejection/failure each contain one valid error; invalid status/error combinations cannot be created through the public API.
5. **Given** unknown enum values, **when** a stable name is requested, **then** Core returns bounded `unknown` without exposing raw input or free-form text.
6. **Given** a Shipping target, **when** the module compiles, **then** no Automation implementation, test name, or developer-only dependency enters Shipping.

## Automated verification

- `BrokenStreets.Core.Commands.Envelope`;
- `BrokenStreets.Core.Results.Policy`;
- all existing `BrokenStreets.Core` tests and the project smoke test;
- PowerShell runner self-test;
- `Tools/BS.cmd All` for Generate, Development Editor Build, Automation, Data Validation, and Cook;
- Win64 Shipping build and test-name/class-marker audit;
- `git diff --check`, changed/generated-file audit, local-link audit, secrets scan, Git/LFS status, reachable-object audit, and `git lfs fsck`.

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
   Expected: ten Core tests are listed: the eight accepted BS-014 through BS-016 tests plus Commands Envelope and Results Policy.
6. Select every filtered test and click `Start Tests`.
   Expected: all ten tests are green, with 0 failed and 0 skipped.

Checkpoint A

PASS if the build has zero failures and all ten `BrokenStreets.Core` Automation tests pass with zero failures/skips and no engine-selection, rebuild, or crash dialog.

FAIL if compilation reports any introduced error/warning, Unreal asks to choose an engine or rebuild modules, a Core test is missing, or any test is red/yellow. Stop and send the complete Visual Studio Build output or Automation Testing Log plus one screenshot. Do not edit files or settings.

Checkpoint A result: Pending creator execution for candidate `0e113a5eb8fa55be066e44e4acd37bcbb8c0fd3b`.

## Risks and rollback

- Base/rollback: `180a9a83fd686a3414c821569db19df088265077`.
- A generic payload/dispatcher would centralize domain truth and create premature coupling; BS-017 deliberately provides values only.
- Confusing correlation with idempotency could duplicate mutations; documentation and tests pin command ID as logical-command identity and correlation ID as grouping only.
- Treating `Failed` as safe automatic retry could duplicate future partial work; the contract explicitly grants no retry behavior.
- Error codes may later need a richer registry or localization mapping; no player-facing or persisted consumer exists, so a future consumer can add its own reviewed mapping without migration.
- Before any consumer depends on BS-017, rollback is a normal `git revert` followed by Build/Test/Validate/Cook. No asset, save, network, or configuration migration is required.

## Docs/ADR updates

- update `Docs/Systems/Core.md` with command/correlation identity, result/error invariants, authority boundaries, and tests;
- register this task and set STATUS/ROADMAP/Core to active BS-017 work;
- update testing documentation with pure command/result coverage;
- no ADR unless implementation must introduce persistence, replication, or a generic execution framework outside the reversible defaults above.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| 2026-08-31 | `0e113a5eb8fa55be066e44e4acd37bcbb8c0fd3b` | tree `0d204b9784a2d362f303d10843ed724667064744`; Source `a24007261a6d9139be7e8830badfc4afd9b85055`; unchanged Config `104bc2810fbeefaa6b33a36d824c273400c11e33`; unchanged Content `41343e24397b32d46f6f51c4fc5269c8005c6fdb` | runner self-test 6/6; `BS.cmd All` Generate/Build/Test/Validate PASS and Cook controlled skips; Automation 11/11; assets 3/3; Cook 514/521 plus 7 classified Engine-only omissions, zero project omissions/warnings; Win64 Shipping Build PASS; 22 Shipping Automation markers audited with 0 found; local links 46/46; Git/LFS/reachable-object, scope, generated-file, and secret audits PASS; independent candidate generation `20260831T145854Z-35204-e331a983` captured 32 refs and all 3 LFS objects | Automated PASS; creator Build and Editor Automation 10/10 pending | Codex |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- exact command/correlation/error/result contracts and invariants;
- candidate hash/tree plus automated and Shipping evidence;
- creator build and ten-Core-test steps with PASS/FAIL criteria;
- skipped/N/A checks with reasons;
- rollback commit and next task BS-018.

Automated candidate verification is complete. The task remains `Needs Owner Verification` until Madalin completes Checkpoint A. Runtime acceptance is tied to candidate `0e113a5eb8fa55be066e44e4acd37bcbb8c0fd3b`; this evidence update changes documentation only. Network, persistence/fault, and performance scenarios are N/A because BS-017 adds no RPC, replicated state, persisted bytes, command executor, retry store, Tick, or representative workload. Renderer/config audit is N/A because Config is byte-identical to the accepted BS-016 baseline.

Retained local evidence:

- complete gate: `Saved/Automation/BS-009/20260831T145926Z-14120-2d87047a/run.json`, SHA-256 `313D9FBE834C1094F6A7BB3B4FAEB7083E2AE7176DD6FC4FD8CAB4C2DAF29E53`;
- Automation report: `Saved/Automation/BS-009/20260831T145926Z-14120-2d87047a/Steps/04-Test/TestReport/index.json`, SHA-256 `83CC051EDC24C1B64A02726E37DB57967F438C74EC41219AEE7CBEFB01E75672`;
- Shipping build: `Saved/Verification/BS-017/0e113a5/ShippingBuild/UnrealBuildTool.log`, SHA-256 `C82B56AF8ADCA480DB24390C96DA764DA05F1A3CE1BB9AF350C4D59DBD5856C7`;
- Shipping executable: `Binaries/Win64/BrokenStreets-Win64-Shipping.exe`, SHA-256 `E39D6C7CD5EA373C653969446F9BE596B3367FC27651E9E852B61DFAC4BCE5CE`;
- pre-verification repository generation: `E:/BrokenStreets_RepositoryBackup/Generations/20260831T145854Z-35204-e331a983`, with exact candidate HEAD, 32 refs, and all 3 LFS objects.
