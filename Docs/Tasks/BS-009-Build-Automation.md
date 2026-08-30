# BS-009 — Build, Test, Validate, and Cook Automation

**Status:** Done
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-009-build-automation`
**Base commit:** `0de0648e070f58c7d095fc5dba2468a5c7eb7b8c`
**Roadmap milestone:** M1 — Recoverable baseline
**System docs:** [Toolchain](../Build/TOOLCHAIN.md), [Test strategy](../Testing/TEST_STRATEGY.md), [Task workflow](../Workflows/CODEX_TASK_WORKFLOW.md)

## Observable outcome

From any terminal in the repository, the creator can start `Doctor`, `Generate`, `Build`, `Test`, `Validate`, `Cook`, or `All` through one command. Every run displays a concise result, returns the correct exit code, and preserves local logs and a JSON summary.

## Why now

BS-009 turns the manual BS-007A build into a repeatable gate. It unlocks the first smoke test, TestGym, complete recovery, and every later C++ change.

## In scope

- dependency-free Windows PowerShell 5.1 runner;
- deterministic discovery and exact validation of UE 5.8.2 CL 56702186;
- `Doctor`, `Generate`, `Build`, `Test`, `Validate`, `Cook`, and `All`;
- timeout and strict termination of the launched process tree;
- native exit-code propagation and distinct semantic-failure and timeout codes;
- local logs and JSON summary under `Saved/Automation/BS-009/`;
- explicit `SKIPPED_NO_TESTS` until BS-010 and `SKIPPED_NO_ASSETS` until project-owned assets exist;
- usage documentation and evidence.

## Out of scope

- first Automation smoke test, BS-010;
- first project-owned map and assets, BS-011;
- staging, packaging, archive, or distribution;
- cloud CI, dedicated servers, or non-Windows platforms;
- EngineAssociation, installed engine, gameplay, Config, or Content changes.

## Dependencies and required decisions

- BS-008 is Done;
- baseline is UE 5.8.2 CL 56702186 and Visual Studio 2026;
- BS-009 Cook is a local `Windows` commandlet run without stage or package;
- zero tests and zero-asset validation are visible temporary states, not false PASS results;
- an invalid explicit `EngineRoot` fails instead of silently selecting another engine.

## Allowed files/domains

- `Tools/`;
- `Docs/Build/TOOLCHAIN.md`;
- `Docs/Tasks/`;
- `Docs/STATUS.md`.

Changes to `Source/`, `Config/`, `Content/`, `.uproject`, plugins, and Engine are forbidden.

## Authority/network impact

N/A — local tooling with no networking or authority/replication change.

## Persistence/migration impact

N/A — no save data. Outputs are reproducible and ignored by Git under `Saved/`.

## Performance budget

- runner polls no more often than 250 ms and does not remain resident;
- one runner may operate on the repository at a time;
- default timeouts: Generate 10 minutes, Build 60, Test 30, Validate 30, Cook 120;
- Cook uses neither `CookAll`, iterative cook, stage, nor package.

## Blueprint/Editor impact

No Blueprint or asset. Unreal Editor must be closed for real actions; commands are headless.

## Acceptance criteria

1. `Doctor` verifies project, UE 5.8.2 CL 56702186, toolchain, and workspace without a script-hard-coded engine path.
2. `Generate` exits 0, reports `Result: Succeeded`, and produces `.sln` and `.slnx`.
3. `Build` compiles `BrokenStreetsEditor Win64 Development` and the project DLL exists.
4. Before BS-010, `Test` verifies Unreal markers and reports `SKIPPED_NO_TESTS`, never false PASS.
5. Without project-owned assets, `Validate` combines local inventory and UE 5.8 `AssetCheck` output to report `SKIPPED_NO_ASSETS`; invalid, unvalidated, or missing results fail even when the process returns 0.
6. `Cook` for `Windows` ends with `0 error(s)`, retains output under `Saved/Cooked/Windows`, and preserves benign Engine `Packages Skipped by Platform` as `PASS_WITH_SKIPS`.
7. Timeout or native failure terminates the launched process tree, preserves nonzero code, and identifies the exact log.
8. `All` runs Doctor → Generate → Build → Test → Validate → Cook, fail-fast, with one JSON summary.

## Automated verification

- Windows PowerShell 5.1 syntax and plan;
- `Doctor` and `All` through `Tools/BS.cmd`;
- real UE log-marker and exit-code verification;
- Git, Git LFS, and local documentation link checks;
- forbidden-domain diff audit.

## Manual acceptance

No playtest or manual setup is required for Done. The creator receives one rerun command and returns the displayed log path on failure.

## Risks and rollback

- **Base:** `0de0648e070f58c7d095fc5dba2468a5c7eb7b8c`.
- The first cook may be long because the baseline uses the Engine OpenWorld map, DX12/SM6, Ray Tracing, and Substrate.
- The runner never deletes output, changes engine association, or kills processes by name.
- Rollback: revert BS-009 commits; `Saved/` output remains ignored and reproducible.

## Docs/ADR updates

- `Docs/Build/TOOLCHAIN.md` — canonical command and result interpretation;
- `Docs/STATUS.md` — progress and verified evidence;
- `Docs/Tasks/README.md` — index.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| August 30, 2026 | `557ede8cc16cb1daedee2a1511a720dde79b6ade` | `d556d791e7fabdbbcf90b501f8f87f4d089dfcd3` | `Tools/Tests/Runner.SelfTest.ps1` | PASS — 5/5: arguments, native code 37, timeout 124, orphaned grandchild, atomic JSON | Codex |
| August 30, 2026 | `557ede8cc16cb1daedee2a1511a720dde79b6ade` | same tree; no C++/Config/Content | `Tools/BS.cmd All` — UE 5.8.2 CL 56702186, `BrokenStreetsEditor Win64 Development` | `PASS_WITH_SKIPS`, code 0; Generate/Build PASS, zero tests until BS-010, zero assets until BS-011, Cook 578 packages plus 7/7 classified Engine omissions, zero warnings | Codex |

Canonical local evidence: `Saved/Automation/BS-009/20260830T083527Z-29808-a4d97f1e/run.json`. Output remains local, reproducible, and Git-ignored. Additional probes: Doctor PASS in `20260830T082922Z-31884-43180674`; `All -PlanOnly` PLANNED in `20260830T082938Z-12004-a95a98b1`.

Manual acceptance, networking, persistence, and playtest: N/A — local tooling only, with no gameplay, C++, Config, Content, or asset change. Editor was closed for real checks.

## Final handoff

- Verified candidate: `557ede8cc16cb1daedee2a1511a720dde79b6ade`.
- Final evidence commit: `c45d1fa871aae435440d37d2414094580e33fe94`; task, status, and index only, with no runtime or build-script change.
- Creator command: close Unreal Editor and run `F:\BrokenStreets\Tools\BS.cmd All`.
- Expected before BS-010/BS-011: `PASS_WITH_SKIPS` with the explained skips. Stop and report any nonzero code or `FAILED` with the `Summary:` line.
- Safe rollback: revert BS-009 commits to base `0de0648e070f58c7d095fc5dba2468a5c7eb7b8c`; generated `Saved/`, `Binaries/`, and solution files remain reproducible.
- Next logical task: BS-010 — first Broken Streets Automation smoke test.
