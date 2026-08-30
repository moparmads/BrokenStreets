# Canonical toolchain

**Updated:** August 30, 2026
**Policy:** versions change only through a separate task and branch, a complete build, and a rollback plan.

## Installed and verified baseline

| Component | Version / path | Status |
|---|---|---|
| Unreal Engine | 5.8.2, changelist 56702186 | verified |
| Engine root | `F:/UE_5.8.2/UE_5.8` | verified |
| Project root | `F:/BrokenStreets` | verified |
| Visual Studio | Community 2026, 18.9.1 | verified |
| Toolset | MSVC v14.50 x64/x86 from `.vsconfig` | installed |
| Primary Windows SDK | 10.0.22621.0 | installed |
| Additional Windows SDKs | 10.0.26100.0, 10.0.28000.0 | installed; do not change the implicit baseline |
| Git | 2.53.0.windows.3 | verified |
| Git LFS | 3.7.1 | verified locally in the repository |
| Target platform | Win64 Desktop | fixed for v1 |

Engine Source and Editor Symbols are installed for inspection and debugging. The installed engine is not modified.

## Targets and configurations

| Purpose | Target | Platform | Configuration |
|---|---|---|---|
| normal Editor work | `BrokenStreetsEditor` | Win64 | Development |
| gameplay debugging when needed | `BrokenStreetsEditor` | Win64 | DebugGame |
| packaged profiling | `BrokenStreets` | Win64 | Development |
| release candidate | `BrokenStreets` | Win64 | Shipping |

`Debug Editor` is not the normal workflow. Shipping must not contain unintended automation or debug tooling.

## Reference build command

For automated verification with Unreal Editor closed:

```powershell
& 'F:\UE_5.8.2\UE_5.8\Engine\Build\BatchFiles\Build.bat' BrokenStreetsEditor Win64 Development '-Project=F:\BrokenStreets\BrokenStreets.uproject' -WaitMutex -NoHotReloadFromIDE
```

This reference command passed in the BS-007A clean clone. BS-009 wraps it in a repeatable action with a clear log and exit code. A manual Visual Studio build remains available to the creator.

## Canonical BS-009 runner

With Unreal Editor closed, the normal complete verification command is:

```powershell
.\Tools\BS.cmd All
```

Available actions are `Doctor`, `Generate`, `Build`, `Test`, `Validate`, `Cook`, and `All`. `Test`, `Validate`, and `Cook` automatically build the Editor target first so they cannot accidentally verify a stale C++ DLL. Use `-PlanOnly` to preview without launching Unreal processes.

The runner discovers the engine without a script-hard-coded path, but accepts only the version and changelist pinned in `Tools/Build/RunnerConfig.json`. It runs `UnrealBuildTool.dll` through the engine's bundled DotNet runtime, avoiding the apphost path that may display the generic `.NET 0xe0434352` dialog without explaining inaccessible caches or logs. Before launch, `Doctor` verifies that local UBT roots are writable, then probes the bundled runtime, effective Win64 SDK, Visual Studio 18, MSVC 14.50, `cl.exe`, `link.exe`, and the CRT library.

Each run writes `run.json`, a runner log, and per-step logs under `Saved/Automation/BS-009/<run-id>/`. After BS-010, zero matching project tests is a failure. `SKIPPED_NO_ASSETS` remains visible until BS-011. During Cook, `Packages Skipped by Platform` is accepted only when every entry has an allowed reason, the classified total equals the UE total, and every omitted package is Engine-owned. Any deviation or project-owned omission blocks the gate.

External processes are contained by a Windows Job Object with `KILL_ON_JOB_CLOSE`. Timeout handling combines that job with a PID snapshot and `taskkill /T`, then requires zero active processes before reporting confirmed termination. `Tools/Tests/Runner.SelfTest.ps1` covers an orphaned grandchild process, native exit-code propagation, and atomic JSON summary writing.

## Regenerating Visual Studio files

Creator workflow:

1. Close Unreal Editor and Visual Studio.
2. Open File Explorer at `F:\BrokenStreets`.
3. Right-click `BrokenStreets.uproject`.
4. Select `Generate Visual Studio project files`.
5. Wait for completion and open `BrokenStreets.sln`.

If the option is missing, do not modify registry entries or associations at random. Send a screenshot; Codex will use the exact installed engine utility.

`.sln`, `.vs/`, `Binaries/`, and `Intermediate/` are reproducible and are not committed.

The associated Epic Launcher installation utility is:

```powershell
& 'C:\Program Files\Epic Games\Launcher\Engine\Binaries\Win64\UnrealVersionSelector.exe' /projectfiles 'F:\BrokenStreets\BrokenStreets.uproject'
```

Do not assume `GenerateProjectFiles.bat` exists in a Launcher-installed engine; the BS-007A clean clone proved that this installation does not contain it.

### Portability to another profile or PC

The `EngineAssociation` value in `.uproject` may be a GUID registered only on the current machine. On a new profile or PC:

- install and verify exactly UE 5.8.2;
- build and open through `Build.bat` and `UnrealEditor.exe` from that engine's absolute path;
- associate the project locally with the exact version only for Explorer/IDE integration;
- do not commit an association change caused only by recovery;
- BS-009 pins and tests project generation independently from Explorer; BS-007B validates it on another profile or PC.

## Live Coding

Live Coding may be used only for small, approved changes inside a `.cpp` body that do not alter layout, reflection, or schema.

Close the Editor and perform a full build for:

- `UCLASS`, `USTRUCT`, `UENUM`, `UPROPERTY`, or `UFUNCTION`;
- header files and module/build dependencies;
- sensitive constructor or default-subobject changes;
- save schema, serialization, and migrations;
- replication layout;
- plugin activation;
- suspicious errors after Live Coding.

## Pinning and upgrades

- `BrokenStreets.uproject` remains associated with UE 5.8.2 until an explicit milestone.
- Do not open the working branch in another engine version “for testing.”
- An upgrade uses a separate branch, backup, clean build/cook, migration tests, asset validation, and before/after benchmarks.
- Never save assets converted by a new version over the stable branch.

## PC renderer configuration baseline

BS-013B replaced wizard defaults with the accepted reversible test path:

- project-owned Editor/game/server startup map;
- Win64 DX12/SM6;
- Software Lumen, Virtual Shadow Maps, Nanite support, TSR, and Substrate Blendable GBuffer;
- project hardware ray tracing disabled;
- Android File Server explicitly disabled with no generated token;
- `BS-PC-Recommended-P0` at 1920×1080 High, 100% screen percentage, VSync Off, and Dynamic Resolution Off.

Run `Tools\BS-RendererBaseline.cmd Audit` after configuration changes. Run `Tools\BS-RendererBaseline.cmd All` only for an intentional clean candidate that must be audited, packaged, and captured. A renderer or preset change invalidates prior evidence until Build/Test/Validate/Cook, exact-map package, and performance gates are repeated.

## Build evidence

Record in the task packet:

- candidate commit hash and, if a later commit changes evidence/docs only, the verified runtime/content tree;
- target/platform/configuration;
- engine version;
- `Succeeded/Failed` result;
- count of new warnings;
- relevant log path;
- date and executor.

“The Editor opened” does not replace an explicit build when a task changes structural C++.

Build evidence proves only the verified candidate or tree. Any later change to C++, Config, Content, `.uproject`, plugins, or build scripts marks that evidence `INVALIDATED` and requires the affected checks again. A later status/evidence-only commit may retain the evidence if it explicitly identifies the candidate and does not change runtime inputs.
