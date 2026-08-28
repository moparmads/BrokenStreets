# Arhitectura Broken Streets

**Status:** arhitectură țintă, nu descrierea unei implementări existente.
**Realitatea curentă:** un singur modul C++ gol; vezi `Docs/STATUS.md`.

## 1. Obiective arhitecturale

Arhitectura trebuie să permită:

- solo și co-op privat cu un listen-server host plus maximum trei clienți;
- patru jucători fără tether, în zone/interioare/joburi diferite;
- progres personal portabil între lumile prietenilor, fără backend dedicat;
- economie, ownership și save rezistente la retry, reconnect și crash în limite documentate;
- lume Manhattan-like extinsă district cu district;
- mii de definiții de bunuri fără a încărca toate asset-urile simultan;
- reprezentări LOD pentru populație, trafic și world state;
- build, test, profiling și migrare repetabile de către un creator care nu scrie cod.

## 2. Invariante

1. **Server authority:** clientul exprimă intenția; partea server a listen serverului validează și aplică gameplay-ul.
2. **Single writer:** fiecare adevăr runtime are un singur owner de domeniu.
3. **Separation of forms:** Definition, Persistent Record, Replicated DTO și Runtime Actor sunt tipuri diferite.
4. **Stable identity:** `DefinitionId` este imutabil; instanțele folosesc `FGuid`/typed IDs. Gameplay Tags clasifică, nu identifică.
5. **Persistence is not an Actor:** save-ul nu conține pointeri `UObject`, nume runtime ori presupuneri despre actors încărcați.
6. **UI is not gameplay:** UI emite comenzi și consumă read models/evenimente.
7. **Save is not gameplay:** Save serializează stări valide și orchestrează I/O/migration; nu decide prețuri, ownership ori rezultate.
8. **Data-driven, bounded runtime:** cataloagele folosesc Asset Manager/soft references; runtime-ul are limite și update rates explicite.
9. **Compatibility first:** build, content și save schema au handshake înainte ca un profil să fie acceptat.
10. **Measured scaling:** nicio tehnologie de replicare, streaming ori crowd nu este adoptată fără scenariu și prag măsurabil.

## 3. Topologia UE per proces

Faptul că un obiect există pe PC-ul host-ului nu îl face automat autoritate. `Host` descrie jucătorul/PC-ul care rulează sesiunea; `server` descrie rolul autoritativ de rețea. Clientul local al host-ului nu ocolește validarea serverului. Rolurile sunt explicite.

### `UGameInstanceSubsystem`

Există pe fiecare proces. Este potrivit pentru:

- orchestration local de profile;
- online/session flow;
- servicii de aplicație care supraviețuiesc schimbării world-ului;
- preferințe și bootstrap local.

Nu este automat replicat și nu este automat autoritate server. Orice operație gameplay trece prin boundary-ul de rețea și ownerul domeniului.

### `AGameModeBase` — server only

- orchestration server-only pentru intrare, spawn, ruleset și tranziții de sesiune;
- aprobă/refuză conectarea după compatibility/profile validation;
- nu devine depozit monolitic pentru economie, inventar ori toate joburile.

### `AGameStateBase` — read model public

- stare publică a lumii: clock, vreme, phase, informații de sesiune necesare tuturor;
- snapshot/replication pentru late join;
- nu conține profile complete ori secrete personale.

### `APlayerController` — command boundary privat

- primește inputul clientului local;
- expune RPC-urile client→server validate/rate-limited;
- poate găzdui fațade owner-only pentru date private;
- nu calculează direct regulile domeniilor; delegă ownerilor autoritativi.

### `APlayerState` — identitate/read model public per jucător

- identitate runtime, display data și rezumate publice necesare altor jucători;
- persistă la schimbarea Pawn-ului;
- nu replică inventarul complet, soldurile private ori Portable Profile integral.

### `APawn` / `ACharacter`

- prezență fizică, movement, collision, animation-facing state și componente apropiate de avatar;
- nu deține economie, save ori catalog;
- poate avea fațade/componente replicate cu responsabilitate clară.

### `UWorldSubsystem`

- servicii legate de world: clock authority, registries, directors, scheduling local acelui world;
- nu se presupune persistent între worlds;
- replicarea se face prin Actor/Component/subobject dedicat, nu prin subsystem direct.

### `ULocalPlayerSubsystem`

- input/UI preferences, presentation și servicii strict locale;
- fără mutații autoritative de gameplay.

## 4. Structura de module și surse

Începem cu puține module compilate:

```text
Source/
  BrokenStreets/
    Public/              # API stabil minim necesar altor module
    Private/
      Core/
      Identity/
      Online/
      Network/
      World/
      Player/
      Interaction/
      Items/
      Inventory/
      Ownership/
      Economy/
      Jobs/
      Legality/
      ...
      Tests/             # numai teste excluse corect din Shipping
  BrokenStreetsEditor/   # viitor modul Type=Editor
    Private/
      Validation/
      Import/
      Debug/
```

