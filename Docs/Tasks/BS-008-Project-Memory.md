# BS-008 — Project memory and agent workflow

**Status:** In Progress
**Owner:** Madalin Gavrila
**Branch:** `docs/BS-008-project-memory`
**Base commit:** `f1b5648`
**Roadmap milestone:** M1B

## Observable outcome

Orice task Codex pornit din `F:/BrokenStreets` găsește reguli consistente despre produs, arhitectură, ownership, C++/Blueprint, task workflow, testare, performance, Git, recovery și următorul pas, fără ca Madalin să repete contextul.

## Why now

Repository-ul și baseline-ul C++ există. Memoria trebuie fixată înainte de primul cod propriu pentru a evita sisteme contradictorii și pași manuali vagi.

## In scope

- root `AGENTS.md` și `README.md`;
- documente canonice și index/status;
- roadmap corectat pentru dependențe;
- architecture/system ownership;
- task/system/ADR templates;
- build, Git, recovery, test și performance workflow;
- clean-room/reference policy;
- versionare și GitHub sync.

## Out of scope

- schimbări C++/Config/Content;
- map, TestGym, build scripts și automation code;
- renderer/plugin activation changes;
- implementarea oricărui sistem gameplay;
- backup fizic Source Art.

## Dependencies

- BS-001–BS-006 Done;
- official Codex AGENTS.md discovery guidance reviewed;
- existing 200-question decision register and roadmap audited;
- current project/toolchain/config inspected.

## Allowed files/domains

- `AGENTS.md`, `README.md`, `Docs/**` numai.

## Network/persistence/performance impact

Documentație only; N/A pentru runtime. Regulile rezultate sunt constraints pentru task-urile viitoare.

## Acceptance criteria

1. Din root, agentul identifică owner workflow și limba de comunicare.
2. Poate indica sursa de adevăr pentru produs, arhitectură, sistem, status și roadmap.
3. Rezumă corect limita C++/Blueprint și single-writer ownership.
4. Folosește topologia exactă `1 host + max 3 clients = 4 players total`.
5. Identifică BS-007A ca recovery simplu și BS-009 ca următorul tooling task.
6. Nu declară gameplay existent.
7. Toate linkurile locale relative și documentele obligatorii există.
8. `AGENTS.md` rămâne sub limita implicită de 32 KiB.
9. Git diff conține numai documentație, fără fișiere generate/secrete.
10. Commitul este sincronizat pe repository-ul privat.

## Verification

- markdown/file/link audit;
- terminology/conflict search;
- AGENTS byte count;
- Git status/diff check;
- BS-007A clean clone/build/Editor initialization evidence trecut pe baseline `f1b5648`;
- no Unreal build required deoarece nu se schimbă C++/Config/Content.

## Risks and rollback

- risc: documentație prea mare ori duplicată; atenuare prin INDEX, docs JIT și surse canonice;
- risc: propuneri tratate ca decizii; atenuare prin status explicit și PENDING_DECISIONS;
- rollback: revert commitul BS-008; base `f1b5648` rămâne baseline.
