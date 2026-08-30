# Project status

**Updated:** August 30, 2026
**Current milestone:** Recoverable foundation
**Active branch:** `feature/BS-012-testgym-network`

## Summary

- Last completed task: `BS-011` — project-owned TestGym core map.
- Active task: `BS-012` — prepare and verify `L_TestGym_Network`; the binary network map does not exist yet.
- Next task after BS-012: `BS-013` — `L_Benchmark_Street` placeholder.

## What actually exists

- Unreal Engine 5.8.2 Blank C++ project;
- one runtime module, `BrokenStreets`;
- one deterministic C++ Automation smoke test on `main`;
- one project-owned Unreal map, `/Game/BS/Maps/Test/L_TestGym_Core`, containing only the Unreal Basic Level template actor set;
- local Windows PowerShell 5.1 runner through `Tools/BS.cmd` with engine/toolchain pinning, timeouts, process containment, logs, and JSON summary;
- verified `Development Editor | Win64` build;
- functioning Git, Git LFS, `main` branch, and private remote;
- independent versioned Git/LFS backup tooling and a verified local backup on the separate `E:` physical disk;
- no Broken Streets gameplay code;
- no project-owned `.uasset` files and no project-owned `.umap` other than `L_TestGym_Core`;
- no network TestGym, multiplayer, save, or game systems;
- the default map is still the Engine template `/Engine/Maps/Templates/OpenWorld`.

## Verified baselines

