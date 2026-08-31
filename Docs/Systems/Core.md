# Core

**Status:** Needs Owner Verification
**Product owner:** Madalin Gavrila
**Runtime system owner:** Core
**Active task:** BS-017 — typed results, errors, and command envelope
**Last verified commit/gate:** BS-017 candidate `0e113a5eb8fa55be066e44e4acd37bcbb8c0fd3b`; automated Build/Test/Validate/Cook, Shipping, static, and backup gates PASS; creator Build and Editor Automation 10/10 pending

## 1. Purpose

Core supplies small dependency-free contracts that every gameplay domain can use without becoming a gameplay owner. BS-014 introduced stable definition identity, unique instance identity, and the project Gameplay Tags policy. BS-015 added owned native log categories, bounded structured context, and a typed fail-closed feature-flag query. BS-016 added the pre-materialization compatibility boundary. BS-017 adds distinct command/correlation identity, a minimal envelope, bounded machine error codes, and invariant result states. These primitives prevent later systems from inventing incompatible identifiers, log fields, mutable global switches, profile/session version rules, or ambiguous command outcomes.

## 2. Non-goals

- Core does not own characters, items, money, jobs, world state, networking, UI, or save files.
- Core does not allocate domain-specific IDs before their first owning consumer.
- Core does not provide a universal registry, event bus, service locator, transaction engine, or global mutable singleton.
- Core does not provide arbitrary structured fields, player/account context, telemetry transport, analytics, remote configuration, dynamic flag mutation, experiments, or Blueprint helper libraries.
- BS-014 through BS-017 do not add Asset Manager, a serialized save header or file, migration execution, tag replication optimization, or a domain command consumer.
- BS-016 does not override Unreal's native network version, approve a connection, materialize a profile, scan/hash content, or expose a player-facing recovery message.
- BS-017 does not add a dispatcher, handler registry, generic payload, RPC, retry engine, deduplication store, journal, free-form error detail, or player-facing/localized message.
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
- Reversible default: `[BrokenStreets.Compatibility]` starts at build compatibility `1`, content compatibility `1`, current save schema `1`, and minimum readable save schema `1`.
- Reversible default: build/content lanes match exactly; they change only for a reviewed incompatible contract change, never merely because a commit or executable is newer.
- Reversible default: a presented save schema is readable when `MinimumReadableSaveSchemaVersion <= SaveSchemaVersion <= CurrentSaveSchemaVersion`.
- Reversible default: every version is canonical unsigned decimal in `1..4294967295`; zero, sign, whitespace, leading zero, punctuation, overflow, missing value, or an inverted save range invalidates the local policy or presented signature.
- Reversible default: fail-closed evaluation order is invalid local policy, invalid presented signature, build mismatch, content mismatch, save too old, then save too new.
- Initial schema lane `1` reserves the contract BS-020 may use; it does not claim that a save header, serializer, migration, or player profile already exists.
- Reversible default: `FBSCommandId` and `FBSCorrelationId` are distinct C++ types over non-zero GUIDs with strict lowercase hyphenated external text.
- Reversible default: one root envelope generates distinct command/correlation values; one child generates a new command ID while inheriting the root correlation ID.
- Reversible default: retrying the same logical command reuses its command ID. Correlation groups related work and never provides idempotency, authority, or permission.
- Reversible default: `FBSErrorCode` accepts exactly `<domain>.<reason>`, with two 1–64 character lowercase ASCII snake_case segments.
- Reversible default: `FBSResult` is valid only as `Succeeded` without an error, `Rejected` with a valid error, or `Failed` with a valid error. Default/cleared state is `Invalid`.
- `Rejected` is a deliberate terminal refusal by a future owner. `Failed` reports an execution failure but grants no automatic retry and makes no recovery/commit claim.
- Machine error codes are bounded control-flow/diagnostic identifiers, never raw details, trusted input, or player-facing text. A future consumer owns localization mapping.
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
- Policy `(build=3, content=4, current_save=5, minimum_readable_save=2)` accepts signatures `(3,4,2)` through `(3,4,5)`, rejects `(3,4,1)` as `save_schema_too_old`, and rejects `(3,4,6)` as `save_schema_too_new`.
- The same policy rejects `(9,4,5)` as `build_version_mismatch` and `(3,9,5)` as `content_version_mismatch`. Multiple mismatches still return the first result in the fixed evaluation order.
- A missing or malformed source-controlled compatibility value makes startup validation fail closed with one bounded Core error; valid defaults emit no routine success message.
- `economy.insufficient_funds` is a valid machine error code. `Economy.InsufficientFunds`, `economy.insufficient-funds`, extra segments, whitespace, and overlong segments are invalid.
- A root command and explicitly created child have different command IDs and the same correlation ID. Retrying the root reuses its original envelope rather than creating a child.
- A success result has no error code; `Rejected(inventory.capacity_exceeded)` and `Failed(save.io_unavailable)` carry exactly one bounded code without free-form details.

