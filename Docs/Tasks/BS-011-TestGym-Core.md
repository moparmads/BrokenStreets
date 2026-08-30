# BS-011 — Project-Owned TestGym Core Map

**Status:** Needs Owner Verification
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-011-testgym-core`
**Base commit:** `a6ad7b3d08fdd3330aa0e35c20b93b53d1938598`
**Roadmap milestone:** M1 — Recoverable baseline and project memory
**System docs:** [Test strategy](../Testing/TEST_STRATEGY.md), [Toolchain](../Build/TOOLCHAIN.md), [Editor instruction standard](../Workflows/EDITOR_INSTRUCTION_STANDARD.md), [ADR-0005](../Decisions/ADR-0005-Renderer-And-Scalability-Baseline.md)

## Observable outcome

`/Game/BS/Maps/Test/L_TestGym_Core` is the first project-owned Unreal map. It opens as a small, neutral TestGym fixture, passes Map Check and project Data Validation, cooks without a project-owned omission, is present in a packaged Win64 Development build, and loads when that packaged build is launched with the map's explicit URL.

## Why now

BS-009 and BS-010 provide repeatable automation, while BS-010A protects Git and Git LFS data before binary content begins. BS-011 removes the missing-`Content` baseline warning, proves the first real `.umap` path and LFS workflow, and gives later systems a controlled fixture without beginning Manhattan production.

## In scope

- one `Basic Level` map saved as `Content/BS/Maps/Test/L_TestGym_Core.umap`;
- only the actors supplied by the Unreal `Basic Level` template for the initial fixture;
- no Level Blueprint gameplay or per-frame script;
- Git LFS lock, pointer, object, push, and post-merge unlock verification for the map;
- the minimum BS-009 runner regression required to recognize UE 5.8 class-prefixed asset identities as validation coverage;
- Map Check, Data Validation, Build, Automation, Cook, packaged Win64 Development creation, and explicit packaged-map launch;
- exact creator steps and visual acceptance;
- task, status, and verification documentation.

## Out of scope

- changing `GameDefaultMap`, `EditorStartupMap`, renderer, scalability, or PC-only configuration; BS-013B owns those changes;
- World Partition, Data Layers, HLOD, four streaming bubbles, or production-world scale;
- `L_TestGym_Network`, which is BS-012;
- `L_Benchmark_Street`, which is BS-013;
- gameplay C++, Blueprint gameplay, GameMode, Pawn, UI, interaction, AI, vehicles, or replication;
- production meshes, materials, textures, Source Art, Marketplace content, plugins, or external dependencies;
- Manhattan layout, final art, or performance claims.

## Dependencies and required decisions

- BS-009, BS-010, and BS-010A are Done on `main`;
- decision 27 confirms that the first map is a simple TestGym used before city production;
- ADR-0005 remains Proposed and explicitly assigns renderer/scalability cleanup to BS-013B, not this task;
- the reversible task default is Unreal's `Basic Level` template as a non-production, non-World-Partition fixture;
- the canonical asset root is `/Game/BS/...`, and the exact map name is already established by the Editor instruction standard;
- no material product decision is missing.

## Allowed files/domains

- `Content/BS/Maps/Test/L_TestGym_Core.umap`;
- `Tools/Invoke-BrokenStreets.ps1` and `Tools/Tests/Runner.SelfTest.ps1`, limited to the demonstrated validation-identity regression;
- `Docs/Tasks/BS-011-TestGym-Core.md`, `Docs/Tasks/README.md`, and `Docs/STATUS.md`;
- small verification documentation only when evidence requires it;
- generated build, validation, cook, package, and log output only under ignored `Saved/`, `Binaries/`, `Intermediate/`, or an explicitly named temporary verification directory.

Forbidden: other project assets, unrelated runner behavior, `Config/`, `.uproject`, plugins, Engine Source, runtime C++, Source Art, generated IDE files in Git, and unrelated documentation.

## Authority/network impact

N/A. The map introduces no gameplay owner, state, RPC, replication, session behavior, late join, reconnect, or network payload. BS-012 owns the first network TestGym.

## Persistence/migration impact

N/A. The map contains no save state, persistent ID, schema, migration, or economy data. It must not be referenced by an existing save format because no game save exists yet.

## Performance budget

- no Blueprint Tick, scripted loop, AI, physics workload, Niagara, audio, or production asset load;
- retain only the small actor set created by the `Basic Level` template;
- the source `.umap` should remain below 5 MiB; exceeding the bound blocks acceptance until accidental embedded or added content is explained;
- no performance claim is made from an empty fixture; it is a controlled baseline for later workloads;
- no World Partition or runtime streaming decision is introduced.

## Blueprint/Editor impact

Madalin creates and saves the binary map through Unreal Editor 5.8.2 after Codex acquires its Git LFS lock. Visual Studio is not required. The first checkpoint creates no Blueprint and does not modify template actors. After saving, the Editor must close before Codex inspects, commits, builds, validates, cooks, and packages the exact asset.

## Acceptance criteria

1. **Given** the locked planned asset path **When** the creator saves the `Basic Level` **Then** exactly one new project-owned package exists at `/Game/BS/Maps/Test/L_TestGym_Core` and no unrelated asset is created or modified.
2. **Given** the saved map **When** Map Check and Data Validation run **Then** the package is valid with 0 errors and no unexplained warning.
3. **Given** the staged map **When** Git inspects it **Then** `.umap` is a valid LFS pointer, the referenced object exists locally, and the lock belongs to the task owner.
4. **Given** `Tools/BS.cmd All` **When** it runs on the candidate **Then** Build and Automation pass, Validate finds project content instead of `SKIPPED_NO_ASSETS`, and Cook reports no project-owned omission or new warning.
5. **Given** a packaged Win64 Development build **When** it is launched with `/Game/BS/Maps/Test/L_TestGym_Core` **Then** the log proves that exact map loads without a fatal error.
6. **Given** the packaged build **When** Madalin opens it **Then** the expected Basic Level floor and lighting are visible and the application remains responsive.
7. **Given** the accepted merge and GitHub push **When** Git LFS is audited **Then** the remote object is available, local and remote `main` agree, and the map lock is released only after those checks pass.

## Automated verification

- inspect `git status`, attributes, lock owner, staged LFS pointer, `git lfs status`, `git lfs ls-files`, and `git lfs fsck --pointers HEAD`;
- run `Tools/Tests/Runner.SelfTest.ps1`, including class-prefixed identity, bare object identity, wrong-package, and prefix-collision cases;
- run the map through Unreal Map Check and project Data Validation;
- run `Tools/BS.cmd All` with Unreal Editor closed;
- verify `Development Editor | Win64`, `BrokenStreets.Smoke.ProjectBoot`, Data Validation, and Cook results from the exact candidate tree;
- create a Win64 Development package for the explicit TestGym map in ignored verification output;
- launch the packaged executable with the explicit map URL and retain the load log;
- audit changed paths, package size, warnings, generated files, and absence of Level Blueprint gameplay;
- inspect pending LFS objects before push and confirm the remote object after push.

## Manual acceptance

### Checkpoint A — create the project-owned map

**Goal:** Create exactly one Basic Level map at the locked BS-011 path.
**Applications needed:** Unreal Editor 5.8.2 and File Explorer.
**Unreal Editor state:** Closed at the start; Open only for the numbered steps; Closed after Checkpoint A.
**Visual Studio state:** Not needed.
**Expected duration:** 5 minutes.
**Files/assets created or modified:** `/Game/BS/Maps/Test/L_TestGym_Core` only.
**Do not touch:** Project Settings, Config, the Engine template map, Level Blueprint, template actors, other Content folders, Source Art, or engine version conversion.

Exact numbered steps are issued only after Codex confirms the branch preparation commit and Git LFS lock. The creator stops after the first save and returns the requested screenshot before Codex continues.

### Checkpoint B — packaged visual load

After automated verification, Codex provides the exact packaged executable path and launch steps. PASS requires the expected Basic Level floor and lighting, a responsive window, and no crash dialog. Any visual or log mismatch returns the task to `In Progress`.

## Risks and rollback

- **Base:** `a6ad7b3d08fdd3330aa0e35c20b93b53d1938598`.
- A `.umap` is binary and cannot be meaningfully line-reviewed; strict path, actor-count, validation, cook, packaged-load, and visual checks reduce accidental content risk.
- The Basic Level references Engine content. This is acceptable for the fixture and does not authorize copying or modifying Engine assets.
- This task does not prove World Partition, networking, representative performance, production art, or default-map configuration.
- Rollback requires the Editor closed, a public-history revert after merge, verification that no later accepted map depends on this fixture, and normal Git LFS lock handling. Never remove the asset in File Explorer as an ad hoc rollback.

## Docs/ADR updates

- update task index and STATUS with only verified facts;
- keep ADR-0005 Proposed and unchanged because BS-013B owns renderer/scalability decisions;
- no system document or new ADR is justified for one test fixture.

## Verification evidence

| Date | Candidate commit | Runtime/content tree | Build/test/trace | Result | Executed by |
|---|---|---|---|---|---|
| August 30, 2026 | `859cc7a7d3d78150e28f2bd80f5445627ae7aee2` | first map candidate; LFS OID `008fdcaef2fe3d4765ba95ccd8b7be03af445ff7083eeec5ba38f883e5f2730d`; 49,037 bytes | `Tools/BS.cmd All`; `Saved/Automation/BS-009/20260830T112422Z-41008-0fa8d453/run.json` | INVALIDATED — Build and Automation passed; Unreal validated 1/1 assets with 0 errors/warnings, but the runner rejected coverage because it did not recognize UE 5.8's class-prefixed World identity. A runner-only regression repair requires a new candidate and complete rerun. | Codex |
| August 30, 2026 | `43cf7d04d32f126eadeb6cdbb21784373142e8b7` | unchanged map LFS OID `008fdcaef2fe3d4765ba95ccd8b7be03af445ff7083eeec5ba38f883e5f2730d`; 49,037 bytes; one project-owned package | runner self-test 6/6; `Tools/BS.cmd All`; `Saved/Automation/BS-009/20260830T112827Z-37852-5504cb0b/run.json`; `Saved/Verification/BS-011/MapCheck-43cf7d0/Unreal.log`; Win64 Development `BuildCookRun`; `Saved/Verification/BS-011/PackagedBoot-43cf7d0/Packaged.log` | PASS — Build and Automation passed; Data Validation requested/validated 1/1 project assets with 0 invalid/unable/missing; Cook reported 0 project-owned omissions and 0 warnings; Map Check reported 0 errors and 0 warnings; package/archive completed with UAT exit 0; the package manifest contains `L_TestGym_Core.umap`; the packaged executable loaded the exact map, brought its world up for play, and exited normally with status 0. Creator visual acceptance remains pending. | Codex |

Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks candidate evidence `INVALIDATED` until the relevant checks are rerun. A later evidence/docs-only commit may reference the unchanged tree.

## Final handoff

The locked Basic Level map exists and the exact candidate passed LFS, runner regression, Build, Automation, Data Validation, Cook, Map Check, Win64 Development packaging, and packaged-map boot verification. The task is at `Needs Owner Verification` until Madalin accepts Checkpoint B. The feature branch, remote LFS object, merge, post-merge audit, backup generation, and lock release follow only after that visual acceptance.
