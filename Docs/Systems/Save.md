# Save

**Status:** Implemented
**Product owner:** Madalin Gavrila
**Runtime system owner:** Save
**Active task:** None; BS-020 accepted and ready to integrate
**Last verified commit/gate:** candidate `51f0be9ebff63ba91c5b82fd20dc047b18cfe6fb`; automated and creator gates PASS

## 1. Purpose

Save owns versioned framing, validation, migration coordination, checksums, I/O ordering, generations, and recovery for semantic snapshots supplied by other owners. BS-020 implements only the first deterministic in-memory envelope and corruption harness so future stores share one bounded compatibility and integrity boundary.

## 2. Non-goals

- Save never calculates gameplay, prices, ownership, rewards, progression, authority, or conflict winners.
- BS-020 adds no profile/world/session payload, slot, file path, disk I/O, cloud, manifest, generation, async job, UI, or recovery selection.
- BS-020 does not promise authenticity, anti-cheat, encryption, compression, cross-PC atomicity, or protection from intentional local editing.
- Full profile/world/session persistence remains M4. Crash-safe generations, checksum-backed manifests, migrations, and startup fallback remain BS-031.
- Product-wide exclusions remain in `Docs/NON_GOALS.md`.

## 3. Decisions and open questions

- Confirmed: portable personal progress belongs to the player-owned future `PortableCharacterProfile`; world truth belongs to the host-owned future `HostWorldSave`.
- Confirmed: intentional local editing is accepted; Save prevents accidental corruption and duplication within documented limits rather than claiming a secure backend economy.
- Confirmed: every persistent format has a schema, validation, and migration path; materialization occurs only after validation.
- Relevant ADR: `ADR-0001 — Portable Character Ownership`.
- BS-016 owns the source-controlled build/content/save compatibility policy; Save consumes it.
- Reversible BS-020 defaults: `BSAV`, envelope format `1`, 32-byte little-endian header, 64 MiB absolute payload cap, CRC-32 corruption detection, exact input length, and fixed failure precedence.
- Research informed only original safety requirements and sequencing; external/research implementation details are not project dependencies.
- Open after BS-020: exact store-specific payload caps, fragment registry, field evolution, compression, generation count, conflict UX, and ambiguous cross-PC commit policy at their roadmap gates.

## 4. Behaviors and examples

- A payload `{0x10, 0x20, 0x30}` under compatibility `(1,1,1)` serializes to one exact 35-byte envelope and round-trips byte-for-byte.
- Repeating serialization with identical policy and payload produces identical bytes; no timestamp, random ID, path, or machine value enters the envelope.
- A flipped payload byte fails checksum validation and exposes neither parsed header nor partial payload.
- A structurally and checksum-valid envelope with build/content mismatch or schema outside the readable interval fails through the existing BS-016 policy.
- A trailing byte, truncated file, impossible size, or payload above the cap fails before output allocation.

## 5. Ownership and invariants

| Dimension | Owner / rule |
|---|---|
| Storage owner | BS-020 operation-local byte arrays; future stores own committed files and manifests. |
| Runtime mutation authority | Save validates/framing only. The future server/local store boundary selects which approved semantic snapshot may be persisted; domain owners still own gameplay truth. |
| Persistent fragment owner | No domain fragment exists in BS-020. Save owns the envelope metadata; future domains own semantic payload fragments. |
| Replication audience | None. Save bytes are local/server-only and never replicated as gameplay state. |

Invariants that may never be violated:

- no output payload or header becomes visible before every structural, checksum, and compatibility check passes;
- all outputs are cleared on every failure;
- envelope bytes contain no pointer, `UObject`, Actor, runtime name, path, timestamp, random padding, or uninitialized memory;
- input length and payload size are exact and bounded before allocation/copy;
- checksum covers every serialized header field except the checksum field itself, plus every payload byte;
- checksum proves only accidental integrity, never identity, ownership, permission, or authenticity;
- build/content/schema values come from or are evaluated by BS-016, not a second policy;
- a successful envelope parse does not materialize gameplay state or approve a profile/session;
- format and schema versions are distinct and change only with tests and migration/rollback evidence.