## 5. Ownership and invariants

| Dimension | Owner / rule |
|---|---|
| Storage owner | Value structs store canonical identity, compatibility, command/result, and error-code values; log context stores ephemeral validated values; project config stores reviewed flag and compatibility defaults. Future domain records own their copies. |
| Runtime mutation authority | Core validates/represents immutable metadata and reads immutable process configuration. A future domain owner decides when a command is created, validates/applies the intent, owns any deduplication/recovery state, and returns the result. Network approves connections and Save approves/migrates/materializes profiles. |
| Persistent fragment owner | None through BS-016; future domains serialize identifiers in versioned fragments and Save owns the future header/schema registry. Feature flags and the local readable-version policy are configuration, not save state. |
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
- a compatibility signature is metadata presented for validation, never proof of identity, authority, ownership, permission, content existence, or file integrity;
- invalid/missing local configuration and invalid presented signatures always reject before state materialization;
- build/content lanes match exactly, while the readable save-schema interval is inclusive and never inverted;
- version changes are explicit source-controlled compatibility decisions, not automatic timestamps, Git hashes, or per-build churn;
- command identity and correlation identity are distinct and cannot be implicitly converted from each other or raw GUIDs;
- a command envelope contains exactly one valid command ID and one valid correlation ID; a child never reuses the parent's command ID;
- a command ID identifies a logical command across retries; a correlation ID groups work and cannot substitute for idempotency, authorization, or transaction identity;
- an error code is canonical bounded machine text and never contains free-form, private, localized, or untrusted details;
- a valid success contains no error; a valid rejection/failure always contains one valid error; an invalid construction clears prior output;
- result status and error code never prove that state changed, is safe to retry, was persisted, or was shown to a player;
- Core has no dependency on gameplay systems, UI, online services, save orchestration, or Editor-only modules.

## 6. States and transitions

