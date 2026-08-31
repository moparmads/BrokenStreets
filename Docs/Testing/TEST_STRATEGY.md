# Test Strategy

Testing proves correctness in the same topology and build in which the product will run. PIE provides fast feedback; it is not final acceptance for Steam, cooking, save recovery, or four separate simulation bubbles.

## 1. Levels

### Pure/unit-style automation

For logic that does not require a World:

- integer money math;
- typed IDs and validation;
- state transitions;
- weight, capacity, and permissions;
- transaction idempotency;
- serialization helpers and migrations;
- deterministic selection and seeds.
- bounded structured-log formatting and fail-closed feature-flag parsing.
- build/content/save compatibility parsing, range invariants, decision precedence, and stable rejection reasons.

### Engine automation

- UObject/data behavior;
- Asset Manager and definitions;
- settings, tags, and redirects;
- schema and registry;
- command validation;
- content and data validators.

### Functional map tests

- interaction;
- player and vehicle;
- job, police, and AI;
- property and interior;
- integration between owners;
- project-owned TestGym fixtures.

### Network tests

- listen server plus multiprocess clients;
- authority, RPC, and relevancy;
- late join and reconnect;
- together and separated bubbles;
- latency, loss, and disconnect;
- owner-only/public privacy.

### Persistence/fault tests

- save, load, and migration;
- crash at I/O stages;
- corrupt, stale, and conflicting state;
- duplicate commands;
- rollback and recovery.

### Performance/soak

- Unreal Insights and counters;
- representative packaged workload;
- memory, streaming, and network growth;
- traversal and long sessions.

## 2. Universal code-task gate

- `BrokenStreetsEditor | Win64 | Development` build;
- targeted tests;
- Data Validation when data or assets exist;
- zero new warning or log spam;
- every skipped test declares a reason and risk;
- important bugs receive regression tests where feasible;
- test/debug code is excluded from Shipping.

## 3. Multiplayer matrix

For an authoritative or replicated feature:

| Scenario | Purpose |
|---|---|
| solo | same rule without a remote client |
| one host plus one client | basic boundary and state |
| one host plus three clients | total four-player limit |
| everyone together | contention and public relevancy |
| everyone separated | four-bubble CPU, memory, streaming, and relevancy |
| late join | complete snapshot/read model |
| reconnect | reservation, recovery, and idempotency |
| disconnect during a command | correct cancel, commit, or report |
| 100–200 ms latency | prediction, UX, and command correctness |
| moderate packet loss | retry and state reconstruction |
| invalid or spamming client | server validation and rate limiting |

Local PIE/multiprocess is a smoke test. A feature gate uses packaged Development and multiprocess automation, with Gauntlet after it is introduced. The Steam gate uses at least two PCs, two accounts, and two real networks. Before content lock, use four real PCs: the host reference machine plus three remote clients.

## 4. Persistence and transactions

Required where relevant:

- sending the same `TransactionId` 100 times produces one result;
- an old expected revision is explicitly rejected or reconciled;
- a disconnect between steps reaches commit, rollback, or report—never silent partial state;
- crash before and after capture, serialize, temporary write, flush, read-back/checksum, replace, and manifest commit;
- temporary, truncated, corrupt, or invalid-checksum files;
- temporary file on the same volume, no premature manifest update, and newest-to-oldest fallback to a valid committed generation;
- golden migrations preserve StableIds;
- ProfileEpoch conflicts and stale receipts;
- CharacterActiveTime does not jump after offline time, another host, world clock, or timezone;
- `LastAppliedActiveTime` does not apply an effect twice;
- an item cannot exist in two containers;
- VehicleRecord/PropertyRecord does not clone during materialization;
- two PropertyInstanceIds using one template never share storage or decor;
- world-cell unload/reload does not lose authoritative Actor/state;
- compatibility handshake rejects an incompatible build, content, or schema with a recovery message.

## 5. Performance

Acceptance uses:

- packaged Development or Shipping-like build;
- pinned commit, build, engine, driver, hardware, preset, and resolution;
- at least three comparable runs;
- declared warm-up;
- p50/p95/p99/max for GT, RT, and GPU where available;
- hitches and longest frames;
- working set, VRAM, loaded cells, and Actor/component/AI/physics counts;
- network bandwidth, RPC/replication counts, and snapshot sizes;
- retained traces and counters under standard names.

The provisional normal 60 FPS target seeks p95 ≤ 13.33 ms for the limiting pipeline, providing approximately 20% reserve. Final budgets freeze only after Benchmark Street on reference hardware. Frame Generation never manufactures a PASS.

## 6. Determinism and fixtures

- TestGym uses controlled seeds and dates.
- Every test cleans created state or uses an isolated world/save.
- Time, weather, participant count, and latency profile are explicit.
- Test DefinitionIds and InstanceIds are stable and cannot be confused with production content.
- A test never depends on another test's execution order.
- A flaky test is not ignored; repair it or remove it from the gate with a documented justification.

## 7. Security and abuse scope

Private co-op accepts intentional local save editing, but the listen server's server side must reject the following even from the host's local client:

- RPC without permission or identity;
- invalid distance, state, or target;
- payload or cardinality beyond the limit;
- spam without rate limiting;
- client-provided money, item, job, or damage result;
- stale or replayed command that would duplicate a result;
- access to another player's private data.

## 8. Evidence

The task packet records:

```text
Commit/build:
Test name/command:
Topology:
Map/seed:
Latency/loss:
Hardware/preset:
Expected:
Actual:
PASS/FAIL:
Log/trace/report path:
Warnings/skips:
```

Large generated reports remain under `Saved/` or approved storage. Git receives only small, useful baseline summaries without sensitive data.

Evidence is tied to the candidate commit or tree. If any runtime input changes after testing—C++, Config, Content, `.uproject`, plugin, or build script—the evidence becomes `INVALIDATED` and relevant checks repeat. A later task/status/evidence-only commit may reference the verified candidate while explicitly listing unchanged runtime files.
