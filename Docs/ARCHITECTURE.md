# Broken Streets Architecture

**Status:** target architecture, not a description of an existing implementation.
**Current reality:** one empty C++ module; see `Docs/STATUS.md`.

## 1. Architecture goals

The architecture must support:

- solo and private co-op through one listen-server host plus at most three clients;
- four untethered players in different areas, interiors, or jobs;
- portable personal progress between friends' worlds without a dedicated backend;
- economy, ownership, and saves resilient to retries, reconnects, and crashes within documented limits;
- a Manhattan-like world expanded district by district;
- thousands of possession definitions without loading every asset at once;
- population, traffic, and world-state LOD representations;
- repeatable build, test, profiling, and migration for a creator who does not write code.

## 2. Invariants

1. **Server authority:** the client expresses intent; the listen server's server side validates and applies gameplay.
2. **Single writer:** every runtime truth has exactly one domain owner.
3. **Separation of forms:** Definition, Persistent Record, Replicated DTO, and Runtime Actor are different types.
4. **Stable identity:** `DefinitionId` is immutable; instances use `FGuid` or typed IDs. Gameplay Tags classify; they never identify instances.
5. **Persistence is not an Actor:** saves contain no `UObject` pointers, runtime names, or assumptions about loaded Actors.
6. **UI is not gameplay:** UI sends commands and consumes read models or events.
7. **Save is not gameplay:** Save serializes valid state and orchestrates I/O and migration; it never decides prices, ownership, or outcomes.
8. **Data-driven, bounded runtime:** catalogs use Asset Manager and soft references; runtime systems declare limits and update rates.
9. **Compatibility first:** build, content, and save schema complete a handshake before a profile is accepted.
10. **Measured scaling:** no replication, streaming, or crowd technology is adopted without a scenario and measurable threshold.

## 3. UE topology per process

An object existing on the host PC does not automatically make it authoritative. `Host` describes the player or PC running the session; `server` describes the authoritative network role. The host's local client never bypasses server validation.

### `UGameInstanceSubsystem`

Exists on every process. Suitable for:

- local profile orchestration;
- online and session flow;
- application services that survive World changes;
- preferences and local bootstrap.

It is neither automatically replicated nor automatically authoritative. Gameplay operations cross the network boundary and reach the domain owner.

### `AGameModeBase` — server only

- server-only orchestration for entry, spawn, ruleset, and session transitions;
- accepts or rejects connections after compatibility and profile validation;
- never becomes a monolithic store for economy, inventory, or every job.

### `AGameStateBase` — public read model

- public world state such as clock, weather, phase, and required session information;
- snapshot and replication for late join;
- never contains complete profiles or personal secrets.

### `APlayerController` — private command boundary

- receives local client input;
- exposes validated and rate-limited client-to-server RPCs;
- may host owner-only facades for private data;
- delegates domain rules to authoritative owners instead of calculating them directly.

### `APlayerState` — public identity/read model per player

- runtime identity, display data, and public summaries needed by other players;
- survives Pawn changes;
- never replicates complete inventory, private balances, or the entire Portable Profile.

### `APawn` / `ACharacter`

- physical presence, movement, collision, animation-facing state, and avatar-adjacent components;
- never owns economy, save, or catalogs;
- may contain replicated facades or components with explicit responsibilities.

### `UWorldSubsystem`

- World-scoped services such as clock authority, registries, directors, and local scheduling;
- never assumed to persist across Worlds;
- replication occurs through a dedicated Actor, Component, or subobject—not through the subsystem directly.

### `ULocalPlayerSubsystem`

- input and UI preferences, presentation, and strictly local services;
- no authoritative gameplay mutations.

## 4. Module and source structure

Start with few compiled modules:

```text
Source/
  BrokenStreets/
    Public/              # minimum stable API required by other modules
    Private/
      Core/
      Identity/
      Online/
      Network/
      World/
      Player/
      Interaction/
      Items/
      Inventory/
      Ownership/
      Economy/
      Jobs/
      Legality/
      ...
      Tests/             # tests correctly excluded from Shipping
  BrokenStreetsEditor/   # future Type=Editor module
    Private/
      Validation/
      Import/
      Debug/
```

