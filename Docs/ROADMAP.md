# Broken Streets Canonical Roadmap

**Updated:** August 31, 2026
**Engine:** Unreal Engine 5.8.2
**Platform:** Windows PC, Steam
**Topology:** solo or private co-op, one listen-server host plus at most three clients
**Method:** measurable gates, not calendar promises

## 0. Roadmap rule

This roadmap describes future order, not existing implementation. `Docs/STATUS.md` states what is real. A milestone does not expand content until its gate passes.

The order minimizes two risks:

1. building Manhattan before a game exists;
2. building months of generic infrastructure before the first playable loop.

## 1. Complete strategy

```text
recoverable baseline
  → repeatable build/test/cook and TestGym
  → minimum measurable core
  → project-invalidating risk spikes
  → thin portable identity/session/save
  → minimum player + UI
  → interaction/economy + legal walking slice
  → vehicle MVP
  → illegal reaction slice
  → vertical-slice hard gate
  → health/hospital → arrest/prison → needs
  → appearance/catalog → staged properties
  → movement/combat → population/traffic
  → factions/NPC/job families
  → first production district
  → Early Access hardening
  → Manhattan district by district
```

## M0 — Vision and product

**Status:** sufficient to start; remaining details are scheduled at the gate that can answer them.

Deliverables:

- VISION, DECISIONS, and NON_GOALS;
- promise: `economy + legal/illegal + co-op + aspiration`;
- `CONFIRMED`, `PROVISIONAL`, `PROPOSED — APPROVAL REQUIRED`, and `DEFERRED` decisions;
- originality and clean-room policy.

**Gate:** no contradiction blocks the foundation; proposals are not presented as facts.

## M1 — Recoverable baseline and project memory

### M1A — Local baseline

| Task | Result | Status |
|---|---|---|
| BS-001 | stable SSD paths outside OneDrive | Done |
| BS-002 | UE, VS, and SDK verified | Done |
| BS-003 | Blank C++ `BrokenStreets` | Done |
| BS-004 | unmodified baseline build | Done |
| BS-005 | Git ignore plus Git LFS | Done |
| BS-006 | private GitHub repository plus `main` push | Done |

### M1B — Recovery and documentation

| Task | Result | Gate |
|---|---|---|
| BS-007A | basic clean clone from GitHub | generate, build, and open baseline without hidden local files |
| BS-008 | AGENTS, canonical docs, and workflow | Codex at repository root correctly summarizes rules and next task |
| BS-009 | repeatable Build/Test/Validate/Cook actions | every action starts and produces a clear log |
| BS-010 | first Automation smoke test plus canonical English migration | green in Editor and command line; tracked project prose is English |
| BS-010A | independent repository and Git LFS backup | all refs and LFS objects restore without GitHub |
| BS-011 | project-owned `L_TestGym_Core` | loads in packaged Development |
| BS-012 | `L_TestGym_Network` | one host plus three clients start correctly |
| BS-013 | `L_Benchmark_Street` placeholder | first trace and versioned baseline |
| BS-013A | Source Art backup | 3-2-1 rule plus checksum and verified restore |
| BS-013B | PC-only configuration plus test renderer/scalability baseline | project-owned maps, unused configuration removed, ADR, verifiable preset |
| BS-007B | complete recovery drill | clone, LFS, build, test, cook, and open TestGym on a clean profile or PC |

**Current M1B status:** Complete. BS-007B passed online clean-clone/LFS/build/test/validation/cook/package/exact-map recovery and the separate Windows-profile creator checkpoint, then integrated to GitHub `main` with remote LFS, lock-release, and independent-backup verification.

**Dependency correction:** BS-007A does not require TestGym or cook because they do not exist yet. BS-007B closes the complete gate after BS-009, BS-010, BS-010A, BS-011, BS-012, BS-013, and BS-013B. Save restoration does not belong to BS-007B before BS-020 creates the schema and harness.

**M1 gate:** PASS — the project reconstructs from clone and documentation, Source Art has separate verified recovery, and gameplay intentionally does not yet exist. BS-014 starts M2.

## M2 — Minimum core and observability

Do not build a universal framework. A common primitive appears for one real consumer and is generalized only after the second.