Core IDs, error codes, envelopes, compatibility values, and results are immutable values, not gameplay state machines. IDs/error codes/envelopes have invalid/default and valid/canonical states; failed parsing or construction resets output. A result has one invalid default state and three valid closed states created only through invariant factories. A child-envelope factory changes neither parent nor correlation. Compatibility evaluation is pure. Log context and immutable configuration retain their existing validation behavior. No UI or Blueprint transition mutates these contracts.

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
- compatibility signature: `FBSCompatibilitySignature` with non-zero `uint32` build compatibility, content compatibility, and presented save-schema versions;
- compatibility policy: `FBSCompatibilityPolicy` with exact non-zero build/content lanes and non-zero current/minimum-readable save schemas where minimum is not greater than current;
- compatibility config: `[BrokenStreets.Compatibility]` keys `BuildCompatibilityVersion`, `ContentCompatibilityVersion`, `CurrentSaveSchemaVersion`, and `MinimumReadableSaveSchemaVersion`, all initialized to canonical decimal `1`;
- compatibility result: closed `EBSCompatibilityResult` with stable lowercase names `compatible`, `invalid_policy`, `invalid_signature`, `build_version_mismatch`, `content_version_mismatch`, `save_schema_too_old`, and `save_schema_too_new`; unknown enum values map to bounded diagnostic name `unknown`;
- command ID: `FBSCommandId`, non-zero GUID, canonical lowercase hyphenated text, logical-command/idempotency identity only;
- correlation ID: distinct `FBSCorrelationId`, non-zero GUID with the same text grammar, causal grouping only;
- command envelope: `FBSCommandEnvelope`, exactly one valid command ID plus one valid correlation ID, with explicit root/child construction and no payload or caller identity;
- machine error: `FBSErrorCode`, exact `<domain>.<reason>` text with two bounded lowercase snake_case segments;
- result: `FBSResult` plus closed `EBSResultStatus`; success has no error, rejection/failure have one error, and unknown status names map to `unknown`;
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
| `FBSCompatibilitySignature::TryCreate` | future Network/Save boundary | Core | three non-zero `uint32` versions | bool + valid signature or cleared invalid output | deterministic |
| `FBSCompatibilityPolicy::TryCreate` | project configuration/future tests | Core | non-zero build/content/current/minimum; minimum <= current | bool + valid policy or cleared invalid output | deterministic |
| `FBSCompatibility::TryParseVersion` | compatibility config boundary | Core | canonical decimal `1..4294967295` | bool + parsed version or cleared zero | deterministic |
| `FBSCompatibility::TryLoadCurrentPolicy` | module startup/future boundary owner | Core/config | exactly four project-owned keys | bool + valid policy or cleared invalid output | deterministic for one config snapshot |
| `FBSCompatibility::Evaluate` | future Network/Save boundary | Core | valid local policy and presented signature | one closed specific `EBSCompatibilityResult` | pure and deterministic |
| `FBSCompatibility::GetStableName` | diagnostics/future localization mapping | Core | closed result enum | fixed machine name or `unknown` | deterministic |
| `FBSCommandId::Create/TryParse` | future typed command creator/boundary | Core validates form; future owner assigns meaning | non-zero generated GUID or exact canonical text | valid command ID or cleared output | same logical command reuses the same ID |
| `FBSCorrelationId::Create/TryParse` | future coordinator/boundary | Core validates form; future coordinator groups work | non-zero generated GUID or exact canonical text | valid correlation ID or cleared output | grouping only; not idempotency |
| `FBSCommandEnvelope::CreateRoot` | future typed command creator | Core value construction | none | valid root command/correlation metadata | new logical root |
| `FBSCommandEnvelope::TryCreateChild` | future coordinator | Core validates parent | one valid parent envelope | new command ID, inherited correlation, or cleared output | child is a distinct logical command |
| `FBSErrorCode::TryParse` | future domain result boundary | Core | exact bounded `<domain>.<reason>` | valid machine code or cleared output | deterministic |
| `FBSResult::Succeeded/TryCreateRejected/TryCreateFailed` | future domain owner | Core enforces invariant; domain owns meaning | valid status-specific construction | valid result metadata or cleared output | no retry/commit behavior implied |

Events notify; the owner mutates truth. Core emits no event, dispatches no command, and owns no network command through BS-017. Future typed domain commands may carry the envelope, but their owner still validates/applies/rejects them and owns deduplication/recovery. Network or Save may call compatibility evaluation, but each remains the owner of connection approval or profile migration/materialization.

## 9. Multiplayer

BS-014 through BS-017 add no RPC, connection hook, or replicated object. A later authoritative domain creates/validates IDs on the server and includes only required values in owner/public/relevant DTOs. A valid envelope never authenticates the sender or bypasses identity, permission, range, state, rate-limit, payload, replay, or stale-revision checks. Clients never dictate a result. Gameplay Tag fast/dynamic replication remains off until a real consumer proves identical dictionaries and measures the benefit. Late join, reconnect, disconnect, four-player separation, latency, privacy, and bandwidth are N/A until a network consumer exists.

## 10. Persistence and migration

- store: no gameplay/save store; BS-015/BS-016 add only project configuration metadata, while BS-017 adds ephemeral value contracts only;
- serialized fragment/header `SchemaVersion`: N/A until BS-020; compatibility lane `1` is reserved but no bytes are persisted by BS-016;
- the wrappers contain only serializable value data and support archive round-trip;
- future schemas reject invalid values before state materialization;
- a DefinitionId migration is explicit, versioned, one-way, and duplicate-checked; an asset rename alone needs no identity migration;
- an InstanceId is preserved through save/load and runtime promotion/demotion;
- corrupt/stale/conflict handling belongs to the future owning schema and Save coordinator.
- log contexts are ephemeral and are not persisted as authoritative state; feature flags are never written into player/world saves.
- a future profile header presents one build/content/save signature; Save rejects an invalid build/content lane or unsupported schema before materialization, then performs any approved migration under its own task;
- increasing `CurrentSaveSchemaVersion` requires a real schema plus tests; increasing `MinimumReadableSaveSchemaVersion` drops support and therefore requires explicit migration/rollback evidence and player-facing recovery behavior.
- command/correlation IDs, error codes, and results have no archive operator or persisted schema in BS-017. A future owning task must version their transport/store and define deduplication, receipt, fault, and recovery behavior.

## 11. Performance and simulation LOD

