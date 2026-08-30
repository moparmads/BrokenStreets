# Broken Streets local automation

BS-009 provides one entry point for local project checks. The runner supports Windows PowerShell 5.1, installs nothing, and does not modify Unreal Engine.

## Normal command

1. Close Unreal Editor.
2. Open PowerShell in `F:\BrokenStreets`.
3. Run:

```powershell
.\Tools\BS.cmd All
```

Do not launch `BS.cmd` by double-clicking it: the temporary window closes when the run ends and hides the result. Run it from an already-open terminal.

After BS-010, `Test` must discover and pass exactly the first Broken Streets smoke test. The complete `All` gate may still finish as `PASS_WITH_SKIPS` while BS-011 has not created project-owned assets and Cook reports only explicitly classified Engine omissions. A controlled skip is never hidden as a plain PASS.

## Actions

| Action | What it verifies or produces |
|---|---|
| `Doctor` | project files, UE 5.8.2 CL 56702186, bundled .NET, Win64 SDK 10.0.22621.0, VS 18/MSVC 14.50, running processes, UBT permissions, and free space |
| `Generate` | regenerates `.sln` and `.slnx` |
| `Build` | compiles `BrokenStreetsEditor Win64 Development` |
| `Test` | builds first, then runs only `BrokenStreets` Automation tests; zero matching tests is a failure |
| `Validate` | builds first, then validates project-owned assets; `SKIPPED_NO_ASSETS` is expected until BS-011 |
| `Cook` | builds first, then performs a local `Windows` cook without staging or packaging |
| `All` | runs Doctor, Generate, Build, Test, Validate, and Cook in that order |

Example for one check:

```powershell
.\Tools\BS.cmd Test
```

Preview commands without launching Unreal:

```powershell
.\Tools\BS.cmd All -PlanOnly
```

## Engine discovery and execution safety

Engine discovery uses this order:

1. optional `-EngineRoot` argument;
2. local `BROKENSTREETS_UE_ROOT` environment variable;
3. locally registered `EngineAssociation`;
4. Epic Games Launcher manifests.

The runner accepts only the version pinned in `Tools/Build/RunnerConfig.json`. An incorrect explicit path fails instead of silently selecting another engine.

Automation launches `UnrealBuildTool.dll` through the engine's bundled DotNet runtime, not the `UnrealBuildTool.exe` apphost. This avoids the secondary launch path that previously displayed the generic `.NET 0xe0434352` exception in Visual Studio even though the real build succeeded.

In UE 5.8, `Packages Skipped by Platform` may contain Editor-only packages. The runner reports these as `PASS_WITH_SKIPS` only when the native process exits with 0, the Unreal footer confirms `0 error(s)`, Cook output exists, every omission matches an allowed reason, the classified count exactly matches UE's reported count, and every omitted package is Engine-owned. Any unknown or project-owned omission, nonzero native code, error footer, or incomplete output remains a failure.

Every external process is immediately contained in a Windows Job Object with `KILL_ON_JOB_CLOSE`. On timeout, the runner also uses a PID snapshot and `taskkill /T` as a verification fallback, then confirms that the job has no active processes. The same cleanup is verified after a nonzero native exit. A child process therefore cannot remain running after its intermediate parent exits.

Run the runner self-test after changing anything under `Tools/`:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Tools\Tests\Runner.SelfTest.ps1
```

It verifies native argument handling, exact exit-code propagation, timeout code `124`, termination of an orphaned grandchild process, and atomic UTF-8 writing of `run.json`.

## Logs and exit codes

Each run creates:

```text
Saved/Automation/BS-009/<run-id>/
├── run.json
├── runner.log
└── Steps/
    └── <number>-<step>/
        ├── command.txt
        ├── stdout.log
        ├── stderr.log
        ├── combined.log
        └── Unreal.log / TestReport (when applicable)
```

`Saved/` is ignored by Git. On failure, provide the final result and the displayed `Log:` or `Summary:` path so Codex can identify the exact step and code.

Exit-code contract:

- nonzero native code: preserved unchanged;
- `2`: preflight or invalid invocation;
- `21`: the process returned 0, but authoritative UE markers indicate an invalid or incomplete result;
- `70`: internal error or a process that could not start;
- `124`: timeout; only the process group launched by the runner is terminated and verified.

## Independent repository backup

BS-010A adds a second entry point that protects committed Git history and Git LFS payloads on the separately approved `E:` physical disk:

```powershell
.\Tools\BS-Backup.cmd
```

The normal manual command requires a clean working tree. Save and commit the intended checkpoint first; uncommitted files are never represented by a repository backup. `-AllowDirty` is reserved for the daily scheduled task, where the manifest records that uncommitted files were excluded.

Every successful run publishes an immutable directory under:

```text
E:\BrokenStreets_RepositoryBackup\
├── Generations\<run-id>\
│   ├── repository.bundle
│   ├── refs.txt
│   ├── lfs-objects.tsv
│   ├── manifest.json
│   └── checksums.sha256
├── LfsObjects\
├── Logs\
├── LATEST.json
└── LATEST.previous.json
```

The bundle contains all captured Git refs and tags. Git LFS payloads are verified by their SHA-256 OID and copied once into the shared content-addressed store. The tool retains 30 Git generations and never deletes LFS objects automatically. It warns below 100 GiB free and fails below the 10 GiB hard reserve.

The scheduled task does not inherit the interactive Codex PATH. `RepositoryBackupConfig.json` therefore pins the verified local Git executable that includes Git LFS, while interactive runs retain a PATH fallback. If the Codex runtime is relocated, update and reverify that path before the next scheduled backup.

Preview safety checks without writing:

```powershell
.\Tools\BS-Backup.cmd -PlanOnly
```

After changing backup or restore tooling, run its non-empty Git LFS regression test. It creates isolated fixtures on `F:` and `E:`, restores three refs plus one LFS payload without GitHub, and removes only its own verified temporary folders after success:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Tools\Backup\Tests\Backup.SelfTest.ps1
```

Inspect the daily 19:00 scheduled task:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\Tools\Backup\Register-RepositoryBackupTask.ps1 -Action Inspect
```

## Offline repository restore

Restoration never writes into the main project and never contacts GitHub. Always choose a new destination:

```powershell
.\Tools\BS-Restore.cmd -DestinationRoot E:\BrokenStreets_RepositoryBackup\RestoreTests\<new-test-name>
```

The restore verifies the latest pointer, every listed checksum, the bundle, every captured ref, every LFS pointer/payload, Git object integrity, and a clean `main` working copy. It creates both a complete bare repository and `WorkingCopy`. The restored working copy's `origin` points to that local bare repository, not GitHub.

After a recovery, run from the restored `WorkingCopy`:

```powershell
.\Tools\BS.cmd Build
.\Tools\BS.cmd Test
```

Do not delete a failed generation or restore folder before its logs are reviewed. Backup data and restore drills are outside the game repository and are never committed.
