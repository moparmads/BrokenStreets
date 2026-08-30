# BS-013A — Source Art 3-2-1 Backup and Verified Restore

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-013A-source-art-backup`
**Base commit:** `a84ba6d65ca19faa2a7bef89bf6a59e747f2c1ee`
**Roadmap milestone:** M1 — Recoverable baseline and project memory
**System docs:** [Recovery and rollback](../Workflows/RECOVERY_AND_ROLLBACK.md), [Git workflow](../Workflows/GIT_WORKFLOW.md), [Toolchain](../Build/TOOLCHAIN.md)

## Observable outcome

`F:/BrokenStreets_SourceArt` can be captured into immutable, checksummed, content-addressed generations on both `E:` and the approved external drive. A selected generation can be restored into a new folder and verified byte-for-byte. The external checkpoint also contains a complete repository and Git LFS backup, so removing and storing that drive separately provides the third copy and off-site layer.

## Why now

The game repository is recoverable, but creator-owned 3D source files are outside Git and currently have no verified backup. Source Art protection is required before production asset creation and before the complete BS-007B recovery drill.

## In scope

- local Source Art backup under `E:/BrokenStreets_SourceArtBackup`;
- offline recovery root `BrokenStreets_OfflineBackup` on the approved 1 TB LaCie USB drive, currently mounted as `G:`;
- a stable marker that allows the offline drive to be found after its drive letter changes;
- SHA-256 content-addressed objects, immutable generation inventories, checksums, and last-successful pointers;
- deduplication of identical file content across generations without modifying source files;
- a local manual checkpoint command and daily 19:30 local scheduled task;
- a manual offline command that captures both Source Art and the complete Git/Git LFS repository recovery set;
- conservative capacity warnings and hard-reserve failure;
- synthetic regression tests, corruption rejection, interrupted-publication safety, empty real-source baseline, and isolated restore;
- exact quarterly sample-restore and external-drive handling instructions.

## Out of scope

- cloud subscriptions or paid backup providers;
- BitLocker or other encryption; the creator explicitly declined encryption for this drive;
- automatic deletion of content objects or user Source Art;
- synchronizing an open or changing DCC file by guessing around sharing violations;
- gameplay, C++, Config, Content, `.uproject`, plugins, Engine Source, or save data;
- treating the offline drive as continuously attached storage.

## Dependencies and required decisions

- BS-010A and BS-013 are Done on `main`;
- working Source Art root: `F:/BrokenStreets_SourceArt`;
- local backup root: `E:/BrokenStreets_SourceArtBackup` on a different internal physical disk;
- offline medium: 1 TB LaCie USB drive, NTFS, stored separately from the PC after a successful checkpoint;
- encryption: none, accepted with the explicit confidentiality risk recorded below;
- retention: successful generation metadata is retained; content objects are never deleted automatically;
- reversible capacity defaults: warn below 100 GiB and fail before publication below a 20 GiB reserve or when the estimated write cannot preserve that reserve;
- capacity review trigger: Source Art reaches 300 GiB, either backup drive falls below 150 GiB free, or the offline checkpoint no longer fits with reserve;
- local frequency: before meaningful Source Art operations and daily at 19:30 while the PC is available;
- offline frequency: after meaningful asset work, before risky migrations or milestone closure, and at least weekly while Source Art is changing;
- quarterly restore: restore a selected generation to a new folder, verify it, and open representative source files in their authoring applications.

## Allowed files/domains

- `Tools/SourceArtBackup/` and thin command wrappers under `Tools/`;
- `Tools/README.md`;
- `Docs/Tasks/`, `Docs/STATUS.md`, `Docs/PENDING_DECISIONS.md`, and recovery/toolchain workflow documentation;
- external data only under `E:/BrokenStreets_SourceArtBackup` and the marked `BrokenStreets_OfflineBackup` root on the approved external drive;
- the named Windows scheduled task for the local Source Art backup.

Forbidden: modifying or deleting any file under `F:/BrokenStreets_SourceArt`, writing outside the named backup roots, gameplay and Unreal content, Engine Source, or unrelated Windows settings.

## Authority/network impact

N/A — developer recovery tooling only. It creates no gameplay state, RPC, replication, session, late-join, or reconnect behavior. Backup and restore require no network service.

## Persistence/migration impact

The operational backup schema is versioned independently from game saves. Published generations and content objects are immutable. A staging generation must validate before publication and before the last-successful pointer changes. Restore always targets a new folder and never overwrites Source Art, the game repository, or Unreal Engine.

## Performance budget

- no game runtime, package, or cook impact;
- file hashing and first-copy I/O scale with changed bytes; unchanged content is reused by hash;
- no permanent filesystem watcher and no background process inside Unreal;
- daily execution must tolerate an empty source and fail visibly if a source file changes or cannot be read;
- capacity checks happen before publication and protect the configured hard reserve.

## Blueprint/Editor impact

No Blueprint, asset, map, or Unreal configuration changes. Unreal Editor is not required. DCC applications should be closed, or their files saved and no longer changing, for a meaningful manual checkpoint.

## Acceptance criteria

1. **Given** an empty or populated Source Art tree **When** a local backup runs **Then** a verified immutable generation is published on `E:` without changing the source.
2. **Given** unchanged or duplicate files **When** another generation runs **Then** existing verified content objects are reused rather than copied again.
3. **Given** a partial run, unreadable/changing input, corrupted object, or insufficient capacity **When** backup or restore runs **Then** it fails in English and the prior successful pointer remains valid.
4. **Given** a successful generation **When** it restores to a new folder **Then** directories, file lengths, and every SHA-256 hash match the selected inventory.
5. **Given** the marked external drive **When** the offline checkpoint runs **Then** both the latest Source Art generation and a complete Git/Git LFS recovery generation are verified under the dedicated offline root.
6. **Given** the external drive receives another Windows drive letter **When** the offline command runs **Then** it locates the unique approved marker rather than trusting `G:` alone.
7. **Given** a successful offline checkpoint **When** the creator safely ejects and stores the drive separately **Then** the project has three copies on separate storage with one off-site copy.

## Automated verification

- Windows PowerShell 5.1 parser checks for every new script;
- synthetic nested, Unicode, binary, duplicate-content, and multi-generation fixture;
- exact source/restore inventory comparison;
- corruption rejection before restore destination creation;
- failed-publication pointer-preservation test;
- path escape, source overwrite, wrong-drive, and existing-destination rejection;
- real empty Source Art local and offline generations;
- offline repository bundle/LFS restore without GitHub;
- restored repository Git/LFS integrity plus Development Editor build and Automation smoke test;
- repository scope, English, secrets, diff, and Git LFS status checks.

## Manual acceptance

No Unreal Editor or Visual Studio action is required.

1. Save and close files in the 3D authoring application.
2. Connect the approved LaCie drive and unlock it if Windows requests access.
3. Open PowerShell in `F:\BrokenStreets`.
4. Run `\.\Tools\BS-OfflineBackup.cmd`.
5. Require PASS for both Repository and Source Art and note the displayed generation IDs.
6. Use **Safely Remove Hardware and Eject Media**, disconnect the drive, and store it separately from the PC.
7. Any FAIL, missing PASS, or Windows disk warning fails acceptance; retain the drive connected and provide the complete terminal result.

## Risks and rollback

- **Base:** `a84ba6d65ca19faa2a7bef89bf6a59e747f2c1ee`.
- Without encryption, anyone who possesses the external drive can read the repository and Source Art. Physical custody is the accepted control; credentials and secrets must never be placed in either source.
- A 1 TB drive is suitable for the current empty baseline but is not permanent capacity for an asset-heavy project. The review trigger is mandatory and a larger/replacement medium may be needed before production growth.
- Storing the drive beside the PC would not satisfy off-site protection; the creator approved separate storage after each successful checkpoint.
- Rollback disables only the named scheduled task and reverts repository tooling/docs. Existing verified backup generations remain recovery data unless the creator explicitly authorizes removal.

## Docs/ADR updates

- resolve OPS-01B with the approved physical offline layer, accepted no-encryption risk, capacity trigger, and retention/frequency policy;
- document local/offline backup, restore, quarterly drill, safe ejection, failure, and drive-replacement procedures;
- update STATUS and task index with verified facts;
- no runtime ADR is required.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| | | | | | |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

- versioned local and offline backup commands;
- verified restore evidence and exact external-drive handling steps;
- no Unreal Editor action;
- explicit plaintext-drive and finite-capacity risks;
- rollback commit and BS-013B as the next roadmap task.
