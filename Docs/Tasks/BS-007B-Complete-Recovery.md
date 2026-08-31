# BS-007B — Complete Project Recovery Drill

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-007B-complete-recovery`
**Base commit:** `d43e4fd09fec0cb48cc63e269eb75f350f7e2f79`
**Roadmap milestone:** M1B — Recovery and documentation
**System docs:** [Recovery and rollback](../Workflows/RECOVERY_AND_ROLLBACK.md), [Git workflow](../Workflows/GIT_WORKFLOW.md), [Toolchain](../Build/TOOLCHAIN.md)

## Observable outcome

Broken Streets can be reconstructed into a new folder from the private GitHub repository, with all three Git LFS maps materialized and verified. The reconstructed project can generate IDE files, build `BrokenStreetsEditor | Win64 | Development`, pass the Broken Streets Automation test and Data Validation, cook and package Win64 Development, and load `L_TestGym_Core` through the exact UE 5.8.2 executable. A second Windows profile repeats the project/toolchain gate without relying on the current profile's Unreal association or generated project state.

## Why now

BS-009 through BS-013B created the repeatable runner, smoke test, repository backup, TestGym maps, benchmark fixture, Source Art recovery, and pinned PC baseline. BS-007B now proves that those parts reconstruct one usable project instead of only passing in the original working directory. Passing this task closes the M1 recovery gate before gameplay foundations begin.

## In scope

- a new online clean clone under `E:/BrokenStreets_RecoveryTests/`;
- exact candidate/ref and clean-clone provenance;
- Git LFS pull, pointer, payload, hash, and clean-state audits for every project-owned `.umap`;
- absence of inherited `Binaries`, `DerivedDataCache`, `Intermediate`, `Saved`, `.vs`, and generated solution files before verification;
- project generation, Development Editor build, Automation, Data Validation, and cook through `Tools/BS.cmd All`;
- Win64 Development Build/Cook/Stage/Package/Archive of `/Game/BS/Maps/Test/L_TestGym_Core`;
- exact UE 5.8.2 executable load of `L_TestGym_Core` with a retained log and normal exit;
- one controlled Git LFS lock, pointer, remote-object, push, and unlock exercise using the existing Core TestGym map without changing its bytes;
- a second clean verification workspace executed from another local Windows profile;
- structured English evidence, timings, discovered problems, and recovery/toolchain documentation updates.

## Out of scope

- game-save restoration before BS-020 defines the schema and fault harness;
- Source Art restoration, already covered by BS-013A;
- gameplay, networking logic, UI, economy, character, or world implementation;
- modifying, duplicating, resaving, moving, or renaming an Unreal binary asset solely for this drill;
- Engine Source, plugins, renderer settings, project defaults, or toolchain upgrades;
- deleting failed recovery workspaces before their evidence is reviewed;
- treating a same-profile build directory as the clean-profile result.

## Dependencies and required decisions

- BS-009, BS-010, BS-010A, BS-011, BS-012, BS-013, BS-013A, and BS-013B are Done on `main`.
- The verified engine remains `F:/UE_5.8.2/UE_5.8`, UE 5.8.2 changelist 56702186.
- The online source is the private repository `https://github.com/moparmads/BrokenStreets.git`.
- The recovery work root is the separate internal disk at `E:/BrokenStreets_RecoveryTests`.
- The clean-profile method is a temporary local standard Windows account on this PC. It is reversible and avoids requiring a second PC.
- The LFS exercise uses `/Game/BS/Maps/Test/L_TestGym_Core`. Its bytes must remain unchanged; the existing real remote object is audited while the task branch is pushed under a lock.
- No paid service or subscription is required.

## Allowed files/domains

- `Tools/Recovery/**` and `Tools/BS-RecoveryDrill.cmd`;
- `Tools/README.md`;
- `Docs/Tasks/BS-007B-Complete-Recovery.md`, `Docs/Tasks/README.md`, `Docs/STATUS.md`, `Docs/ROADMAP.md`, `Docs/Build/TOOLCHAIN.md`, and `Docs/Workflows/RECOVERY_AND_ROLLBACK.md`;
- ignored evidence under `Saved/Recovery/BS-007B/`;
- isolated recovery workspaces only under `E:/BrokenStreets_RecoveryTests/`.

Forbidden: `Content/**`, `Source/**`, `Config/**`, `BrokenStreets.uproject`, Engine Source, plugins, Source Art, existing backup generations, unrelated Windows settings, and any existing project/recovery destination.

## Authority/network impact

N/A — developer recovery tooling only. No gameplay authority, RPC, audience, relevancy, late join, reconnect, or disconnect behavior changes. Network access is used only for the private GitHub clone, Git LFS transfer, and the controlled branch/lock workflow.

## Persistence/migration impact

N/A for game persistence — BS-020 has not created a save schema. Recovery evidence is operational metadata under ignored `Saved/` and isolated `E:` workspaces. The drill never overwrites the live repository, Source Art, Engine, or an existing recovery destination.

