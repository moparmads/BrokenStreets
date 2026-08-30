# Toolchain canonic

**Actualizat:** 30 august 2026
**Politică:** versiunile se schimbă numai prin task/branch separat, build complet și plan de rollback.

## Baseline instalat și verificat

| Componentă | Versiune / cale | Status |
|---|---|---|
| Unreal Engine | 5.8.2, changelist 56702186 | verificat |
| Engine root | `F:/UE_5.8.2/UE_5.8` | verificat |
| Project root | `F:/BrokenStreets` | verificat |
| Visual Studio | Community 2026, 18.9.1 | verificat |
| Toolset | MSVC v14.50 x64/x86 din `.vsconfig` | instalat |
| Windows SDK principal | 10.0.22621.0 | instalat |
| Windows SDK suplimentare | 10.0.26100.0, 10.0.28000.0 | instalate; nu schimbă baseline-ul implicit |
| Git | 2.53.0.windows.3 | verificat |
| Git LFS | 3.7.1 | verificat local în repo |
| Platformă țintă | Win64 Desktop | fixată pentru v1 |

Engine Source și Editor Symbols au fost instalate pentru inspecție/debug. Engine-ul instalat nu se modifică.

## Ținte și configurații

| Scop | Target | Platform | Configuration |
|---|---|---|---|
| lucru normal în Editor | `BrokenStreetsEditor` | Win64 | Development |
| debug gameplay când este necesar | `BrokenStreetsEditor` | Win64 | DebugGame |
| packaged profiling | `BrokenStreets` | Win64 | Development |
| release candidate | `BrokenStreets` | Win64 | Shipping |

Nu folosim `Debug Editor` ca workflow normal. Shipping nu conține automation/debug tooling neintenționat.

## Build command de referință

Pentru verificare automatizată, cu Unreal Editor închis:

```powershell
& 'F:\UE_5.8.2\UE_5.8\Engine\Build\BatchFiles\Build.bat' BrokenStreetsEditor Win64 Development '-Project=F:\BrokenStreets\BrokenStreets.uproject' -WaitMutex -NoHotReloadFromIDE
```

Comanda de referință a trecut în clean clone-ul BS-007A. BS-009 o încapsulează într-o acțiune repetabilă, cu log și cod de ieșire clar; build-ul manual din Visual Studio rămâne disponibil pentru creator.

## Runnerul canonic BS-009

Cu Unreal Editor închis, comanda normală pentru verificarea completă este:

```powershell
.\Tools\BS.cmd All
```

Acțiunile disponibile sunt `Doctor`, `Generate`, `Build`, `Test`, `Validate`, `Cook` și `All`. `Test`, `Validate` și `Cook` compilează automat targetul Editor înainte de acțiunea cerută, astfel încât nu pot verifica accidental un DLL C++ vechi. O previzualizare fără procese Unreal se obține cu `-PlanOnly`.

Runnerul descoperă engine-ul fără o cale hard-coded în script, dar acceptă numai versiunea și changelist-ul fixate în `Tools/Build/RunnerConfig.json`. Pentru UBT folosește runtime-ul DotNet livrat cu engine-ul și `UnrealBuildTool.dll`; astfel evită executabilul apphost care poate afișa dialogul generic `.NET 0xe0434352` fără să explice lipsa de acces la cache/loguri. `Doctor` verifică înainte de lansare că rădăcinile locale UBT sunt inscriptibile, apoi probează runtime-ul inclus, Win64 SDK-ul efectiv, Visual Studio 18, toolset-ul MSVC 14.50, `cl.exe`, `link.exe` și biblioteca CRT.

Fiecare rulare scrie `run.json`, logul runnerului și loguri separate pe etapă sub `Saved/Automation/BS-009/<run-id>/`. Stările temporare `SKIPPED_NO_TESTS` și `SKIPPED_NO_ASSETS` sunt vizibile până la BS-010, respectiv BS-011. La Cook, `Packages Skipped by Platform` este acceptat numai când fiecare element are un motiv permis, totalul clasificat este identic cu totalul UE și toate pachetele sunt Engine-owned; orice abatere ori pachet project-owned blochează gate-ul.