- update model: event/data-boundary only; no Tick or scheduler;
- validation is bounded to at most 129 DefinitionId characters or 36 InstanceId characters;
- hashes use the canonical string or 128-bit GUID;
- no loaded asset, Actor, component, memory pool, RPC, or bandwidth cost;
- context formatting occurs only at a log boundary and is bounded by fixed fields;
- flag lookup is permitted only at startup or another explicit low-frequency boundary; the first consumer queries once during module startup;
- with the default flag disabled, startup emits no new routine message and does not format a context;
- compatibility evaluation is constant time over four `uint32` policy values and three signature values, with no allocation or formatting;
- compatibility configuration reads exactly four bounded values only at startup or another explicit compatibility boundary; valid startup emits no routine message;
- command/envelope validity is constant time over at most two GUIDs; root/child creation generates at most two non-zero GUIDs plus a collision retry;
- error-code validation performs one bounded scan over at most 129 characters; result construction is constant time with one bounded code copy;
- command/results add no execution loop, queue, registry, Tick, thread, RPC, bandwidth, or retained global state;
- simulation LOD is N/A, but every representation of one future entity preserves the same stable ID.

## 12. C++ / Blueprint / Editor surface

- C++: existing identity/tags/observability/feature-flag/compatibility contracts plus `FBSCommandId`, `FBSCorrelationId`, `FBSCommandEnvelope`, `FBSErrorCode`, `EBSResultStatus`, and `FBSResult`;
- Data Assets/Tables/Curves/Tags: no assets; only the native root and project settings;
- Blueprint: definition/instance ID structs remain reflected for future properties; observability, feature flags, compatibility, commands, and results are C++ only and expose no Blueprint construction/mutation library;
- Editor setup: none; configuration is source controlled;
- validation: strict ID/context/config/version parsers, future catalog duplicate validation in BS-018, native/config tag policy tests, default-off feature-flag tests, and exhaustive compatibility-result tests.

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
- zero, malformed, noncanonical, missing, overflowing, or inverted compatibility configuration clears the local policy and makes startup report one bounded error without echoing raw values;
- an invalid presented signature, exact build/content mismatch, or save schema outside the inclusive readable range returns a specific fail-closed result before any future profile state is materialized;
- compatibility does not verify checksum, authenticity, stable-ID validity, content presence, revision, ProfileEpoch, receipts, or permissions; each future owner must still validate its own boundary.
- malformed, zero, uppercase, braced, or noncanonical command/correlation IDs are rejected and clear prior output; an invalid parent cannot create a child;
- command/correlation metadata never authenticates a caller, authorizes a mutation, establishes transaction identity, or proves that a previous attempt completed;
- malformed, uppercase, whitespace-bearing, punctuated, extra-segment, or overlong error codes are rejected and clear prior output;
- invalid result construction clears prior state. `Failed` never authorizes blind retry, and no result carries private/free-form text or a player-visible message.

## 14. Debug and observability

- `LogBrokenStreets` owns project lifecycle diagnostics; `LogBSCore` owns Core validation/configuration diagnostics. A future system adds its own category only with a real consumer.
- `FBSLogContext` produces searchable single-line fields in a fixed order and intentionally has no arbitrary key/value API.
- Canonical ID `ToString` values are safe structured identifiers, but future logs and free-form message text must still respect audience/privacy.
- `CoreVerboseDiagnostics` defaults off and, when enabled, emits one structured module-startup message. No debug command, overlay, telemetry transport, or remote sink is added.
- invalid compatibility configuration emits one fixed `LogBSCore` startup error with operation `compatibility_startup`; valid defaults emit no success spam. Presented values are not logged by Core.
- stable compatibility result names are safe machine identifiers for future structured logs/localization mapping, not player-facing English text.
- stable command result status names and error-code text are safe bounded machine identifiers only. Core emits no command/result log and provides no automatic localization or UI mapping.
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
- canonical compatibility version parsing, maximum/zero/leading-zero/overflow/malformed bounds, output clearing, signature/policy invariants, current-signature generation, and exact project defaults;
- compatible current/minimum/intermediate save schemas, invalid input, every mismatch result, deterministic precedence, and every stable machine name.
- strict command/correlation GUID parsing, compile-time type separation, output clearing, generated uniqueness, explicit root/child correlation behavior, and invalid-parent rejection;
- bounded error-code grammar/equality/hash/clearing, result construction invariants, status predicates, and stable/unknown status names.

### Functional/network

N/A. No World, Actor, gameplay behavior, RPC, or replicated consumer exists.