## Performance budget

- no runtime hot path or shipping code impact;
- the online drill is bounded by Git/LFS transfer plus the existing runner/package timeouts;
- at least 20 GiB must remain free before Unreal verification begins;
- every phase records UTC start/end time and duration;
- no persistent watcher, service, or background process is added.

## Blueprint/Editor impact

No Blueprint or asset change. Automated verification runs with Unreal Editor and Visual Studio closed. The final creator check opens the recovered project/package only after the automated candidate passes. The exact map is `/Game/BS/Maps/Test/L_TestGym_Core`.

## Acceptance criteria

1. **Given** a new non-existing destination on `E:` **When** the online drill clones the approved ref **Then** the checked-out commit is exact, the tree is clean, and no local generated project state was inherited.
2. **Given** the clean clone **When** Git LFS is pulled and audited **Then** all three project maps are materialized, every index blob is a valid LFS pointer, every working file matches its SHA-256 OID, and Git LFS fsck passes.
3. **Given** the materialized clone and exact UE installation **When** the complete runner executes **Then** Generate, Build, Test, Validate, and Cook pass with one Automation success, three valid project assets, and zero project-owned cook omissions.
4. **Given** the clean candidate **When** the recovery package phase runs **Then** a Win64 Development package contains `L_TestGym_Core` and UAT exits `0` with authoritative success markers.
5. **Given** the exact engine executable **When** the recovered Core TestGym map is loaded **Then** the retained log identifies the exact map and engine build, reports no fatal/crash marker, and the process exits normally.
6. **Given** the existing Core TestGym LFS asset is locked by Madalin **When** the task branch is audited and pushed **Then** the index pointer and remote object are verified, the asset bytes are unchanged, and the lock is released only after remote confirmation.
7. **Given** a temporary second Windows profile and a second pristine staged workspace **When** its profile verification runs through the absolute engine path **Then** generation/build/test/validation/cook and exact-map load pass without changing or committing `EngineAssociation`.
8. **Given** any failed phase **When** the drill stops **Then** it retains its logs/workspace, does not publish a false PASS, and does not delete or overwrite any protected path.

## Automated verification

- Windows PowerShell 5.1 parser checks for every recovery script;
- isolated recovery self-test for path boundaries, new-destination enforcement, LFS pointer parsing, hash mismatch rejection, phase failure propagation, and atomic evidence publication;
- exact online clone and candidate/ref audit;
- `git lfs pull`, index-pointer checks, working-file OID checks, `git lfs fsck --pointers HEAD`, and `git lfs fsck`;
- `Tools/BS.cmd All -EngineRoot F:\UE_5.8.2\UE_5.8` from the online clean clone;
- exact-map Win64 Development package and package-manifest/log audit;
- exact-engine headless map-load checkpoint with retained log;
- controlled remote LFS lock/pointer/push/object/unlock audit;
- diff, parser, English, secrets, generated-file, repository-scope, and clean-state audits.

## Manual acceptance

The exact clean-profile and visual instructions are issued only after the automated online candidate passes. They follow `Docs/Workflows/EDITOR_INSTRUCTION_STANDARD.md` and use a temporary standard Windows account, a separately staged pristine workspace, the absolute UE 5.8.2 executable, and exact PASS/FAIL evidence. Unreal Editor and Visual Studio remain closed until those instructions explicitly say otherwise.

## Risks and rollback

- **Base:** `d43e4fd09fec0cb48cc63e269eb75f350f7e2f79`.
- A private GitHub clone can fail because of credentials or the previously observed Windows `git-remote-https.exe` crash. The failed workspace/log remains evidence; the tool does not silently substitute the local repository for the online clone.
- First-use DDC and build time can be substantially longer on a clean profile. Time alone is not failure until the documented timeout is reached.
- The temporary Windows profile must not receive credentials, secrets, or administrator rights merely for this test.
- An LFS lock is remote mutable state. The asset bytes are pinned before the exercise; a mismatch stops the task, and unlock occurs only after remote verification.
- Repository rollback is `git revert` of the integrated tooling/docs commit. External recovery workspaces remain evidence until Madalin explicitly approves their removal.
- No game save or asset compatibility change exists because no runtime/content/schema file may change.

## Docs/ADR updates

- close the BS-007B sections of recovery, status, roadmap, task index, and toolchain documentation with measured evidence;
- record any profile/credential/tool discovery limitation explicitly;
- no runtime ADR is expected because no game or renderer decision changes.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| | | | | | |

Any later change to C++, Config, Content, `.uproject`, plugins, or recovery/build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged verified tree.

## Final handoff

- exact online and clean-profile recovery roots;
- candidate, merge, tree, and remote identity;
- LFS asset path, lock ID/owner, pointer OID, working-file hash, remote-object result, and unlock result;
- runner, package, exact-map load, and creator visual evidence;
- measured duration and every skipped/N/A item with reason;
- retained failed attempts or zero-failure statement;
- rollback base and the next roadmap task.
