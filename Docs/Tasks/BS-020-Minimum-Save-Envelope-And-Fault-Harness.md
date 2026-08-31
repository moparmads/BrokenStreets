# BS-020 — Minimum Save Envelope and Fault Harness

**Status:** Done
**Owner:** Madalin Gavrila
**Branch:** `main`
**Base commit:** `d312ad8ed760414e3d29c97c8f5fae7ed1098dc3`
**Roadmap milestone:** M2 — Minimum core and observability
**System docs:** `Docs/Systems/Save.md`, `Docs/Systems/Core.md`

## Observable outcome

Broken Streets can encode a bounded byte payload inside one deterministic versioned save envelope and decode it only after structural, integrity, and build/content/save-schema compatibility checks pass. A Development Automation fault harness proves that truncated, malformed, corrupted, oversized, trailing, and incompatible inputs fail closed without exposing partial payload state.

## Why now

BS-016 reserved compatibility schema lane `1`, but no persisted header or serializer exists. BS-020 turns that reservation into the first real, domain-neutral byte contract before character, world, session-journal, or gameplay payloads exist. This keeps future profile and world stores from inventing incompatible framing and gives later recovery work a deterministic corruption harness.

The creator-authorized local research was consulted only for clean-room safety principles: validate complete input before materialization, keep runtime handles out of persistent data, separate schema from storage, preserve last-known-good state on failure, and make fault injection explicit. No research code, text, layout, identifiers, or proprietary binary format enters the repository.

## In scope

- add one fixed 32-byte little-endian envelope header with `BSAV` magic, envelope format version, header size, build compatibility, content compatibility, save schema, payload size, and envelope checksum;
- use the existing BS-016 compatibility policy and current signature rather than inventing another version source;
- serialize an opaque payload deterministically with no `UObject`, Actor, path, slot, profile, world, or gameplay semantics;
- validate all structure, exact file length, payload bound, checksum, and compatibility before returning header or payload output;
- expose one closed result enum with stable bounded machine names and deterministic failure precedence;
- cap the absolute envelope payload at 64 MiB; future stores must declare lower domain-specific limits where appropriate;
- add exact golden-byte, round-trip, compatibility, output-clearing, and deterministic fault-matrix Automation coverage;
- keep the fault harness and Automation implementation out of Shipping while retaining the runtime envelope reader/writer;
- create the Save system document and synchronize task/status/roadmap/index/test documentation.

## Out of scope

- actual profile, character, world, session, item, economy, job, position, or progression data;
- SaveGame slots, filenames, directories, platform storage, Steam Cloud, user selection, or UI;
- disk I/O, async jobs, temporary files, flush, atomic replace, manifest, rotating generations, quarantine, or startup fallback;
- compression, encryption, signing, anti-cheat, or a claim that intentional local editing is prevented;
- migrations beyond schema `1`, migration registry, schema fragments, unknown-field preservation, or a reset policy;
- ProfileEpoch, revisions, receipts, leases, conflict resolution, SessionCommitJournal, or cross-PC atomicity;
- RPCs, replication, connection approval, gameplay mutation, Blueprint, Content, maps, plugins, Engine Source, or external dependencies.

## Dependencies and required decisions

- BS-014 through BS-019 are Done on `main` at base commit `d312ad8ed760414e3d29c97c8f5fae7ed1098dc3`.
- BS-016 owns canonical version parsing, project compatibility configuration, and fail-closed signature evaluation. BS-020 consumes that API without changing the configured values of `1`.
- Confirmed persistence rules require a `SchemaVersion`, validation before materialization, no runtime object pointers, and explicit corruption behavior.
- Reversible default: envelope format version `1`, header size `32`, magic bytes `BSAV`, and little-endian unsigned 32-bit fields.
- Reversible default: the checksum covers the first 28 header bytes plus the payload, excluding only the checksum field itself, so header and payload corruption are both detected.
- Reversible default: CRC-32 is accidental-corruption detection, not authentication or anti-cheat.
- Reversible default: one 64 MiB absolute payload ceiling prevents unbounded allocation. It is an envelope safety ceiling, not a target save size or permission for a future store to use the entire limit.
- Reversible default: exact structural and integrity errors precede compatibility errors; invalid output is always cleared.
- No ADR is required now because no production save is written, the format is explicitly versioned, the implementation follows existing accepted architecture, and rollback requires no migration. A storage/generation protocol or breaking envelope change requires an ADR or explicit migration evidence before production data exists.

## Allowed files/domains

- `Source/BrokenStreets/Public/Save/Serialization/**`;
- `Source/BrokenStreets/Private/Save/Serialization/**`;
- `Source/BrokenStreets/Tests/**` for BS-020 Automation and its non-Shipping fault harness;
- `Docs/**` files directly affected by BS-020.

