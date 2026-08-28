# Standardul instrucțiunilor Unreal Editor

Orice pas manual pentru Madalin respectă acest format. UI labels sunt scrise exact în engleză; explicația este în română.

## Header obligatoriu

```text
Goal:
Applications needed:
Unreal Editor state: Open / Closed
Visual Studio state: Open / Closed / Not needed
Expected duration:
Files/assets that will be created or modified:
Do not touch:
```

## Reguli

- o singură acțiune per pas;
- meniu/tab/button/field exact;
- valoarea exactă, inclusiv spelling/case;
- calea exactă unde se salvează asset-ul;
- ce trebuie să apară după pas;
- checkpoint înainte de o operație ireversibilă ori bulk;
- alternative numai dacă UI-ul chiar diferă;
- nu cere „configurează”, „setează corect” ori „creează Blueprint-ul necesar” fără pașii compleți;
- nu cere creatorului să creeze noduri de gameplay autoritativ ca workaround.

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

## Handoff final

```text
PASS criteria:
1. ...
2. ...

If PASS, send:
- confirmation / screenshot / log requested.

If FAIL, send:
- full Output Log section from ... to ...;
- screenshot of ...;
- do not save/close/change ... until Codex replies.

Rollback:
- exact safe action or commit; never vague deletion.
```

## Asset naming și location

Instrucțiunea include întotdeauna:

- asset class/template;
- name cu prefix;
- path sub `/Game/BS/...`;
- parent/class/data source;
- properties ce rămân default;
- Save All checkpoint;
- Data Validation ori testul relevant.

## Exemplu acceptabil

```text
1. In Unreal Editor, click File > New Level.
   Select Empty Level.
   Expected: a new untitled empty level opens.

2. Click File > Save Current Level As.
   Folder: /Game/BS/Maps/Test
   Name: L_TestGym_Core
   Expected: Content Browser shows L_TestGym_Core in that folder.
```

Exemplul nu autorizează crearea hărții până când task-ul relevant este activ.
