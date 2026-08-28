# Ghid de compilare pentru Madalin

Acesta este workflow-ul normal după ce Codex modifică C++. Nu trebuie să scrii ori să repari cod.

## Înainte să începi

Codex trebuie să-ți spună explicit una dintre variante:

- `Editorul trebuie închis` — default pentru headers, reflection, module, networking layout, save/serialization;
- `Editorul poate rămâne deschis` — numai pentru o schimbare mică verificată;
- `Folosește Live Coding` — numai când Codex justifică exact că schimbarea este sigură.

Dacă nu spune, închide Unreal Editor înainte de build. Salvează asset-urile când Editorul întreabă numai dacă știi că sunt modificările tale intenționate.

## Build normal în Visual Studio

1. Închide Unreal Editor.
2. Deschide File Explorer.
3. Intră în `F:\BrokenStreets`.
4. Deschide `BrokenStreets.sln`.
5. Așteaptă până când Visual Studio termină încărcarea soluției și nu mai afișează operații de restore/indexing importante.
6. În bara de sus, la `Solution Configurations`, selectează `Development Editor`.
7. Imediat lângă, la `Solution Platforms`, selectează `Win64`.
8. În `Solution Explorer`, deschide `Games`.
9. Click dreapta pe proiectul `BrokenStreets` din `Games`.
10. Apasă `Build`.
11. În partea de jos, deschide tab-ul `Output` dacă nu este deja vizibil.
12. La `Show output from`, selectează `Build`.
13. Așteaptă până apare rezumatul final.

### PASS

Output-ul se termină cu:

- `Result: Succeeded` sau echivalent;
- `Build: 1 succeeded, 0 failed` ori un rezumat fără failed;
- zero erori.

Nu este o problemă dacă target-ul este `up-to-date` și nu există error.

### FAIL

Dacă apare `failed`, `error C...`, `UnrealHeaderTool failed` ori fereastra se oprește:

1. Nu modifica fișiere și nu căuta singur un fragment de cod.
2. Nu apăsa `Clean Solution` și nu șterge foldere.
3. În `Output`, selectează textul de la `Build started` până la rezumatul final.
4. Copiază întregul text și trimite-l lui Codex.
5. Dacă textul este prea mare, salvează-l într-un `.txt` și atașează fișierul.
6. Atașează și o captură cu prima eroare, dar logul text complet este mai important.

Logul Unreal Build Tool se află de obicei în:

`C:\Users\madal\AppData\Local\UnrealBuildTool\Log.txt`

Trimite-l numai dacă Codex îl cere ori Output-ul este incomplet.

## După build reușit

1. Închide Visual Studio numai dacă vrei; nu este obligatoriu.
2. Deschide `F:\BrokenStreets\BrokenStreets.uproject`.
3. Dacă Unreal întreabă dacă trebuie rebuild modules, oprește-te și trimite captura; build-ul explicit tocmai făcut ar trebui să fie suficient.
4. Urmează testul manual exact dat de Codex.
5. Trimite rezultatul PASS ori captura/logul cerut la FAIL.

## Când NU folosim Live Coding

Nu apăsa `Ctrl+Alt+F11` pentru:

- clase/structuri/enum-uri Unreal noi;
- schimbări `UPROPERTY`, `UFUNCTION`, `UCLASS`, `USTRUCT`, `UENUM`;
- `.h`, `.Build.cs`, Target.cs ori plugin/module changes;
- replicated properties/RPC layout;
- save schema/serialization/migrations;
- constructor/default subobject changes;
- crash-uri sau stare suspectă după un patch anterior.

Pentru acestea: închide Editorul și rulează build-ul complet de mai sus.

## Ce nu faci manual

- nu copiezi cod în Visual Studio;
- nu editezi `.Build.cs`, config ori `.uproject`;
- nu apeși `Rebuild Solution` decât dacă task-ul spune explicit;
- nu construiești proiectul `UE5` ori toate cele 59+ proiecte din solution;
- nu ștergi `Binaries/Intermediate/Saved` ca primă soluție;
- nu alegi altă versiune de Unreal.

Codex îți va spune exact dacă un caz excepțional cere alt pas.