Procesele externe sunt izolate prin Windows Job Object cu `KILL_ON_JOB_CLOSE`. Timeout-ul combină job-ul cu snapshot PID și `taskkill /T`, apoi cere zero procese active înainte de a raporta terminarea ca fiind confirmată. Self-testul din `Tools/Tests/Runner.SelfTest.ps1` acoperă inclusiv un proces nepot orfan, propagarea codurilor native și sumarul JSON atomic.

## Regenerarea fișierelor Visual Studio

Metoda pentru creator:

1. Închide Unreal Editor și Visual Studio.
2. Deschide File Explorer la `F:\BrokenStreets`.
3. Click dreapta pe `BrokenStreets.uproject`.
4. Selectează `Generate Visual Studio project files`.
5. Așteaptă finalizarea și deschide `BrokenStreets.sln`.

Dacă opțiunea lipsește, nu modifica registry sau association la întâmplare. Trimite o captură; Codex va folosi utilitarul engine-ului exact instalat.

Fișierele `.sln`, `.vs/`, `Binaries/` și `Intermediate/` sunt regenerabile și nu se comit.

Utilitarul asociat în instalarea Epic Launcher este:

```powershell
& 'C:\Program Files\Epic Games\Launcher\Engine\Binaries\Win64\UnrealVersionSelector.exe' /projectfiles 'F:\BrokenStreets\BrokenStreets.uproject'
```

Nu presupune existența `GenerateProjectFiles.bat` în engine-ul instalat prin Launcher; clean clone-ul BS-007A a demonstrat că acel fișier nu există în această instalare.

### Portabilitate pe alt profil/PC

Valoarea `EngineAssociation` din `.uproject` poate fi un GUID înregistrat numai local. Pe un profil/PC nou:

- instalează și verifică exact UE 5.8.2;
- pentru build/open folosește direct `Build.bat` și `UnrealEditor.exe` din calea absolută a acelui engine;
- asociază local proiectul cu versiunea exactă numai pentru integrarea Explorer/IDE;
- nu comite o schimbare de association produsă numai de recovery;
- BS-009 trebuie să fixeze și să testeze o comandă de project generation independentă de meniul Explorer; BS-007B o validează pe alt profil ori PC.

## Live Coding

Live Coding poate fi folosit numai pentru schimbări mici, aprobate, în corpul `.cpp`, fără layout/reflection/schema.

Editorul trebuie închis și se face build complet pentru:

- `UCLASS`, `USTRUCT`, `UENUM`, `UPROPERTY`, `UFUNCTION`;
- header files și module/build dependencies;
- constructor/default subobject changes sensibile;
- save schema, serialization și migrations;
- replication layout;
- plugin activation;
- erori suspecte după Live Coding.

## Pinning și upgrade

- `BrokenStreets.uproject` rămâne asociat cu UE 5.8.2 până la un milestone explicit.
- Nu se deschide proiectul cu altă versiune „pentru test” pe branch-ul de lucru.
- Upgrade-ul folosește branch separat, backup, clean build/cook, migration tests, asset validation și benchmark before/after.
- Nu se salvează asset-uri convertite într-o versiune nouă peste branch-ul stabil.

## Config baseline ce necesită task explicit

Wizardul a lăsat active opțiuni ce nu sunt încă decizii de produs:

- Ray Tracing;
- Substrate;
- configurație Android File Server într-un proiect PC-only;
- harta implicită aflată în Engine content.

BS-011 creează harta project-owned. BS-013B deține curățarea configului PC-only și baseline-ul renderer/scalability de test, cu ADR și verificare. Tokenurile/configul local nu sunt copiate în documentație.

## Dovada unui build

Păstrează în task packet:

- candidate commit hash și, dacă un commit ulterior schimbă numai evidence/docs, runtime/content tree-ul verificat;
- target/platform/configuration;
- engine version;
- rezultatul `Succeeded/Failed`;
- numărul de warning-uri noi;
- calea/logul relevant;
- data și cine a executat build-ul.

„Editorul s-a deschis” nu înlocuiește un build explicit când task-ul schimbă C++ structural.

Buildul dovedește numai candidatul/tree-ul verificat. Orice schimbare ulterioară în C++, Config, Content, `.uproject`, pluginuri sau build scripts marchează dovada `INVALIDATED` și cere rebuild/test. Un commit ulterior exclusiv de status/evidence poate păstra dovada dacă notează explicit candidatul și nu schimbă inputurile runtime.
