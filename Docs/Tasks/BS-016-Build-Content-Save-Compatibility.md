# BS-016 — Build, Content, and Save Compatibility Handshake

**Status:** Needs Owner Verification
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-016-compatibility-handshake`
**Base commit:** `0772b9dd8f323461661a5f042ed435481951743b`
**Roadmap milestone:** M2 — Minimum core and observability
**System docs:** `Docs/Systems/Core.md`

## Observable outcome

Broken Streets exposes one deterministic C++ compatibility contract that describes the current build-compatibility lane, content-compatibility lane, current save schema, and oldest readable save schema. A caller can evaluate a peer or profile signature and receive one stable, specific decision: compatible, invalid input, build mismatch, content mismatch, save schema too old, or save schema too new. The project-owned defaults load successfully at startup and malformed configuration fails closed.

## Why now

BS-014 established stable identity and BS-015 established bounded diagnostics and configuration-backed controls. Every future session or profile boundary must reject incompatible state before materialization. BS-016 supplies that narrow shared contract before BS-017 adds generic results/command envelopes, BS-018 adds content catalogs, and BS-020 creates the first persisted save header and migration harness.

## In scope

- add a plain C++ `FBSCompatibilitySignature` containing non-zero build, content, and save-schema versions presented by a future peer or profile;
- add a plain C++ `FBSCompatibilityPolicy` containing the local exact build/content versions plus the inclusive readable save-schema range;
- add `EBSCompatibilityResult` with stable machine names for the exact acceptance or rejection reason;
- add strict canonical unsigned-decimal parsing and fail-closed project configuration loading from `[BrokenStreets.Compatibility]`;
- set reversible initial defaults to build `1`, content `1`, current save schema `1`, and minimum readable save schema `1`;
- validate the project-owned compatibility policy once during module startup without retaining mutable global state or emitting routine success spam;
- add pure Automation coverage for parsing, construction/invariants, project defaults, deterministic precedence, and every compatibility outcome;
- synchronize Core, status, roadmap, task index, and test documentation;
- run the complete Build/Test/Validate/Cook gate plus Win64 Shipping and test-marker audits.

## Out of scope

- save files, save headers, serializers, migration execution, checksums, generations, recovery UI, or profile materialization; those begin at BS-020 and later save tasks;
- RPCs, connection approval, OnlineSubsystem/Steam integration, replicated objects, session travel, or overriding Unreal's native network-version handshake;
- Asset Manager, catalog hashes, asset scanning, redirects, or content loading; those belong to BS-018;
- generic result/error types, commands, correlation IDs, localized player messages, or recovery envelopes; those belong to BS-017 and the first consumer;
- marketing/build display versions, automatic Git hashes, timestamps, engine-version changes, or a version bump on every commit;
- Blueprint APIs, UI, maps, assets, plugins, Engine Source, renderer, or unrelated gameplay work.

## Dependencies and required decisions

- BS-014, BS-014A, and BS-015 are Done on `main` at base commit `0772b9dd8f323461661a5f042ed435481951743b`.
- Accepted architecture requires build, content, and save schema compatibility before a profile is accepted.
- Core owns shared version metadata; Network owns future connection approval and Save owns future header parsing, migration, and materialization.
- Reversible default: build and content versions must match exactly. These values are compatibility lanes and change only for an incompatible runtime/protocol or content-contract change, not for every build or commit.
- Reversible default: save compatibility is the inclusive range `MinimumReadableSaveSchemaVersion..CurrentSaveSchemaVersion`; values outside it fail closed as too old or too new.
- Reversible default: all four initial values are `1`. This reserves the first compatibility lane for BS-020 but does not claim that a save file or serializer exists yet.
- Reversible default: evaluation reports invalid policy/signature before mismatch details, then checks build, content, too-old schema, and too-new schema in that fixed order.
- No ADR is required because the policy is explicit, local, configurable, has no persisted or replicated consumer yet, and can evolve through a future version/migration task before player data exists.

## Allowed files/domains

- `Source/BrokenStreets/BrokenStreets.cpp`;
- `Source/BrokenStreets/Public/Core/Compatibility/**` and `Source/BrokenStreets/Private/Core/Compatibility/**`;
- `Source/BrokenStreets/Tests/**`;
- `Config/DefaultGame.ini`;
- `Docs/Systems/Core.md`, this task packet, task/index/status/roadmap/testing/workflow documents only where synchronization is required;
- no `Content/**`, `.uproject`, Build.cs/module dependency, Engine Source, plugin, renderer, map, online, save-file, or gameplay-domain changes.

## Authority/network impact

Core represents and evaluates immutable compatibility metadata only. No gameplay truth, RPC, connection decision, replicated object, audience, relevancy, rate limit, or server/client mutation path is added. A future Network owner may consume the build/content decision at connection approval, but late join, reconnect, disconnect, four-player separation, latency, and bandwidth tests are N/A in BS-016 because there is no network consumer or payload.

## Persistence/migration impact

Project configuration gains version metadata, but BS-016 creates no save store, serialized header, schema layout, migration, player profile, world save, generation, or recovery operation. The schema range is a pre-materialization decision contract only. BS-020 must use the reserved schema lane or explicitly bump it with migration evidence. Persistence/fault tests beyond pure compatibility decisions are N/A until a real save format exists.

## Performance budget

- evaluation is constant time over four `uint32` values with no allocation, scan, Tick, Actor, UObject, subsystem, task, thread, asset load, or network traffic;
- configuration loading occurs only at startup or an explicit compatibility boundary and reads exactly four bounded canonical decimal values;
- stable result names are static literals; successful startup emits no routine message;
- no performance trace is required because there is no hot path or representative workload.

## Blueprint/Editor impact

- the API is C++ only and deliberately not reflected or serializable before BS-020 defines the real save boundary;
- no Blueprint nodes, assets, Project Settings panel, maps, or manual configuration are added;
- Unreal Editor must be closed for the structural C++ build and opened only for Automation acceptance;
- the creator does not edit configuration, code, Content, maps, or Engine files.

## Acceptance criteria

1. **Given** canonical non-zero versions and a readable save range, **when** a policy/signature is created, **then** it is valid and exposes the exact values; zero, noncanonical, overflow, or inverted-range input is rejected and clears the output.
2. **Given** the source-controlled project defaults, **when** the current policy is loaded, **then** it resolves to build `1`, content `1`, current save schema `1`, and minimum readable save schema `1`.
3. **Given** a valid matching signature, **when** it is evaluated, **then** the result is `Compatible`.
4. **Given** an invalid policy/signature or a mismatched build/content/save schema, **when** it is evaluated, **then** it fails closed with the stable specific result and deterministic precedence.
5. **Given** a future local policy with current schema greater than minimum readable schema, **when** an older signature remains inside that inclusive range, **then** it is accepted; values below or above the range are rejected.
6. **Given** a Shipping target, **when** the module compiles, **then** no Automation implementation, test name, or developer-only dependency enters Shipping.

## Automated verification

- `BrokenStreets.Core.Compatibility.Policy`;
- `BrokenStreets.Core.Compatibility.Evaluation`;
- all existing `BrokenStreets.Core` tests and project smoke test;
- PowerShell runner self-test;
- `Tools/BS.cmd All` for Generate, Development Editor Build, Automation, Data Validation, and Cook;
- Win64 Shipping build and test-name/class-marker audit;
- renderer/config baseline audit because `DefaultGame.ini` changes;
- `git diff --check`, changed/generated-file audit, local-link audit, secrets scan, Git/LFS status, and `git lfs fsck`.

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
   Expected: eight Core tests are listed: the six accepted BS-014/BS-015 tests plus two Compatibility tests.
6. Select every filtered test and click `Start Tests`.
   Expected: all eight tests are green, with 0 failed and 0 skipped.

Checkpoint A

PASS if the build has zero failures and all eight `BrokenStreets.Core` Automation tests pass with zero failures/skips and no rebuild/crash dialog.

FAIL if compilation reports any introduced error/warning, Unreal asks to choose an engine or rebuild modules, a Core test is missing, or any test is red/yellow. Stop and send the complete Visual Studio Build output or Automation Testing Log plus one screenshot. Do not edit files or settings.

Checkpoint A result: Pending creator execution for candidate `a516cbf7b777ec3b7ad5e128b70d9d0657b882ea`.

## Risks and rollback

- Base/rollback: `0772b9dd8f323461661a5f042ed435481951743b`.
- Bumping a compatibility lane too often would reject valid peers or profiles; versions change only for a reviewed incompatible contract change.
- Accepting unknown or malformed values could materialize unsafe state; every invalid policy/signature fails closed before mismatch evaluation.
- An exact build/content rule may later require an explicit compatible range; no live save or network consumer exists, so a future task can extend the contract with tests and an ADR if evidence requires it.
- Before any consumer depends on BS-016, rollback is a normal `git revert` followed by Build/Test/Validate/Cook. No asset, save, or network migration is required.

## Docs/ADR updates

- update `Docs/Systems/Core.md` with version ownership, numeric grammar, evaluation order, configuration defaults, boundaries, and tests;
- register this task and set STATUS/ROADMAP/Core to active BS-016 work;
- update testing documentation with the pure compatibility decision coverage;
- no ADR unless implementation must depart from the reversible defaults above.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| 2026-08-31 | `a516cbf7b777ec3b7ad5e128b70d9d0657b882ea` | tree `e2e9a465552cdfff1ddf80ba25c8c6634cbd6358`; Source `f4e53de56377d0aa3066f733a426efbd68b25c08`; Config `104bc2810fbeefaa6b33a36d824c273400c11e33`; unchanged Content `41343e24397b32d46f6f51c4fc5269c8005c6fdb` | runner self-test 6/6; `BS.cmd All` Generate/Build/Test/Validate PASS and Cook controlled skips; Automation 9/9; assets 3/3; Cook 514/521 plus 7 classified Engine-only omissions, zero project omissions/warnings; Win64 Shipping Build PASS; 18 Shipping Automation markers audited with 0 found; direct renderer/config audit 52/52; local links 45/45; Git/LFS/reachable-object, scope, generated-file, and secret audits PASS; independent candidate generation `20260831T124836Z-39684-2d542d46` captured 30 refs and all 3 LFS objects | Automated PASS; creator Build and Editor Automation 8/8 pending | Codex |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- exact signature/policy/result/config contracts and defaults;
- candidate hash/tree plus automated and Shipping evidence;
- creator build and eight-Core-test steps with PASS/FAIL criteria;
- skipped/N/A checks with reasons;
- rollback commit and next task BS-017.

Automated candidate verification is complete. The task remains `Needs Owner Verification` until Madalin completes Checkpoint A. Runtime/config acceptance is tied to candidate `a516cbf7b777ec3b7ad5e128b70d9d0657b882ea`; this evidence update changes documentation only.

Retained local evidence:

- complete gate: `Saved/Automation/BS-009/20260831T124853Z-36332-beb43c37/run.json`, SHA-256 `F24F861186240A676C4384301DE869C9BD247940DC3B9ABA342B30FFFDEE1BA1`;
- Automation report: `Saved/Automation/BS-009/20260831T124853Z-36332-beb43c37/Steps/04-Test/TestReport/index.json`, SHA-256 `6243D6EEDFEB86516B71FF476C62B03CAEF382B67F9BD12EE184E17D9B9C102E`;
- Shipping build: `Saved/Verification/BS-016/a516cbf/ShippingBuild/UnrealBuildTool.log`, SHA-256 `1577C5651E0D369293A67DB63713DC6D0A1D4DFCA1CB51A61B874A1BE7F35EC7`;
- Shipping executable: `Binaries/Win64/BrokenStreets-Win64-Shipping.exe`, SHA-256 `77687062DFDE1A2FF80F416BFFE62048B3587F1E1FECD7FFC92F1D608B27BB85`;
- renderer/config audit: `Saved/Verification/BS-016/a516cbf/RendererAudit/renderer-audit.json`, SHA-256 `7E0FC03623FE1CE1F66D64EB3CF355FFD90A061B8AE3595933C4F582AA72A5A7`;
- pre-verification repository generation: `E:/BrokenStreets_RepositoryBackup/Generations/20260831T124836Z-39684-2d542d46`, with exact candidate HEAD, 30 refs, and all 3 LFS objects.

The `BS-RendererBaseline.cmd Audit` wrapper twice encountered the known Codex-host Windows PowerShell command-availability instability and could not resolve the standard `Get-FileHash` command inside its nested script. The unchanged underlying audit script was then executed directly under Windows PowerShell and passed 52/52, producing the retained report above. No renderer tool or project runtime input was changed.
