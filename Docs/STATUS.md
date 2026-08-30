# Starea proiectului

**Actualizat:** 28 august 2026
**Milestone curent:** Fundație recuperabilă
**Branch activ:** `feature/BS-009-build-automation`

## Rezumat

- Ultimul task complet: `BS-008` — memoria proiectului, arhitectura, roadmapul și workflow-ul Codex.
- Task activ: `BS-009` — acțiuni repetabile Build/Test/Validate/Cook.
- Următorul task după BS-009: `BS-010` — primul Automation smoke test.

## Ce există efectiv

- proiect Unreal Engine 5.8.2 Blank C++;
- un singur modul runtime `BrokenStreets`;
- build `Development Editor | Win64` reușit manual;
- Git, Git LFS, branch `main` și remote privat funcționale;
- fără cod gameplay Broken Streets;
- fără asset-uri `.uasset`/`.umap` proprii proiectului;
- fără TestGym, teste automate, multiplayer, save ori sisteme de joc;
- harta implicită este încă template-ul Engine `/Engine/Maps/Templates/OpenWorld`.

## Baseline-uri verificate

- Runtime baseline: `f1b5648` — `chore: initialize Broken Streets Unreal project`.
- Build manual: reușit, `1 succeeded, 0 failed`, la 28 august 2026.
- BS-007A clean clone: `main` clonat într-un folder temporar separat; Git LFS pull și status clean.
- Solution generation: reușită prin `UnrealVersionSelector.exe` din Epic Games Launcher.
- Clean-clone build: `Result: Succeeded`, 7/7 actions, 38,87 secunde, MSVC 14.50 + Windows SDK 10.0.22621.0.
- Headless Editor initialization: engine inițializat, template map încărcat și Map Check `0 Error(s), 0 Warning(s)`. Procesul de primă pornire a continuat mentenanța DDC după comanda Quit și a fost oprit controlat după ce criteriul de încărcare trecuse; shutdown automation se standardizează în BS-009.
- Project-memory candidate: `b3115494e0568342278fa18a2f89f5f9aa386332`, tree `8339f1a6151eb4158b257dfbea5854ada639e3e4`.
- BS-008: 36 fișiere/4.118 linii de documentație, 0 linkuri locale rupte, `AGENTS.md` 13.688 bytes, Git și Git LFS fsck PASS, fără schimbări C++/Config/Content.
- GitHub: branch-ul BS-008 și `main` au fost împinse; la închidere, `main` local și `origin/main` sunt verificate identice.

## Abateri și lucruri deschise

- `Config/DefaultEngine.ini` are momentan `r.RayTracing=True`; roadmapul presupunea Ray Tracing Off. Nu se schimbă până la un task de configurare/benchmark explicit.
- `F:/BrokenStreets_SourceArt` există, dar backup-ul 3-2-1 și restore drill-ul nu sunt încă verificate.
- Nu există încă obiecte Git LFS; acest lucru este normal cât timp proiectul nu are asset-uri Unreal proprii.
- Clean clone-ul fără folder `Content/` a produs un warning baseline `DirectoryWatcher` pentru calea lipsă; BS-011 îl elimină natural când creează prima hartă project-owned. Map Check-ul a rămas 0/0.
- Nu există încă backup independent al tuturor refs și obiectelor Git LFS; `BS-010A` îl configurează și îl testează fără GitHub înainte de asset-uri importante.
- Recovery complet cu TestGym, smoke tests, cook și LFS este `BS-007B`; depinde de `BS-009`, `BS-010`, `BS-010A`, `BS-011`, `BS-012`, `BS-013` și `BS-013B`. Recovery-ul de save începe separat după BS-020.

## Criteriul pentru actualizare

Actualizează acest document numai cu fapte verificate: commit, build, test, asset sau sistem existent. Nu muta un task în `Done` doar fiindcă documentația ori codul a fost scris.
