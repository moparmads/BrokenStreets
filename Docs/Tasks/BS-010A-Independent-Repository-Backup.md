# BS-010A — Independent Repository and Git LFS Backup

**Status:** Done
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-010A-independent-backup`
**Base commit:** `cfd2edffc70bb9a22fd39041f9fe91a2b038da69`
**Roadmap milestone:** M1 — Recoverable baseline and project memory
**System docs:** [Recovery and rollback](../Workflows/RECOVERY_AND_ROLLBACK.md), [Git workflow](../Workflows/GIT_WORKFLOW.md), [Toolchain](../Build/TOOLCHAIN.md)

## Observable outcome

`E:/BrokenStreets_RepositoryBackup` contains a versioned, checksummed repository backup that preserves every captured Git ref and every Git LFS object referenced by those refs. A new working copy can be restored and verified without contacting GitHub, then built and tested with the pinned Unreal Engine.

## Why now

GitHub is currently the only remote repository copy. Important Unreal assets begin in BS-011, and a Git bundle does not contain Git LFS payloads. BS-010A establishes independent recovery before binary content exists.

## In scope

- safe PowerShell 5.1-compatible backup and restore tooling;
- full Git bundle for all captured local refs and tags;
- shared content-addressed backup of all required Git LFS objects, with no automatic LFS deletion;
- per-generation manifest, SHA-256 checksums, ref inventory, LFS inventory, and last-successful pointer;
- backup root `E:/BrokenStreets_RepositoryBackup` on physical disk 0, separate from the project on physical disk 1;
- 30 successful Git generations retained, with a warning below 100 GB free;
- manual checkpoint before risky work and a daily 19:00 Windows scheduled task;
- offline restoration into a new folder, Git/LFS integrity verification, Development Editor build, and Automation smoke test;
- operator, frequency, capacity, retention, failure, and credential-renewal procedures.

## Out of scope

- Source Art backup, which is BS-013A;
- off-site storage, approved for the later Source Art 3-2-1 task;
- additional encryption; the creator accepted the current Windows/storage protection for this local independent copy;
- GitHub replacement, provider migration, or removal of the existing `origin` remote;
- manufacturing a temporary Unreal asset only to exercise a non-empty LFS transfer; BS-007B performs the first real asset lock/pointer/push drill;
- gameplay, Config, Content, `.uproject`, plugins, Engine Source, or save data.

## Dependencies and required decisions

- BS-010 is Done on `main`;
- creator approved `E:/BrokenStreets_RepositoryBackup` on the separate Kingston NVMe;
- creator approved daily 19:00 plus manual checkpoints, 30 Git generations, permanent LFS object retention, 100 GB capacity warning, and no additional encryption;
- off-site backup remains deferred to BS-013A;
- there are currently zero Git LFS objects and zero project-owned Unreal assets, so the empty-LFS path is verified here and the first non-empty asset exercise remains BS-007B.

## Allowed files/domains

- `Tools/Backup/` and a thin command wrapper under `Tools/`;
- `Tools/README.md`;
- `Docs/Tasks/`, `Docs/STATUS.md`, `Docs/PENDING_DECISIONS.md`, and recovery/build workflow documentation;
- external backup and restore-test data only under `E:/BrokenStreets_RepositoryBackup`;
- the named Windows scheduled task for this repository backup.

Forbidden: gameplay code, `Content/`, `Config/`, `.uproject`, Engine Source, plugins, generated project files in Git, Source Art, and unrelated Windows settings.

## Authority/network impact

N/A — this is developer tooling. It creates no gameplay state, RPC, replication, session, late-join, or reconnect behavior. Optional origin refresh may use GitHub, but backup creation and restoration must work from local data when GitHub is unavailable.

## Persistence/migration impact

The backup format is operational data, not a game save. Its manifest has a schema version. Generations are immutable after publication; staging must validate before the last-successful pointer changes. Restore never writes into the main project.

## Performance budget

- no effect on game runtime, cook output, or packaged size;
- backup may scale with Git history plus newly referenced LFS objects, but existing LFS objects are copied once into a content-addressed store;
- fail before backup when free space is below the hard reserve; warn at 100 GB;
- daily work must not modify the working tree or block Unreal runtime behavior.

## Blueprint/Editor impact

No Blueprint or asset changes. Unreal Editor is not required for backup. It must be closed only for the final restored-copy build/test if a conflicting Editor instance is running.

## Acceptance criteria

1. **Given** all local refs and tags **When** backup runs **Then** a verified bundle and exact ref inventory are published in a new immutable generation.
2. **Given** every LFS pointer reachable from captured refs **When** backup runs **Then** its SHA-256 payload exists and verifies in the independent shared LFS store.
3. **Given** a successful generation **When** its manifest and checksums are audited **Then** bundle, refs, LFS inventory, policy, source commit, tool versions, and UTC completion time agree.
4. **Given** GitHub is not used **When** the latest generation restores into a new folder **Then** all captured refs and LFS objects verify with no network remote required.
5. **Given** the restored `main` working copy **When** the pinned toolchain runs **Then** Development Editor build and `BrokenStreets.Smoke.ProjectBoot` pass.
6. **Given** daily operation **When** the schedule is inspected **Then** it points to the committed backup tool, runs at 19:00, and starts after a missed time when possible.
7. **Given** low capacity or an invalid/incomplete backup **When** the tool runs **Then** it reports failure or warning in English and never advances the last-successful pointer prematurely.

## Automated verification

- PowerShell parser checks under Windows PowerShell 5.1;
- backup dry-run/safety validation and a real backup generation;
- Git bundle verification and exact ref comparison;
- manifest and SHA-256 audit;
- offline mirror and working-copy restore;
- `git fsck`, Git LFS pointer/object audit, and clean restored `main`;
- restored-copy `Tools/BS.cmd Build` and `Tools/BS.cmd Test`;
- repository diff, scope, language, secrets, and Git LFS status checks.

## Manual acceptance

No Unreal Editor or Visual Studio action is required.

1. Open PowerShell in `F:\BrokenStreets`.
2. Run `.\Tools\BS-Backup.cmd`.
3. Wait for `[PASS] Published generation ...` and confirm the path is under `E:\BrokenStreets_RepositoryBackup\Generations`.
4. Send Codex the complete terminal result or a screenshot. Any `[FAIL]` is a failed acceptance and must be repaired before merge.

The scheduled task is already registered, enabled, and proven by one direct Task Scheduler run with result code 0. Creator acceptance proves the normal checkpoint command and presentation at the handoff boundary.

Creator acceptance was completed on August 30, 2026. Madalin Gavrila ran the normal checkpoint command from `F:\BrokenStreets`; generation `20260830T104652Z-28620-93aa2606` was published under the approved `E:` backup root. Its manifest records a clean source at `a9f57e601cb14491f34f66e22ea83fbc4745a666`, origin refresh `PASS`, 11 captured refs, 0 current LFS objects, and the approved retention/capacity policy. `LATEST.json` points to the same generation and source commit.

## Risks and rollback

- **Base:** `cfd2edffc70bb9a22fd39041f9fe91a2b038da69`.
- The local independent copy survives failure of the project SSD or GitHub, but not loss of the entire PC/location; BS-013A adds the approved off-site layer.
- The 100 GB threshold is an alert, not a final production capacity estimate; Unreal asset growth must be measured.
- No automatic LFS garbage collection or deletion is allowed.
- Rollback removes or disables only the named scheduled task and reverts repository tooling/docs. Existing successful backup generations remain recovery data unless the creator explicitly authorizes their deletion.

## Docs/ADR updates

- resolve OPS-01 for the BS-010A local layer while keeping off-site Source Art work in BS-013A;
- document backup, restore, retention, capacity, and credential procedures;
- update STATUS and task index with verified facts;
- no runtime ADR is required.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| August 30, 2026 | `f15227f2da9507582da1f9bedc358b8485691ea4` | tree `4b84d24edf2abc954c84b350f7c4d74a35bb4af7`; tooling/docs only; no C++/Config/Content/`.uproject`/plugin changes | parser checks; existing runner self-test; backup self-test; same-volume safety rejection; generation `20260830T103932Z-20076-8eb088fc`; offline restore `BS-010A-f15227f`; restored Build/Test summaries under the restore `Saved/Automation/BS-009/`; scheduled-task direct run | PASS — runner 5/5; synthetic restore 3 refs + 1 LFS object; real generation 10 refs + 0 current LFS objects, clean source, origin refresh PASS; offline restore 10 refs, 0 LFS, no network; restored Build 27.965s; restored Test 1/1 passed; scheduled task enabled/Ready, last result 0, next run 19:00 | Codex |
| August 30, 2026 | `a9f57e601cb14491f34f66e22ea83fbc4745a666` | evidence/docs-only commit over the unchanged verified tooling tree | creator command `Tools/BS-Backup.cmd`; generation `20260830T104652Z-28620-93aa2606`; manifest and `LATEST.json` audit | PASS — clean source; origin refresh PASS; 11 refs; 0 current LFS objects; approved owner, retention, capacity, schedule, encryption, and off-site policy recorded | Madalin Gavrila / Codex manifest audit |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

Automated verification and creator acceptance are complete. BS-010A is ready for integration into `main`; the integrated commit and final clean `main` backup are recorded during closure.