## 6. States and transitions

The BS-020 writer is pure: `Cleared → ValidatedPolicyAndBounds → HeaderSerialized → ChecksumCommitted → Complete`, with any failure returning to `Cleared`.

The reader is pure: `Cleared → StructuralHeaderValidated → ExactLengthValidated → ChecksumValidated → CompatibilityValidated → Complete`. Any failure returns one closed result and leaves outputs `Cleared`. No partial or hidden state transition exists.

## 7. Data model and identity

Header layout, all fields unsigned 32-bit little-endian:

| Offset | Field | Rule |
|---:|---|---|
| 0 | magic | four bytes `BSAV` |
| 4 | envelope format version | exactly `1` in BS-020 |
| 8 | header size | exactly `32` |
| 12 | build compatibility | non-zero BS-016 value |
| 16 | content compatibility | non-zero BS-016 value |
| 20 | save schema | non-zero BS-016 value |
| 24 | payload size | `0..64 MiB` and exact remaining file length |
| 28 | envelope checksum | CRC-32 of bytes `0..27`, then the exact payload |

- no `DefinitionId`, `InstanceId`, Gameplay Tag, or store identity exists before a real semantic payload/store owner;
- maximum cardinality: exactly one header and one opaque payload per envelope;
- no public/player/network field exists;
- no asset/soft reference exists;
- a future format change increments the envelope format and supplies explicit read/migration/rollback evidence; it never silently reinterprets format `1`.

## 8. Commands, events, and API

| Name | Caller | Validator/owner | Input bounds | Result/event | Idempotency/revision |
|---|---|---|---|---|---|
| `FBSSaveEnvelopeHeader::TryCreate` | Save/tests | Save | valid signature, payload size `<=64 MiB`, checksum value | valid immutable header or cleared output | pure/deterministic |
| `FBSSaveEnvelope::TrySerialize` | future store/tests | Save | valid local policy plus bounded opaque payload | exact envelope bytes or cleared output | same inputs produce same bytes |
| `FBSSaveEnvelope::TryDeserialize` | future store/tests | Save | bounded complete bytes plus local policy | validated header/payload or cleared output | pure/deterministic |
| `FBSSaveEnvelope::GetStableName` | diagnostics/tests | Save | closed result enum | fixed bounded machine name or `unknown` | deterministic |

No event, command dispatcher, file write, gameplay mutation, retry, or transaction is introduced.

## 9. Multiplayer

BS-020 adds no RPC, replication, session admission, identity, profile transfer, or network audience. A local envelope presented by a future client remains untrusted and must pass server/domain validation after Save validation. Late join, reconnect, disconnect, four-player topology, latency/loss, and bandwidth tests are N/A until a Network/Identity consumer exists.

## 10. Persistence and migration

- store: none in BS-020;
- envelope format: `1`; payload schema: project current `1`;
- capture boundary and game-thread snapshot: N/A until a domain owner supplies semantic state;
- asynchronous I/O: N/A; all work is in-memory and synchronous at an explicit test/data boundary;
- golden data: exact fixed envelope bytes in Automation;
- migration: no older schema exists; unsupported format/schema reject explicitly;
- corruption: structural, length, checksum, and compatibility faults fail closed with cleared outputs;
- temporary files, flush, read-back, atomic replace, manifest commit, generations, fallback, receipts, revisions, ProfileEpoch, and conflict policy are not claimed by BS-020.

## 11. Performance and simulation LOD

- event/data-boundary only; no Tick or scheduler;
- O(payload bytes) copy and checksum with an absolute 64 MiB cap;
- fixed 32-byte header and constant-time structural/compatibility checks;
- rejection before output payload allocation;
- no asset, Actor, thread, registry, RPC, disk, network, or retained global-state cost;
- simulation LOD is N/A.

## 12. C++ / Blueprint / Editor surface

