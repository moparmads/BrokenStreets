# Recovery, Backup, and Restoration

GitHub is a remote copy; it is not proof that the project can be reconstructed. Recovery is tested.

## BS-007A — basic clean clone

This can run now:

1. Choose a new, explicit folder outside `F:/BrokenStreets` and `F:/UE_5.8.2`.
2. Clone the private repository and `main`.
3. Run Git LFS pull.
4. Confirm `.vs`, `Binaries`, `Intermediate`, and `Saved` are intentionally absent.
5. Generate Visual Studio files.
6. Build `BrokenStreetsEditor | Win64 | Development`.
7. Open the project and confirm the empty baseline.
8. Record duration, commit, and every undocumented step.

PASS proves the base project does not depend on its old cache. The recovery folder never becomes the main project.

BS-007A ran under the same Windows profile and UE installation. It does not yet prove portability to another profile or PC, nor recovery of saves, LFS assets, or Source Art that did not exist at baseline.

## Engine association on a new profile or PC

`BrokenStreets.uproject` may contain an `EngineAssociation` GUID registered only locally. That GUID is not a portable path and must not be assumed to exist elsewhere.

Safe recovery:

1. install and verify exactly UE 5.8.2 and record its absolute path;
2. build through that engine's `Engine/Build/BatchFiles/Build.bat` with the absolute `.uproject` path;
3. open through the same engine's `Engine/Binaries/Win64/UnrealEditor.exe`, passing the `.uproject`;
4. for Explorer/IDE integration, associate the project locally and regenerate files. Do not push an `EngineAssociation` rewrite caused only by recovery without an upgrade/toolchain task;
5. BS-009 validates project generation without hidden Explorer dependence; BS-007B repeats it on another Windows profile or second PC.

## BS-007B — complete project recovery

Run after BS-009, BS-010, BS-010A, BS-011, BS-012, BS-013, and BS-013B:

1. create a new clean clone;
2. run Git LFS pull and pointer audit;
3. generate project files;
4. command-line Development Editor build;
5. Automation smoke tests;
6. Data Validation;
7. minimal cook and package;
8. open and load `L_TestGym_Core` through the exact engine executable;
9. perform an approved LFS lock, unlock, pointer, and push exercise on a test asset;
10. repeat on another Windows profile or second PC without assuming the local GUID;
11. report steps, duration, and problems, then update toolchain documentation.

Save restoration is not a BS-007B criterion before BS-020 creates the schema and fault harness. From BS-020 onward, every persistent gate adds its own restore and fault test.

## Independent repository and Git LFS backup — BS-010A

GitHub is the collaboration remote, not the only disaster-recovery plan. Before the first important Unreal asset, BS-010A requires:

- every required ref and tag plus every Git LFS object, not only the working tree;
- a versioned copy on media or storage independent from both GitHub and the project SSD;
- manifest, checksum, and last-successful-backup date;
- remote checkpoint before risky operations or asset migrations;
- restoration into a new folder while GitHub is unavailable or disabled;
- build/open of the restored commit and verification of every LFS pointer;
- owner, frequency, retention, capacity alert, and credential-renewal procedure.

A `git bundle` alone does not include LFS objects. The approved solution must preserve both Git objects/refs and LFS storage, or use a second remote that provides both. Codex never selects a provider or medium without creator approval.

### Approved local layer

The creator approved this BS-010A policy on August 30, 2026:

- owner: Madalin Gavrila;
- source: `F:/BrokenStreets` on physical disk 1;
- independent root: `E:/BrokenStreets_RepositoryBackup` on physical disk 0;
- frequency: daily at 19:00 plus a manual checkpoint before risky operations or asset migrations;
- retention: 30 immutable Git generations; shared content-addressed LFS payloads are never deleted automatically;
- capacity: warn below 100 GiB free and fail below a 10 GiB hard reserve;
- encryption: no additional encryption for this local copy;
- off-site protection: deferred to BS-013A, where repository and Source Art capacity/provider are selected together.