Forbidden: `Config/**`, `Content/**`, `.uproject`, plugins, Engine Source, maps, generated solutions/binaries, backup tooling, unrelated Core behavior, and gameplay domains.

## Authority/network impact

BS-020 is a local pure byte boundary and adds no RPC, replicated state, network transport, session admission, or gameplay authority. A structurally valid envelope is never proof of identity, ownership, permission, authenticity, or server acceptance. Host/client, late join, reconnect, latency/loss, relevancy, audience, and four-player tests are N/A because no network consumer exists.

## Persistence/migration impact

- store: none; the envelope is an in-memory framing primitive only;
- envelope format: version `1` with a fixed 32-byte header;
- payload schema: current project schema `1` from BS-016;
- capture boundary: N/A because no domain state or owner snapshot exists;
- migration: no old schema exists; too-old and too-new envelopes reject explicitly;
- golden data: one exact schema-1 envelope vector is committed in Automation code;
- corruption: every failure clears outputs and returns one stable result;
- I/O, temporary files, flush, read-back, atomic replace, manifest ordering, rotating generations, and fallback are N/A until BS-031 because BS-020 writes no file.

## Performance budget

- event/data-boundary only; no Tick, timer, scheduler, thread, registry, startup scan, asset load, disk, or network I/O;
- O(payload bytes) serialization, checksum, and successful copy;
- structural and compatibility rejection occurs before payload output allocation;
- absolute input payload limit 64 MiB, exact input-size checks use widened arithmetic, and all header fields are fixed-size;
- the fault matrix runs only under `WITH_DEV_AUTOMATION_TESTS`.

## Blueprint/Editor impact

C++ owns the envelope, validation, checksum, result names, and tests. No Blueprint API, asset, Data Table, map, project setting, or manual content setup is added. Unreal Editor must remain closed during structural build and opens only for creator Automation acceptance.

## Acceptance criteria

1. **Given** a valid local compatibility policy and bounded payload, **when** the writer runs, **then** it produces deterministic `header + payload` bytes with the current build/content/save signature and a valid checksum.
2. **Given** the resulting bytes and a compatible local policy, **when** the reader runs, **then** it returns the exact payload and header only after every check succeeds.
3. **Given** empty, truncated, malformed-magic, unsupported-format, wrong-header-size, oversized, length-mismatched, trailing, header-corrupt, or payload-corrupt bytes, **when** the reader runs, **then** it returns one deterministic failure and clears all prior output.
4. **Given** an invalid local policy or a structurally valid envelope with invalid/mismatched build, content, or save schema values, **when** the reader runs, **then** it maps the existing BS-016 compatibility result without exposing payload state.
5. **Given** the golden schema-1 fixture, **when** it is serialized on repeated runs, **then** every byte and the stable result name match the committed vector.
6. **Given** Shipping, **when** the project compiles, **then** the runtime serializer remains available but the BS-020 Automation names and fault harness implementation are absent.
7. **Given** any BS-020 test, **when** it completes, **then** it creates no save file, slot, Content asset, config mutation, or persistent runtime state.

## Automated verification

- `BrokenStreets.Save.Envelope.Header`;
- `BrokenStreets.Save.Envelope.RoundTripGolden`;
- `BrokenStreets.Save.Envelope.Compatibility`;
- `BrokenStreets.Save.Envelope.FaultMatrix`;
- all existing `BrokenStreets` tests and project smoke;
- PowerShell runner self-test;
- `Tools/BS.cmd All` for Generate, Development Editor Build, Automation, Data Validation, and Cook;
- Win64 Shipping build and BS-020 Automation/fault-harness marker audit;
- renderer/config regression, changed/generated-file, English-prose, secrets, Git/LFS, link, reachable-object, and independent-backup audits.

## Manual acceptance

Goal: prove that the exact BS-020 C++ candidate builds and every Save envelope/fault test passes in Unreal Editor.

Applications needed: Visual Studio 2026 and Unreal Editor 5.8.2.

Unreal Editor state: Closed before build; Open only after build succeeds.

Visual Studio state: Open for build; it may be closed before the Editor tests.

Expected duration: 5–10 minutes.

Files/assets created or modified manually: none.

Do not touch: Project Settings, config files, Content, maps, Blueprints, plugins, or code.

1. Open `F:\BrokenStreets\BrokenStreets.sln` in Visual Studio.
   Expected: the `BrokenStreets` solution finishes loading.
2. Set `Solution Configurations` to `Development Editor` and `Solution Platforms` to `Win64`.
   Expected: the top bar shows both exact values.
3. In `Solution Explorer`, expand `Games`, right-click `BrokenStreets`, and click `Build`.
   Expected: `Output` ends with `Build: 1 succeeded, 0 failed` or an up-to-date success with zero errors.