- C++: `FBSSaveEnvelopeHeader`, `EBSSaveEnvelopeResult`, and `FBSSaveEnvelope`;
- Automation-only: local deterministic fault mutation helpers under `WITH_DEV_AUTOMATION_TESTS`;
- Data Assets/Tables/Curves/Tags: none;
- Blueprint: none;
- Editor setup: none; creator opens Session Frontend only to run tests;
- validation: fixed layout, canonical endian encoding, exact length, cap, checksum, BS-016 compatibility, output clearing, stable result names, and golden bytes.

## 13. Failure, exploit, and recovery

- empty/truncated input returns `header_truncated`;
- wrong magic, format, or header size returns its exact structural result before checksum;
- declared payload above the cap returns `payload_too_large`; exact-size mismatch or trailing bytes returns `file_size_mismatch`;
- any covered-byte corruption returns `checksum_mismatch`;
- invalid local policy or header signature and every build/content/schema incompatibility map to explicit results;
- no input length controls unchecked allocation or arithmetic;
- duplicate requests, stale revision, permissions, disconnect, host crash, partial disk transaction, and generation recovery are N/A because there is no command, owner state, network, or I/O;
- future disk recovery preserves last-known-good state; BS-020 cannot claim it yet.

## 14. Debug and observability

- no new log category or routine success log is needed for a pure result-returning boundary;
- stable bounded result names are safe machine identifiers, not player-facing text;
- raw payload bytes and external input are never logged;
- no debug command, overlay, telemetry, or recovery report exists;
- fault harness and Automation code are excluded from Shipping.

## 15. Automated tests

### Unit/automation

- header constants, bounds, signature retention, invalid clearing, and stable names;
- deterministic writer plus exact golden bytes and round-trip;
- invalid policy/signature and build/content/too-old/too-new compatibility mapping;
- every prefix truncation and explicit magic/format/header-size/payload-size/trailing/checksum/payload corruption;
- stale output clearing on every failure.

### Functional/network

N/A: no World, UObject, actor, asset, RPC, replication, or semantic state exists.

### Persistence/fault/performance

In-memory deterministic golden/fault coverage is required. Disk crash points, manifest/generation fallback, migration across schema versions, transaction idempotency, ProfileEpoch conflicts, and soak are N/A until their owning tasks introduce real state and I/O.

## 16. Exact manual acceptance

Follow `Docs/Tasks/BS-020-Minimum-Save-Envelope-And-Fault-Harness.md`: close Unreal Editor, build `BrokenStreets | Development Editor | Win64` in Visual Studio, open the project, filter Session Frontend Automation by `BrokenStreets.Save`, and run exactly four tests. PASS requires 4 passed, 0 failed, 0 skipped, no project-save prompt, and no engine-selection, module-rebuild, or crash dialog.

## 17. Rollout, rollback, and compatibility

- no feature flag: there is no production caller or automatic execution path;
- base: `d312ad8ed760414e3d29c97c8f5fae7ed1098dc3`;
- BS-016 config remains build `1`, content `1`, current save `1`, minimum readable save `1`;
- runtime envelope code remains in Shipping; Automation and fault helpers do not;
- rollback is a normal revert plus Build/Test/Validate/Cook and Shipping audit;
- no production file or payload requires migration on rollback.

## 18. Evidence and history

| Date | Task/commit | Build/test/trace | Result | Approved by |
|---|---|---|---|---|
| 2026-08-31 | BS-020 / `51f0be9ebff63ba91c5b82fd20dc047b18cfe6fb` | `Tools/BS.cmd All`: Generate/Build PASS, Automation 20/20 including Save 4/4, Data Validation 3/3, Cook 514/521 plus seven classified Engine-only omissions and zero project omissions/warnings; Win64 Shipping PASS with 0/9 BS-020 test markers; renderer/config 52/52; runner self-test 6/6; Git/LFS/reachable-object, scope, links, English-prose, secrets, and independent-backup audits PASS; creator Visual Studio build and Save Automation 4/4 PASS | Automated and creator acceptance PASS; integration pending | Madalin Gavrila and Codex |
