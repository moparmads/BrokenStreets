# Recovery, backup și restaurare

GitHub este o copie remote, nu dovada că proiectul poate fi reconstruit. Recovery se testează.

## BS-007A — clean clone simplu

Poate fi executat acum:

1. Alege un folder nou, explicit, în afara `F:/BrokenStreets` și `F:/UE_5.8.2`.
2. Clonează repository-ul privat și branch-ul `main`.
3. Rulează Git LFS pull.
4. Confirmă că lipsesc intenționat `.vs`, `Binaries`, `Intermediate`, `Saved`.
5. Generează fișierele Visual Studio.
6. Build `BrokenStreetsEditor | Win64 | Development`.
7. Deschide proiectul și confirmă baseline-ul gol.
8. Notează durata, commitul și orice pas ne-documentat.

PASS demonstrează că proiectul de bază nu depinde de cache-ul vechi. Folderul recovery nu devine proiectul principal.

BS-007A a fost executat pe același profil Windows și cu aceeași instalare UE. Nu demonstrează încă portabilitate pe alt profil/PC și nu demonstrează recovery de save, asset-uri LFS ori source art care nu existau la baseline.

## Engine association pe profil/PC nou

`BrokenStreets.uproject` poate conține un `EngineAssociation` GUID înregistrat local. GUID-ul nu este o cale portabilă și nu trebuie presupus existent pe alt profil sau PC.

Recovery-ul sigur:

1. instalează/verifică exact UE 5.8.2 și notează calea absolută;
2. rulează build-ul prin `Engine/Build/BatchFiles/Build.bat` din acel engine, cu calea absolută a `.uproject`;
3. deschide prin `Engine/Binaries/Win64/UnrealEditor.exe` din același engine, cu `.uproject` ca argument;
4. pentru integrarea Explorer/IDE, asociază local proiectul cu engine-ul exact și regenerează fișierele; o rescriere de `EngineAssociation` făcută numai pentru recovery nu se împinge fără task de upgrade/toolchain;
5. BS-009 validează comanda de project generation fără dependență ascunsă de Explorer, iar BS-007B o repetă pe alt profil Windows sau pe al doilea PC.

## BS-007B — recovery complet al proiectului

Se execută după BS-009, BS-010, BS-010A, BS-011, BS-012, BS-013 și BS-013B:

1. clean clone nou;
2. Git LFS pull și pointer audit;
3. project generation;
4. command-line Development Editor build;
5. automation smoke tests;
6. Data Validation;
7. cook/package minimal;
8. open/load `L_TestGym_Core` prin executable-ul engine-ului exact;
9. LFS lock/unlock/pointer/push exercise pentru un asset de test aprobat;
10. repetare pe alt profil Windows sau al doilea PC, fără a presupune GUID-ul local;
11. raport cu pași/durată/probleme și update toolchain docs.

Restore-ul de save nu este un criteriu BS-007B înainte ca BS-020 să creeze schema și fault harness-ul. Din BS-020 încolo, fiecare gate persistent adaugă propriul restore/fault test.

## Backup independent pentru repository și Git LFS — BS-010A

GitHub este remote-ul de colaborare, nu singurul plan de disaster recovery. Înainte de primul asset Unreal important, BS-010A cere:

- toate refs/tag-urile necesare și toate obiectele Git LFS, nu doar working tree-ul;
- o copie versionată pe mediu/locație independentă de GitHub și de SSD-ul proiectului;
- manifest/checksum și data ultimului backup reușit;
- checkpoint remote înainte de operații riscante ori migrații de asset-uri;
- restore într-un folder nou cu accesul la GitHub dezactivat/indisponibil;
- build/open al commitului restaurat și verificarea fiecărui pointer LFS;
- owner, frecvență, retenție, alertă de capacitate și procedură de reînnoire a credentialelor.

Un `git bundle` singur nu include obiectele LFS. Soluția aprobată trebuie să păstreze atât obiectele Git/refs, cât și storage-ul LFS ori să folosească un al doilea remote care oferă ambele. Providerul/mediul nu se alege automat fără acordul creatorului.

## Backup Source Art 3-2-1

`F:/BrokenStreets_SourceArt` nu este protejat de repository-ul jocului.

Gate-ul cere:

- trei copii totale;
- două tipuri de medii/locații;
- o copie off-site;
- checksum/manifest pentru fișiere importante;
- versionare ori snapshot policy;
- capacitate estimată și alertă înainte de umplere;
- restore trimestrial al unui eșantion într-un folder nou.

Nu configura automat un provider/cloud fără alegerea și autorizarea creatorului.

## Save recovery viitor

Fiecare schema persistentă trebuie să aibă:

- versions/migrations;
- checksum și minimum o generație anterioară validă;
- temp pe același volum cu destinația;
- ordinea `capture → serialize temp → flush → read-back/checksum → atomic local replace → manifest commit`;
- manifest actualizat numai după validare; temp neconfirmat nu devine generație activă;
- startup selection newest-to-oldest dintre generațiile committed valide, cu fallback raportat;
- golden test files;
- crash/fault injection înainte și după fiecare etapă, plus corrupt/truncated/stale behavior;
- recovery UI/report;
- compatibility/rollback plan.

## Incident checklist

La proiect corupt/build imposibil:

1. oprește salvările și bulk operations;
2. notează branch/commit/status și copiază logul;
3. nu șterge foldere largi ca prim pas;
4. verifică dacă un clean clone reproduce;
5. clasifică: source/config, generated files, asset LFS, engine/toolchain, save;
6. restaurează din sursa cea mai îngustă și verificată;
7. rebuild/test înainte de a relua munca;
8. adaugă regresie/documentație pentru cauza reală.

## Destructive safety

Orice delete/move recursiv:

- are target absolut verificat;
- nu folosește root, home, workspace root generic, globs ori variabile nerezolvate;
- preferă un folder recovery/trash;
- nu atinge proiectul principal, engine-ul sau Source Art fără aprobarea explicită a creatorului.