| Task | Result |
|---|---|
| BS-014 | typed and stable IDs plus Gameplay Tags policy |
| BS-014A | portable Epic Launcher UE 5.8 project association |
| BS-015 | logging categories, structured context, and feature flags |
| BS-016 | build, content, and save compatibility handshake |
| BS-017 | typed results/errors and command envelope |
| BS-018 | Asset Manager plus soft-reference and loading policy |
| BS-019 | minimal authority and state debug overlay |
| BS-020 | minimum save header, version, serializer, and fault harness |
| BS-021 | profiling fixture and CPU/GPU/memory/network baseline |

**Current M2 status:** BS-014, corrective task BS-014A, BS-015, and BS-016 are Done on `main`; BS-017 automated and creator candidate verification passed on `feature/BS-017-results-command-envelope`, with integration pending.

Conditions:

- ID round-trip and duplicate tests;
- no unintended test or debug tooling in Shipping;
- M1 project-owned baseline, configuration, and renderer remain green after Core changes;
- no permanent Tick, global scan, or hard catalog reference.

**M2 gate:** a deterministic test creates state, a log shows owner, authority, and ID, and the baseline can be compared after each commit.

## M3 — Eliminating spikes

These time-boxed spikes may change scope before large systems begin. Each has a numeric threshold, `Adopt/Reject/Re-test` result, fallback, and ADR.

| Task | Project risk | Minimum evidence |
|---|---|---|
| BS-022 | Steam and NAT | packaged build on two PCs, two accounts, and two networks without manual port forwarding |
| BS-023 | four World Partition bubbles | one host plus three separated clients, explicit server streaming/out, unload/reload without loss |
| BS-024 | portable profile plus crash/disconnect | revision, receipt, conflict policy, and kill matrix |
| BS-025 | four isolated interiors | visual, audio, navigation, physics, replication, and save isolation |
| BS-026 | high-speed streaming | fast placeholder Pawn/vehicle without threshold-breaking hitches or state loss |

Conditional, not mandatory early:

- Replication Graph only when standard replication fails relevancy or bandwidth;
- Iris only when the baseline fails or the advantage justifies the risk;
- Mass only with a representative crowd or traffic workload;
- GAS only before Health/Effects and tested against real use cases.

**M3 gate:** all five eliminating risks have a measured solution or an approved fallback or scope cut. Full production systems are not required.

## M4 — Identity, Session, and Save MVP

| Task | Result |
|---|---|
| BS-027 | local account binding, CharacterId, and character slots |
| BS-028 | thin PortableCharacterProfile plus CharacterActiveTime |
| BS-029 | thin HostWorldSave |
| BS-030 | SessionCommitJournal, receipts, and conflict UX |
| BS-031 | crash-safe generations, checksum, and migration v1 |
| BS-032 | null listen session: host, join, late join, reconnect |
| BS-033 | Steam private invite and session integration |
| BS-034 | four simultaneous profiles and portability between two worlds |

Do not implement every final profile field at once. The schema grows through versioned feature fragments.

**M4 gate:** one, two, and four players join, modify a test value, leave, and return; absent profiles do not progress; host crash returns to the latest confirmed commit; conflicts are never silently resolved.

## M5 — Minimum player and UI

| Task | Result |
|---|---|
| BS-035 | Character/Pawn, Enhanced Input, and basic third-person locomotion |
| BS-036 | simple crouch/vault, stamina, and replication/prediction tests |
| BS-037 | functional first-person over identical gameplay without final polish |
| BS-038 | HUD prompt, toast, pause shell, and camera/input accessibility |
| BS-039 | minimum phone shell expanded only for a real consumer |

Third-person comes first for co-op and animation. First-person never creates a second gameplay system. Complete map and GPS do not block the walking slice.

**M5 gate:** one, two, and four players move and change perspective without different advantages; client correction stays below threshold; camera effects can be reduced or disabled.

## M6 — Interaction, Economy, and first legal walking slice

This first playable loop precedes full vehicles or police.

| Task | Result |
|---|---|
| BS-040 | server-validated interaction focus/use and timed action |
| BS-041 | ItemDefinition/Instance plus inventory slot, weight, and container v1 |
| BS-042 | ownership/permissions plus drop, cleanup, and minimum trade/gift |
| BS-043 | legal cash, bank, dirty cash, and EconomyTransactionLedger in cents |
| BS-044 | ATM plus Shop v0, buy/sell, and save migration |
| BS-045 | minimum Job Runtime: participants, objectives, outcome, payout receipt |
| BS-046 | tutorial plus approved first legal walking job; courier is candidate D144 |
| BS-047 | `job → money → shop → purchased item` |