- `Private/` folders express logical ownership, not separate modules.
- API stays private until a real external consumer exists.
- A new module requires a different lifetime or dependency boundary that has been demonstrated.
- Tests use `WITH_DEV_AUTOMATION_TESTS` or a `DeveloperTool` module and never enter Shipping accidentally.
- `BrokenStreetsEditor` is not a dependency of the runtime module.
- The engine under `F:/UE_5.8.2` is not modified.

## 5. Four forms of an entity

### Definition

Shared data, immutable during normal runtime:

- stable `DefinitionId`;
- class or category through Gameplay Tags;
- base price, weight, capacity, and tuning;
- soft references to mesh, icon, audio, and other assets;
- data version where migration matters.

Renaming an asset does not change `DefinitionId`. Redirects or migration maps preserve compatibility.

### Persistent Instance Record

- typed `InstanceId` or `FGuid`;
- owner, state, modifications, container, and fields that differ from the Definition;
- serializable types only, with no `UObject` or Actor references;
- `SchemaVersion` and validation.

### Replicated DTO / read model

- only fields required by the audience;
- separate from save structure to prevent leaks and coupling;
- owner-only balances and private inventory;
- initial snapshot plus deltas for collections;
- compatible with late join and reconnect.

### Runtime representation

- Actor, Component, UObject, or representation data loaded near a player;
- may be destroyed and recreated without destroying its record;
- promotion and demotion preserve StableId and relevant state.

This separation applies to items, vehicles, properties, important NPCs, and jobs.

## 6. Command flow

```text
Local input/UI
  → typed intent through PlayerController/facade
  → server validation: identity, permission, state, range, rate limit
  → domain owner applies or rejects the mutation
  → typed event/result
  → other owners react through explicit commands
  → read model/replication updates
  → persistence captures state according to policy
```

- Do not build a universal event bus in advance. Use typed C++ APIs, delegates, and UE facilities; extract common infrastructure only after at least two real consumers exist.
- A multi-domain operation uses an idempotent coordinator or use case. The coordinator never becomes the data owner.
- Purchase example: Shop validates offer → coordinator requests Economy debit → requests item creation or movement from Items/Inventory → requests Ownership → completes or compensates through TransactionId. No domain writes another domain's state directly.

## 7. Multiplayer and replication

### Contract

- four players maximum: `1 host + 0–3 clients`;
- private listen server, initially Steam-only;
- join-in-progress and reconnect;
- no tether; four relevancy and streaming bubbles may exist;
- the listen server's server side is runtime mutation authority; the host's local client uses the same command and RPC validation paths as a remote client;
- local profiles presented at join are untrusted input and are validated before materialization.

### Technical baseline

Standard UE replication is the mandatory fallback. Replication Graph and Iris are `Adopt/Reject` candidates, never Shipping assumptions:

- first measure standard replication under a representative workload;
- adopt Replication Graph only when four-bubble relevancy requires it and the pinned UE build passes tests;
- evaluate Iris only when the baseline fails or Iris offers a measurable advantage;
- domain APIs never depend on a single replication backend;
- an ADR records the result and fallback.

### Rules

- RPCs describe intent, never a result dictated by the client;
- use reliable only for rare events that must arrive, never per frame;
- durable state uses replicated properties and collections, not multicast-only messages;
- repeatable actions have rate limits and payload caps;
- relevancy, priority, and owner-only audience are explicit;
- every system document describes late join, reconnect, disconnect during transaction, and security validation.

## 8. Persistence model

### `PortableCharacterProfile` — player-owned file

Contains only confirmed portable personal progress: identity, appearance, money, inventory, portable vehicle and property records, persistent needs and health, reputations, criminal record, unlocks, and receipts. The exact schema grows incrementally and is never implemented all at once.

### `HostWorldSave` — host-owned file

Contains world-owned truth: WorldId, clock and weather, district and event state, job/world deltas, important world-owned NPCs, and runtime materializations required for recovery. It may never permanently overwrite a guest profile with an old copy.

### `SessionCommitJournal` — authoritative while the session runs

Distinct from `EconomyTransactionLedger`:

- `EconomyTransactionLedger` owns monetary operations and economic idempotency;
- `SessionCommitJournal` tracks join revision, commits, receipts, and profile-export coordination.

Without a backend, no durable atomic transaction across two PCs is promised. The exact ambiguous-result policy requires approval before the save MVP. The recommended direction is:

1. the latest checkpoint confirmed by both parties wins;
2. an unconfirmed result is rolled back or enters a recovery report;
3. a cross-host conflict blocks automatic import and requires human choice;
4. a manual restore changes `ProfileEpoch` and invalidates the previous local lease.

### I/O

- coherent immutable snapshot captured on the game thread;
- serialization and I/O may become asynchronous only after capture;
- temporary file on the same volume as the destination;
- ordering: `capture → serialize temp → flush → read-back/checksum → atomic local replace → manifest commit`;
- manifest never points to a new generation before verification, and at least one prior valid generation remains recoverable;
- at startup, unconfirmed temporary files are ignored or quarantined, generations are checked newest to oldest, and fallback is reported;
- fault injection at every stage, including before and after replace and manifest;
- build, content, and schema handshake before accepting a profile;
- migrations preserve IDs or fail explicitly with a recovery path.

## 9. World Partition, interiors, and four bubbles

Enabling World Partition is not enough. A spike and ADR define:

- Runtime Hash and grid/cell sizes;
- streaming sources for host and three clients;
- server streaming and server streaming-out;
- ownership of authoritative Actors when a cell unloads;
- navigation mesh and spawn anchors;
- high-speed traversal;
- HLOD, Data Layers, and OFPA;
- memory and hitch thresholds.

UE configuration may keep the entire world loaded on the server. For Manhattan and four bubbles, behavior must be measured in the exact 5.8.2 build, never assumed.

Private interiors do not use individual server travel. An abstract service materializes isolated instances inside the same authoritative World. The spike validates four simultaneous instances for:

- visual isolation and occlusion;
- audio;
- collision and physics;
- navigation and AI;
- replication and relevancy;
- visitors and permissions;
- collision-free IDs and saves;
- load, unload, and memory caps.

The exact implementation stays `Proposed` until the spike.

## 10. Scheduling and simulation LOD

Do not build a universal scheduler before real cases exist. Every system document declares its update model:

| Level | Representation |
|---|---|
| Full | complete gameplay, AI, physics, and animation near the player |
| Reduced | complete Actor at reduced frequency and cost |
| Representation | data-oriented record or Mass when adopted, without a complete Actor |
| Statistical | result derived from data and seed without physical presence |

Economy, ownership, and save are event-driven. Needs use deltas from `CharacterActiveTime`. Directors use explicit frequencies and budgets. Promotion and demotion preserve StableId.

## 11. Blueprint and asset boundary

C++ owns authority, persistence, replication, and hot paths. Blueprint and Editor configure animation visuals, UI layout, assets, maps, and StateTrees using C++ tasks. Blueprint logic with persistent state, networking, many branches or loops, or permanent Tick is an architecture defect by default.

Asset Manager and Primary Data Assets, or a validated equivalent, keep catalogs data-driven. Large references remain soft until an explicit lifetime requires loading. Content validation checks naming, DefinitionId, duplicate IDs, references, collision, and metadata.

## 12. Configuration baseline and known debt

The empty project currently has:

- `GameDefaultMap=/Engine/Maps/Templates/OpenWorld`;
- Ray Tracing enabled;
- Substrate enabled;
- Android File Server configuration present and enabled despite the initial PC-only target.

This documentation task does not change them. BS-011 creates a project-owned map. BS-013B explicitly owns PC-only configuration cleanup and the measurable renderer/scalability baseline. Tokens and secrets from configuration never enter documentation or logs.

## 13. Changing architecture

An ADR is required for a cross-system choice that is hard to reverse or affects saves, networking, performance, or build. Reversible tuning does not receive an ADR.

Flow:

1. observed problem and metric;
2. alternatives and fallback;
3. network, save, performance, and Editor impact;
4. creator product decision or demonstrated technical acceptance;
5. ADR;
6. synchronized ARCHITECTURE, OWNERSHIP, system document, ROADMAP, and task updates.

Never build speculative infrastructure merely because it “might be useful.”
