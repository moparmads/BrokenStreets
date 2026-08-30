# [System Name]

**Status:** Proposed
**Product owner:** Madalin Gavrila
**Runtime system owner:** [domain]
**Active task:** BS-###
**Last verified commit/gate:** none

## 1. Purpose

What observable player result does the system produce, and why does it exist now?

## 2. Non-goals

What does this version not solve? Link `Docs/NON_GOALS.md` and the future milestone.

## 3. Decisions and open questions

- Confirmed decisions from `Docs/DECISIONS.md`:
- Relevant ADRs:
- Reversible `DEFAULT` values:
- Questions requiring a Decision Packet:

## 4. Behaviors and examples

Describe observable rules and three to five concrete examples, including a failure case.

## 5. Ownership and invariants

| Dimension | Owner / rule |
|---|---|
| Storage owner | |
| Runtime mutation authority | |
| Persistent fragment owner | |
| Replication audience | |

Invariants that may never be violated:

- ...

## 6. States and transitions

List states, the event or command that changes each state, preconditions, and result. No implicit transition may be hidden in UI or Blueprint.

## 7. Data model and identity

- immutable `DefinitionId`:
- `InstanceId`/typed IDs:
- maximum cardinality:
- public/private/server-only fields:
- classification Gameplay Tags:
- soft references/assets:
- rename/deprecation/redirect policy:

Never save `UObject` or Actor pointers, and never use Gameplay Tags as instance identity.

## 8. Commands, events, and API

| Name | Caller | Validator/owner | Input bounds | Result/event | Idempotency/revision |
|---|---|---|---|---|---|
| | | | | | |

Events notify; the owner mutates truth. A network command has a rate limit and explicit result.

## 9. Multiplayer

- server/client responsibilities;
- RPC validation;
- owner-only/public/relevant data;
- snapshot/delta/FastArray policy;
- late join;
- reconnect;
- disconnect during a command;
- one host plus three separated clients;
- latency/loss behavior;
- bandwidth/payload caps.

## 10. Persistence and migration

- store: Portable Profile / Host World / SessionCommitJournal / none;
- fragment `SchemaVersion`;
- capture boundary and game-thread ownership;
- asynchronous I/O snapshot rule;
- migration/golden files;
- corrupt/stale/conflict behavior;
- transaction/recovery receipts.

## 11. Performance and simulation LOD

- update model: event / engine movement / scheduled Hz / justified Tick;
- CPU, memory, bandwidth, and loaded-asset budgets;
- Full/Reduced/Representation/Statistical behavior;
- spawn/despawn/pooling policy;
- benchmark scenario and before/after evidence.

## 12. C++ / Blueprint / Editor surface

- C++ classes/components/services:
- Data Assets/Tables/Curves/Tags:
- Blueprint child/configuration only:
- exact required Editor setup:
- validation rules:

## 13. Failure, exploit, and recovery

Include duplicate request, stale revision, invalid IDs, permission denial, disconnect, host crash, partial transaction, unload/reload, and corrupt data where relevant.

## 14. Debug and observability

- log category and required context IDs;
- debug overlay/commands;
- metrics/trace counters;
- recovery report;
- Shipping exposure restrictions.

## 15. Automated tests

### Unit/automation

- Given / When / Then

### Functional/network

- solo;
- one host plus one client;
- one host plus three clients;
- together/separated;
- late join/reconnect;
- latency/loss.

### Persistence/fault/performance

- ...

## 16. Exact manual acceptance

Write steps in the format from `Docs/Workflows/EDITOR_INSTRUCTION_STANDARD.md`, with PASS/FAIL criteria and required log or screenshot.

## 17. Rollout, rollback, and compatibility

- feature flag/default state;
- base commit;
- rollback commit/revert plan;
- save/content/network compatibility;
- fallback if the gate fails.

## 18. Evidence and history

| Date | Task/commit | Build/test/trace | Result | Approved by |
|---|---|---|---|---|
| | | | | |