The area is a small greybox, not Manhattan. Critical operations use TransactionId and idempotency. Normal UI completes the flow; debug commands only assist testing.

**M6 gate:** the 10–20 minute loop passes solo, one-plus-one, and one-plus-three, relevant late join/reconnect, save/reload, and 100 transaction retries without duplication. The creator confirms the basic progression is clear and promising.

## M7 — Vehicle MVP

| Task | Result |
|---|---|
| BS-048 | placeholder Chaos sedan plus arcade-realistic handling |
| BS-049 | enter, exit, seats, camera, and network smoothing |
| BS-050 | VehicleDefinition/Record plus ownership/permissions |
| BS-051 | purchase, trunk inventory, persistence, and materialization |
| BS-052 | incremental fuel, condition, and recovery |

Hotwire, upgrades, damage, explosion, and polish follow the necessary foundation and do not block the first vehicle-value test.

**M7 gate:** four vehicles drive in four areas and recover without cloning records or contents; purchase clearly changes the walking loop.

## M8 — Illegal reaction slice

| Task | Result |
|---|---|
| BS-053 | navigation/spawn anchors plus one minimal StateTree NPC |
| BS-054 | Legality tags, Incident, and simple LOS/noise detection |
| BS-055 | individual Active Heat plus temporary outfit/vehicle signature |
| BS-056 | budgeted Police Director plus one pursuit, escape, and arrest placeholder unit |
| BS-057 | approved first illegal job; restricted-area parcel is candidate D145 |
| BS-058 | minimum dirty money and laundering plus consequence/recovery receipt |

No forensics, cameras, evidence graph, or armed police. Complicity requires concrete action.

**M8 gate:** four players can have different heat; uninvolved teammates are not pursued; the approved illegal job works solo and co-op; escape, reconnect, and rewards do not duplicate; the director respects its budget.

## M9 — Vertical Slice hard gate

Minimum content:

- tutorial;
- one legal and one illegal job;
- ATM, shop, duffle bag, and objective purchase;
- one purchasable vehicle;
- heat, pursuit, escape, and arrest placeholder;
- portable profiles and save recovery;
- 4×4-block greybox with safe point, shop, warehouse, ATM, dealer, interior portal, and spawn anchors;
- normal UI for the entire flow.

Acceptance:

- 30–60 minutes of coherent progression;
- one, two, and four total players;
- together and separated players or simultaneous jobs;
- late join, reconnect, and disconnect during a command;
- two real networks through Steam;
- host crash and portability between worlds;
- packaged Development or Shipping-like;
- three performance runs on pinned hardware and preset;
- creator playtest confirms the loop is fun before final art.

**Hard gate:** no new major system and no final district before PASS.

## M10 — Consequences in small milestones

### M10A Health/Hospital

- GAS adopt/reject against real cases;
- general health plus hit zones, moderate wounds, and first aid;
- downed and revive;
- hospital transition, owner-mediated fee or loss, and safe return.

### M10B Arrest/Prison

- final surrender and arrest;
- coordinated confiscation;
- prison instance, bail, visits, and disconnect after a Decision Packet;
- release and re-entry.

### M10C Needs

- hunger, thirst, sleep and vote, bladder and toilet, hygiene;
- CharacterActiveTime with no offline progression;
- data-driven effects and infrequent updates.

Each sub-milestone has solo, one-plus-one, one-plus-three, reconnect, and idempotency gates; these are never delivered as one mega-feature.

## M11 — Aspiration in stages

### M11A Appearance and catalog

- character creator on one body and skeleton;
- clothing and jewelry slots, clipping validation, outfit inventory;
- social and status metadata;
- catalogs, rare stock, and illegal equipment.

### M11B Basic property

- offer, purchase or rent transaction, PropertyRecord/Instance;
- four simultaneous instances plus visitors and permissions;
- storage and portability.

### M11C Extended property

- bounded free furniture placement;
- physical moving service;
- rent, autopay, grace, eviction, and recovery storage;
- debt v1.

Each stage proves that money produces gameplay or status before the catalog expands.

