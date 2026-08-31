# BS-014A — Portable Unreal Engine Association

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `fix/BS-014A-portable-engine-association`
**Base commit:** `416ef367b4854c9846d7c6408e14d3965d90c858`
**Roadmap milestone:** M2 — Minimum core and observability, infrastructure correction

## Observable outcome

Double-clicking `BrokenStreets.uproject` opens the project directly in the installed Epic Launcher Unreal Engine 5.8 line instead of showing `Select Unreal Engine Version` on every launch.

The tracked association is the portable Launcher release key `5.8`, not a per-user registered-build GUID. The exact supported toolchain remains Unreal Engine 5.8.2, changelist 56702186, pinned and verified separately by the project runner.

## Why now

BS-014 creator acceptance exposed a repeated version-selection dialog. Selecting the visible 5.8 option opened the project successfully but rewrote `EngineAssociation` from a local GUID to `5.8`. The Epic Launcher manifest identifies the installed engine as `UE_5.8`, version `5.8.2-56702186`, at `F:/UE_5.8.2/UE_5.8`. Committing the standard release association removes dependence on a user-specific GUID while preserving the exact verified engine line.

## In scope

- replace the tracked per-user GUID with `"EngineAssociation": "5.8"`;
- document how Launcher release associations differ from custom registered-build GUIDs;
- rerun the complete Generate/Build/Test/Validate/Cook gate because `.uproject` is a runtime input;
- confirm one normal File Explorer double-click opens directly without the version picker;
- synchronize GitHub and the independent repository backup after acceptance.

## Out of scope

- changing or upgrading Unreal Engine;
- editing Engine Source, Windows registry, Epic Launcher manifests, plugins, C++, Config, maps, or assets;
- changing the pinned UE 5.8.2 changelist or runner discovery rules;
- claiming portability to a PC where the UE 5.8 Launcher release is not installed.

## Acceptance criteria

1. **Given** the tracked project file, **when** `EngineAssociation` is inspected, **then** it is exactly `5.8` and contains no machine-specific GUID.
2. **Given** the installed Epic Launcher manifest, **when** the project runner performs Doctor and the complete gate, **then** it resolves UE 5.8.2 changelist 56702186 and Generate, Build, Test, Validate, and Cook pass under the existing rules.
3. **Given** Unreal Editor is closed, **when** Madalin Gavrila double-clicks `BrokenStreets.uproject` in File Explorer, **then** Unreal Editor opens the project directly without displaying `Select Unreal Engine Version`, a module rebuild prompt, or a crash dialog.
4. **Given** a future PC or Windows profile, **when** the matching Epic Launcher UE 5.8 release is installed, **then** the project does not require the original per-user registered-build GUID.

## Automated verification

- inspect `.uproject` JSON and exact association value;
- confirm the Epic Launcher manifest reports `UE_5.8`, UE 5.8.2 CL 56702186, and the expected install path;
- `Tools/BS.cmd All`;
- `git diff --check`, documentation link audit, Git/LFS status and fsck.

## Manual acceptance

Unreal Editor state: closed before the test.

1. Open File Explorer at `F:\BrokenStreets`.
2. Double-click `BrokenStreets.uproject` once.
3. Confirm Unreal Editor opens `BrokenStreets` directly and the version-selection dialog does not appear.
4. Close Unreal Editor normally with `Alt+F4`.

PASS: the project opens directly in UE 5.8.2 with no version picker, module rebuild prompt, or crash dialog.

FAIL: any selector, rebuild prompt, wrong engine, or crash appears. Close the dialog without choosing another engine and send a screenshot.

## Risks and rollback

- Base/rollback: `416ef367b4854c9846d7c6408e14d3965d90c858`.
- A computer without the matching Launcher release still requires UE 5.8 installation; this task does not hide a missing toolchain.
- A future source-built engine may require an intentionally registered GUID in a separate upgrade/toolchain task.
- Rollback is a normal revert of this task followed by the complete project gate.

## Verification evidence

| Date | Commit/state | Evidence | Result | Executed by |
|---|---|---|---|---|
| 2026-08-31 | pre-change `main` `416ef367b4854c9846d7c6408e14d3965d90c858` | repeated creator version picker; selecting 5.8 opened the project; Epic manifest `UE_5.8`, version `5.8.2-56702186`, install `F:/UE_5.8.2/UE_5.8`; pre-change backup `20260831T110926Z-11592-72ea6520`, 25 refs and 3 LFS objects | Root cause confirmed; corrective candidate pending | Madalin Gavrila and Codex |

## Final handoff

- accepted portable association and exact candidate commit;
- complete automated gate summary;
- creator double-click PASS/FAIL;
- merge, GitHub parity, and final backup generation;
- rollback commit and next task BS-015.
