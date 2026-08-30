# Task packets

Every implementable result has a stable `BS-###` ID and one active document. The task describes outcome, scope, and evidence; the roadmap describes order.

## States

```text
Draft → Ready → In Progress → Needs Owner Verification → Done
              ↘ Blocked / Needs Decision
                         ↘ Verification Failed → In Progress
```

- `Draft`: dependencies, decisions, or acceptance are missing.
- `Ready`: Definition of Ready is complete.
- `In Progress`: an active branch and work in progress exist.
- `Needs Owner Verification`: Codex verified everything available; Madalin has exact build/playtest steps.
- `Verification Failed`: a log/screenshot proves failure; the task returns to implementation.
- `Blocked / Needs Decision`: a material choice or external dependency prevents progress.
- `Done`: every universal and relevant conditional requirement has evidence, and status/docs/commit are synchronized.

Written code does not mean `Done`.

## Definition of Ready

Before code:

- observable outcome and why it comes now;
- in scope/out of scope;
- domain owner and dependencies;
- multiplayer authority/audience;
- persistence/migration impact;
- performance/update model;
- Blueprint/Editor surface;
- material decisions accepted or a reversible default declared;
- Given/When/Then criteria;
- automated/manual verification and rollback.

## Rules

- Do not combine independent systems into one large task for convenience.
- A task may contain subtasks, but keeps one coherent outcome.
- An important bug receives a regression test when feasible.
- An implemented ID is never reused for another result.
- Done task files may remain as evidence; Git preserves history.

## Index

| Task | Title | Status | Branch |
|---|---|---|---|
| BS-008 | Project memory and agent workflow | Done | `main` |
| [BS-009](BS-009-Build-Automation.md) | Build/Test/Validate/Cook automation | Done | `main` |
| [BS-010](BS-010-Automation-Smoke-Test.md) | First Automation smoke test and canonical English migration | Done | `main` |
| [BS-010A](BS-010A-Independent-Repository-Backup.md) | Independent repository and Git LFS backup | Done | `main` |
| [BS-011](BS-011-TestGym-Core.md) | Project-owned TestGym core map | Done | `main` |