4. Close Visual Studio if desired, then open `F:\BrokenStreets\BrokenStreets.uproject`.
   Expected: Unreal Editor opens directly in UE 5.8 without an engine-selection, module-rebuild, or crash dialog.
5. Click `Tools` > `Session Frontend`, open the `Automation` tab, and enter `BrokenStreets.Save` in the filter.
   Expected: exactly four BS-020 Save tests are listed: `Header`, `RoundTripGolden`, `Compatibility`, and `FaultMatrix`.
6. Select all four filtered tests and click `Start Tests`.
   Expected: all four tests are green, with 4 passed, 0 failed, and 0 skipped.
7. Close Unreal Editor normally without saving.
   Expected: no asset/save prompt or crash dialog appears.

Checkpoint A

PASS if the Visual Studio build has zero failures, all four filtered tests pass with zero failures/skips, and Unreal opens/closes normally without requiring a project change.

FAIL if compilation reports an introduced error/warning, an expected test is missing/fails/skips, Unreal requests a rebuild or project save, or a crash dialog appears. Stop and send the complete Build output or Automation Testing Log plus one screenshot. Do not edit files or settings.

Checkpoint A result: PASS on August 31, 2026. Madalin Gavrila supplied a Visual Studio `Development Editor | Win64` build showing `1 succeeded, 0 failed`, then ran the exact four `BrokenStreets.Save` tests in Unreal Editor Session Frontend. All four completed with result `Success`, with no failure or skip. Unreal Editor and Visual Studio were closed before integration.

## Risks and rollback

- Base/rollback: `d312ad8ed760414e3d29c97c8f5fae7ed1098dc3`.
- A binary layout can become accidental permanent policy; the envelope has its own explicit format version and no production writer/store is introduced in this task.
- CRC can be mistaken for security; naming and documentation define it only as corruption detection.
- Malicious length fields can cause allocation or overflow; widened exact-length arithmetic and the absolute payload cap reject before output allocation.
- Partial state can escape after a late failure; outputs are cleared at entry and assigned only after structure, checksum, and compatibility pass.
- Rollback is a normal revert plus Build/Test/Validate/Cook and Shipping marker audit. No migration or player recovery is required because no file or production payload exists.

## Docs/ADR updates

- create `Docs/Systems/Save.md` just in time;
- register BS-020 and synchronize STATUS, ROADMAP, indexes, Core compatibility references, and test strategy;
- no ADR unless implementation introduces disk/generation policy, a non-versioned/breaking file layout, external storage, encryption/authentication, or production data.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| 2026-08-31 | `51f0be9ebff63ba91c5b82fd20dc047b18cfe6fb` | tree `80dc0fccda0fc58ad9d45a4588dc1bf38ca0c614`; Source `b59f609d48434c5e564256a6368805d3cd7c2264`; unchanged Config `12d196629107bd334cdcc86e568d4525caa837ac`; unchanged Content `41343e24397b32d46f6f51c4fc5269c8005c6fdb` | runner self-test 6/6; `Tools/BS.cmd All` Generate/Build/Test/Validate PASS and Cook controlled skips; Automation 20/20 including Save 4/4; assets 3/3; Cook 514/521 plus seven classified Engine-only omissions, zero project omissions/warnings; Win64 Shipping PASS; 9 Shipping test/fault markers audited with 0 found; renderer/config 52/52; local links 51/51; Git/LFS/reachable-object, scope, generated-file, English-prose, and secret audits PASS; generation `20260831T174520Z-35284-ae02616e` captured 38 refs and all 3 LFS objects; creator Visual Studio build `1 succeeded, 0 failed`; creator Unreal Editor Save Automation 4/4 `Success` | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
| 2026-08-31 | merge `3bc0a3de8e900fcfa7e2de531fae4fee7dec5d40` | tree `fc25d9e944ac27f66cb8dc7d7708c5aeffd43aef`; accepted Source `b59f609d48434c5e564256a6368805d3cd7c2264`; unchanged Config `12d196629107bd334cdcc86e568d4525caa837ac`; unchanged Content `41343e24397b32d46f6f51c4fc5269c8005c6fdb` | post-merge `Tools/BS.cmd All`: Generate/Build PASS, Automation 20/20, Data Validation 3/3, Cook 514/521 plus seven classified Engine-only omissions with zero project omissions/warnings; summary `Saved/Automation/BS-009/20260831T182257Z-15016-c74d873b/run.json` | PASS; integrated on `main`; publication and final recovery audit follow in the evidence commit | Codex |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- exact envelope layout, bounds, result, compatibility, checksum, and output-clearing contracts;
- candidate hash/tree plus automated, Cook, Shipping, regression, and backup evidence;
- creator Development Editor build and four-test Automation steps with PASS/FAIL criteria;
- skipped/N/A checks with reasons;
- rollback commit and next task BS-021.
