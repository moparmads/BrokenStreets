# Definition of Done

DoD este risk-based. Cerințele universale se aplică mereu; cerințele condiționale sunt completate sau marcate `N/A` cu motiv. Checkbox-uri executate fără relevanță nu cresc calitatea.

## A. Cerințe universale

- [ ] Outcome-ul observabil din task packet este atins.
- [ ] `git diff HEAD`, indexul staged și LFS status rămân în scope și păstrează modificările creatorului.
- [ ] Owner/invariante/dependențe respectă ARCHITECTURE și SYSTEM_OWNERSHIP.
- [ ] Verificarea cea mai relevantă a trecut.
- [ ] Nu există warning/log spam nou neexplicat.
- [ ] Failure paths și input bounds relevante sunt acoperite.
- [ ] Documentele, task packet-ul și STATUS sunt sincronizate cu realitatea.
- [ ] Base commit și rollback/revert plan sunt cunoscute.
- [ ] Pașii manuali sunt exacți și au fost executați dacă sunt necesari.
- [ ] Candidate commit/tree-ul verificat este notat; orice schimbare runtime ulterioară a invalidat și a rerulat dovada relevantă.
- [ ] Commitul este atomic; working tree este curat după commit.
- [ ] Creatorul a confirmat build/playtest pentru task-urile ce cer acceptance uman.

## B. C++ / reflection / module

Se aplică la `.h`, UHT/reflection, module, dependencies, serialization/replication layout:

- [ ] Unreal Editor închis înainte de build structural.
- [ ] `BrokenStreetsEditor | Win64 | Development` compilează.
- [ ] Noile warnings sunt zero ori justificate/aprobate.
- [ ] Live Coding artifacts nu sunt folosite ca dovadă.
- [ ] Shipping nu primește test/editor dependencies.

## C. Networking

Se aplică dacă feature-ul este replicat/autoritar:

- [ ] solo;
- [ ] 1 host + 1 client;
- [ ] 1 host + 3 clienți total patru jucători;
- [ ] împreună și separați dacă relevancy contează;
- [ ] late join;
- [ ] reconnect;
- [ ] disconnect mid-command;
- [ ] invalid/spam/stale input refuzat;
- [ ] latency/loss conform task-ului;
- [ ] audience/privacy și payload/bandwidth verificate;
- [ ] packaged multi-process la feature gate, nu numai PIE.

## D. Persistență/economie

- [ ] save/load/reload determinist;
- [ ] SchemaVersion/migration/golden data;
- [ ] truncated/corrupt/temp/manifest behavior;
- [ ] temp pe același volum, flush/read-back/checksum/atomic replace/manifest ordering;
- [ ] startup selectează cea mai nouă generație committed validă și raportează fallback-ul;
- [ ] crash/fault stages relevante înainte și după fiecare etapă I/O;
- [ ] duplicate TransactionId este idempotent;
- [ ] stale revision/ProfileEpoch conflict nu este rezolvat tăcut;
- [ ] absent character time nu avansează;
- [ ] rollback nu lasă două copies ori sold parțial;
- [ ] build/content/schema handshake.

## E. Performance/hot path

- [ ] benchmark scenario, hardware, preset, build și driver fixate;
- [ ] minimum trei rulări unde există variance;
- [ ] p50/p95/p99/max GT/RT/GPU și hitches după relevanță;
- [ ] working set/VRAM/loaded cells/actor counts/bandwidth după relevanță;
- [ ] before/after și trace păstrat;
- [ ] target/headroom trecut sau fallback/scope cut aprobat;
- [ ] Low nu elimină gameplay.

## F. Content/Blueprint/Editor

- [ ] naming/folder/DefinitionId valid;
- [ ] Data Validation;
- [ ] LFS lock obținut înainte de editare, pointerul staged verificat, obiectul remote confirmat și lock-ul eliberat după merge;
- [ ] source/license/manifest;
- [ ] Blueprint nu deține autoritate/persistență;
- [ ] soft references și load policy;
- [ ] collision/material/LOD/Nanite/HLOD budgets relevante;
- [ ] exact Editor setup și expected visual result.

## G. Gate/milestone

- [ ] clean clone/recovery;
- [ ] command-line build/test/validate/cook;
- [ ] packaged Development/Shipping-like;
- [ ] 1 host + 3 clients și hardware/network cerute;
- [ ] soak/fault/security/exploit audit cerut;
- [ ] docs/ADR/decision status final;
- [ ] rollback build/commit/tag unde roadmapul cere.

## H. Documentation-only

- [ ] link/file existence audit;
- [ ] terminology/status/source-of-truth consistency;
- [ ] niciun secret, generated file ori material extern neaprobat;
- [ ] AGENTS sub limita de discovery;
- [ ] `git diff HEAD` și lista staged conțin numai documentație;
- [ ] runtime build marcat `N/A` cu motiv.

## Evidence minim în task

```text
Candidate commit:
Verified runtime/content tree:
Final evidence/merge commit:
Engine/build target:
Commands/tests:
Manual acceptance:
Result:
Skipped/N/A and reason:
Warnings/risks:
Rollback:
```
