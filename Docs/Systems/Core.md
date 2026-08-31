# Core

**Status:** Implemented; BS-015 candidate accepted, integration pending
**Product owner:** Madalin Gavrila
**Runtime system owner:** Core
**Active task:** BS-015 — Core observability and feature flags
**Last verified commit/gate:** BS-015 candidate `3669500ed3724a3bea95767e1122c7ead8d1c192`; automated Build/Test/Validate/Cook and Shipping PASS; creator Build and Editor Automation 6/6 PASS

## 1. Purpose

Core supplies small dependency-free contracts that every gameplay domain can use without becoming a gameplay owner. BS-014 introduced stable definition identity, unique instance identity, and the project Gameplay Tags policy. BS-015 adds the minimum shared observability and rollout controls: owned native log categories, bounded structured context, and a typed fail-closed feature-flag query. These primitives prevent later systems from inventing incompatible identifiers, log fields, or mutable global switches.

## 2. Non-goals

- Core does not own characters, items, money, jobs, world state, networking, UI, or save files.
- Core does not allocate domain-specific IDs before their first owning consumer.
- Core does not provide a universal registry, event bus, service locator, transaction engine, or global mutable singleton.
- Core does not provide arbitrary structured fields, player/account context, telemetry transport, analytics, remote configuration, dynamic flag mutation, experiments, or Blueprint helper libraries.
- BS-014/BS-015 do not add Asset Manager, save schemas, migration execution, tag replication optimization, results/errors, or command/correlation envelopes.
- Product-wide exclusions remain in `Docs/NON_GOALS.md`.

## 3. Decisions and open questions

- Confirmed architecture: `DefinitionId` is immutable, instances use GUID-backed typed IDs, and Gameplay Tags classify rather than identify.
- Relevant ADRs: none; this implements accepted architecture without a difficult-to-reverse exception.
- Reversible default: `FBSDefinitionId` canonical text is `<type>:<name>`; both segments contain 1–64 lowercase ASCII letters, digits, or underscore and begin with a letter.
- Reversible default: every project-owned Gameplay Tag is `BS` or a descendant of `BS`; only descendants are assigned as classifications.
- Reversible default: Gameplay Tag fast and dynamic replication are off until BS-016 and a real replicated consumer can prove identical dictionaries and measure the benefit.
- Reversible default: native `LogBrokenStreets` owns project lifecycle diagnostics and `LogBSCore` owns Core primitive, validation, and configuration diagnostics. A future domain adds a category only with its first real consumer.
- Reversible default: `FBSLogContext` accepts one required 1–64 character lowercase snake_case operation and optional valid DefinitionId/InstanceId fields. Its fixed output order is `operation`, `definition_id`, `instance_id`.
- Reversible default: no free-form or private value can enter structured context. Message text still follows the audience/privacy policy of its caller.
- Reversible default: `EBSFeatureFlag` is a closed reviewed enum backed by `[BrokenStreets.FeatureFlags]`; missing, malformed, or unknown values fail closed.
- `CoreVerboseDiagnostics` is the first real flag, defaults to `False`, and controls only one structured primary-module startup diagnostic.
- Flag queries occur at startup or explicit low-frequency boundaries, never on Tick or in a hot loop. Runtime mutation and remote overrides are not supported.
- Open question deferred to BS-018: exact definition types, catalog sources, duplicate scanning, Asset Manager mapping, and production redirects.

## 4. Behaviors and examples

- `item:water_bottle` is a valid DefinitionId and stays unchanged if its future Data Asset is renamed or moved.
- `Item:WaterBottle`, `item.water_bottle`, `item:water-bottle`, and `item:` are invalid because identity accepts only its canonical grammar.
- `0f8fad5b-d9cb-469f-a165-70867728950e` is a canonical InstanceId; a generated ID uses the same lowercase hyphenated form.
- An invalid parse clears its output instead of leaving a stale prior ID.
- `BS.Item.Category.Food` may classify a future definition. It can never replace `item:water_bottle` or a GUID-backed item instance.
- A future tag rename uses a versioned Gameplay Tag redirect; a future DefinitionId replacement uses an owning-domain migration map. These are different compatibility mechanisms.
- `operation=load_definition definition_id=item:water_bottle instance_id=0f8fad5b-d9cb-469f-a165-70867728950e` is a deterministic structured context string. Uppercase, spaces, punctuation, newlines, digit-leading, and overlong operation names are rejected.
- A failed optional-ID assignment clears that field so a later log cannot accidentally reuse stale identity.
- `CoreVerboseDiagnostics=False` emits no startup message. Canonical `True` enables one `LogBrokenStreets` startup message; missing, malformed, and unknown flags remain disabled.

