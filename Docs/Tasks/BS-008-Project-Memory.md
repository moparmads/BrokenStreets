# BS-008 — Project Memory and Agent Workflow

**Status:** Done
**Owner:** Madalin Gavrila
**Branch:** `main` (integrated from `docs/BS-008-project-memory`)
**Base commit:** `f1b5648`
**Roadmap milestone:** M1B

## Observable outcome

Any Codex task started from `F:/BrokenStreets` finds consistent rules for product, architecture, ownership, C++/Blueprint boundaries, task workflow, testing, performance, Git, recovery, and the next step without Madalin repeating context.

## Why now

The repository and C++ baseline exist. Project memory must be established before original code to prevent contradictory systems and vague manual steps.

## In scope

- root `AGENTS.md` and `README.md`;
- canonical documents, index, and status;
- dependency-corrected roadmap;
- architecture and system ownership;
- task, system, and ADR templates;
- build, Git, recovery, testing, and performance workflows;
- clean-room and reference policy;
- versioning and GitHub synchronization.

## Out of scope

- C++, Config, or Content changes;
- map, TestGym, build scripts, or automation code;
- renderer or plugin activation;
- gameplay-system implementation;
- physical Source Art backup.

## Dependencies

- BS-001 through BS-006 Done;
- official Codex AGENTS.md discovery guidance reviewed;
- existing 200-question register and roadmap audited;
- current project, toolchain, and configuration inspected.

## Allowed files/domains

- `AGENTS.md`, `README.md`, and `Docs/**` only.

## Network/persistence/performance impact

Documentation only; runtime impact N/A. Resulting rules constrain future tasks.

## Acceptance criteria

1. From repository root, the agent identifies owner workflow and conversation language.
2. It identifies sources of truth for product, architecture, system, status, and roadmap.
3. It correctly summarizes the C++/Blueprint boundary and single-writer ownership.
4. It uses exact topology: `1 host + max 3 clients = 4 players total`.
5. It identifies BS-007A as basic recovery and BS-009 as the next tooling task.
6. It declares no gameplay exists.
7. Every required relative link and document exists.
8. `AGENTS.md` remains below the default 32 KiB discovery limit.
9. Git diff contains only documentation with no generated file or secret.
10. The commit is synchronized to the private repository.

## Verification

- Markdown, file, and link audit;
- terminology and conflict search;
- AGENTS byte count;
- Git status and diff;
- existing BS-007A clean-clone, build, and Editor-initialization evidence on baseline `f1b5648`;
- Unreal build N/A because C++, Config, and Content do not change.

## Completion evidence

- Candidate commit: `b3115494e0568342278fa18a2f89f5f9aa386332`.
- Verified tree: `8339f1a6151eb4158b257dfbea5854ada639e3e4`.
- Scope: 36 new files, 4,118 lines, exclusively `AGENTS.md`, `README.md`, and `Docs/**`.
- Link/file audit: zero broken local links; every required file exists.
- `AGENTS.md`: 13,688 bytes, below the default 32 KiB limit.
- Terminology, source-of-truth, decision, and dependency audits: PASS after independent corrections.
- `git diff --cached --check`, `git fsck --no-dangling`, and `git lfs fsck --pointers HEAD`: PASS.
- Secret, generated-file, and runtime-scope audit: PASS; no C++, Config, Content, `.uproject`, or plugin change.
- Runtime build: `N/A` for BS-008; baseline `f1b5648` has clean-clone build and Editor-initialization PASS through BS-007A.
- Remote: task branch and `main` pushed; local and `origin/main` verified identical at closure.
- Manual Unreal/Visual Studio acceptance: `N/A`, documentation only.
- Next task: `BS-009`.

## Risks and rollback

- risk: oversized or duplicated documentation; mitigated through INDEX, just-in-time documents, and canonical ownership;
- risk: proposals treated as decisions; mitigated through explicit statuses and PENDING_DECISIONS;
- rollback: revert the BS-008 commit; base `f1b5648` remains the baseline.
