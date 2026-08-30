# Task packets

Fiecare rezultat implementabil are un ID stabil `BS-###` și un singur document activ. Task-ul descrie rezultat, scope și dovadă; roadmapul descrie ordinea.

## Stări

```text
Draft → Ready → In Progress → Needs Owner Verification → Done
              ↘ Blocked / Needs Decision
                         ↘ Verification Failed → In Progress
```

- `Draft`: lipsesc dependențe, decizii ori acceptarea.
- `Ready`: Definition of Ready este completă.
- `In Progress`: branch activ și schimbări în lucru.
- `Needs Owner Verification`: Codex a verificat ce poate; Madalin are pași exacți de build/playtest.
- `Verification Failed`: log/captură arată eșec; task-ul revine la implementare.
- `Blocked / Needs Decision`: o alegere materială sau dependență externă împiedică progresul.
- `Done`: toate cerințele universale și cele condiționale relevante au dovadă, status/docs/commit sunt sincronizate.

Cod scris nu înseamnă `Done`.

## Definition of Ready

Înainte de cod:

- rezultat observabil și motivul pentru care vine acum;
- in scope/out of scope;
- owner de domeniu și dependențe;
- authority/audience pentru multiplayer;
- persistence/migration impact;
- performance/update model;
- Blueprint/Editor surface;
- decizii materiale acceptate ori default reversibil declarat;
- criterii Given/When/Then;
- verificări automate/manuale și rollback.

## Reguli

- Nu combina sisteme independente într-un task mare doar pentru comoditate.
- Un task poate avea subtask-uri, dar păstrează un singur outcome coerent.
- Un bug important primește regression test când este fezabil.
- Un ID deja implementat nu se reutilizează pentru alt rezultat.
- Fișierele task-urilor Done pot rămâne ca evidence; Git păstrează istoricul.

## Index

| Task | Titlu | Status | Branch |
|---|---|---|---|
| BS-008 | Project memory and agent workflow | Done | `main` |
| [BS-009](BS-009-Build-Automation.md) | Automatizare Build/Test/Validate/Cook | In Progress | `feature/BS-009-build-automation` |