## 5. Ownership and invariants

| Dimension | Owner / rule |
|---|---|
| Storage owner | Value structs store canonical identity values; log context stores ephemeral validated values; project config stores reviewed flag defaults. Future domain records own their copies. |
| Runtime mutation authority | Core validates/represents and reads immutable process configuration; the future domain owner decides when an ID is created/assigned and whether a flag may gate its reversible feature. |
| Persistent fragment owner | None in BS-014/BS-015; future domains serialize identifiers in versioned fragments. Feature flags are configuration, not save state. |
| Replication audience | Defined by the future consuming DTO or log caller; Core has no default gameplay or network audience. |

Invariants that may never be violated:

- an accepted DefinitionId never changes because an asset, file, class, or display name changes;
- an InstanceId identifies exactly one logical instance within its owning scope and is never recycled;
- default/invalid IDs never enter authoritative state;
- DefinitionId and InstanceId are not implicitly interchangeable with each other or raw storage types;
- Gameplay Tags classify state/capability/category and never provide unique definition or instance identity;
- structured context contains only a canonical operation and optional validated Core IDs; it never accepts arbitrary text, secrets, display names, account data, or raw payloads;
- a feature flag is a reversible rollout/diagnostic control, never proof of authority, ownership, compatibility, or permission;
- missing, malformed, and unknown feature flags fail closed, and no current flag changes gameplay truth;
- Core has no dependency on gameplay systems, UI, online services, save orchestration, or Editor-only modules.

## 6. States and transitions

IDs are immutable values, not state machines. They have two validation states: invalid/default and valid/canonical. `TryParse` or future domain-owned generation may produce a valid value; failed validation resets output to invalid. A log context is invalid/default until `TryCreate` accepts its operation; optional ID assignment is validated independently. Feature flags resolve from immutable project configuration on query and have no runtime transition API. No UI or Blueprint transition mutates these contracts.

## 7. Data model and identity

- immutable `DefinitionId`: `FBSDefinitionId`, canonical bounded text `<type>:<name>`, currently prepared for later mapping to Unreal `FPrimaryAssetId` without coupling identity to an asset path;
- `InstanceId`/typed IDs: `FBSInstanceId`, a non-zero `FGuid` represented externally as lowercase `8-4-4-4-12` hyphenated text;
- maximum cardinality: DefinitionId text is at most 129 characters; InstanceId remains 128 bits; domain collections declare their own count bounds;
- public/private/server-only fields: the value alone has no audience; future owning records decide exposure;
- classification Gameplay Tags: root `BS`; C++ behavior contracts use centrally declared native tags, while reviewed data-only classifications may use system-owned config tag lists;
- soft references/assets: none in BS-014;
- log context: ephemeral `FBSLogContext`, with one 1–64 character operation and at most one DefinitionId plus one InstanceId; maximum formatted size is bounded by those fields and fixed keys;
- log categories: native `LogBrokenStreets` and `LogBSCore`, both defaulting to `Log` verbosity and compiled through standard Unreal verbosity;
- feature flags: closed C++ `EBSFeatureFlag`; `CoreVerboseDiagnostics` maps to config key `CoreVerboseDiagnostics` and stable diagnostic name `core_verbose_diagnostics`;
- feature-flag config: `[BrokenStreets.FeatureFlags]` in game configuration; only case-sensitive canonical `True` and `False` values are accepted;
- rename/deprecation/redirect policy: DefinitionId changes require an explicit domain migration map and duplicate audit; tag renames require `GameplayTagRedirects`; asset redirects never substitute for either rule.

Never save `UObject` or Actor pointers, and never use Gameplay Tags as instance identity.

## 8. Commands, events, and API

