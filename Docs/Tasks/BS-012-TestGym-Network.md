# BS-012 — Network TestGym Fixture

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-012-testgym-network`
**Base commit:** `7c7e2790fcac562a85e53bc1e21f091fce8dfd60`
**Roadmap milestone:** M1 — Recoverable baseline and project memory
**System docs:** [Architecture](../ARCHITECTURE.md), [Test strategy](../Testing/TEST_STRATEGY.md), [ADR-0002](../Decisions/ADR-0002-Private-Steam-Listen-Server.md), [ADR-0003](../Decisions/ADR-0003-Replication-Backend-Selection.md)

## Observable outcome

`/Game/BS/Maps/Test/L_TestGym_Network` is a small project-owned network fixture with four valid PlayerStart actors. A packaged Win64 Development build starts one local listen host plus three separate local client processes on that map, every client completes the engine connection and join path, and all four processes bring the same world up for play without a crash or unexplained network warning.

## Why now

BS-011 proved the first project-owned map, Git LFS workflow, validation, cook, package, and packaged-map load. BS-012 adds the smallest real four-process topology fixture before Core, gameplay, Steam sessions, World Partition, or production content can hide connection failures. It proves only the roadmap's M1 network-start gate and becomes the controlled map used by later network tasks.

## In scope

- one new map at `Content/BS/Maps/Test/L_TestGym_Network.umap`, created from `L_TestGym_Core` through Unreal Editor;
- the unchanged Basic Level actor set plus exactly four PlayerStart actors;
- deterministic PlayerStart labels and transforms with enough separation to avoid initial pawn overlap;
- no Level Blueprint gameplay and no per-frame script;
- one local loopback topology: one packaged listen host plus three separately launched packaged clients;
- standard Unreal Engine replication and default engine gameplay classes only;
- Git LFS lock, pointer, object, push, post-merge audit, and unlock for the new map;
- Build, Automation, Data Validation, Cook, Map Check, package, network-log, creator, and backup evidence;
- task, status, and verification documentation.

## Out of scope

- Steam Online Subsystem, Steam invites, NAT traversal, two accounts, two PCs, or two real networks; BS-022 and BS-033 own those gates;
- custom session hosting, session discovery, reservations, join-in-progress state restoration, reconnect, host migration, shutdown UX, or a four-player admission limit; BS-032 and later session tasks own them;
- custom GameMode, GameState, PlayerController, PlayerState, Pawn, Character, HUD, UI, RPC, replicated gameplay property, or gameplay authority rule;
- Replication Graph or Iris adoption; ADR-0003 remains Proposed until representative workloads exist;
- World Partition, four separated streaming bubbles, relevancy tuning, dormancy, latency/loss, network profiling, or soak testing;
- changing `GameDefaultMap`, `EditorStartupMap`, renderer, scalability, input, plugins, `.uproject`, or any Config file;
- production meshes, materials, Source Art, Marketplace content, or Engine Source changes.

## Dependencies and required decisions

- BS-009 through BS-011 are Done on `main`;
- decisions 55–63 confirm four total players, a private listen server, join support, and no tether;
- ADR-0002 is Accepted and defines the eventual Steam listen-server topology;
- standard Unreal replication is the mandatory fallback while ADR-0003 remains Proposed;
- the reversible task default is local IP loopback on an isolated non-default port, with no Steam or online-session claims;
- no material product decision is missing for this smoke fixture.

## Allowed files/domains

- `Content/BS/Maps/Test/L_TestGym_Network.umap`;
- `Docs/Tasks/BS-012-TestGym-Network.md`, `Docs/Tasks/README.md`, and `Docs/STATUS.md`;
- generated package, process logs, and verification helpers only under ignored `Saved/` output;
- no tracked C++, Config, plugin, `.uproject`, Source Art, or unrelated documentation change.

## Authority/network impact

The fixture introduces no Broken Streets gameplay truth and no custom network API. The listen host uses Unreal's standard server role, and the three clients use the standard engine connection path. There are no custom RPCs, replicated DTOs, private fields, or mutation rules to validate in BS-012.

The test proves only that four packaged processes can start and join the same empty map locally. It does not prove Steam transport, session privacy, maximum-player enforcement, secure commands, reconnect, durable late-join state, relevancy, separated bubbles, or production bandwidth.

## Persistence/migration impact

N/A. The map and topology smoke create no save, profile, world record, session journal, schema, migration, or persistent network state.

## Performance budget

- no Tick, scheduler, AI, physics workload beyond the template, gameplay replication, or production asset load;
- source map remains below 5 MiB and contains only the template actors plus three additional PlayerStarts;
- host begins listening within 30 seconds on the development PC;
- each of three clients completes connection, joins, and brings `L_TestGym_Network` up for play within 30 seconds after launch;
- every process remains alive and responsive for a 10-second observation window;
- process memory, frame time, bandwidth, four-bubble scaling, latency, and packet loss are observations only, not claims or acceptance budgets at this empty-fixture gate.

## Blueprint/Editor impact

Madalin creates the binary map through Unreal Editor 5.8.2 after Codex acquires its planned-path Git LFS lock. The map is created with `Save Current Level As` from `L_TestGym_Core`; the existing core map is not modified. The original PlayerStart is renamed and positioned, then duplicated three times. No Blueprint, material, mesh, Project Setting, plugin, or C++ class is created.

The four required actor labels and transforms are:

| Actor label | Location (X, Y, Z) | Rotation (Pitch, Yaw, Roll) |
|---|---:|---:|
| `PS_Network_01` | `-400, -400, 120` | `0, 45, 0` |
| `PS_Network_02` | `400, -400, 120` | `0, 135, 0` |
| `PS_Network_03` | `-400, 400, 120` | `0, -45, 0` |
| `PS_Network_04` | `400, 400, 120` | `0, -135, 0` |

## Acceptance criteria

1. **Given** the locked planned path **When** the creator saves the network fixture **Then** exactly one new project-owned package exists at `/Game/BS/Maps/Test/L_TestGym_Network`, `L_TestGym_Core` remains byte-identical, and no unrelated asset changes.
2. **Given** the saved fixture **When** its actors are inspected **Then** it retains the Basic Level template actors and contains exactly four PlayerStarts with the required labels and transforms, with no Level Blueprint gameplay.
3. **Given** the saved map **When** Map Check and Data Validation run **Then** the package has 0 errors and no unexplained warning.
4. **Given** the staged map **When** Git inspects it **Then** `.umap` is a valid LFS pointer, its payload exists locally, and the lock belongs to the task owner.
5. **Given** the exact candidate **When** `Tools/BS.cmd All` runs **Then** Build and Automation pass, both project maps validate, and Cook reports no project-owned omission or new warning.
6. **Given** a package cooked for the explicit network map **When** one listen host and three independent local clients launch **Then** the host listens successfully, each client connects and joins, all processes load `/Game/BS/Maps/Test/L_TestGym_Network`, and no process reports a fatal, connection failure, or map-load failure.
7. **Given** the four-process manual checkpoint **When** Madalin observes it **Then** the host and three clients remain responsive on the expected TestGym for at least 10 seconds and close normally.
8. **Given** accepted integration **When** Git, GitHub, Git LFS, and backup are audited **Then** local and remote `main` agree, the map object is recoverable, and the lock is released only after the verified push.

## Automated verification

- preserve SHA-256 for `L_TestGym_Core` and prove it did not change;
- inspect changed paths, map size, LFS attributes, lock owner, staged pointer, `git lfs status`, `git lfs ls-files`, and `git lfs fsck --pointers HEAD`;
- run Map Check and project Data Validation;
- run `Tools/Tests/Runner.SelfTest.ps1` and `Tools/BS.cmd All` on the exact candidate;
- build, cook, stage, package, and archive Win64 Development with `/Game/BS/Maps/Test/L_TestGym_Network` explicitly selected;
- run one packaged listen host and three packaged loopback clients on an isolated port, with one retained log per process;
- require three accepted client connections and joins in the host log, and exact-map load plus normal shutdown in every process log;
- scan for fatal, crash, travel failure, connection failure, load failure, and unexplained network warnings;
- audit that no custom networking backend, plugin, Config, or gameplay code entered the task.

## Manual acceptance

### Checkpoint A — create the network fixture

**Goal:** Save the core map as `L_TestGym_Network` and configure exactly four PlayerStarts.
**Applications needed:** Unreal Editor 5.8.2.
**Unreal Editor state:** Closed at the start; Open only for the issued numbered steps; Closed after Checkpoint A.
**Visual Studio state:** Not needed.
**Expected duration:** 10 minutes.
**Files/assets created or modified:** `/Game/BS/Maps/Test/L_TestGym_Network` only.
**Do not touch:** `L_TestGym_Core`, Level Blueprint, template lighting/floor actors, Project Settings, Config, plugins, other Content folders, Source Art, or engine association.

Codex issues the exact numbered Editor steps only after the preparation commit is pushed and the new map path is locked. The creator returns a screenshot showing the map name, World Outliner with all four PlayerStarts, and Content Browser path, then closes the Editor.

### Checkpoint B — four-process visual smoke

After the packaged automated topology passes, Codex supplies one-click ignored launchers or exact launch steps. PASS requires one listen-host window and three client windows on the expected TestGym, all responsive for 10 seconds, with no crash or connection dialog. This empty fixture does not require the players to see or interact with each other.

## Risks and rollback

- **Base:** `7c7e2790fcac562a85e53bc1e21f091fce8dfd60`.
- Four loopback processes prove only local engine networking. They cannot validate Steam identity, real NAT, router behavior, remote latency, or production security.
- Default engine pawn and game classes are temporary test behavior, not Broken Streets architecture or a player implementation.
- The map is binary; strict path, core-map hash, actor setup, Map Check, Data Validation, cook, packaged topology, LFS, and visual checks reduce accidental-content risk.
- Rollback requires both maps and every packaged process closed, then a public-history revert after merge. Never delete or rename the map in File Explorer.
- No save or network protocol compatibility impact exists because this task defines neither.

## Docs/ADR updates

- update the task index and STATUS with verified facts;
- keep ADR-0002 Accepted and unchanged;
- keep ADR-0003 Proposed and unchanged because this empty fixture does not provide a representative replication-backend workload;
- do not create an Online/Session system document because no Broken Streets session system is designed or implemented here.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| | | | | | |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later task/status/evidence-only commit may reference the verified candidate while explicitly listing unchanged runtime files.

## Final handoff

Preparation is in progress. The task remains open until the creator creates the locked map, Codex verifies the exact candidate through LFS/build/validation/cook/package/four-process logs, and the creator accepts the packaged four-process visual smoke.
