# BS-009 — Automatizare Build/Test/Validate/Cook

**Status:** Done
**Owner:** Madalin Gavrila
**Branch:** `feature/BS-009-build-automation`
**Base commit:** `0de0648e070f58c7d095fc5dba2468a5c7eb7b8c`
**Roadmap milestone:** M0 — Fundație recuperabilă
**System docs:** [Toolchain](../Build/TOOLCHAIN.md), [Test strategy](../Testing/TEST_STRATEGY.md), [Task workflow](../Workflows/CODEX_TASK_WORKFLOW.md)

## Observable outcome

Din orice terminal aflat în repository, creatorul poate porni `Doctor`, `Generate`, `Build`, `Test`, `Validate`, `Cook` sau `All` printr-o singură comandă. Fiecare rulare afișează un rezultat scurt, întoarce un cod de ieșire corect și păstrează local logurile și sumarul JSON.

## Why now

BS-009 transformă build-ul manual verificat în BS-007A într-un gate repetabil. Deblochează primul smoke test (BS-010), TestGym (BS-011), recovery complet (BS-007B) și toate schimbările C++ ulterioare.

## In scope

- runner Windows PowerShell 5.1 fără dependențe externe;
- descoperire deterministă și validare exactă UE 5.8.2, changelist 56702186;
- acțiuni `Doctor`, `Generate`, `Build`, `Test`, `Validate`, `Cook`, `All`;
- timeout și terminarea strictă a arborelui procesului lansat;
- propagarea codurilor native și coduri distincte pentru eșecuri semantice/timeout;
- loguri locale și sumar JSON sub `Saved/Automation/BS-009/`;
- clasificare explicită `SKIPPED_NO_TESTS` până la BS-010 și `SKIPPED_NO_ASSETS` până există asset-uri project-owned;
- documentație de utilizare și evidence.

## Out of scope

- primul Automation smoke test (BS-010);
- prima hartă și asset-uri project-owned (BS-011);
- staging, packaging, archive ori distribuție;
- CI cloud, servere dedicate sau platforme non-Windows;
- modificarea EngineAssociation, a engine-ului instalat, a gameplay-ului, Config sau Content.

## Dependencies and required decisions

- BS-008 este Done;
- baseline-ul este UE 5.8.2 / CL 56702186 și Visual Studio 2026;
- cook-ul BS-009 este commandlet local pentru platforma `Windows`, fără stage/package;
- testele zero și validarea zero asset-uri sunt stări temporare vizibile, nu rezultate PASS false;
- un `EngineRoot` explicit invalid produce fail și nu cade silențios pe alt engine.

## Allowed files/domains

- `Tools/`;
- `Docs/Build/TOOLCHAIN.md`;
- `Docs/Tasks/`;
- `Docs/STATUS.md`.

Sunt interzise schimbări în `Source/`, `Config/`, `Content/`, `.uproject`, pluginuri și engine.

## Authority/network impact

N/A — tooling local, fără networking și fără schimbări de authority/replication.

## Persistence/migration impact

N/A — nu atinge save data. Outputurile sunt regenerabile și ignorate de Git sub `Saved/`.

## Performance budget

- runnerul nu face polling mai des de 250 ms și nu rămâne rezident după rulare;
- un singur runner poate opera repository-ul la un moment dat;
- timeout implicit: Generate 10 min, Build 60 min, Test 30 min, Validate 30 min, Cook 120 min;
- Cook nu folosește `CookAll`, iterative cook, stage sau package.

## Blueprint/Editor impact

Niciun Blueprint și niciun asset. Unreal Editor trebuie închis pentru acțiunile reale; toate comenzile sunt headless.

## Acceptance criteria

1. **Given** repository-ul pe acest PC **When** rulează `Doctor` **Then** proiectul, UE 5.8.2/CL 56702186, toolchain-ul și spațiul de lucru sunt verificate fără cale de engine hard-coded în script.
2. **Given** fișierele de soluție sunt regenerabile **When** rulează `Generate` **Then** UnrealBuildTool termină cu 0, raportează `Result: Succeeded`, iar `.sln` și `.slnx` există.
3. **Given** targetul C++ curent **When** rulează `Build` **Then** `BrokenStreetsEditor Win64 Development` compilează și DLL-ul proiectului există.
4. **Given** BS-010 nu există încă **When** rulează `Test` **Then** markerii Unreal sunt verificați și rezultatul este `SKIPPED_NO_TESTS`, nu PASS fals.
5. **Given** nu există asset-uri project-owned **When** rulează `Validate` **Then** inventarul local și liniile `AssetCheck` din UE 5.8 produc `SKIPPED_NO_ASSETS`; orice asset invalid, imposibil de validat ori rezultat lipsă pentru asset-uri existente produce fail chiar dacă procesul întoarce 0.
6. **Given** configurația Win64 curentă **When** rulează `Cook` **Then** commandlet-ul `Cook` pentru `Windows` termină cu footer-ul `0 error(s)`, outputul rămâne sub `Saved/Cooked/Windows`, iar excluderile benigne raportate de UE ca `Packages Skipped by Platform` sunt păstrate explicit ca `PASS_WITH_SKIPS`.
7. **Given** o acțiune expiră sau procesul nativ eșuează **When** runnerul se încheie **Then** arborele PID lansat este oprit, codul nenul este păstrat și logul exact este indicat.
8. **Given** toate gate-urile sunt disponibile **When** rulează `All` **Then** ordinea este Doctor → Generate → Build → Test → Validate → Cook, fail-fast, cu un singur sumar JSON.

