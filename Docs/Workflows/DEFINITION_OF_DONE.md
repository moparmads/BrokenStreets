# Definition of Done

The DoD is risk-based. Universal requirements always apply; conditional requirements are completed or marked `N/A` with a reason. Irrelevant checked boxes do not improve quality.

## A. Universal requirements

- [ ] The task packet's observable outcome is achieved.
- [ ] `git diff HEAD`, staged index, and LFS status remain in scope and preserve creator changes.
- [ ] Owners, invariants, and dependencies comply with ARCHITECTURE and SYSTEM_OWNERSHIP.
- [ ] The most relevant verification passed.
- [ ] No new unexplained warning or log spam exists.
- [ ] Relevant failure paths and input bounds are covered.
- [ ] Documentation, task packet, and STATUS match reality.
- [ ] Base commit and rollback/revert plan are known.
- [ ] Manual steps are exact and were executed when required.
- [ ] The verified candidate commit/tree is recorded; later runtime changes invalidate and rerun relevant evidence.
- [ ] The commit is atomic and the working tree is clean after commit.
- [ ] The creator confirmed build/playtest for tasks requiring human acceptance.

## B. C++ / reflection / module

Applies to `.h`, UHT/reflection, modules, dependencies, or serialization/replication layout:

- [ ] Unreal Editor was closed before structural build.
- [ ] `BrokenStreetsEditor | Win64 | Development` compiles.
- [ ] New warnings are zero or justified and approved.
- [ ] Live Coding artifacts are not used as evidence.
- [ ] Shipping receives no test/editor dependencies.

## C. Networking

Applies when a feature is replicated or authoritative:

- [ ] solo;
- [ ] one host plus one client;
- [ ] one host plus three clients, four players total;
- [ ] together and separated when relevancy matters;
- [ ] late join;
- [ ] reconnect;
- [ ] disconnect during command;
- [ ] invalid, spam, and stale input rejected;
- [ ] task-defined latency and loss;
- [ ] audience, privacy, payload, and bandwidth verified;
- [ ] packaged multiprocess at the feature gate, not only PIE.

## D. Persistence/economy

- [ ] deterministic save, load, and reload;
- [ ] SchemaVersion, migration, and golden data;
- [ ] truncated, corrupt, temporary, and manifest behavior;
- [ ] same-volume temporary file, flush, read-back, checksum, atomic replace, and manifest ordering;
- [ ] startup selects the newest valid committed generation and reports fallback;
- [ ] relevant crash/fault points before and after each I/O stage;
- [ ] duplicate TransactionId is idempotent;
- [ ] stale revision or ProfileEpoch conflict is never silently resolved;
- [ ] absent-character time does not advance;
- [ ] rollback leaves neither duplicates nor partial balance;
- [ ] build/content/schema handshake.

## E. Performance/hot path

- [ ] benchmark scenario, hardware, preset, build, and driver are pinned;
- [ ] at least three runs where variance exists;
- [ ] relevant p50/p95/p99/max GT/RT/GPU and hitches;
- [ ] relevant working set, VRAM, loaded cells, Actor counts, and bandwidth;
- [ ] retained before/after result and trace;
- [ ] target/headroom passed or fallback/scope cut approved;
- [ ] Low does not remove gameplay.

## F. Content/Blueprint/Editor

- [ ] valid naming, folder, and DefinitionId;
- [ ] Data Validation;
- [ ] LFS lock acquired before editing, staged pointer verified, remote object confirmed, and lock released only after merge;
- [ ] source, license, and manifest;
- [ ] Blueprint does not own authority or persistence;
- [ ] soft references and load policy;
- [ ] relevant collision, material, LOD, Nanite, and HLOD budgets;
- [ ] exact Editor setup and expected visual result.

## G. Gate/milestone

- [ ] clean clone and recovery;
- [ ] command-line build, test, validation, and cook;
- [ ] packaged Development or Shipping-like;
- [ ] one host plus three clients and required hardware/network;
- [ ] required soak, fault, security, and exploit audit;
- [ ] final documentation, ADR, and decision status;
- [ ] rollback build, commit, or tag where the roadmap requires it.

## H. Documentation-only

- [ ] link and file-existence audit;
- [ ] terminology, status, and source-of-truth consistency;
- [ ] no secret, generated file, or unapproved external material;
- [ ] AGENTS stays within the discovery limit;
- [ ] `git diff HEAD` and staged list contain documentation only;
- [ ] runtime build marked `N/A` with reason.

## Minimum task evidence

```text
Candidate commit:
Verified runtime/content tree:
Final evidence/merge commit:
Engine/build target:
Commands/tests:
Manual acceptance:
Result:
Skipped/N/A and reason:
Warnings/risks:
Rollback:
```
