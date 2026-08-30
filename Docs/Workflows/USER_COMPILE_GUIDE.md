# Compilation Guide for Madalin

This is the normal workflow after Codex changes C++. You never need to write or repair code.

## Before starting

Codex must explicitly state one of:

- `Unreal Editor must be closed` — the default for headers, reflection, modules, networking layout, save, or serialization;
- `Unreal Editor may remain open` — only for a verified small change;
- `Use Live Coding` — only when Codex explains exactly why the change is safe.

If no state is given, close Unreal Editor before building. Save assets when prompted only when they are known intentional changes.

## Normal Visual Studio build

1. Close Unreal Editor.
2. Open File Explorer.
3. Navigate to `F:\BrokenStreets`.
4. Open `BrokenStreets.sln`.
5. Wait until Visual Studio finishes loading the solution and no important restore or indexing operation remains.
6. In the top bar, set `Solution Configurations` to `Development Editor`.
7. Set adjacent `Solution Platforms` to `Win64`.
8. In `Solution Explorer`, expand `Games`.
9. Right-click the `BrokenStreets` project under `Games`.
10. Click `Build`.
11. Open the bottom `Output` tab if it is not visible.
12. Set `Show output from` to `Build`.
13. Wait for the final summary.

### PASS

Output ends with:

- `Result: Succeeded` or equivalent;
- `Build: 1 succeeded, 0 failed`, or another summary with no failed project;
- zero errors.

An `up-to-date` target with no error is acceptable.

### FAIL

If `failed`, `error C...`, `UnrealHeaderTool failed`, or a stopped window appears:

1. Do not change files or search for a code fragment yourself.
2. Do not click `Clean Solution` and do not delete folders.
3. In `Output`, select everything from `Build started` through the final summary.
4. Copy the complete text and send it to Codex.
5. If it is too large, save it to a `.txt` file and attach it.
6. Include a screenshot of the first error, but the complete text log is more important.

The Unreal Build Tool log is usually:

`C:\Users\madal\AppData\Local\UnrealBuildTool\Log.txt`

Send it only when Codex requests it or the Output is incomplete.

## After a successful build

1. Close Visual Studio only if desired.
2. Open `F:\BrokenStreets\BrokenStreets.uproject`.
3. If Unreal asks to rebuild modules, stop and send a screenshot; the explicit build should already be sufficient.
4. Follow the exact manual test supplied by Codex.
5. Return the PASS result or the requested screenshot/log on FAIL.

## When not to use Live Coding

Do not press `Ctrl+Alt+F11` for:

- new Unreal classes, structures, or enums;
- changes to `UPROPERTY`, `UFUNCTION`, `UCLASS`, `USTRUCT`, or `UENUM`;
- `.h`, `.Build.cs`, Target.cs, plugin, or module changes;
- replicated property or RPC layout;
- save schema, serialization, or migration;
- constructor or default-subobject changes;
- crashes or suspicious state after a prior patch.

For these changes, close the Editor and run the complete build above.

## What not to do manually

- do not paste code into Visual Studio;
- do not edit `.Build.cs`, configuration, or `.uproject`;
- do not click `Rebuild Solution` unless the task explicitly requires it;
- do not build the `UE5` project or all 59+ projects in the solution;
- do not delete `Binaries`, `Intermediate`, or `Saved` as a first response;
- do not select another Unreal version.

Codex will provide exact instructions whenever an exceptional case requires another action.
