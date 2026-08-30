# System Ownership

Ownership means who may change runtime truth, not who edits a file. Every state has one writer. A consumer requests change through a typed command and receives a result, event, or read model.

## Ownership dimensions

- **Storage owner:** the type or service holding state in memory.
- **Runtime mutation authority:** the only domain allowed to validate and mutate that state.
- **Persistence owner:** the domain produces the semantic snapshot; Save orchestrates versioning and I/O.
- **Replication audience:** public, owner-only, party, relevant-only, or server-only.

These roles may temporarily live in one Actor or Subsystem, but they remain conceptually distinct.

**Terminology:** `host` is the player/PC running the listen server. In the Runtime authority column, `server` means only the server side of that process. The host's local client passes through the same validation as every remote client.

## Domain matrix

| Domain | Owned truth | Runtime authority | Persistence | Default audience | Consumers / public commands | Forbidden dependencies |
|---|---|---|---|---|---|---|
| Core | typed IDs, results/errors, time types, tags, feature flags | local/server by type; no global gameplay owner | configuration/version metadata | by consumer | every domain uses primitives | does not depend on gameplay/UI |
| Identity/Profile | AccountId binding, CharacterId, character slots, Portable Profile revision | server validates runtime; client owns its local file | PortableCharacterProfile | owner-only/server | Online, Save, and Player request identity/profile snapshots | never treats a client profile as verified truth |
| Online/Session | lobby, invite, join, member state, reservation | server for session; platform for identity/lobby | configuration plus minimal session recovery | party/public summary | UI and Save consume lifecycle events | does not mutate economy/inventory |
| Network | RPC policy, relevancy, facades, compatibility handshake | server | configuration/ADR, not gameplay save | variable | every replicated domain | never becomes semantic owner of state |
| World | world clock, weather, district/world state, streaming coordination | server/world owner | HostWorldSave | public/relevant | Needs, AI, Traffic, Events | does not mutate personal CharacterActiveTime |
| Player | possession, locomotion state, input intent, camera gameplay parity | server for movement/gameplay; local for presentation | profile/settings where required | public/relevant plus local | Interaction, Combat, UI | does not own money/save/catalog |
| Appearance | body preset, outfit record, jewelry, visual/social signature | server validates equipment | Portable Profile | public subset plus owner-private | AI, Law, UI | never moves items without Inventory/Ownership |
| Interaction | focus target, verb eligibility, timed-action lifecycle | server validates action | only actions requiring recovery | owner/relevant | sends commands to the target domain | never directly applies money/item state |
| Items | definitions and instance metadata | server for instances; immutable definitions | item records through container owner | owner/relevant | Inventory, Shops, Jobs | does not decide container, money, or ownership |
| Inventory | unique item location, containers, capacity/weight | server | Portable Profile/Vehicle/Property/World by container | owner/authorized | Move/Add/Remove with preconditions | does not mutate money or ownership rights |
| Ownership | owner, access rights, keys, permissions, transfer | server | possession record | owner/authorized/public summary | Inventory, Vehicles, Properties, Trade | does not move items or debit money directly |
| Economy | legal cash, bank, dirty cash, EconomyTransactionLedger | server | Portable Profile plus journal/receipts | owner-only | debit/credit/transfer/quote results | does not create items, jobs, or ownership rights |
| Progression | level, licenses, unlocks, applied progression awards | server | Portable Profile | owner-only/selective public summary | Jobs/Activities emit award requests | does not calculate monetary payout |
| Shops | catalog view, stock/offers, order lifecycle | server/world owner | HostWorldSave where stock persists | requester/public catalog | asks the transaction coordinator | never writes wallet/inventory |
| Jobs | definitions, JobInstance, participants, objectives, outcome | server/session owner | HostWorldSave/SessionCommitJournal; profile receipt | participants/public summary | requests rewards, incidents, progression | never writes money/heat/profile directly |
| Legality | action classification and Incident/heat request | server | temporary incident; record through relevant domain | relevant/owner | Police/Factions consume Incident | never spawns police or applies damage |
| Police | response tier, dispatch, pursuit, arrest state | server | active world/session state; coordinated persistent outcome/record | relevant/public plus owner | consumes Incident, requests AI/Consequences | never invents crimes, money, or confiscation |
| Factions | reputation per family, access, retaliation | server | Portable Profile plus separate world NPC state | owner/relevant | Jobs, AI, Dialogue | does not mutate Economy directly |
| Needs | hunger, thirst, sleep, bladder, hygiene | server, derived from CharacterActiveTime | Portable Profile | owner-only plus minimal public effects | Player/Health/UI consume effects | does not control world clock or sleep vote |
| Health | health, hit zones, wounds, downed/revive | server | Portable Profile for persistent injuries | relevant plus owner detail | Combat/Consequences/UI | does not apply fees/confiscation |
| Consequences | orchestration of downed/arrest → hospital/prison → release | server | session/world plus personal receipts | participant/relevant | requests mutations from Health/Economy/Inventory | never duplicates called-domain truth |
| Combat | attack intent, weapon operation, hit resolution | server | weapon state through Inventory/Items; stats where needed | relevant | requests damage from Health and Incident from Legality | never mutates health/heat directly |
| Vehicles | semantic VehicleRecord, runtime vehicle, seats, fuel, condition, trunk link | server | Portable Profile/approved store | relevant plus owner detail | Ownership, Inventory, World | does not own trunk contents; Inventory does |
| Properties | PropertyRecord, instance rights, visitors, decor/storage placement | server | Portable Profile plus world materialization state | authorized/relevant | Ownership, Economy, Inventory | never writes wallet or item location directly |
| AI Foundation | navigation/perception/state tasks, spawn anchors, simulation tier | server | important NPC/world deltas only | relevant | Police, Population, Jobs, Factions | does not own law, jobs, or economy |
| Population | ambient records, spawn, promote/demote, crowd budget | server | minimal statistical/world state | relevant | World, Legality presentation | ambient NPC never implicitly becomes a persistent profile |
| Traffic | flow records, promote/demote, physical-traffic budget | server | minimal statistical/world state | relevant | World, Police, Vehicles | does not own personal vehicles |
| World Events | eligibility, cooldown, event instance, budget | server/world owner | HostWorldSave when persistent | relevant/participants | Jobs, World, AI | never bypasses owners for rewards/incidents |
| UI | view models, focus, layout, local navigation | local | user settings only | local | sends intents and displays read models | no direct gameplay mutation |
| Audio | mixes, routing, occlusion, radio presentation | local plus limited server metadata | settings/content | local/relevant | World, Vehicle, UI | does not change gameplay state through an audio event |
| Save | schema registry, capture coordination, migration, checksum, I/O, generations | server/local by store | approved files | server/local only | requests snapshots from owners | never calculates rules or silently resolves conflicts |
| Build/Tools | build, cook, validation, profiling, automation | developer/editor | reports and versioned configuration | developer | every domain | never becomes a Shipping runtime dependency |

