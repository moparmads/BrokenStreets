# Broken Streets — comenzi de proiect

BS-009 oferă un singur punct de intrare pentru verificările locale. Runnerul este compatibil cu Windows PowerShell 5.1, nu instalează nimic și nu modifică Unreal Engine.

## Comanda normală

1. Închide Unreal Editor.
2. Deschide PowerShell în `F:\BrokenStreets`.
3. Rulează:

```powershell
.\Tools\BS.cmd All
```

La final trebuie să apară `Rezultat final: PASS_WITH_SKIPS` până când BS-010 adaugă primul test și BS-011 adaugă primele asset-uri. `Test` și `Validate` își declară explicit lipsa temporară de conținut, iar Cook poate raporta separat numai omisiuni Engine clasificate; nimic din acestea nu este mascat ca PASS simplu.

## Acțiuni

| Acțiune | Ce verifică/produce |
|---|---|
| `Doctor` | proiectul, UE 5.8.2 CL 56702186, .NET inclus, Win64 SDK 10.0.22621.0, VS 18/MSVC 14.50, procesele, permisiunile UBT și spațiul liber |
| `Generate` | regenerează `.sln` și `.slnx` |
| `Build` | compilează `BrokenStreetsEditor Win64 Development` |
| `Test` | compilează mai întâi, apoi rulează numai testele `BrokenStreets`; momentan `SKIPPED_NO_TESTS` |
| `Validate` | compilează mai întâi, apoi verifică asset-urile project-owned; momentan `SKIPPED_NO_ASSETS` |
| `Cook` | compilează mai întâi, apoi face cook local pentru `Windows`, fără stage/package |
| `All` | Doctor → Generate → Build → Test → Validate → Cook, fail-fast |

Exemplu pentru o singură verificare:

```powershell
.\Tools\BS.cmd Build
```

Previzualizare fără să lanseze Unreal:

```powershell
.\Tools\BS.cmd All -PlanOnly
```

## Engine discovery

Ordinea este:

1. parametrul opțional `-EngineRoot`;
2. variabila locală `BROKENSTREETS_UE_ROOT`;
3. EngineAssociation înregistrat local;
4. manifestele Epic Games Launcher.

Runnerul acceptă numai versiunea fixată în `Tools/Build/RunnerConfig.json`. O cale explicită greșită produce fail; nu selectează silențios alt engine.

Automatizarea lansează `UnrealBuildTool.dll` prin runtime-ul DotNet inclus de engine, nu executabilul apphost `UnrealBuildTool.exe`. Astfel evită ruta secundară care a afișat excepția generică `.NET 0xe0434352` în Visual Studio, în timp ce build-ul real era reușit.

În UE 5.8, `Packages Skipped by Platform` poate include pachete exclusiv pentru Editor. Runnerul le raportează ca `PASS_WITH_SKIPS` numai dacă procesul nativ a ieșit cu 0, footer-ul Unreal confirmă `0 error(s)`, outputul Cook există, fiecare omisiune corespunde unui motiv permis, numărul clasificat este exact cel raportat de UE și toate pachetele sunt Engine-owned. Orice omisiune necunoscută sau project-owned, cod nativ nenul, footer cu erori ori output incomplet rămâne fail.

Fiecare proces extern este izolat imediat într-un Windows Job Object cu `KILL_ON_JOB_CLOSE`. La timeout, runnerul folosește și un snapshot PID plus `taskkill /T` ca verificare/fallback, apoi confirmă că job-ul nu mai conține procese active. Aceeași curățare este verificată după un cod nativ nenul. Astfel, un proces copil rămas fără părintele intermediar nu poate continua în fundal.

Self-testul runnerului, destinat verificării după modificări în `Tools/`, se rulează cu:

```powershell
.\Tools\Tests\Runner.SelfTest.ps1
```

El verifică argumentele native, propagarea exactă a codului de ieșire, timeout-ul `124`, oprirea unui proces nepot orfan și scrierea atomică UTF-8 a `run.json`.

## Loguri și erori

Fiecare rulare creează:

```text
Saved/Automation/BS-009/<run-id>/
├── run.json
├── runner.log
└── Steps/
    └── NN-Action/
        ├── command.txt
        ├── stdout.log
        ├── stderr.log
        ├── combined.log
        └── Unreal.log / TestReport (unde se aplică)
```

`Saved/` este ignorat de Git. La fail, trimite captura cu rezultatul și calea `Log:` ori `Sumar:` afișată; Codex poate identifica exact etapa și codul.

Codurile runnerului:

- cod nativ nenul: păstrat nemodificat;
- `20`: preflight/Doctor;
- `21`: procesul a întors 0, dar markerii reali UE arată rezultat invalid sau incomplet;
- `70`: eroare internă ori proces care nu poate porni;
- `124`: timeout; este oprit și verificat numai grupul de procese lansat de runner.