### Persistence/fault/performance

ID archive round-trip and pure compatibility decisions are covered. Save serialization/migration, corruption/fault injection, networking, and performance scenarios are N/A until their owning tasks add real consumers.

## 16. Exact manual acceptance

Follow `Docs/Tasks/BS-017-Typed-Results-And-Command-Envelope.md`: close Unreal Editor, build `BrokenStreets | Development Editor | Win64` in Visual Studio, open the project, filter Session Frontend Automation by `BrokenStreets.Core`, and run all ten Core tests. PASS is 10 passed, 0 failed, 0 skipped with no engine-selection, module-rebuild, or crash dialog.

## 17. Rollout, rollback, and compatibility

- feature flag/default state: `CoreVerboseDiagnostics=False`; no gameplay state changes under either value;
- compatibility defaults: build `1`, content `1`, current save `1`, minimum readable save `1`; no automatic version or hash changes;
- BS-016 base: `0772b9dd8f323461661a5f042ed435481951743b`;
- BS-017 base: `180a9a83fd686a3414c821569db19df088265077`;
- rollback: revert the BS-016 candidate and rerun Build/Test/Validate/Cook before any Network/Save consumer merges; BS-014/BS-015 primitives remain intact;
- no production save file, content catalog handshake, connection approval, or network payload exists yet;
- if a gate fails, revert the BS-016 candidate; no gameplay fallback or migration is needed because no gameplay, profile, content, or network consumer depends on it before merge.
- if BS-017 fails before a consumer exists, revert its candidate and rerun Build/Test/Validate/Cook. No content, config, save, network, or gameplay migration is required.

## 18. Evidence and history

| Date | Task/commit | Build/test/trace | Result | Approved by |
|---|---|---|---|---|
| 2026-08-31 | BS-014 / `2449d3ff0aad8500e27a0496add703ac64c5d35b` | Development Editor Build; Automation 4/4; Data Validation 3/3; Cook; Shipping Build and marker audit; creator Development Editor Build and Editor Automation 3/3 | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
| 2026-08-31 | BS-014 / merge `8b8e5632de92bd1e51bb36904aec0dc3aab70758` | Post-merge Generate, Development Editor Build, Automation 4/4, Data Validation 3/3, Cook, GitHub parity, Git LFS fsck, and independent backup | PASS; implemented on `main` | Madalin Gavrila and Codex |
| 2026-08-31 | BS-015 / `3669500ed3724a3bea95767e1122c7ead8d1c192` | runner self-test 6/6; Generate/Build; Automation 7/7; Data Validation 3/3; Cook with zero project omissions/warnings; Shipping Build and 0/14 test-marker audit; renderer/config 52/52; Git/LFS/static audits; creator Development Editor Build and Editor Automation 6/6 | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
| 2026-08-31 | BS-015 / merge `ccbb92d0fc7a455a9995d529be29e248a22c2812` | accepted Source/Config/Content exact; post-merge Generate/Build, Automation 7/7, Data Validation 3/3, Cook with zero project omissions/warnings, GitHub parity, Git LFS fsck/status, and independent backup | PASS; implemented on `main` | Madalin Gavrila and Codex |
| 2026-08-31 | BS-016 / `a516cbf7b777ec3b7ad5e128b70d9d0657b882ea` | runner self-test 6/6; Generate/Build; Automation 9/9; Data Validation 3/3; Cook with zero project omissions/warnings; Shipping Build and 0/18 test-marker audit; renderer/config 52/52; Git/LFS/static audits; independent backup; creator Development Editor Build and Editor Automation 8/8 | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
| 2026-08-31 | BS-016 / merge `270badd0d1bca006199f7e6f21f3fe2e95e33e2b` | accepted Source/Config/Content exact; post-merge Generate/Build, Automation 9/9, Data Validation 3/3, Cook with zero project omissions/warnings, GitHub parity, Git LFS fsck/status, reachable-object audit, and independent backup | PASS; implemented on `main` | Madalin Gavrila and Codex |
| 2026-08-31 | BS-017 / `0e113a5eb8fa55be066e44e4acd37bcbb8c0fd3b` | runner self-test 6/6; Generate/Build; Automation 11/11; Data Validation 3/3; Cook with zero project omissions/warnings; Shipping Build and 0/22 test-marker audit; links 46/46; Git/LFS/static audits; independent backup | Automated PASS; creator Build and Editor Automation 10/10 pending | Codex |
