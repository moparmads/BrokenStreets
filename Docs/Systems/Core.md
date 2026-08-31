# Core

**Status:** Implemented; BS-015 extension in progress
**Product owner:** Madalin Gavrila
**Runtime system owner:** Core
**Active task:** BS-015 — Core observability and feature flags
**Last verified commit/gate:** merge `8b8e5632de92bd1e51bb36904aec0dc3aab70758`; post-merge Build/Test/Validate/Cook PASS; creator Build and Editor Automation 3/3 PASS

## 1. Purpose

Core supplies small dependency-free contracts that every gameplay domain can use without becoming a gameplay owner. BS-014 introduces only stable definition identity, unique instance identity, and the project Gameplay Tags policy. These primitives prevent saves, catalogs, commands, and replicated data from relying on asset names, Actor names, object pointers, or raw strings.

## 2. Non-goals

- Core does not own characters, items, money, jobs, world state, networking, UI, or save files.
- Core does not allocate domain-specific IDs before their first owning consumer.
- Core does not provide a universal registry, event bus, service locator, transaction engine, or global mutable singleton.
- BS-014 does not add Asset Manager, save schemas, migration execution, tag replication optimization, or Blueprint helper libraries.
- Product-wide exclusions remain in `Docs/NON_GOALS.md`.

## 3. Decisions and open questions

- Confirmed architecture: `DefinitionId` is immutable, instances use GUID-backed typed IDs, and Gameplay Tags classify rather than identify.
- Relevant ADRs: none; this implements accepted architecture without a difficult-to-reverse exception.
- Reversible default: `FBSDefinitionId` canonical text is `<type>:<name>`; both segments contain 1–64 lowercase ASCII letters, digits, or underscore and begin with a letter.
- Reversible default: every project-owned Gameplay Tag is `BS` or a descendant of `BS`; only descendants are assigned as classifications.
- Reversible default: Gameplay Tag fast and dynamic replication are off until BS-016 and a real replicated consumer can prove identical dictionaries and measure the benefit.
- Open question deferred to BS-018: exact definition types, catalog sources, duplicate scanning, Asset Manager mapping, and production redirects.

## 4. Behaviors and examples

- `item:water_bottle` is a valid DefinitionId and stays unchanged if its future Data Asset is renamed or moved.
- `Item:WaterBottle`, `item.water_bottle`, `item:water-bottle`, and `item:` are invalid because identity accepts only its canonical grammar.
- `0f8fad5b-d9cb-469f-a165-70867728950e` is a canonical InstanceId; a generated ID uses the same lowercase hyphenated form.
- An invalid parse clears its output instead of leaving a stale prior ID.
- `BS.Item.Category.Food` may classify a future definition. It can never replace `item:water_bottle` or a GUID-backed item instance.
- A future tag rename uses a versioned Gameplay Tag redirect; a future DefinitionId replacement uses an owning-domain migration map. These are different compatibility mechanisms.

## 5. Ownership and invariants

| Dimension | Owner / rule |
|---|---|
| Storage owner | Value structs store only canonical text or GUID value; future domain records own their copies. |
| Runtime mutation authority | Core validates/represents; the future domain owner decides when an ID is created or assigned. |
| Persistent fragment owner | None in BS-014; future domains serialize the value in their versioned fragments. |
| Replication audience | Defined by the future consuming DTO; Core has no default audience. |

Invariants that may never be violated:

- an accepted DefinitionId never changes because an asset, file, class, or display name changes;
- an InstanceId identifies exactly one logical instance within its owning scope and is never recycled;
- default/invalid IDs never enter authoritative state;
- DefinitionId and InstanceId are not implicitly interchangeable with each other or raw storage types;
- Gameplay Tags classify state/capability/category and never provide unique definition or instance identity;
- Core has no dependency on gameplay systems, UI, online services, save orchestration, or Editor-only modules.

## 6. States and transitions

IDs are immutable values, not state machines. They have two validation states: invalid/default and valid/canonical. `TryParse` or future domain-owned generation may produce a valid value; failed validation resets output to invalid. No UI or Blueprint transition mutates authoritative identity.

## 7. Data model and identity

- immutable `DefinitionId`: `FBSDefinitionId`, canonical bounded text `<type>:<name>`, currently prepared for later mapping to Unreal `FPrimaryAssetId` without coupling identity to an asset path;
- `InstanceId`/typed IDs: `FBSInstanceId`, a non-zero `FGuid` represented externally as lowercase `8-4-4-4-12` hyphenated text;
- maximum cardinality: DefinitionId text is at most 129 characters; InstanceId remains 128 bits; domain collections declare their own count bounds;
- public/private/server-only fields: the value alone has no audience; future owning records decide exposure;
- classification Gameplay Tags: root `BS`; C++ behavior contracts use centrally declared native tags, while reviewed data-only classifications may use system-owned config tag lists;
- soft references/assets: none in BS-014;
- rename/deprecation/redirect policy: DefinitionId changes require an explicit domain migration map and duplicate audit; tag renames require `GameplayTagRedirects`; asset redirects never substitute for either rule.

Never save `UObject` or Actor pointers, and never use Gameplay Tags as instance identity.

## 8. Commands, events, and API

