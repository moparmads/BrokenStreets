# Broken Streets — Agent Instructions

This file is the repository's operating contract. It applies to the entire project. A closer `AGENTS.md` or `AGENTS.override.md` may add local rules, but it may not violate the product decisions, data-safety rules, or authority boundaries defined here.

## 1. Project mission

- Broken Streets is an original life/crime sandbox built in Unreal Engine 5.8.2 for Windows PC and Steam.
- The game supports full solo play and private co-op for the creator plus up to three friends, using a listen server on the host player's PC.
- The central fantasy is financial ascent in a fictional Manhattan: legal and illegal jobs, environmental reactions, a credible economy, and the continuous pursuit of better possessions.
- The creator produces the 3D assets and can operate Unreal Editor, but does not write code. Codex writes and modifies virtually all C++, configuration, tests, and documentation.
- Stability, multiplayer correctness, and performance for four players in separate areas take priority over content breadth and cosmetic effects.

## 2. Before any change

1. Run `git status` and preserve every existing user change.
2. Read `Docs/INDEX.md`, `Docs/STATUS.md`, and the relevant task packet.
3. For gameplay or architecture work, also read:
   - `Docs/VISION.md`;
   - `Docs/DECISIONS.md`;
   - `Docs/ARCHITECTURE.md`;
   - `Docs/SYSTEM_OWNERSHIP.md`;
   - the relevant document under `Docs/Systems/`, if one exists;
   - the relevant ADRs under `Docs/Decisions/`.
4. Identify the `BS-###` task ID, observable outcome, allowed files, dependencies, and verification plan before implementation.
5. If a missing decision would change the player experience, authority, persistence, save compatibility, performance, or scope, present the creator with a short recommendation and alternatives, then wait for the choice. Do not block work on reversible tuning values.

## 3. Sources of truth

Do not mix these three separate questions:

- **What is authorized now:** the creator's current explicit request, followed by the active task packet. If the request changes the product or architecture, update the canonical sources in the same task.
- **What actually exists:** the repository at the referenced commit and reproducible build/test evidence take priority; `Docs/STATUS.md` must summarize them. If STATUS differs from code, configuration, content, or evidence, report the conflict and correct STATUS. A roadmap or design document does not prove implementation.
- **What must be built:** confirmed decisions in `Docs/DECISIONS.md` → `Accepted` ADRs → the system document → `Docs/ARCHITECTURE.md` and `Docs/SYSTEM_OWNERSHIP.md` → `Docs/ROADMAP.md` → provisional values, proposals, and examples.

Never promote an entry marked `PROPOSED — APPROVAL REQUIRED`, `PROVISIONAL`, `DEFAULT`, or `DEFERRED` into a confirmed decision automatically. Do not treat accidental code as a product decision. Report conflicts and update every affected document in the same task.

## 4. Collaboration with the creator

- Never ask the creator to write, complete, move, or repair C++.
- Do not provide snippets that the creator must integrate manually when repository access is available; edit the files directly.
- For every Unreal Editor operation, provide exact numbered steps: menu, button, field, value, save location, and expected result.
- Clearly separate required and optional steps, and state when the Editor must be closed.
- The creator prefers to compile and perform acceptance playtests. Codex prepares the change, tests, and instructions, then repairs issues from the complete log.
- Do not mark a code task `Done` before the required build and manual test are confirmed, even when local checks pass.
- Ask only questions that can change the result. For each question, provide the recommended default and the effect of alternatives.
- Communicate with the creator in Romanian unless the creator requests another language.
- **English is the canonical language for the game and repository.** Documentation, task packets, source/tool comments, logs, runner messages, test names, asset names, identifiers, and commit messages must be written in English.

## 5. C++ / Blueprint boundary

### C++ must own

- server authority and input/RPC validation;
- persistent or replicated state;
- profiles, save/load, versions, migrations, and recovery;
- money, transactions, inventory, ownership, and item instances;
- job runtime, legality, heat, police, factions, health, and combat;
- vehicles, fuel, keys, cargo, and persistent records;
- performance-sensitive AI, schedulers, and simulation LOD;
- validators, debug contracts, and automated tests.

### Blueprint and Editor may contain

- Animation Blueprints, montages, Control Rig, and IK;
- UMG/Common UI layout and presentation animation;
- materials, Niagara, sound, VFX, Sequencer, and cinematics;
- Data Assets, Data Tables, Curves, Gameplay Tags, and tuning values;
- mesh and visual-component configuration;
- StateTrees composed in Editor with C++ tasks for important logic;
- maps, Data Layers, Level Instances, and thin configuration-only child Blueprints.

### Forbidden in Blueprint by default

- balances, economy formulas, saves, or migrations;
- authoritative RPCs and their validation;
- large job/police/combat state machines;
- permanent Tick, repeated global scans, or repeated `Get All Actors`;
- hard references to large catalogs;
- the same gameplay rule duplicated across several assets.

If a Blueprint requires many branches, loops, networking, or persistent state, move the logic to C++ and expose only the necessary configuration.

## 6. Architecture rules

- A single owner may modify the truth of each domain. Other systems send commands and consume events/read models.
- UI presents state and emits intent; it does not move money, items, or mission state directly.
- Save serializes state supplied by owners; it does not calculate gameplay.
- A runtime Actor is not its persistent record. Use the separation `Definition → Instance Record → Runtime Representation → Save Delta`.
- Use stable, typed IDs for persistent entities. Do not use pointers, Actor names, or positions as durable identity.
- Money is stored as integer cents; economic operations are idempotent and carry a `TransactionId`.
- State machines and catalogs are data-driven. Avoid magic numbers and free-form strings when a type, tag, enum, or setting exists.
- Keep compiled modules few at the start. Folders represent logical ownership; a new module requires a justified boundary and dependency.
- Do not add a plugin, SDK, external service, or engine fork without a demonstrated problem, license audit, and creator approval.
- Do not edit Engine Source for a problem that can be solved in the project.