The daily task may record a valid committed-ref backup while the working tree is dirty, but its manifest states that uncommitted files were excluded. A manual checkpoint requires a clean working tree.

### Backup procedure

1. Save intended work and create the checkpoint commit.
2. From `F:/BrokenStreets`, run `.\Tools\BS-Backup.cmd`.
3. Require `[PASS] Published generation ...`; record the displayed generation path.
4. Inspect `LATEST.json`, the generation `manifest.json`, and `checksums.sha256` when the operation is a recovery gate.
5. Do not start the risky operation if backup fails or the latest successful generation does not contain the intended commit.

Each successful generation contains a full Git bundle, exact ref inventory, LFS inventory, manifest, and checksums. LFS objects are stored separately by SHA-256 OID and reused across generations. Staging is published before `LATEST.json` advances; `LATEST.previous.json` preserves the prior pointer.

### Restore procedure without GitHub

1. Choose a new explicit folder under `E:/BrokenStreets_RepositoryBackup/RestoreTests/`; never target the main project, Engine, drive root, or backup root.
2. Run `.\Tools\BS-Restore.cmd -DestinationRoot <new-folder>` from the main repository tools.
3. Confirm PASS for checksum, bundle, exact refs, Git fsck, and every LFS object/pointer.
4. Confirm the restored `WorkingCopy` origin points to the restored local bare repository, not GitHub.
5. In the restored `WorkingCopy`, run `.\Tools\BS.cmd Build` and `.\Tools\BS.cmd Test` through the pinned engine.
6. Keep failed restore folders and logs until the cause is understood. A restore-test folder never becomes the main project.

### Schedule, failure, and credentials

The Windows task `BrokenStreets Repository Backup` runs daily at 19:00 for the signed-in owner, ignores overlapping starts, and starts after a missed time when Windows permits. Its action uses the committed PowerShell tool and writes logs under the independent backup root.

The tool attempts to refresh `origin` and Git LFS first. If authentication or GitHub is unavailable, it reports a warning and publishes only when every LFS payload required by the locally captured refs is present and valid. To renew credentials, sign into the approved `moparmads` GitHub account through the existing Git Credential Manager flow, run `git fetch origin`, then rerun the manual backup. Never place a token in the repository, task action, manifest, or log.

## Source Art 3-2-1 backup

`F:/BrokenStreets_SourceArt` is not protected by the game repository.

The gate requires:

- three total copies;
- two media or storage types;
- one off-site copy;
- checksum or manifest for important files;
- versioning or snapshot policy;
- estimated capacity and pre-full alert;
- quarterly sample restoration into a new folder.

Do not configure a provider or cloud automatically without creator choice and authorization.

## Future save recovery

Every persistent schema requires:

- versions and migrations;
- checksum and at least one prior valid generation;
- temporary file on the same volume as its destination;
- ordering: `capture → serialize temp → flush → read-back/checksum → atomic local replace → manifest commit`;
- manifest update only after validation; an unconfirmed temporary file never becomes active;
- newest-to-oldest selection among valid committed generations, with reported fallback;
- golden test files;
- crash/fault injection before and after every stage plus corrupt, truncated, and stale behavior;
- recovery UI or report;
- compatibility and rollback plan.

## Incident checklist

For project corruption or an impossible build:

1. stop saves and bulk operations;
2. record branch, commit, status, and log;
3. do not delete broad folders as a first step;
4. check whether a clean clone reproduces the problem;
5. classify it as source/configuration, generated files, LFS asset, engine/toolchain, or save;
6. restore from the narrowest verified source;
7. rebuild and test before resuming work;
8. add regression coverage or documentation for the actual cause.

## Destructive safety

Every recursive delete or move:

- uses a verified absolute target;
- never targets a root, home directory, generic workspace root, glob, or unresolved variable;
- prefers a recovery or trash folder;
- never touches the main project, engine, or Source Art without explicit creator approval.
