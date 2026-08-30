# Codex Task Workflow

## 1. Intake

1. Open repository root `F:/BrokenStreets`, never the engine root or Source Art.
2. Read `AGENTS.md`, `Docs/INDEX.md`, `Docs/STATUS.md`, and the task packet.
3. Check branch, status, base commit, and existing changes.
4. Select only the relevant documents according to INDEX.
5. Confirm the outcome, scope, and what will not be touched.

## 2. Definition of Ready

Complete `Docs/Tasks/TASK_TEMPLATE.md`.

For a new system, create its system document from the template and define:

- experience and non-goals;
- single writer and ownership;
- command and event contracts;
- server/client/audience/reconnect;
- data model, IDs, and maximum cardinality;
- persistence and migration;
- update model, LOD, and budget;
- tests and manual acceptance;
- remaining decisions.

When a material choice is missing, present a Decision Packet:

```text
Decision:
Why needed now:
Recommended option:
Alternative(s):
Player/technical impact:
What remains reversible:
```

Do not request answers for tuning that can remain data-driven until playtesting.

## 3. Branch and plan

1. Create `feature/BS-###-*`, `fix/BS-###-*`, or `docs/BS-###-*`.
2. Write a short plan with exactly one step `In Progress`.
3. Identify the cheapest validation and the largest risk.
4. Avoid unrelated changes and infrastructure without a consumer.

## 4. Implementation

- Prefer C++ for authority, persistence, replication, and hot paths.
- Keep truth in one owner; use commands, events, and read models.
- Add tests or regressions with behavior.
- Document any Editor step Codex cannot perform safely.
- Never modify Engine Source, plugins, or save schema outside scope.
- Check diff and status periodically, especially in a dirty worktree.

## 5. Candidate and Codex verification

1. Stage only task files.
2. Inspect `git diff HEAD`, the staged list, `git diff --cached --check`, generated files, and `git lfs status`.
3. Create an atomic candidate commit on the branch before final reproducible verification.
4. Tie all evidence to its hash/tree. If a repair changes runtime inputs, create a new candidate and rerun affected checks.

Select proportional checks from `DEFINITION_OF_DONE.md`:

- static, diff, and documentation checks;
- Development Editor build;
- unit, automation, and functional tests;
- network, persistence, fault, and performance tests;
- Data Validation, cook, and package;
- generated-file, LFS, and license audits.

Every skipped test reports its reason and risk.

## 6. Handoff to Madalin

For code or Editor work:

1. state whether Unreal Editor and Visual Studio must be closed;
2. provide exact English UI labels explained in Romanian;
3. state the expected result after every stage;
4. define PASS and FAIL;
5. give the log location and exact screenshot or complete log to return;
6. instruct the creator to stop if the result differs.

The task becomes `Needs Owner Verification` until evidence is received.

## 7. Failure loop

On failure:

- preserve the complete log and tested commit;
- reproduce and identify the cause without asking the user to repair code;
- change only the demonstrated cause;
- add a regression test where feasible;
- repeat the same acceptance until it passes;
- never stack contradictory workarounds.

## 8. Closure

1. Update the system document, ADR, task, and STATUS with the candidate hash and evidence.
2. Inspect `git diff HEAD`, staged index, generated files, warnings, LFS, and secrets.
3. If needed, create a final evidence/docs-only commit; do not change runtime inputs without reverification.
4. Merge and push according to the Git workflow after acceptance, then confirm `main == origin/main`.
5. The final handoff includes result, files, evidence, creator steps, risks, rollback hash, and next task.

Split a large task before implementation. A task is never “almost Done” while its main gate remains untested.