- Folderele din `Private/` exprimă ownership logic, nu module separate.
- API-ul rămâne privat până există un consumator extern real.
- Un modul nou necesită dependențe/lifetime diferite ori o graniță demonstrată.
- Testele sunt protejate prin `WITH_DEV_AUTOMATION_TESTS` ori mutate într-un modul `DeveloperTool`; nu intră accidental în Shipping.
- `BrokenStreetsEditor` nu este dependency a modulului runtime.
- Engine-ul din `F:/UE_5.8.2` nu se modifică.

## 5. Cele patru forme ale unei entități

### Definition

Date comune, immutable în runtime-ul normal:

- `DefinitionId` stabil;
- clasă/categorie prin Gameplay Tags;
- preț de bază, greutate, capacitate și tuning;
- soft references către mesh, icon, audio și alte asset-uri;
- versiune de date când migrarea este relevantă.

Rename-ul asset-ului nu schimbă `DefinitionId`. Redirects/migration map păstrează compatibilitatea.

### Persistent Instance Record

- `InstanceId` tipizat/`FGuid`;
- owner, stare, modificări, container și câmpuri ce diferă de Definition;
- numai tipuri serializabile; fără referințe `UObject`/Actor;
- SchemaVersion și validare.

### Replicated DTO / read model

- numai câmpurile de care audience-ul are nevoie;
- separat de structura de save pentru a evita leak și coupling;
- owner-only pentru sold/inventar privat;
- snapshot inițial plus delte pentru colecții;
- compatibil cu late join/reconnect.

### Runtime representation

- Actor, Component, UObject ori representation data încărcată lângă jucător;
- poate fi distrusă/recreată fără a distruge recordul;
- promovarea/demovarea păstrează StableId și starea relevantă.

Această separare se aplică itemelor, vehiculelor, proprietăților, NPC-urilor importante și joburilor.

## 6. Fluxul unei comenzi

```text
Input/UI local
  → typed intent prin PlayerController/facade
  → validare server: identity, permission, state, range, rate limit
  → domain owner aplică ori refuză mutația
  → event/result tipizat
  → alți owners reacționează prin comenzi explicite
  → read model/replication se actualizează
  → persistence capturează starea la policy-ul definit
```

- Nu există un event bus universal construit anticipat. Folosim API-uri C++ tipizate, delegates și facilitățile UE; extragem infrastructură comună numai după minimum doi consumatori reali.
- O operație multi-domeniu folosește un coordinator/use case idempotent. Coordinatorul nu devine ownerul datelor.
- Exemplu de cumpărare: Shop validează oferta → coordinatorul cere debit de la Economy → cere creare/mutare item de la Items/Inventory → cere ownership → finalizează ori compensează prin TransactionId. Niciun domeniu nu scrie direct starea altuia.

## 7. Multiplayer și replicare

### Contract

- maximum patru jucători total: `1 host + 0–3 clients`;
- listen server privat, Steam-only inițial;
- join-in-progress și reconnect;
- fără tether; patru relevancy/streaming bubbles posibile;
- partea server a listen serverului este runtime mutation authority; clientul local al host-ului folosește aceleași command/RPC validation paths ca un client remote;
- profilele locale prezentate la join sunt input neîncrezător, validate înainte de materializare.

### Baseline tehnic

Standard UE replication este fallback-ul obligatoriu. Replication Graph și Iris sunt candidați `Adopt/Reject`, nu presupuneri de shipping:

- întâi se măsoară standard replication într-un workload reprezentativ;
- Replication Graph se adoptă numai dacă relevancy-ul celor patru bule justifică și build-ul UE folosit trece testele;
- Iris se evaluează numai dacă baseline-ul nu trece ori oferă un avantaj măsurabil;
- API-urile domeniilor nu depind de un singur backend de replicare;
- un ADR consemnează rezultatul și fallback-ul.

### Reguli

- RPC-urile descriu intenții, nu rezultate impuse de client;
- reliable numai pentru evenimente rare ce trebuie livrate; niciodată per frame;
- stare durabilă prin proprietăți/collections replicate, nu multicast-only;
- rate limit și payload caps pe acțiuni repetabile;
- relevancy/priority/owner-only explicite;
- fiecare system doc descrie late join, reconnect, disconnect în tranzacție și security validation.

## 8. Modelul de persistență

### `PortableCharacterProfile` — deținut ca fișier de jucător

Conține numai progres personal portabil confirmat: identitate, appearance, bani, inventar, recorduri portabile de vehicule/proprietăți, needs/health persistent, reputații, cazier, unlock-uri și receipts. Exacta schemă crește incremental, nu este implementată integral din prima versiune.

### `HostWorldSave` — deținut de host

Conține adevărul world-owned: WorldId, clock/weather, district/event state, job/world deltas, NPC-uri importante world-owned și materializări runtime necesare recovery-ului. Nu poate suprascrie permanent un profil guest cu o copie veche.

### `SessionCommitJournal` — autoritar cât sesiunea rulează

Este distinct de `EconomyTransactionLedger`:

- `EconomyTransactionLedger` deține operațiile monetare și idempotency economică;
- `SessionCommitJournal` urmărește join revision, commits/receipts și coordonarea exportului profilului.

Fără backend, nu promitem tranzacție atomică durabilă între două PC-uri. Politica exactă pentru rezultate ambigue trebuie aprobată înainte de MVP-ul save; direcția recomandată este:

1. ultimul checkpoint confirmat de ambele părți câștigă;
2. rezultatul neconfirmat se rollback-uiește ori intră în recovery report;
3. conflictul cross-host blochează importul automat și cere alegere umană;
4. restore-ul manual schimbă `ProfileEpoch` și invalidează lease-ul local vechi.

### I/O

- snapshot coerent/immutable capturat pe game thread;
- serializare și I/O asincron numai după capture;
- temp file creat pe același volum cu destinația finală;
- ordinea este `capture → serialize temp → flush → read-back/checksum → atomic local replace → manifest commit`;
- manifestul nu indică noua generație înainte ca aceasta să fie verificată, iar cel puțin o generație validă anterioară rămâne recuperabilă;
- la startup, temp-urile neconfirmate sunt ignorate/quarantine; generațiile se verifică de la cea mai nouă la cea mai veche și fallback-ul este raportat;
- fault injection în fiecare etapă, inclusiv înainte și după replace/manifest;
- build/content/schema handshake înainte de acceptarea profilului;
- migrations păstrează ID-urile ori eșuează explicit cu recovery path.

## 9. World Partition, interioare și patru bule

World Partition nu este suficient doar prin activare. Spike-ul trebuie să fixeze prin ADR:

- Runtime Hash și grid/cell sizes;
- streaming sources pentru host și cei trei clienți;
- server streaming și server streaming-out;
- ownership-ul actorilor autoritativi când o celulă se descarcă;
- navmesh și spawn anchors;
- high-speed traversal;
- HLOD/Data Layers/OFPA;
- memorie și hitch thresholds.

Configul UE poate ține implicit întreaga lume încărcată pe server; pentru Manhattan și patru bule, comportamentul trebuie verificat în build-ul exact 5.8.2 și nu presupus.

Interioarele private nu folosesc server travel individual. Un serviciu abstract materializează instanțe izolate în același world autoritativ. Spike-ul validează patru instanțe simultane pentru:

- izolare vizuală și occlusion;
- audio;
- collision și physics;
- nav/AI;
- replication/relevancy;
- visitors/permissions;
- ID-uri și save fără coliziuni;
- încărcare, unload și memory caps.

Implementarea exactă rămâne `Proposed` până la spike.

## 10. Scheduling și simulation LOD

Nu construim un scheduler universal înainte de cazuri reale. Fiecare system doc declară modelul de update:

| Nivel | Reprezentare |
|---|---|
| Full | gameplay/AI/physics/animație completă lângă jucător |
| Reduced | Actor complet cu frecvență și cost reduse |
| Representation | record data-oriented/Mass dacă este adoptat, fără Actor complet |
| Statistical | rezultat din date/seed fără prezență fizică |

Economy, ownership și save sunt event-driven. Needs folosesc delte din `CharacterActiveTime`. Directors folosesc frecvențe explicite și bugete. Promovarea/demovarea păstrează StableId.

## 11. Blueprint și asset boundary

C++ deține autoritatea, persistența, replicarea și hot paths. Blueprint/Editor configurează vizual Animation, UI layout, assets, maps și StateTrees cu task-uri C++. Orice logică Blueprint cu stare persistentă, networking, multe ramuri/bucle sau Tick permanent este defect arhitectural implicit.

Asset Manager și Primary Data Assets/echivalentul validat țin cataloagele data-driven. Toate referințele mari sunt soft până când lifetime-ul cere explicit load. Content validation verifică naming, DefinitionId, duplicate IDs, references, collision și metadata.

## 12. Config baseline și datorii cunoscute

Proiectul gol are momentan:

- `GameDefaultMap=/Engine/Maps/Templates/OpenWorld`;
- Ray Tracing activ;
- Substrate activ;
- Android File Server config prezent/activ, deși ținta inițială este PC-only.

Acestea nu se modifică în task-ul de documentație. BS-011 creează map-ul project-owned, iar BS-013B deține explicit curățarea configului PC-only și baseline-ul renderer/scalability măsurabil. Nu se copiază tokenuri ori secrete din config în documente/loguri.

## 13. Schimbarea arhitecturii

Un ADR este necesar pentru o alegere cross-system, greu de inversat ori care afectează save/network/performance/build. Tuning-ul reversibil nu primește ADR.

Flux:

1. problemă observată și metrică;
2. alternative și fallback;
3. impact network/save/performance/Editor;
4. decizia creatorului pentru produs ori acceptarea tehnică demonstrată;
5. ADR;
6. update simultan la ARCHITECTURE, OWNERSHIP, system doc, ROADMAP și task.

Nu construim infrastructură anticipată doar pentru că „ar putea fi utilă”.
