# Items

**Status:** In Progress
**Product owner:** Madalin Gavrila
**Runtime system owner:** Items
**Active task:** BS-018 — Asset Manager and soft-reference loading policy
**Last verified commit/gate:** Design contract only; implementation pending

## 1. Purpose

Items owns immutable item definitions and, in later tasks, item-instance metadata. BS-018 establishes only the definition/content boundary: a stable DefinitionId maps to one Primary Data Asset, large presentation dependencies stay soft, and callers request explicit bundles asynchronously without loading the complete future catalog.

## 2. Non-goals

- no inventory, container, ownership, transfer, price, weight, capacity, durability, legality, stock, shop, equipment, or item instance;
- no production catalog assets or final catalog decisions;
- no universal catalog framework, custom Asset Manager, synchronous gameplay loading, bulk runtime preload, UI, save, network, or gameplay behavior;
- product-wide exclusions remain in `Docs/NON_GOALS.md`.

## 3. Decisions and open questions

- Confirmed architecture: definitions are immutable shared data; stable DefinitionId survives asset rename/move; Asset Manager and soft references prevent bulk residency.
- Relevant ADRs: none; BS-018 uses stock Unreal Asset Manager and follows accepted architecture.
- Reversible default: `item` is the first concrete Primary Asset type and `/Game/BS/Definitions/Items` is its only scan root.
- Reversible default: `World` and `UI` are the only initial bundles; neither is loaded unless explicitly selected.
- Reversible default: registered item definitions use recursive `AlwaysCook`; cooking does not imply runtime loading.
- Deferred: production item fields, taxonomy, prices, stock, redirects, and content-version changes wait for their owning consumer and real assets.

## 4. Behaviors and examples

- `item:water_bottle` maps to Primary Asset ID `item:water_bottle` regardless of the asset filename or package move.
- A definition may point softly to a world mesh in `World` and an icon in `UI`; requesting `UI` does not request `World`.
- A definition-only request selects no bundles and loads only the Primary Data Asset.
- `vehicle:sedan`, an unknown bundle, duplicate bundle, invalid ID, unregistered ID, or item asset outside the approved root fails closed.
- Releasing a definition request removes the Asset Manager load ownership; domain/runtime owners must retain any intentional lifetime separately.

## 5. Ownership and invariants

| Dimension | Owner / rule |
|---|---|
| Definition storage owner | Items; immutable Primary Data Assets |
| Runtime mutation authority | N/A in BS-018; definitions never mutate during normal runtime |
| Persistent fragment owner | None in BS-018; future records store DefinitionId only |
| Replication audience | None; no item state is replicated |

Invariants:

- one canonical `item:<name>` DefinitionId identifies one logical item definition;
- asset path/name is never durable identity;
- presentation dependencies remain soft until an explicit bundle lifetime requests them;
- loading never proves ownership, permission, stock, price, legality, or server authority;
- no runtime call loads all definitions or blocks synchronously.

## 6. States and transitions

BS-018 has no item gameplay state. A load request moves from rejected/failed or accepted to Unreal-managed completion; explicit release ends the gateway's load ownership. Completion does not create an item instance or mutate gameplay truth.

## 7. Data model and identity

- immutable `DefinitionId`: `FBSDefinitionId` with required type `item`;
- `InstanceId`/typed IDs: none until the first item-instance owner;
- maximum cardinality: one DefinitionId per registered asset; a request selects at most two unique bundles;
- public/private/server-only fields: immutable definition metadata is shared; no player data exists;
- classification Gameplay Tags: deferred until a concrete item consumer defines the first necessary tags;
- soft references/assets: optional world mesh and UI icon only in BS-018;
- rename/deprecation/redirect policy: preserve DefinitionId; add reviewed Primary Asset/path redirects only when a real rename or deprecation occurs.

Never save UObject/Actor pointers and never use Gameplay Tags as instance identity.

## 8. Commands, events, and API