| Name | Caller | Validator/owner | Input bounds | Result/event | Idempotency/revision |
|---|---|---|---|---|---|
| `FBSDefinitionId::TryParse` | any domain/data boundary | Core | canonical text, two 1–64 character segments | bool + valid value or cleared invalid output | deterministic |
| `FBSInstanceId::Create` | future owning domain | future domain decides assignment | none | new non-zero GUID-backed value | intentionally unique, not idempotent |
| `FBSInstanceId::TryParse` | any domain/data boundary | Core | exact lowercase hyphenated GUID | bool + valid value or cleared invalid output | deterministic |
| equality/hash/archive | containers and serializers | Core | already represented values | deterministic comparison/round-trip | deterministic |

Events notify; the owner mutates truth. Core emits no event and owns no network command in BS-014.

## 9. Multiplayer

BS-014 adds no RPC or replicated object. A later authoritative domain creates/validates IDs on the server and includes only required values in owner/public/relevant DTOs. Clients never gain mutation authority by possessing an ID. Gameplay Tag fast/dynamic replication remains off. Late join, reconnect, disconnect, four-player separation, latency, and bandwidth are N/A until a consumer exists.

## 10. Persistence and migration

- store: none in BS-014;
- fragment `SchemaVersion`: N/A until BS-020;
- the wrappers contain only serializable value data and support archive round-trip;
- future schemas reject invalid values before state materialization;
- a DefinitionId migration is explicit, versioned, one-way, and duplicate-checked; an asset rename alone needs no identity migration;
- an InstanceId is preserved through save/load and runtime promotion/demotion;
- corrupt/stale/conflict handling belongs to the future owning schema and Save coordinator.

## 11. Performance and simulation LOD

- update model: event/data-boundary only; no Tick or scheduler;
- validation is bounded to at most 129 DefinitionId characters or 36 InstanceId characters;
- hashes use the canonical string or 128-bit GUID;
- no loaded asset, Actor, component, memory pool, RPC, or bandwidth cost;
- simulation LOD is N/A, but every representation of one future entity preserves the same stable ID.

## 12. C++ / Blueprint / Editor surface

- C++: `FBSDefinitionId`, `FBSInstanceId`, and central native `BS` root tag;
- Data Assets/Tables/Curves/Tags: no assets; only the native root and project settings;
- Blueprint: structs are reflected for future properties, but BS-014 exposes no Blueprint construction/mutation library;
- Editor setup: none; configuration is source controlled;
- validation: strict ID parsers, future catalog duplicate validation in BS-018, and native/config tag policy tests.

## 13. Failure, exploit, and recovery

- invalid, empty, malformed, noncanonical, zero, or overlong input returns false and clears output;
- duplicate equal DefinitionIds collapse under hash equality and future catalog validation must report them as an error;
- clients cannot use a syntactically valid ID as proof of existence, permission, ownership, or authority;
- tag presence never proves instance identity or permission;
- corrupt loaded IDs are rejected by the owning schema rather than regenerated silently;
- generated InstanceIds are not regenerated during reload, reconnect, streaming, or representation changes.

## 14. Debug and observability

- BS-015 owns log categories and structured context.
- Canonical `ToString` values are safe context identifiers but future logs must respect audience/privacy.
- No debug command or overlay is needed in BS-014.
- Automation code is enclosed by `WITH_DEV_AUTOMATION_TESTS`; no test UI or developer dependency enters Shipping.

## 15. Automated tests

### Unit/automation

- valid and invalid DefinitionId grammar;
- canonical string and archive round-trip;
- valid/generated/zero/malformed/noncanonical InstanceId behavior;
- equality, hash, and duplicate set behavior;
- compile-time separation from the other ID and raw storage;
- native `BS` tag availability and pinned Gameplay Tags settings.

### Functional/network

N/A. No World, Actor, gameplay behavior, RPC, or replicated consumer exists.

### Persistence/fault/performance

Archive round-trip is covered. Save migration, corruption/fault injection, networking, and performance scenarios are N/A until their owning tasks add real consumers.

## 16. Exact manual acceptance

Follow `Docs/Tasks/BS-014-Stable-Identifiers-And-Gameplay-Tags.md`: close Unreal Editor, build `BrokenStreets | Development Editor | Win64` in Visual Studio, open the project, filter Session Frontend Automation by `BrokenStreets.Core`, and run all three tests. PASS is 3 passed, 0 failed, 0 skipped with no module-rebuild or crash dialog.

## 17. Rollout, rollback, and compatibility

- feature flag/default state: none; value types and the reserved tag root become available when the module loads;
- base: `56ad7c9f5f0188b949bd7c8b6ab0179fa60ed1c8`;
- rollback: revert BS-014 and rerun Build/Test/Validate/Cook before any consumer merges;
- no production save, content, or network compatibility exists yet;
- if a gate fails, no gameplay fallback is needed because no consumer depends on this task before merge.

## 18. Evidence and history

| Date | Task/commit | Build/test/trace | Result | Approved by |
|---|---|---|---|---|
| 2026-08-31 | BS-014 / `2449d3ff0aad8500e27a0496add703ac64c5d35b` | Development Editor Build; Automation 4/4; Data Validation 3/3; Cook; Shipping Build and marker audit; creator Development Editor Build and Editor Automation 3/3 | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
| 2026-08-31 | BS-014 / merge `8b8e5632de92bd1e51bb36904aec0dc3aab70758` | Post-merge Generate, Development Editor Build, Automation 4/4, Data Validation 3/3, Cook, GitHub parity, Git LFS fsck, and independent backup | PASS; implemented on `main` | Madalin Gavrila and Codex |
