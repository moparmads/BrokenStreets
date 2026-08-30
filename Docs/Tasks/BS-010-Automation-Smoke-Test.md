# BS-010 — First Automation Smoke Test and Canonical English Migration

**Status:** Done
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-010-automation-smoke`
**Base commit:** `a924d598b69bcc339b36deeba77d16c201f656dc`
**Roadmap milestone:** M1 — Recoverable baseline and project memory
**System docs:** [Test strategy](../Testing/TEST_STRATEGY.md), [Toolchain](../Build/TOOLCHAIN.md), [Task workflow](../Workflows/CODEX_TASK_WORKFLOW.md)

## Observable outcome

The `BrokenStreets.Smoke.ProjectBoot` Automation test is discovered and passes both from the Unreal Editor Automation UI and through `Tools/BS.cmd Test`. The repository's canonical human-readable content is English: documentation, task packets, source/tool comments, runner messages, and user-facing project text.

## Why now

BS-009 made build and test execution repeatable but correctly reported zero project tests. BS-010 proves the test harness before gameplay work begins. The creator also established English as the canonical game and repository language, so the migration belongs before more code, tasks, and content multiply the translation cost.

## In scope

- one deterministic, editor-context C++ Automation smoke test in the existing `BrokenStreets` module;
- verification that the project identity is `BrokenStreets` and its primary module is loaded;
- make zero matching project tests a failure after the smoke test exists;
- translate all tracked project-authored human-readable repository content to English without changing existing product or architecture decisions;
- add a permanent canonical-language rule to `AGENTS.md`;
- build, command-line Automation, Data Validation, and Cook verification.

## Out of scope

- gameplay logic, networking, persistence, UI, maps, or content assets;
- a new test module or plugin;
- TestGym maps and functional tests (BS-011/BS-012);
- rewriting historical Git commits or changing existing hashes;
- translating third-party names, engine output, identifiers, paths, or quoted API markers.

## Dependencies and required decisions

- BS-009 is Done and `Tools/BS.cmd Test` is operational;
- Unreal Engine is pinned to 5.8.2 CL 56702186;
- English is the canonical language for the game and repository;
- creator conversation remains Romanian unless requested otherwise;
- the existing runtime module is sufficient; no new module boundary is justified.

## Allowed files/domains

- `Source/BrokenStreets/Tests/`;
- `Tools/Build/RunnerConfig.json` and English-only messages/comments under `Tools/`;
- all tracked project-authored Markdown documentation and task packets;
- `AGENTS.md`, `README.md`, and status/index files.

Forbidden: `Content/`, `Config/`, `.uproject`, Engine Source, plugins, generated files, and unrelated runtime behavior.

## Authority/network impact

N/A — the smoke test has no world, player, RPC, replicated state, or network side effect.

## Persistence/migration impact

N/A — no save schema or persistent data is created or modified.

## Performance budget

- the test performs constant-time string/module checks and must finish in under one second after discovery;
- no Actor, World, Tick, asset load, heap-scale fixture, or asynchronous work;
- test code is guarded by `WITH_DEV_AUTOMATION_TESTS` and is not an unintended Shipping runtime feature.

## Blueprint/Editor impact

No Blueprint, map, or asset changes. Unreal Editor must be closed for the structural C++ build. Manual acceptance later opens Editor only to run the test through the Automation UI.

## Acceptance criteria

1. **Given** the Development Editor build **When** Automation discovers `StartsWith:BrokenStreets` **Then** exactly one project test is available and `BrokenStreets.Smoke.ProjectBoot` passes.
2. **Given** the smoke test runs **When** it inspects the process **Then** the project name is `BrokenStreets` and the `BrokenStreets` primary module is loaded.
3. **Given** `Tools/BS.cmd Test` **When** the test completes **Then** the runner reports one performed, one succeeded, zero failed, and no zero-test skip.
4. **Given** the Unreal Editor Automation UI **When** the same test is selected and run **Then** it appears green with no errors or warnings.
5. **Given** any tracked project-authored human-readable file **When** the language audit runs **Then** Romanian prose is absent and English is declared canonical.
6. **Given** the complete gate **When** `Tools/BS.cmd All` runs **Then** Build and Test pass; only already-explained content/Engine skips may remain.

## Automated verification

- Windows PowerShell 5.1 parser and runner self-test;
- `Tools/BS.cmd Build`;
- `Tools/BS.cmd Test`;
- `Tools/BS.cmd All`;
- repository language audit, documentation link audit, diff/scope/secrets/LFS checks.

## Manual acceptance

Completed on August 30, 2026 through Unreal Editor's Session Frontend → Automation tab. `BrokenStreets.Smoke.ProjectBoot` completed in 0.006 seconds with a green result: 1 test, 0 failures, 0 skips, and the Automation Testing Log reported `Success`.

## Risks and rollback

- **Base:** `a924d598b69bcc339b36deeba77d16c201f656dc`.
- A broad translation can accidentally alter a decision; semantic spot checks and link/terminology audits are required.
- Automation output markers may differ across UE versions; the engine remains pinned and the real 5.8.2 log is authoritative.
- Rollback is a revert of the BS-010 commits; there is no content/save migration.

## Docs/ADR updates

- all canonical documentation translated without changing decisions;
- `AGENTS.md` gains the canonical English policy;
- `Docs/STATUS.md`, `Docs/ROADMAP.md`, and task index track BS-010;
- no ADR is required because this is a language/workflow rule, not a runtime architecture change.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| August 30, 2026 | `888942e37c23810f8dc7fe38700b21254e77d3f6` | tree `9c505c91d0553b56fc2039b1c2604584bd0d7812`; C++ test only; no Content/Config | runner self-test; `Tools/BS.cmd All`; local summary `Saved/Automation/BS-009/20260830T092315Z-17944-67bfdda6/run.json` | `PASS_WITH_SKIPS`, code 0 — self-test 5/5; Generate/Build PASS; Test 1 performed, 1 succeeded, 0 failed; Validate skipped with 0 project assets until BS-011; Cook 578 packages plus 7/7 classified Engine omissions, 0 warnings | Codex |
| August 30, 2026 | `e51a12a0b44a5ef38b81409faa232a0ac9100199` (documentation-only evidence commit over the unchanged candidate tree) | unchanged candidate runtime/content tree | Unreal Editor Session Frontend → Automation UI | `PASS` — 1 test, 0 failures, 0 skips; `BrokenStreets.Smoke.ProjectBoot` green; Automation Testing Log result `Success` | Madalin Gavrila |
| August 30, 2026 | `d24f336` (documentation-only acceptance commit over the unchanged candidate runtime/content files) | `.uproject` restored byte-for-byte to the verified candidate; no working-tree changes | final `Tools/BS.cmd All`; local summary `Saved/Automation/BS-009/20260830T094937Z-37516-4eb9c17e/run.json` | `PASS_WITH_SKIPS`, code 0 — Doctor 0 warnings; Generate/Build PASS; Test 1 performed, 1 succeeded, 0 failed, 0 skipped; Validate intentionally skipped with 0 project assets until BS-011; Cook 578 packages plus 7/7 classified Engine omissions, 0 warnings | Codex |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts invalidates the candidate evidence until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged candidate tree.

## Final handoff

Automated candidate verification and creator Automation UI acceptance are complete. BS-010 is ready for integration into `main`; no gameplay, Config, Content, Blueprint, map, plugin, or save data changed.