| Name | Caller | Validator/owner | Input bounds | Result/event | Idempotency/revision |
|---|---|---|---|---|---|
| Create item load request | future local domain/runtime owner | Core loading policy | one valid item ID; zero to two unique `World`/`UI` bundles | valid immutable request or cleared output | no gameplay mutation |
| Request async load | future local domain/runtime owner | Asset Manager gateway | valid request; registered item definition | request accepted or bounded machine error; completion delegate | repeated loads share Unreal management; no gameplay idempotency implied |
| Release definition | lifetime owner | Asset Manager gateway | one valid item ID | unloaded manager ownership count | no gameplay mutation |
| Audit item catalog | Automation/content gate | Items/Core policy | registered unloaded metadata | valid or exact duplicate/type/path failure | deterministic for one registry snapshot |

Events notify; the owner mutates truth. BS-018 emits no gameplay event and dispatches no command.

## 9. Multiplayer

BS-018 adds no RPC, replicated object, mutable item state, audience, snapshot, delta, late join, reconnect, or bandwidth. Every process may resolve identical immutable definitions, but the server remains authoritative for future item instances and ownership. Network scenarios are N/A.

## 10. Persistence and migration

Store/schema/version/migration/recovery are N/A because BS-018 writes no bytes. Future persistent records store DefinitionId and validate it against the compatible catalog before materialization; they never serialize asset paths or UObject pointers.

## 11. Performance and simulation LOD

- update model: event/request only; no Tick, timer, or Actor scan;
- catalog audit uses metadata without loading definitions;
- runtime loads one requested definition and selected bundle dependencies asynchronously;
- lifetime owner releases when no longer needed;
- no production assets/workload exist, so profiling is N/A in BS-018; Cook and the no-hard-reference audit protect the structural budget.

## 12. C++ / Blueprint / Editor surface

- C++: concrete item Primary Data Asset, bounded load-request value, async Asset Manager gateway, and unloaded catalog audit;
- Data Assets: future native `UBSItemDefinition` instances under `/Game/BS/Definitions/Items`;
- Blueprint: data-only configuration may be considered only when a real consumer proves inheritance is needed; no loading or authority logic;
- Editor setup: none for BS-018 acceptance;
- validation: valid item ID, primary ID equality, approved name/root, soft properties/bundles, Asset Manager scan rule, and duplicate unloaded metadata.

## 13. Failure, exploit, and recovery

- invalid/wrong-type IDs, invalid/duplicate bundles, unavailable manager, unknown definitions, invalid paths, and duplicates fail closed with cleared output or bounded machine errors;
- a syntactically valid ID is not proof of inventory existence or permission;
- unload/reload preserves logical identity because DefinitionId is independent of UObject lifetime;
- disconnect, host crash, partial transaction, and corrupt save are N/A because no network, transaction, or persistence exists.

## 14. Debug and observability

BS-018 adds no routine log spam or debug overlay. Machine errors use bounded `assets.*` codes where the async request boundary needs a result. Automation retains exact configuration/catalog failures. Test code remains excluded from Shipping.

## 15. Automated tests

### Unit/automation

- definition Primary Asset ID, wrong-type rejection, and stable identity;
- soft-property and exact bundle metadata;
- request bounds, deterministic bundle order, clearing, and missing registration;
- exact Asset Manager type/root/class/cook settings;
- unloaded catalog type, canonical ID, duplicate, and path audit.

### Functional/network

N/A. No World, Actor, gameplay behavior, RPC, or replicated consumer exists.

### Persistence/fault/performance

N/A. No persisted bytes, I/O, runtime hot path, or representative production asset exists.

## 16. Exact manual acceptance

Follow `Docs/Tasks/BS-018-Asset-Manager-And-Loading-Policy.md`: close Unreal Editor, build `BrokenStreets | Development Editor | Win64` in Visual Studio, open the project, filter Session Frontend Automation by `BrokenStreets.Core`, and run all thirteen Core tests. PASS is 13 passed, 0 failed, 0 skipped with no engine-selection, module-rebuild, or crash dialog.

## 17. Rollout, rollback, and compatibility

- feature flag/default state: none; no production asset or gameplay consumer exists;
- base: `1de51b14c74d44a8bfa7673349c9071f8dd42191`;
- rollback: revert the BS-018 candidate and rerun Build/Test/Validate/Cook before any item asset or consumer merges;
- content compatibility remains lane `1`; no real definition, redirect, or semantic catalog change exists yet;
- no save/network migration or gameplay fallback is required.

## 18. Evidence and history

| Date | Task/commit | Build/test/trace | Result | Approved by |
|---|---|---|---|---|
| | | | | |
