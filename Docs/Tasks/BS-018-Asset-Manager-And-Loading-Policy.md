# BS-018 — Asset Manager and Soft-Reference Loading Policy

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-018-asset-manager-loading-policy`
**Base commit:** `1de51b14c74d44a8bfa7673349c9071f8dd42191`
**Roadmap milestone:** M2 — Minimum core and observability
**System docs:** `Docs/Systems/Core.md`, `Docs/Systems/Items.md`

## Observable outcome

Broken Streets has one concrete, data-driven item-definition boundary registered with Unreal Asset Manager. Every item definition uses its immutable `item:<name>` DefinitionId as its Primary Asset ID, keeps presentation assets as soft references, exposes separate `World` and `UI` bundles, and can be requested only through a validated asynchronous loading API with explicit release. The project contains no production catalog entries yet and never loads the future catalog in bulk at runtime.

## Why now

BS-014 established stable DefinitionId values and their Primary Asset ID conversion. BS-015 through BS-017 added bounded diagnostics, compatibility, and result contracts. BS-018 creates the first real definition consumer before save, inventory, shops, vehicles, or large catalogs depend on content paths. It closes the M2 hard-reference risk without inventing a universal catalog framework.

## In scope

- add a concrete `UBSItemDefinition` Primary Data Asset owned by Items;
- require a valid `item:<name>` DefinitionId and return it as the stable Primary Asset ID;
- add optional soft references for a world mesh and UI icon, assigned to explicit `World` and `UI` Asset Manager bundles;
- register native item definitions under `/Game/BS/Definitions/Items` through project-owned Asset Manager configuration;
- use recursive `AlwaysCook` management for registered item definitions and their selected bundles without loading them all at runtime;
- add a bounded request value and one asynchronous Asset Manager gateway; reject invalid IDs, wrong definition types, unknown/duplicate bundles, unavailable Asset Manager state, and unregistered definitions;
- add an unloaded catalog audit that checks the registered item type, canonical IDs, duplicate IDs, and project path without loading definition objects;
- add Editor data validation for identity, filename, package path, and soft-reference policy;
- add deterministic Automation coverage for definition identity, request policy, Asset Manager configuration, and the unloaded catalog audit;
- synchronize task, Items/Core, roadmap, status, system index, task index, and test documentation.

## Out of scope

- production `.uasset` catalog entries, meshes, textures, icons, sounds, or source art;
- inventory, containers, ownership, prices, weight, capacity, rarity, legality, shops, stock, vehicles, equipment, or gameplay effects;
- a universal definition base class, universal registry, service locator, dependency injection framework, or custom Asset Manager subclass;
- synchronous gameplay loading, startup loading of every definition, permanent strong references, preloading an entire catalog, or unmanaged streamable handles;
- Blueprint loading helpers, UI, maps, renderer changes, plugins, Engine Source, external dependencies, or build-system changes;
- Primary Asset redirects or content-version increments before a real renamed/deprecated definition exists;
- RPCs, replication, network authorization, save files, schemas, migration, transactions, retries, or command dispatch.

## Dependencies and required decisions

- BS-014 through BS-017 are Done on `main` at base commit `1de51b14c74d44a8bfa7673349c9071f8dd42191`.
- Confirmed architecture requires data-driven catalogs, stable DefinitionIds, Asset Manager or a validated equivalent, and soft references for large presentation assets.
- Reversible default: `item` is the first concrete Primary Asset type because Items already owns item definitions and later inventory/shop tasks need them; other domains add their own concrete types only when their first consumer exists.
- Reversible default: `World` and `UI` are the only allowed bundles. A request may select neither, one, or both; duplicate or unknown bundle names fail closed.
- Reversible default: registered item definitions and selected bundle dependencies use `AlwaysCook`; this affects package inclusion, not runtime residency.
- Reversible default: no production item asset is created in BS-018. The first owning gameplay task creates and validates the first real catalog entry.
- No ADR is required because the task follows accepted architecture, uses stock Unreal facilities, adds no external dependency, and leaves domain expansion reversible.

## Allowed files/domains

- `Source/BrokenStreets/Public/Items/Definitions/**`;
- `Source/BrokenStreets/Private/Items/Definitions/**`;
- `Source/BrokenStreets/Public/Core/Assets/**` and matching `Private` implementation for the shared bounded loading gateway only;
- `Source/BrokenStreets/Tests/**`;
- `Config/DefaultGame.ini` for Asset Manager settings only;
- `Docs/**` files directly affected by BS-018.

Forbidden: `Content/**`, `.uproject`, plugins, Engine Source, renderer/input/map configuration, backup tooling, generated project files, and unrelated gameplay domains.

## Authority/network impact

Definitions are immutable shared data. The Asset Manager exists per process and does not grant gameplay authority. A valid DefinitionId or loaded definition never proves existence in a player's inventory, ownership, permission, legality, price, or server approval. BS-018 adds no RPC, Actor, replicated object, audience, late-join state, reconnect behavior, or bandwidth, so solo/client/four-player network tests are N/A.

## Persistence/migration impact

BS-018 writes no save data and changes no schema. Persistent records will store DefinitionId, never an asset path or UObject pointer. Asset renames/moves must preserve DefinitionId and later use reviewed Primary Asset or path redirects where necessary. Save/load, corruption, fault injection, migration, receipt, and crash tests are N/A because no bytes are persisted.

## Performance budget

- no Tick, timer, global Actor scan, synchronous gameplay load, or startup load of all item definitions;
- catalog audit reads Asset Registry metadata and Primary Asset IDs without materializing definition objects;
- each request carries one item ID and at most two unique known bundle names;
- runtime loading uses Unreal's asynchronous `LoadPrimaryAsset` path and explicit release;
- no representative production assets or runtime consumer exist, so frame/memory profiling is N/A; build, Automation, Data Validation, and Cook detect structural regressions.

## Blueprint/Editor impact

- C++ owns identity, validation, request policy, and loading gateway;
- creators will later create native-class Data Asset instances under `/Game/BS/Definitions/Items` and configure data only;
- Blueprints do not load assets, own runtime truth, or bypass validation;
- no Editor-created file is required for BS-018 acceptance;
- Unreal Editor must remain closed during structural builds and may open only after the candidate build passes.

## Acceptance criteria

1. **Given** a valid `item:<name>` DefinitionId, **when** an item definition reports its Primary Asset ID, **then** the values match exactly and survive asset rename/move semantics.
2. **Given** an invalid or non-item DefinitionId, **when** the item definition or load request is evaluated, **then** it fails closed and exposes no valid Primary Asset ID/request.
3. **Given** future world/UI presentation assets, **when** an item definition references them, **then** only soft object pointers exist and their metadata assigns `World` or `UI` bundles.
4. **Given** a load request, **when** bundles are validated, **then** zero, one, or both unique known bundles are accepted in deterministic order while unknown, empty, or duplicate bundles are rejected and prior output is cleared.
5. **Given** project settings, **when** Asset Manager initializes, **then** native `item` assets are scanned recursively only under `/Game/BS/Definitions/Items`, are runtime assets, use `AlwaysCook`, and invalid-asset warnings remain enabled.
6. **Given** the registered item catalog, **when** the audit runs, **then** it uses unloaded metadata and rejects an invalid type, noncanonical ID, duplicate ID, or path outside the approved root.
7. **Given** Shipping, **when** the module compiles, **then** no Automation implementation, developer-only dependency, synchronous-loading helper, or Editor-only validation body enters Shipping.

## Automated verification

- `BrokenStreets.Core.Assets.ItemDefinition`;
- `BrokenStreets.Core.Assets.LoadingPolicy`;
- `BrokenStreets.Core.Assets.Configuration`;
- all existing `BrokenStreets.Core` tests and the project smoke test;
- PowerShell runner self-test;
- `Tools/BS.cmd All` for Generate, Development Editor Build, Automation, Data Validation, and Cook;
- Win64 Shipping build and Automation marker audit;
- direct Asset Manager/configuration audit, renderer/config regression audit, changed/generated-file audit, local-link audit, secrets scan, Git/LFS status, reachable-object audit, and `git lfs fsck`.

## Manual acceptance

Goal: confirm the exact C++ candidate builds on the creator workstation and all Core asset-policy tests pass in Unreal Editor.

Applications needed: Visual Studio 2026 and Unreal Editor 5.8.2.

Unreal Editor state: Closed before build; Open only after build succeeds.

Visual Studio state: Open for build; it may be closed before the Editor test.

Expected duration: 5–10 minutes.

Files/assets created or modified manually: none.

Do not touch: Project Settings, config files, Content, Data Assets, maps, Blueprints, plugins, or code.

1. Open `F:\BrokenStreets\BrokenStreets.sln` in Visual Studio.
   Expected: the `BrokenStreets` solution finishes loading.
2. Set `Solution Configurations` to `Development Editor` and `Solution Platforms` to `Win64`.
   Expected: the top bar shows both exact values.
3. In `Solution Explorer`, expand `Games`, right-click `BrokenStreets`, and click `Build`.
   Expected: `Output` ends with `Build: 1 succeeded, 0 failed` or an up-to-date success with zero errors.
4. Close Visual Studio if desired, then open `F:\BrokenStreets\BrokenStreets.uproject`.
   Expected: Unreal Editor opens directly in UE 5.8 without an engine-selection, module-rebuild, or crash dialog.
5. Click `Tools` > `Session Frontend`, open the `Automation` tab, and enter `BrokenStreets.Core` in the filter.
   Expected: thirteen Core tests are listed: the ten accepted BS-014 through BS-017 tests plus Item Definition, Loading Policy, and Configuration.
6. Select every filtered test and click `Start Tests`.
   Expected: all thirteen tests are green, with 0 failed and 0 skipped.

Checkpoint A

PASS if the build has zero failures and all thirteen `BrokenStreets.Core` Automation tests pass with zero failures/skips and no engine-selection, rebuild, or crash dialog.

FAIL if compilation reports any introduced error/warning, Unreal asks to choose an engine or rebuild modules, an expected Core test is missing, or any test is red/yellow. Stop and send the complete Visual Studio Build output or Automation Testing Log plus one screenshot. Do not edit files or settings.

Checkpoint A result: Pending creator execution after automated candidate verification.

## Risks and rollback

- Base/rollback: `1de51b14c74d44a8bfa7673349c9071f8dd42191`.
- Incorrect Primary Asset IDs can break durable references after a rename; the implementation derives them only from validated DefinitionId.
- Hard references or synchronous loads can scale into startup/runtime stalls; C++ properties remain soft and the public gateway exposes asynchronous request plus explicit release only.
- Duplicate IDs can make catalog resolution ambiguous; unloaded catalog audit treats duplicates as an error.
- Overbroad scanning can package unrelated content; the rule is limited to the concrete native item class and one approved directory.
- Before a production definition exists, rollback is a normal revert followed by Build/Test/Validate/Cook. No asset, save, network, or gameplay migration is required.

## Docs/ADR updates

- create `Docs/Systems/Items.md` with definition ownership, stable identity, soft references, loading lifetime, validation, and failure policy;
- update Core with the first DefinitionId consumer and shared loading boundary;
- register BS-018 and synchronize STATUS, ROADMAP, indexes, and test strategy;
- no ADR unless implementation requires a custom Asset Manager, universal catalog, synchronous runtime loading, external dependency, or incompatible content/version policy.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| | | | | | |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- exact item-definition, Asset Manager registration, soft-reference, bundle, async-load, release, and audit contracts;
- candidate hash/tree plus automated, Cook, Shipping, config, and backup evidence;
- creator build and thirteen-Core-test steps with PASS/FAIL criteria;
- skipped/N/A checks with reasons;
- rollback commit and next task BS-019.
