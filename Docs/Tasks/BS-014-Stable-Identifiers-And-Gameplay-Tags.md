# BS-014 — Stable Identifiers and Gameplay Tags Policy

**Status:** Needs Owner Verification
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-014-stable-ids-tags`
**Base commit:** `56ad7c9f5f0188b949bd7c8b6ab0179fa60ed1c8`
**Roadmap milestone:** M2 — Minimum core and observability
**System docs:** `Docs/Systems/Core.md`

## Observable outcome

The project exposes two distinct reflected C++ value types: a stable `FBSDefinitionId` for immutable catalog identity and an `FBSInstanceId` for unique runtime/persistent instances. Both reject invalid input, have one canonical text representation, support deterministic round-trip serialization, equality, and hashing, and cannot be implicitly substituted for each other.

The project also owns a single native `BS` Gameplay Tag root and a documented tag policy. Runtime tag contracts must use central native declarations, data-only classification may use reviewed config sources, tag redirects preserve renames, and tags never serve as definition or instance identity.

## Why now

M1 proved that the empty project is buildable and recoverable. Every later definition, save record, command, ownership record, and replicated read model needs stable identity before it can be implemented. Gameplay Tags also need a namespace and compatibility policy before gameplay systems create an uncontrolled dictionary.

## In scope

- add `FBSDefinitionId` with canonical `<type>:<name>` text, bounded validation, hashing, equality, and archive round-trip;
- add `FBSInstanceId` backed by `FGuid`, with generation, exact canonical parsing, hashing, equality, and archive round-trip;
- keep both wrappers reflected and usable by later save/data types without exposing unvalidated Blueprint mutation APIs;
- add the Gameplay Tags runtime dependency and the native root tag `BS`;
- pin safe initial Gameplay Tags settings: config import and invalid-tag warnings on, fast and dynamic replication off, game tag unloading off;
- define ownership, naming, redirect, classification, and identity rules in the Core system document;
- add unit-style Automation coverage for valid, invalid, duplicate, distinct-type, hash, and round-trip behavior;
- run the existing complete Build/Test/Validate/Cook gate.

## Out of scope

- domain-specific IDs such as `CharacterId`, `TransactionId`, `ItemInstanceId`, `VehicleInstanceId`, or `PropertyInstanceId` before their owning consumers exist;
- Asset Manager registration, definition assets, duplicate-catalog validation, soft-loading rules, or content redirects; BS-018 owns those;
- save schema, migration registry, networking, RPCs, tag replication tuning, Iris, or compatibility handshake;
- gameplay tag families for systems that do not exist yet;
- gameplay, Blueprint, map, content, plugin, UI, or Engine Source changes;
- a generic ID template, universal registry, event bus, or framework without a second demonstrated consumer.

## Dependencies and required decisions

- BS-007B and the M1 recovery gate are Done at base commit `56ad7c9f5f0188b949bd7c8b6ab0179fa60ed1c8`.
- `Docs/ARCHITECTURE.md` already requires immutable `DefinitionId`, typed or GUID instance identity, and Gameplay Tags only for classification.
- `Docs/SYSTEM_OWNERSHIP.md` assigns typed IDs and tags to Core, which may not depend on gameplay or UI.
- Reversible default: definition IDs use lowercase ASCII `<type>:<name>` segments with letters, digits, and underscore, beginning with a letter and limited to 64 characters per segment.
- Reversible default: project tags use the `BS` root; fast/dynamic replication remains disabled until a real replicated consumer and BS-016 compatibility contract can measure it.
- No ADR is required because this task implements existing architecture invariants and keeps serialization and tag-replication choices versionable.

## Allowed files/domains

- `Source/BrokenStreets/Public/Core/**` and `Source/BrokenStreets/Private/Core/**`;
- `Source/BrokenStreets/Tests/**`;
- `Source/BrokenStreets/BrokenStreets.Build.cs`;
- `Config/DefaultGameplayTags.ini`;
- the task, Core system, task/system indexes, status, roadmap/architecture/testing docs only where synchronization is required;
- no `Content/**`, `.uproject`, Engine Source, plugin, renderer, map, save, online, or unrelated gameplay changes.

## Authority/network impact

Core owns the value-type contracts but no gameplay truth. ID creation occurs in the future domain owner; BS-014 only supplies validation and representation. There is no RPC, replication audience, late join, reconnect, or disconnect behavior. Gameplay Tag fast/dynamic replication is explicitly disabled until a real network consumer exists.

## Persistence/migration impact

No save file exists and no schema version changes. The types are archive-serializable foundations only. Invalid loaded values remain invalid and must be rejected by a future owning schema. A shipped `DefinitionId` may be replaced only through an explicit migration map; a tag rename uses a Gameplay Tag redirect. Neither mechanism is implemented by this task because no production identifiers or tags exist.

## Performance budget

- no Tick, Actor, subsystem, task, thread, allocation loop, or network traffic;
- validation and text conversion occur at data boundaries, not per frame;
- equality and hashing are bounded by a maximum 129-character DefinitionId string or one 128-bit GUID;
- tag fast replication stays off until measured; no performance claim is made.

## Blueprint/Editor impact

- both IDs are reflected `BlueprintType` structs for future property compatibility;
- C++ owns construction and validation; no Blueprint factory or mutation library is added without a consumer;
- one native root tag is visible in the tag dictionary after module startup but must not be assigned as gameplay classification by itself;
- no assets or Editor setup are required;
- Unreal Editor must be closed for the structural C++ and module dependency build.

## Acceptance criteria

1. **Given** a canonical string such as `item:water_bottle`, **when** it is parsed, serialized, loaded, hashed, and compared, **then** the same valid `FBSDefinitionId` is recovered and duplicate set insertion produces one entry.
2. **Given** missing separators, empty segments, uppercase, whitespace, invalid punctuation, a digit-leading segment, an extra separator, or an overlong segment, **when** DefinitionId parsing runs, **then** it fails and clears the output.
3. **Given** a newly generated or canonical lowercase hyphenated GUID, **when** it is parsed and round-tripped, **then** the same valid `FBSInstanceId` is recovered; zero, uppercase, malformed, or differently formatted GUID text is rejected.
4. **Given** `FBSDefinitionId` and `FBSInstanceId`, **when** code is compiled, **then** neither type is implicitly convertible or constructible from the other or from its raw storage type.
5. **Given** the Broken Streets module starts, **when** Gameplay Tags initialize, **then** native root `BS` is valid and the project settings match the pinned safe defaults.
6. **Given** a Shipping target, **when** the module compiles, **then** no Automation implementation or developer-only dependency enters Shipping.

## Automated verification

- compile-time type-separation assertions;
- `BrokenStreets.Core.Identity.DefinitionId`;
- `BrokenStreets.Core.Identity.InstanceId`;
- `BrokenStreets.Core.Tags.Policy`;
- PowerShell runner self-test;
- `Tools/BS.cmd All` for Generate, Development Editor Build, all Automation, Data Validation, and Cook;
- `git diff --check`, changed-file audit, generated-file audit, secrets scan, Git/LFS status and fsck.

## Manual acceptance

Goal: confirm the exact reflected C++ candidate builds on the creator workstation and the three Core tests pass in the Editor.

Applications needed: Visual Studio 2026 and Unreal Editor 5.8.2.

Unreal Editor state: Closed before build; Open only after build succeeds.

Visual Studio state: Open for build; it may be closed before the Editor test.

Expected duration: 5–10 minutes.

Files/assets created or modified manually: none.

Do not touch: Engine Source, Project Settings, Gameplay Tags settings, Blueprints, maps, Content, or code.

1. Open `F:\BrokenStreets\BrokenStreets.sln` in Visual Studio.
   Expected: the `BrokenStreets` solution finishes loading.
2. Set `Solution Configurations` to `Development Editor` and `Solution Platforms` to `Win64`.
   Expected: the top bar shows both exact values.
3. In `Solution Explorer`, expand `Games`, right-click `BrokenStreets`, and click `Build`.
   Expected: `Output` ends with `Build: 1 succeeded, 0 failed` or an up-to-date success with zero errors.
4. Close Visual Studio if desired, then open `F:\BrokenStreets\BrokenStreets.uproject`.
   Expected: Unreal Editor opens without requesting a module rebuild or showing a crash dialog.
5. Click `Tools` > `Session Frontend`, open the `Automation` tab, and enter `BrokenStreets.Core` in the filter.
   Expected: exactly the DefinitionId, InstanceId, and Tags Policy tests are listed.
6. Select all three filtered tests and click `Start Tests` (triangle/play icon).
   Expected: 3 tests complete, 0 fail, 0 skip, and all three rows are green.

Checkpoint A

PASS if the build has zero failures and Automation reports 3 passed, 0 failed, 0 skipped.

FAIL if compilation reports any error/warning introduced by this task, Unreal asks to rebuild modules, a test is missing, or any test is red/yellow. Stop and send the complete Visual Studio `Build` output or the `Automation Testing Log` plus one screenshot. Do not edit files or settings.

## Risks and rollback

- Base/rollback: `56ad7c9f5f0188b949bd7c8b6ab0179fa60ed1c8`.
- The main risk is freezing an identifier format before consumers exist; the task limits this to two fundamental forms and keeps domain IDs for their real tasks.
- Definition text is intentionally strict; later display names remain separate localized data and do not weaken identity.
- Tag replication settings are conservative and explicitly revisited with a real replicated catalog.
- Before production data exists, rollback is a normal `git revert` of BS-014 followed by Build/Test/Validate/Cook. No asset or save migration is required.

## Docs/ADR updates

- create `Docs/Systems/Core.md` and register it in the system catalog;
- add this task to the task index and set STATUS/ROADMAP to M2 active work;
- record exact identity and tag rules without duplicating product decisions;
- no ADR unless implementation must depart from the accepted architecture.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| 2026-08-31 | `2449d3ff0aad8500e27a0496add703ac64c5d35b` | tree `70f58a379a05964a34ae377027af0338f3792ded`; Source `0ca7358128a5f68cec8925858d23eaf7dfe72622`; Config `4c801f96e4de5e9812037c5b24124b194a093019`; unchanged Content `41343e24397b32d46f6f51c4fc5269c8005c6fdb` | runner self-test 6/6; `BS.cmd All` Generate/Build/Test/Validate PASS and Cook controlled skips; Automation 4/4; assets 3/3; Win64 Shipping Build PASS; Shipping test-marker audit PASS; links 50/50; Git/LFS/fsck and secret/generated-file audits PASS | Automated PASS; creator compile and Editor Automation pending | Codex |

Retained local evidence:

- complete gate: `Saved/Automation/BS-009/20260831T103708Z-20564-804c8203/run.json`, SHA-256 `0788983132A7657D746350E1DA03CE1F94AB7FB369DAA31E17066A0AEF8B305C`;
- Automation report: `Saved/Automation/BS-009/20260831T103708Z-20564-804c8203/Steps/04-Test/TestReport/index.json`, SHA-256 `D65313EE77ECF837FE2C56F2F341037D163467266EF5CA6D3201027A3CAB0861`;
- Shipping build: `Saved/Verification/BS-014/2449d3f/ShippingBuild/UnrealBuildTool.log`, SHA-256 `860C522C5978D9835C2A8C61C2B5D1AAFE8A5492B08B2C8C80B92193829417D0`.

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- exact ID and Gameplay Tags contracts;
- candidate hash/tree and automated logs;
- creator build and three-test steps with PASS/FAIL;
- skipped/N/A checks with reasons;
- rollback commit and next task BS-015.