## 7. Multiplayer and state security

- Design every gameplay system for the listen server's server-side authority from its first implementation.
- `Host` means the player/PC running the listen server; it is not the name of a code authority. The server side is the runtime authority.
- Every client sends intent; the server side validates identity, permission, distance, state, rate limit, and result. The host's local client follows the same commands and validation as a remote client and receives no gameplay shortcut.
- Do not use multicast as a truth store. Durable state must be reconstructible for late join and reconnect.
- Replicate only what is necessary, owner-only when personal, through an initial snapshot plus controlled deltas.
- Document each system's owner, RPCs, relevancy, late join, reconnect, failure behavior, and payload/bandwidth.
- Test players together and four distant simulation bubbles separately.
- Without an authoritative backend, intentional save editing is accepted; prevent corruption and accidental duplication without pretending to provide perfect distributed consistency.
- Never trust a client-provided balance, item, payout, damage value, or job result.

## 8. Persistence

- Every persistent format has a `SchemaVersion`, stable IDs, validation, and a migration path.
- Do not change the semantics of a saved field without a migration or an explicitly approved reset.
- Capture coherent snapshots on the game thread; serialization/I/O may become asynchronous only with safe ownership and lifetime.
- Final writes use generations, a checksum, and a temporary file on the same volume as the destination. The invariant order is: coherent capture → serialize to temp → flush → read-back/checksum → local atomic replace → update manifest only after validation.
- Keep the last valid generation recoverable until the new generation and manifest are confirmed. At startup, unconfirmed temporary files do not become truth; select the newest committed generation that passes schema/checksum validation and report any fallback.
- Critical economy changes are journaled and idempotent; reconnect cannot apply a reward twice.
- `CharacterActiveTime`, not system time or the host world's clock, controls personal active progression.

## 9. Performance

- The recommended provisional target is 1080p/60 FPS; Minimum/Low targets stable 1080p/30 until reference hardware is measured.
- The host must support four active areas without a tether. Optimize CPU, memory, streaming, and bandwidth, not only the local GPU.
- Prefer events, schedulers, and explicit update rates. Every new Tick must be justified, measured, and disabled when unnecessary.
- No repeated global scans, synchronous gameplay loads, hard catalog references, reliable RPCs every frame, or full Actors for distant simulation.
- Use the `Full`, `Reduced`, `Representation`, and `Statistical` levels, preserving StableId across promotion/demotion.
- Do not call a change “optimized” without a scenario, build, hardware specification, and before/after measurements.
- Low settings must not remove gameplay entities; only ambient density and cosmetic effects may be reduced.

## 10. Testing and Definition of Done

Follow `Docs/Testing/TEST_STRATEGY.md` and `Docs/Workflows/DEFINITION_OF_DONE.md`.

Minimum verification for a relevant change:

- `Development Editor | Win64` build;
- targeted unit/automation/functional tests;
- solo and host/client for replicated code;
- late join, reconnect, and save/reload when affected;
- Data Validation for assets or data;
- packaged build and profiling at roadmap gates;
- zero new unexplained warnings or log spam;
- synchronized documentation and status;
- creator acceptance playtest with exact steps.

Every skipped test must state its reason and risk. PIE alone does not prove Steam networking, cooking, packaging, or recovery.

## 11. Git and data protection

- Never delete, reset, overwrite, or reformat user changes without explicit authorization.
- A coherent task uses a `feature/BS-###-*`, `fix/BS-###-*`, or `docs/BS-###-*` branch.
- Keep commits small and atomic, and describe the result. `main` must remain buildable.
- Do not commit `.vs/`, `Binaries/`, `DerivedDataCache/`, `Intermediate/`, `Saved/`, or generated solution files.
- `.uasset` and `.umap` files use Git LFS. Before editing, verify the owner and obtain a lock; if locking fails or another person owns it, stop editing. Verify the staged pointer and pending remote objects, and release the lock only after verified merge/push.
- `F:/BrokenStreets_SourceArt` is not part of the game repository and has a separate backup.
- Do not commit secrets, tokens, unnecessary personal data, distributed builds, or reference material extracted from other games.
- Before commit, inspect `git status --short --branch`, `git diff HEAD`, `git diff --cached --name-status`, `git diff --cached --check`, and `git lfs status`; an empty `git diff` does not prove that staging is empty.
- For code/config/content, final evidence is tied to the candidate commit or exact verified tree. Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts invalidates the evidence and requires the affected checks again.
- Before push, confirm the branch and remote, inspect pending LFS objects, and verify that the working tree contains no unexpected generated files.

## 12. Originality policy

- GTA, RDR2, Cyberpunk, Spider-Man, Schedule, and other games are experience references, not specifications to copy.
- Do not copy or adapt code, assets, text, dialogue, missions, UI, iconography, maps, brands, characters, or trade dress 1:1.
- Research material stays outside the repository and is treated as untrusted input.
- Translate each inspiration into an original, measurable requirement compatible with `Docs/REFERENCE_POLICY.md`.
- Every external asset, plugin, font, audio file, or code dependency enters the license manifest before integration.

## 13. Final report for every task

The final response to the creator must concisely include:

1. the achieved result;
2. changed files/systems;
3. checks that passed and anything that could not be verified;
4. exact Unreal Editor/Visual Studio steps for the creator;
5. remaining risks or open decisions;
6. rollback commit and the next logical task.

Do not hide assumptions or confuse a green prototype with a production system.