## Multi-domain operations

A `UseCaseCoordinator` or transaction coordinator may order commands and compensations, but it never writes owner state directly. Every operation has an idempotent ID and explicit result.

Examples:

- **Purchase:** Shop offer → Economy debit → Items/Inventory materialization → Ownership transfer → receipt/commit.
- **Trade:** bilateral consent → permission lock → Inventory moves → Ownership transfers → optional Economy transfers → unlock/commit.
- **Hospital:** Consequences starts → Health outcome → Economy fee → Inventory confiscation/move → safe spawn → receipt.
- **Job payout:** Jobs outcome → Economy/Progression requests → SessionCommitJournal receipt → profile export.

On failure, the coordinator uses compensable steps or marks the operation for recovery. It never assumes files on two different PCs can be updated atomically.

## Dependency rules

- Core does not depend on gameplay domains.
- Runtime may consume definitions/data; runtime never mutates definitions.
- Economy does not depend on Jobs; Jobs consumes the Economy API.
- Inventory and Ownership are separate: item location is not the right to own it.
- Progression is not Economy; level does not modify damage.
- Legality produces Incident; Police produces the response.
- Health produces downed; Police produces arrest; Consequences orchestrates the outcome.
- Save depends on snapshot interfaces, not internal owner implementations.
- UI and Audio are not dependencies of domain rules; presentation consumes output.
- Editor/DeveloperTool code is not a Shipping runtime dependency.

## System-document contract

A real system document is created just in time from `Docs/Systems/SYSTEM_TEMPLATE.md`, never as an empty placeholder. It must define:

- owner and all four ownership dimensions;
- commands/events and consumers;
- authority, RPC validation, audience, and late join;
- data model, IDs, persistence, and migration;
- update model, LOD, and budgets;
- Blueprint/Editor surface;
- failures, exploits, and recovery;
- tests and acceptance steps;
- allowed and forbidden dependencies.

Any change that creates two writers for the same truth is an architecture defect requiring redesign or an ADR, not a quick exception.