| Name | Caller | Validator/owner | Input bounds | Result/event | Idempotency/revision |
|---|---|---|---|---|---|
| `FBSDefinitionId::TryParse` | any domain/data boundary | Core | canonical text, two 1–64 character segments | bool + valid value or cleared invalid output | deterministic |
| `FBSInstanceId::Create` | future owning domain | future domain decides assignment | none | new non-zero GUID-backed value | intentionally unique, not idempotent |
| `FBSInstanceId::TryParse` | any domain/data boundary | Core | exact lowercase hyphenated GUID | bool + valid value or cleared invalid output | deterministic |
| equality/hash/archive | containers and serializers | Core | already represented values | deterministic comparison/round-trip | deterministic |
| `FBSLogContext::TryCreate` | any C++ log boundary | Core | canonical operation, maximum 64 characters | bool + valid context or cleared invalid output | deterministic |
| `TrySetDefinitionId` / `TrySetInstanceId` | any C++ log boundary | Core | valid BS-014 ID | bool; assigns valid value or clears invalid field | deterministic |
| `FBSLogContext::ToLogString` | any C++ log boundary | Core | valid bounded context | deterministic single-line key/value text | deterministic |
| `FBSFeatureFlags::IsEnabled` | module/domain startup or explicit state boundary | Core/config | reviewed enum value and project config | enabled/disabled; every error fails disabled | deterministic for one config snapshot |
| `TryParseConfigValue` | feature-flag config boundary | Core | exact `True` or `False` | bool + parsed value or cleared false | deterministic |

Events notify; the owner mutates truth. Core emits no event and owns no network command in BS-014/BS-015. A later domain may use a feature flag only around behavior that its own task, owner, fallback, and tests define.

## 9. Multiplayer

BS-014/BS-015 add no RPC or replicated object. A later authoritative domain creates/validates IDs on the server and includes only required values in owner/public/relevant DTOs. Clients never gain mutation authority by possessing an ID or flag. Gameplay Tag fast/dynamic replication remains off. Logs and local configuration do not replicate. Late join, reconnect, disconnect, four-player separation, latency, and bandwidth are N/A until a network consumer exists.

## 10. Persistence and migration

- store: no gameplay/save store; BS-015 adds only project configuration metadata;
- fragment `SchemaVersion`: N/A until BS-020;
- the wrappers contain only serializable value data and support archive round-trip;
- future schemas reject invalid values before state materialization;
- a DefinitionId migration is explicit, versioned, one-way, and duplicate-checked; an asset rename alone needs no identity migration;
- an InstanceId is preserved through save/load and runtime promotion/demotion;
- corrupt/stale/conflict handling belongs to the future owning schema and Save coordinator.
- log contexts are ephemeral and are not persisted as authoritative state; feature flags are never written into player/world saves.

## 11. Performance and simulation LOD

- update model: event/data-boundary only; no Tick or scheduler;
- validation is bounded to at most 129 DefinitionId characters or 36 InstanceId characters;
- hashes use the canonical string or 128-bit GUID;
- no loaded asset, Actor, component, memory pool, RPC, or bandwidth cost;
- context formatting occurs only at a log boundary and is bounded by fixed fields;
- flag lookup is permitted only at startup or another explicit low-frequency boundary; the first consumer queries once during module startup;
- with the default flag disabled, startup emits no new routine message and does not format a context;
- simulation LOD is N/A, but every representation of one future entity preserves the same stable ID.

## 12. C++ / Blueprint / Editor surface

- C++: `FBSDefinitionId`, `FBSInstanceId`, central native `BS` root tag, `LogBrokenStreets`, `LogBSCore`, `FBSLogContext`, `EBSFeatureFlag`, and `FBSFeatureFlags`;
- Data Assets/Tables/Curves/Tags: no assets; only the native root and project settings;
- Blueprint: ID structs remain reflected for future properties; observability and feature flags are C++ only and expose no Blueprint construction/mutation library;
- Editor setup: none; configuration is source controlled;
- validation: strict ID/context/config parsers, future catalog duplicate validation in BS-018, native/config tag policy tests, and default-off feature-flag policy tests.

## 13. Failure, exploit, and recovery