## Automated verification

- syntax/plan în Windows PowerShell 5.1;
- `Doctor` și `All` lansate prin `Tools/BS.cmd`;
- verificarea markerilor și a codurilor din logurile reale UE;
- verificare Git, Git LFS și linkuri locale de documentație;
- verificarea că diff-ul nu atinge domeniile interzise.

## Manual acceptance

Nu este necesar un playtest sau setup manual pentru Done. Creatorul primește o comandă simplă de rerulare; la fail trimite captura și calea logului afișată.

## Risks and rollback

- **Base:** `0de0648e070f58c7d095fc5dba2468a5c7eb7b8c`.
- Primul cook poate fi lung din cauza hărții Engine OpenWorld, DX12/SM6, Ray Tracing și Substrate existente în baseline.
- Runnerul nu șterge outputuri, nu schimbă engine association și nu omoară procese după nume.
- Rollback: revert-ul commiturilor BS-009; outputurile din `Saved/` rămân regenerabile și ignorate.

## Docs/ADR updates

- `Docs/Build/TOOLCHAIN.md` — comanda canonică și interpretarea rezultatelor;
- `Docs/STATUS.md` — progres și evidence verificată;
- `Docs/Tasks/README.md` — index.

## Verification evidence

| Data | Candidate commit | Runtime/content tree | Build/test/trace | Rezultat | Executat de |
|---|---|---|---|---|---|
| 30 august 2026 | `557ede8cc16cb1daedee2a1511a720dde79b6ade` | `d556d791e7fabdbbcf90b501f8f87f4d089dfcd3` | `Tools/Tests/Runner.SelfTest.ps1` | PASS — 5/5; argumente, cod nativ 37, timeout 124, proces nepot orfan și JSON atomic | Codex |
| 30 august 2026 | `557ede8cc16cb1daedee2a1511a720dde79b6ade` | același tree; fără C++/Config/Content | `Tools/BS.cmd All` — UE 5.8.2 CL 56702186, `BrokenStreetsEditor Win64 Development` | `PASS_WITH_SKIPS`, cod 0; Generate/Build PASS, Test 0 până la BS-010, Validate 0 asset-uri până la BS-011, Cook 578 + 7/7 omisiuni Engine clasificate, 0 warning-uri | Codex |

Evidence local canonic: `Saved/Automation/BS-009/20260830T083527Z-29808-a4d97f1e/run.json`. Outputurile rămân local, regenerabile și ignorate de Git. Probe suplimentare: Doctor PASS în `20260830T082922Z-31884-43180674`; `All -PlanOnly` PLANNED în `20260830T082938Z-12004-a95a98b1`.

Manual acceptance, networking, persistence și playtest: N/A — task exclusiv de tooling local, fără gameplay, C++, Config, Content sau asset-uri. Editorul a fost închis pentru verificările reale.

## Final handoff

- Candidate verificat: `557ede8cc16cb1daedee2a1511a720dde79b6ade`.
- Final evidence commit: commitul documentației care urmează imediat candidatului; hashul este fixat în commitul de închidere fără modificări de runtime/build scripts.
- Comandă creator: închide Unreal Editor și rulează `F:\BrokenStreets\Tools\BS.cmd All`.
- Rezultat așteptat înainte de BS-010/BS-011: `PASS_WITH_SKIPS`, cu skip-urile explicate mai sus; orice cod nenul sau `FAILED` se oprește și se raportează împreună cu linia `Sumar:`.
- Rollback sigur: revert-ul commiturilor BS-009 revine la baza `0de0648e070f58c7d095fc5dba2468a5c7eb7b8c`; fișierele generate din `Saved/`, `Binaries/` și soluțiile rămân regenerabile.
- Următorul task logic: BS-010 — primul Automation smoke test Broken Streets.