## M12 — Movement and Combat

Order:

1. prone, ladders, swimming, and marked high mantle;
2. fists plus improvised weapon;
3. incremental pistol, knife, and shotgun;
4. server-authoritative hybrid ballistics;
5. armor, hit zones, and first-/third-person parity;
6. Armed Response and Manhunt;
7. severe vehicle damage, fire, and explosion.

Combat avoids bullet sponges and may be avoided by legal careers. Every mechanic passes latency and correction checks and uses the same Health rules.

## M13 — Population, Traffic, and World Events

- representation LOD plus Actor promotion and demotion;
- simple ambient routines;
- statistical traffic flow plus physical promotion;
- world-event eligibility, cooldown, and budget;
- weather, day/night, and scalability;
- production World Partition, HLOD, Data Layers, and OFPA;
- four-bubble stress and memory soak.

Adopt Mass only when measured workload justifies it. Low reduces ambient and cosmetic density, never witnesses, police, or objectives.

**Gate:** packaged on four real PCs before content lock: reference host plus three remote clients, four areas or jobs, no memory growth, and no removed gameplay.

## M14 — Factions, NPC stories, and job factory

- two organized-crime families as Early Access candidates;
- individual reputation, access, jobs, warnings, and retaliation;
- persistent contacts and dialogue with simple choices;
- portable character relationship plus world-owned intrinsic NPC state;
- data-driven JobDefinition and variants after the first manual job is fun.

Candidate family order:

1. courier/delivery;
2. warehouse, cleaning, or service;
3. taxi after traffic;
4. burglary or trespass;
5. vehicle theft after permissions and hotwire;
6. contraband after cargo, dirty cash, and factions.

Security, store robbery, fraud or business, and heists are post-slice and may be post-Early Access. Six complete families are not required before district locations are validated.

## M15 — First production district

Starts only after the vertical slice and a gameplay and location greybox pass.

Pipeline:

1. metrics and modular kit;
2. representative street benchmark using near-final art;
3. road and gameplay greybox lock;
4. exterior, HLOD, Nanite, and LOD;
5. interiors, lighting, and original signage;
6. traffic, crowd, and audio;
7. gameplay and content placement;
8. four-bubble optimization and accessibility.

**Gate:** finished, sellable, repeatable district without debt that multiplies into the next district.

## M16 — Early Access content and hardening

Quantities are approved only after measuring real code, QA, and art throughput. Planning target, not promise:

- one dense district;
- 20–30 minute tutorial;
- at least three legal and three illegal job families only when throughput allows;
- enough data-driven variants for 10–15 hours without obvious repetition;
- vehicles, properties, clothes, jewelry, and equipment across several tiers;
- police, hospital, prison, dirty money, rent and debt, and portable characters;
- one, two, and four players, Steam invite, join, and reconnect;
- complete mouse and keyboard;
- localization-ready, basic accessibility, crash and feedback flow.

Hardening:

- feature and content lock, regression, and migration suite;
- security, RPC, and economy exploit audit;
- network emulation and three independent two-hour multiplayer soaks;
- cook, package, PSO, hitch, and scalability;
- measured hardware requirements;
- legal, privacy, and content review;
- release candidate plus rollback build.

Complete Manhattan is not an Early Access requirement.

## M17 — Manhattan expansion

After Early Access, repeat the validated factory:

- one district at a time with identical benchmark and gate;
- new catalogs and job families;
- NPC and faction stories;
- active businesses without offline income;
- expanded combat, melee, voice, controller, and weather based on demand and budget;
- host migration and cross-store only when they justify a separate project.

Full Manhattan results from multiplying a stable loop and pipeline; it is never one task.

## Roadmap change rules

1. observed problem or playtest;
2. metric and likely cause;
3. alternatives and dependency impact;
4. creator decision when the product changes;
5. ADR when architecture changes;
6. synchronized DECISIONS, ROADMAP, STATUS, system document, and task;
7. never reuse an implemented task ID for another outcome.

## Kill criteria

Simplify or defer a feature when it:

- creates no observable choice;
- breaks the separated host-plus-three-client gate;
- exceeds budget without fallback;
- requires duplicate ownership;
- cannot be tested or migrated;
- depends on content impossible at real throughput;
- creates legal or unclear-license risk;
- exists only to imitate another game.