- invalid, empty, malformed, noncanonical, zero, or overlong input returns false and clears output;
- duplicate equal DefinitionIds collapse under hash equality and future catalog validation must report them as an error;
- clients cannot use a syntactically valid ID as proof of existence, permission, ownership, or authority;
- tag presence never proves instance identity or permission;
- corrupt loaded IDs are rejected by the owning schema rather than regenerated silently;
- generated InstanceIds are not regenerated during reload, reconnect, streaming, or representation changes.
- invalid operation text clears the output context; invalid optional IDs clear their field and cannot leave stale log identity;
- missing, malformed, and unknown feature flags resolve disabled; malformed known configuration emits one bounded warning at its low-frequency query boundary without echoing the raw value;
- callers must never put secrets, player/account display data, raw payloads, or untrusted free-form text into log context or messages;
- a flag may not bypass server validation, compatibility, persistence rules, permissions, or ownership.

## 14. Debug and observability

- `LogBrokenStreets` owns project lifecycle diagnostics; `LogBSCore` owns Core validation/configuration diagnostics. A future system adds its own category only with a real consumer.
- `FBSLogContext` produces searchable single-line fields in a fixed order and intentionally has no arbitrary key/value API.
- Canonical ID `ToString` values are safe structured identifiers, but future logs and free-form message text must still respect audience/privacy.
- `CoreVerboseDiagnostics` defaults off and, when enabled, emits one structured module-startup message. No debug command, overlay, telemetry transport, or remote sink is added.
- Automation code is enclosed by `WITH_DEV_AUTOMATION_TESTS`; no test UI or developer dependency enters Shipping.

## 15. Automated tests

### Unit/automation

- valid and invalid DefinitionId grammar;
- canonical string and archive round-trip;
- valid/generated/zero/malformed/noncanonical InstanceId behavior;
- equality, hash, and duplicate set behavior;
- compile-time separation from the other ID and raw storage;
- native `BS` tag availability and pinned Gameplay Tags settings.
- log-context operation grammar, exact field order, optional valid IDs, invalid-input clearing, single-line output, and size boundaries;
- canonical category names and compile-time verbosity;
- stable feature-flag names/keys, strict boolean parsing, explicit default off, true/false resolution, and unknown fail-closed behavior.

### Functional/network

N/A. No World, Actor, gameplay behavior, RPC, or replicated consumer exists.

### Persistence/fault/performance

Archive round-trip is covered. Save migration, corruption/fault injection, networking, and performance scenarios are N/A until their owning tasks add real consumers.

## 16. Exact manual acceptance

Follow `Docs/Tasks/BS-015-Core-Observability-And-Feature-Flags.md`: close Unreal Editor, build `BrokenStreets | Development Editor | Win64` in Visual Studio, open the project, filter Session Frontend Automation by `BrokenStreets.Core`, and run all six Core tests. PASS is 6 passed, 0 failed, 0 skipped with no engine-selection, module-rebuild, or crash dialog.

## 17. Rollout, rollback, and compatibility

- feature flag/default state: `CoreVerboseDiagnostics=False`; no gameplay state changes under either value;
- BS-015 base: `0abb2d6e31fb8f57e11255a0cbbba5784b42725f`;
- rollback: revert BS-015 and rerun Build/Test/Validate/Cook before any consumer merges; BS-014 identifiers/tags remain intact;
- no production save, content, or network compatibility exists yet;
- if a gate fails, keep the flag disabled and revert the BS-015 candidate; no gameplay fallback or migration is needed because no gameplay consumer depends on it before merge.

## 18. Evidence and history

| Date | Task/commit | Build/test/trace | Result | Approved by |
|---|---|---|---|---|
| 2026-08-31 | BS-014 / `2449d3ff0aad8500e27a0496add703ac64c5d35b` | Development Editor Build; Automation 4/4; Data Validation 3/3; Cook; Shipping Build and marker audit; creator Development Editor Build and Editor Automation 3/3 | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
| 2026-08-31 | BS-014 / merge `8b8e5632de92bd1e51bb36904aec0dc3aab70758` | Post-merge Generate, Development Editor Build, Automation 4/4, Data Validation 3/3, Cook, GitHub parity, Git LFS fsck, and independent backup | PASS; implemented on `main` | Madalin Gavrila and Codex |
| 2026-08-31 | BS-015 / `3669500ed3724a3bea95767e1122c7ead8d1c192` | runner self-test 6/6; Generate/Build; Automation 7/7; Data Validation 3/3; Cook with zero project omissions/warnings; Shipping Build and 0/14 test-marker audit; renderer/config 52/52; Git/LFS/static audits; creator Development Editor Build and Editor Automation 6/6 | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