- Runtime baseline: `f1b5648` — `chore: initialize Broken Streets Unreal project`.
- Manual build: `1 succeeded, 0 failed` on August 28, 2026.
- BS-007A clean clone: `main` cloned into a separate temporary directory; Git LFS pull and clean status passed.
- Solution generation passed through Epic Games Launcher's `UnrealVersionSelector.exe`.
- Clean-clone build: `Result: Succeeded`, 7/7 actions, 38.87 seconds, MSVC 14.50 + Windows SDK 10.0.22621.0.
- Headless Editor initialization: engine initialized, template map loaded, and Map Check reported `0 Error(s), 0 Warning(s)`. First-start DDC maintenance continued after Quit and was terminated in a controlled way after the load criterion passed; BS-009 standardized shutdown automation.
- Project-memory candidate: `b3115494e0568342278fa18a2f89f5f9aa386332`, tree `8339f1a6151eb4158b257dfbea5854ada639e3e4`.
- BS-008: 36 files / 4,118 documentation lines, 0 broken local links, `AGENTS.md` 13,688 bytes, Git and Git LFS fsck PASS, no C++/Config/Content changes.
- GitHub: BS-008 branch and `main` were pushed; local `main` and `origin/main` were identical at closure.
- BS-009 candidate `557ede8cc16cb1daedee2a1511a720dde79b6ade`, tree `d556d791e7fabdbbcf90b501f8f87f4d089dfcd3`: runner self-test 5/5 PASS.
- BS-009 `Tools/BS.cmd All`: `PASS_WITH_SKIPS`, code 0; Generate and Build PASS, zero tests declared until BS-010, zero assets declared until BS-011, Cook 578 packages + 7/7 classified Engine omissions, 0 project-owned, 0 warnings. Local evidence: `Saved/Automation/BS-009/20260830T083527Z-29808-a4d97f1e/run.json`.
- BS-010 candidate `888942e37c23810f8dc7fe38700b21254e77d3f6`, tree `9c505c91d0553b56fc2039b1c2604584bd0d7812`: runner self-test 5/5 PASS; `Tools/BS.cmd All` returned `PASS_WITH_SKIPS`, code 0. Generate and Build passed; Test performed 1 and succeeded 1 with 0 failed; Validate declared 0 project assets until BS-011; Cook produced 578 packages plus 7/7 classified Engine omissions with 0 warnings. Local evidence: `Saved/Automation/BS-009/20260830T092315Z-17944-67bfdda6/run.json`. On August 30, 2026, Madalin Gavrila also ran `BrokenStreets.Smoke.ProjectBoot` through Unreal Editor's Session Frontend Automation UI: 1 test, 0 failures, 0 skips, green result, and Automation Testing Log result `Success`.
- Final BS-010 clean-state gate after restoring the exact verified `.uproject`: `Tools/BS.cmd All` returned `PASS_WITH_SKIPS`, code 0; Doctor reported 0 warnings; Generate and Build passed; Test performed 1, succeeded 1, failed 0, and skipped 0; Validate intentionally skipped with 0 project assets until BS-011; Cook produced 578 packages plus 7/7 classified Engine omissions with 0 warnings. Local evidence: `Saved/Automation/BS-009/20260830T094937Z-37516-4eb9c17e/run.json`.
- BS-010A candidate `f15227f2da9507582da1f9bedc358b8485691ea4`, tree `4b84d24edf2abc954c84b350f7c4d74a35bb4af7`: backup self-test restored 3 refs and 1 synthetic LFS payload without GitHub; real clean generation `20260830T103932Z-20076-8eb088fc` captured 10 refs and 0 current LFS payloads with verified checksums; offline restore `BS-010A-f15227f` restored all 10 refs; restored Development Editor Build passed in 27.965 seconds; restored Automation performed 1 and succeeded 1 with 0 failed/skipped; the daily 19:00 scheduled task is enabled, starts after a missed time, and its direct test run returned 0.
- BS-010A creator acceptance: on August 30, 2026, Madalin Gavrila ran the normal manual checkpoint command. Generation `20260830T104652Z-28620-93aa2606` was published from a clean `a9f57e601cb14491f34f66e22ea83fbc4745a666`; manifest and `LATEST.json` agree, origin refresh passed, 11 refs were captured, and 0 current LFS objects were expected.
- BS-010A was integrated into `main` by merge commit `c20d09790fbe521556700219e03f03d6e50899bd`. No gameplay code, Config, Content, `.uproject`, plugin, or Engine Source file changed.
- BS-011 candidate `43cf7d04d32f126eadeb6cdbb21784373142e8b7`, tree `7d0d7fd8f9162479cbc4fda754885ab4dd2f7ade`: the 49,037-byte TestGym map is stored through Git LFS as OID `008fdcaef2fe3d4765ba95ccd8b7be03af445ff7083eeec5ba38f883e5f2730d`; runner self-test passed 6/6; `Tools/BS.cmd All` returned `PASS_WITH_SKIPS`, code 0; Build and Automation passed; Data Validation validated 1/1 project assets with 0 invalid, unable, missing, warnings, or errors; Cook reported 0 project-owned omissions and 0 warnings; Map Check reported 0 errors and 0 warnings. Local evidence: `Saved/Automation/BS-009/20260830T112827Z-37852-5504cb0b/run.json` and `Saved/Verification/BS-011/MapCheck-43cf7d0/Unreal.log`.
- BS-011 Win64 Development package: UAT Build/Cook/Stage/Package/Archive completed with exit 0; the package manifest contains `BrokenStreets/Content/BS/Maps/Test/L_TestGym_Core.umap`; the packaged executable loaded `/Game/BS/Maps/Test/L_TestGym_Core`, brought the world up for play, and exited normally with status 0. Local archive: `Saved/Packages/BS-011/43cf7d0`; boot evidence: `Saved/Verification/BS-011/PackagedBoot-43cf7d0/Packaged.log`. On August 30, 2026, Madalin Gavrila confirmed the expected Basic Level floor, sky, and lighting in a responsive packaged game window, supplied a screenshot, and closed it normally without a crash dialog.
- BS-011 was integrated into `main` by merge commit `e21c78a60db565f26c5ece33ba386de79cfd0279`. Local and GitHub `main` matched exactly; the remote map pointer referenced LFS OID `008fdcaef2fe3d4765ba95ccd8b7be03af445ff7083eeec5ba38f883e5f2730d`; Git LFS fsck passed; and lock `49915812` was released only after the post-merge audit.
- BS-011 recovery checkpoint: clean generation `20260830T115256Z-29716-852e443d` captured 13 refs and 1 LFS object under `E:/BrokenStreets_RepositoryBackup`. Isolated restore `BS-011-e21c78a` verified all 13 refs and the LFS object without GitHub; the restored map was 49,037 bytes with SHA-256 `008fdcaef2fe3d4765ba95ccd8b7be03af445ff7083eeec5ba38f883e5f2730d`.

## Deviations and open items

- `Config/DefaultEngine.ini` currently has `r.RayTracing=True`; the roadmap assumed Ray Tracing Off. Do not change it before an explicit configuration/benchmark task.
- `F:/BrokenStreets_SourceArt` exists, but its 3-2-1 backup and restore drill are not verified.
- The earlier clean-clone `DirectoryWatcher` warning for a missing `Content/` path is obsolete because BS-011 created the first project-owned content path.
- The independent repository copy is local to the same PC but on a separate physical disk; it does not protect against loss of the entire PC/location. BS-013A adds the approved off-site layer with Source Art.
- The scheduled task pins Git/Git LFS from the current Codex runtime path because Task Scheduler does not inherit the interactive PATH. Relocation of that runtime requires a config update and another direct scheduled-task test.
- Full recovery with TestGym, smoke tests, cook, and LFS is BS-007B; it depends on BS-009, BS-010, BS-010A, BS-011, BS-012, BS-013, and BS-013B. Save recovery begins separately after BS-020.

## Update criterion

Update this document only with verified facts: commit, build, test, asset, or existing system. Do not move a task to `Done` merely because documentation or code was written.
