# Unreal Editor Instruction Standard

Every manual step for Madalin follows this format. UI labels are written exactly in English; explanations to the creator are in Romanian.

## Required header

```text
Goal:
Applications needed:
Unreal Editor state: Open / Closed
Visual Studio state: Open / Closed / Not needed
Expected duration:
Files/assets that will be created or modified:
Do not touch:
```

## Rules

- one action per step;
- exact menu, tab, button, and field;
- exact value, including spelling and case;
- exact asset save path;
- expected result after each step;
- checkpoint before an irreversible or bulk operation;
- alternatives only when the UI genuinely differs;
- never say “configure,” “set it correctly,” or “create the required Blueprint” without complete steps;
- never ask the creator to build authoritative gameplay nodes as a workaround.

## Format

```text
1. In [application], click [menu] > [submenu].
   Expected: [exact panel/window/state].

2. In [panel], set [field] to [value].
   Expected: [exact result].

Checkpoint A
PASS if: ...
FAIL if: ...
If FAIL: stop; attach [screenshot/log/path]. Do not continue.
```

## Final handoff

```text
PASS criteria:
1. ...
2. ...

If PASS, send:
- requested confirmation, screenshot, or log.

If FAIL, send:
- complete Output Log section from ... to ...;
- screenshot of ...;
- do not save, close, or change ... until Codex replies.

Rollback:
- exact safe action or commit; never vague deletion.
```

## Asset naming and location

Instructions always include:

- asset class or template;
- prefixed name;
- path under `/Game/BS/...`;
- parent, class, or data source;
- properties that remain at default;
- Save All checkpoint;
- Data Validation or relevant test.

## Acceptable example

```text
1. In Unreal Editor, click File > New Level.
   Select Empty Level.
   Expected: a new untitled empty level opens.

2. Click File > Save Current Level As.
   Folder: /Game/BS/Maps/Test
   Name: L_TestGym_Core
   Expected: Content Browser shows L_TestGym_Core in that folder.
```

The example does not authorize creating the map before the relevant task is active.
