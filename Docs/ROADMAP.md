# Roadmap canonic Broken Streets

**Actualizat:** 28 august 2026
**Motor:** Unreal Engine 5.8.2
**Platformă:** Windows PC, Steam
**Topologie:** solo sau co-op privat, 1 listen-server host + maximum 3 clienți
**Metodă:** gates măsurabile, nu promisiuni calendaristice

## 0. Regula roadmapului

Roadmapul descrie ordinea viitoare, nu implementarea existentă. `Docs/STATUS.md` spune ce este real. Un milestone nu se extinde cu conținut până când gate-ul lui trece.

Ordinea a fost optimizată pentru două riscuri:

1. să nu construim Manhattan înainte să existe un joc;
2. să nu construim luni de infrastructură generică înainte de prima buclă jucabilă.

## 1. Strategia completă

```text
baseline recuperabil
  → build/test/cook repetabil și TestGym
  → core minim măsurabil
  → spike-uri care pot invalida proiectul
  → identity/session/save portabil subțire
  → player + UI minim
  → interaction/economie + walking legal slice
  → vehicul MVP
  → illegal reaction slice
  → vertical slice hard gate
  → health/hospital → arrest/prison → needs
  → appearance/catalog → proprietăți în trepte
  → movement/combat → population/traffic
  → factions/NPC/job families
  → primul district de producție
  → Early Access hardening
  → Manhattan district cu district
```

## M0 — Viziune și produs

**Status:** suficient pentru pornire; detaliile rămase sunt programate la gate-ul relevant.

Livrabile:

- VISION, DECISIONS, NON_GOALS;
- promisiunea `economie + legal/ilegal + co-op + aspirație`;
- lista deciziilor `CONFIRMAT`, `PROVIZORIU`, `PROPUS — NECESITĂ APROBARE`, `DEFERRED`;
- politică originalitate/clean-room.

**Gate:** nicio contradicție care blochează fundația; propunerile nu sunt prezentate ca fapte.

## M1 — Baseline recuperabil și memoria proiectului

### M1A — Baseline local

| Task | Rezultat | Status |
|---|---|---|
| BS-001 | căi stabile pe SSD, în afara OneDrive | Done |
| BS-002 | UE/VS/SDK verificate | Done |
| BS-003 | Blank C++ `BrokenStreets` | Done |
| BS-004 | build baseline nemodificat | Done |
| BS-005 | Git ignore + Git LFS | Done |
| BS-006 | repository GitHub privat + push `main` | Done |

### M1B — Recovery și documentație

| Task | Rezultat | Gate |
|---|---|---|
| BS-007A | clean clone simplu din GitHub | generate project/build/open baseline fără fișiere locale ascunse |
| BS-008 | AGENTS + documentația canonică + workflow | Codex din root rezumă corect regulile și task-ul următor |
| BS-009 | acțiuni repetabile Build/Test/Validate/Cook | fiecare pornește și produce log clar |
| BS-010 | primul Automation smoke test | verde în Editor și command line |
| BS-010A | backup independent repository + Git LFS | toate refs și obiectele LFS se restaurează fără GitHub |
| BS-011 | `L_TestGym_Core` project-owned | load în packaged Development |
| BS-012 | `L_TestGym_Network` | 1 host + 3 clienți pornesc corect |
| BS-013 | `L_Benchmark_Street` placeholder | primul trace/versioned baseline |
| BS-013A | Source Art backup | regula 3-2-1 + checksum + restore verificat |
| BS-013B | config PC-only + renderer/scalability baseline de test | maps project-owned, config nefolosit eliminat, ADR și preset verificabil |
| BS-007B | recovery drill complet | clone + LFS + build + test + cook + open TestGym pe profil/PC curat |

**Corecție de dependență:** BS-007A nu cere TestGym/cook deoarece ele nu există încă. BS-007B închide gate-ul complet după BS-009, BS-010, BS-010A, BS-011, BS-012, BS-013 și BS-013B. Restore-ul de save nu aparține BS-007B înainte să existe schema/harness-ul BS-020.

**Gate M1:** proiectul poate fi reconstruit din clone și documentație; source art are recovery separat; nu există gameplay încă.

## M2 — Core minim și observabilitate

Nu construim un framework universal. O primitivă comună apare când are un consumator real și se generalizează după al doilea.

| Task | Rezultat |
|---|---|
| BS-014 | typed/stable IDs + Gameplay Tags policy |
| BS-015 | logging categories, structured context și feature flags |
| BS-016 | build/content/save compatibility handshake |
| BS-017 | results/errors și command envelope tipizat |
| BS-018 | Asset Manager + soft reference/loading policy |
| BS-019 | authority/state debug overlay minimal |
| BS-020 | save header/version + serializer/fault harness minimal |
| BS-021 | profiling fixture și baseline CPU/GPU/memory/network |

Condiții:

- IDs au teste de round-trip/duplicate;
- Shipping nu include test/debug tooling neintenționat;
- baseline-ul project-owned/config/renderer din M1 rămâne verde după schimbările Core;
- nu există Tick permanent, global scan ori hard catalog reference.

**Gate M2:** un test determinist poate crea stare, un log arată owner/authority/ID, iar baseline-ul poate fi comparat după commit.

## M3 — Spike-uri eliminatorii

Aceste spike-uri sunt time-boxed și pot schimba scope-ul înainte de sisteme mari. Fiecare are prag numeric, rezultat `Adopt/Reject/Re-test`, fallback și ADR.

| Task | Risc invalidant | Dovadă minimă |
|---|---|---|
| BS-022 | Steam/NAT | packaged build pe 2 PC-uri, 2 conturi și 2 rețele, fără port forwarding manual |
| BS-023 | patru bule World Partition | 1 host + 3 clienți separați, server streaming/out decis, unload/reload fără pierdere |
| BS-024 | profil portabil + crash/disconnect | revision/receipt/conflict policy și kill matrix |
| BS-025 | patru interioare izolate | visual/audio/nav/physics/replication/save isolation |
| BS-026 | high-speed streaming | pawn/vehicul placeholder rapid fără hitch/pierdere de state peste prag |

Condițional, nu obligatoriu devreme:

- Replication Graph numai dacă standard replication nu trece relevancy/bandwidth;
- Iris numai dacă baseline-ul nu trece ori avantajul merită riscul;
- Mass numai când există workload crowd/traffic reprezentativ;
- GAS numai înainte de Health/Effects, pe cazuri reale.

**Gate M3:** cele cinci riscuri eliminatorii au soluție măsurată sau fallback/scope cut aprobat. Nu este necesar un sistem de producție complet.

## M4 — Identity, Session și Save MVP

| Task | Rezultat |
|---|---|
| BS-027 | local account binding + CharacterId + character slots |
| BS-028 | PortableCharacterProfile subțire + CharacterActiveTime |
| BS-029 | HostWorldSave subțire |
| BS-030 | SessionCommitJournal + receipts + conflict UX |
| BS-031 | crash-safe generations/checksum/migration v1 |
| BS-032 | Null listen session: host/join/late join/reconnect |
| BS-033 | Steam private invite/session integration |
| BS-034 | patru profile simultane și portability între două lumi |

Nu implementăm de la început toate câmpurile finale din profile. Schema crește prin feature fragments versionate.

**Gate M4:** 1/2/4 jucători intră, schimbă o valoare de test, ies și revin; profilul absent nu avansează; host crash revine la ultimul commit confirmat; un conflict nu este rezolvat tăcut.

## M5 — Player și UI minim

| Task | Rezultat |
|---|---|
| BS-035 | Character/Pawn, Enhanced Input și locomotion TP de bază |
| BS-036 | crouch/vault simplu, stamina și replication/prediction tests |
| BS-037 | first-person funcțional peste același gameplay, fără polish final |
| BS-038 | HUD prompt/toast/pause shell + accessibility camera/input |
| BS-039 | phone shell minim, extins numai când apare primul consumator |

Third-person vine primul pentru co-op/animație. FP nu creează un al doilea gameplay system. Map/GPS complet nu blochează walking slice.

**Gate M5:** 1/2/4 se mișcă și schimbă perspectiva fără avantaj diferit; client correction rămâne în prag; efectele de cameră pot fi reduse/oprite.

## M6 — Interaction, Economy și primul walking slice legal

Aceasta este prima buclă jucabilă și vine înainte de vehicul/poliție completă.

| Task | Rezultat |
|---|---|
| BS-040 | interaction focus/use + timed action server-validated |
| BS-041 | ItemDefinition/Instance + inventory slot/weight/container v1 |
| BS-042 | ownership/permissions + drop/cleanup + trade/gift minimal |
| BS-043 | legal cash/bank/dirty cash + EconomyTransactionLedger în cenți |
| BS-044 | ATM + Shop v0 + buy/sell + save migration |
| BS-045 | Job Runtime minimal: participants/objectives/outcome/payout receipt |
| BS-046 | tutorial + primul walking job legal aprobat; curieratul este candidatul D144 |
| BS-047 | `job → bani → magazin → obiect cumpărat` |

Zona este un greybox mic, nu Manhattan. Toate operațiile critice au TransactionId și idempotency. UI normal parcurge flow-ul; debug commands doar asistă testarea.

**Gate M6:** bucla de 10–20 minute trece solo/1+1/1+3, late join/reconnect relevant, save/reload și 100 retry pentru tranzacție fără dublare. Creatorul confirmă că progresul de bază este clar și promițător.

## M7 — Vehicle MVP

| Task | Rezultat |
|---|---|
| BS-048 | sedan Chaos placeholder + arcade-realist handling |
| BS-049 | enter/exit/seats/camera și network smoothing |
| BS-050 | VehicleDefinition/Record + ownership/permissions |
| BS-051 | purchase + trunk inventory + persistence/materialization |
| BS-052 | fuel/condition/recovery incremental |

Hotwire, upgrades, damage/explosion și polish vin după fundația necesară; nu blochează primul vehicle value test.

**Gate M7:** patru vehicule pot fi conduse în patru zone și recuperate fără clonarea recordului/conținutului; cumpărarea schimbă clar walking loop-ul.

## M8 — Illegal reaction slice

| Task | Rezultat |
|---|---|
| BS-053 | nav/spawn anchors + un NPC/agent StateTree minimal |
| BS-054 | Legality tags + Incident + detectare simplă LOS/noise |
| BS-055 | Active Heat individual + temporary outfit/vehicle signature |
| BS-056 | Police Director cu buget + o unitate pursuit/escape/arrest placeholder |
| BS-057 | primul job ilegal aprobat; coletul din zonă restricționată este candidatul D145 |
| BS-058 | dirty money + laundering minimal + consecință/recovery receipt |

Fără forensics, camere, evidence graph ori poliție armată. Complicitatea cere acțiune concretă.

**Gate M8:** patru jucători pot avea heat diferit; colegul neimplicat nu este urmărit; jobul ilegal aprobat funcționează solo/co-op; escape/reconnect/reward nu dublează rezultate; directorul respectă bugetul.

## M9 — Vertical Slice hard gate

Conținut minim:

- tutorial;
- job legal și ilegal;
- ATM/shop/duffle/objective purchase;
- un vehicul cumpărabil;
- heat/pursuit/escape/arrest placeholder;
- profile portabile și save recovery;
- greybox 4x4 blocuri cu safe point, shop, warehouse, ATM, dealer, portal interior și spawn anchors;
- UI normal pentru întregul flow.

Acceptare:

- 30–60 minute de progres coerent;
- 1, 2 și 4 jucători total;
- jucători împreună și separați/joburi simultane;
- late join/reconnect/disconnect mid-command;
- două rețele reale prin Steam;
- host crash și portability între lumi;
- packaged Development/Shipping-like;
- trei rulări de performance pe hardware/preset fixat;
- playtest creator: bucla este distractivă înainte de artă finală.

**Hard gate:** niciun sistem major nou și niciun district final până nu trece.

## M10 — Consecințe în milestone-uri mici

### M10A Health/Hospital

- GAS adopt/reject pe cazuri reale;
- health general + hit zones, wounds moderate, first aid;
- downed/revive;
- hospital transition, fee/loss prin owners și safe return.

### M10B Arrest/Prison

- surrender/arrest final;
- confiscare coordonată;
- prison instance, bail/vizite/disconnect după Decision Packet;
- release/re-entry.

### M10C Needs

- hunger, thirst, sleep/vote, bladder/toilet, hygiene;
- CharacterActiveTime, fără progres offline;
- effects data-driven și update rar.

Fiecare submilestone are gate solo/1+1/1+3, reconnect și idempotency; nu se livrează ca mega-feature unic.

## M11 — Aspirație în trepte

### M11A Appearance și catalog

- creator de personaj pe body/skeleton unic;
- clothing/jewelry slots, clipping validation, outfit inventory;
- social/status metadata;
- cataloage, rare stock și illegal equipment.

### M11B Proprietate de bază

- offer, purchase/rent transaction, PropertyRecord/Instance;
- patru instanțe simultane, visitors/permissions;
- storage și portability.

### M11C Proprietate extinsă

- furniture free placement cu limite;
- moving service fizic;
- rent/autopay/grace/eviction/recovery storage;
- debt v1.

Fiecare treaptă dovedește că banii produc gameplay/status înainte să extindă catalogul.

## M12 — Movement și Combat

Ordine:

1. prone/ladders/swimming/marked high mantle;
2. fists + improvized weapon;
3. pistol, knife, shotgun incremental;
4. hybrid server-authoritative ballistics;
5. armor/hit zones și FP/TP parity;
6. Armed Response/Manhunt;
7. vehicle severe damage/fire/explosion.

Combatul nu folosește bullet sponges și poate fi evitat de cariera legală. Fiecare mecanică trece latency/correction și aceleași reguli Health.

## M13 — Population, Traffic și World Events

- representation LOD + Actor promotion/demotion;
- routines ambientale simple;
- traffic statistical flow + physical promotion;
- world event eligibility/cooldown/budget;
- weather/day-night/scalability;
- World Partition/HLOD/Data Layers/OFPA de producție;
- four-bubble stress și memory soak.

Mass este adoptat numai dacă workload-ul măsurat justifică. Low reduce ambient/cosmetic, nu martori, poliție ori obiective.

**Gate:** packaged pe patru PC-uri reale înainte de content lock: host hardware-etalon + trei clienți remote, patru zone/joburi, fără memory growth ori gameplay eliminat.

## M14 — Factions, NPC stories și fabrică de joburi

- două familii mafiote candidate pentru Early Access;
- reputație individuală, access/jobs/warnings/retaliation;
- contacte persistente și dialog cu alegeri simple;
- relația personajului portabilă, NPC intrinsic state world-owned;
- JobDefinition data-driven și variants după primul job manual distractiv.

Ordinea familiilor candidate:

1. courier/delivery;
2. warehouse/cleaning/service;
3. taxi după trafic;
4. burglary/trespass;
5. auto theft după vehicle permissions/hotwire;
6. contraband după cargo/dirty cash/factions.

Security, store robbery, fraud/business și heists sunt post-slice și pot fi post-Early Access. Nu cerem șase familii complete înainte de a valida locațiile districtului.

## M15 — Primul district de producție

Se începe numai după vertical slice și după un greybox gameplay/location pass.

Pipeline:

1. metrics + modular kit;
2. representative street benchmark cu artă apropiată de final;
3. road/gameplay greybox lock;
4. exterior/HLOD/Nanite/LOD;
5. interioare/lighting/signage original;
6. traffic/crowd/audio;
7. gameplay/content placement;
8. four-bubble optimization și accessibility.

**Gate:** district finit, vandabil, repetabil și fără debt ce se multiplică la următorul district.

## M16 — Early Access content și hardening

Cantitățile sunt aprobate numai după măsurarea ritmului real de cod, QA și artă. Ținta de planificare, nu promisiunea, este:

- un district dens;
- tutorial 20–30 minute;
- cel puțin trei familii legale și trei ilegale numai dacă ritmul permite;
- variante data-driven suficiente pentru 10–15 ore fără repetare evidentă;
- vehicule/proprietăți/haine/bijuterii/echipamente pe mai multe tier-uri;
- police, hospital, prison, dirty money, rent/debt și portable characters;
- 1/2/4 players, Steam invite, join/reconnect;
- keyboard/mouse complet;
- localization-ready, accessibility de bază, crash/feedback flow.

Hardening:

- feature/content lock, regression și migration suite;
- security/RPC/economy exploit audit;
- network emulation și 3 × 2h multiplayer soak;
- cook/package/PSO/hitch/scalability;
- hardware requirements măsurate;
- legal/privacy/content review;
- release candidate + rollback build.

Manhattan complet nu este condiție pentru Early Access.

## M17 — Extinderea Manhattan

După Early Access, fabrica validată se repetă:

- câte un district cu același benchmark/gate;
- cataloage și job families noi;
- povești NPC/factions;
- businesses active fără venit offline;
- combat/melee/voice/controller/vreme extinse după cerere și buget;
- host migration/cross-store numai dacă merită un proiect separat.

Full Manhattan este rezultatul multiplicării unei bucle și a unui pipeline stabile, nu un singur task.

## Reguli pentru schimbarea roadmapului

1. problemă observată ori playtest;
2. metrică și cauza probabilă;
3. alternative + impact asupra dependențelor;
4. decizia creatorului când schimbă produsul;
5. ADR când schimbă arhitectura;
6. update simultan la DECISIONS/ROADMAP/STATUS/system docs/task;
7. un ID de task deja implementat nu este reutilizat pentru alt rezultat.

## Kill criteria

O caracteristică este simplificată/amânată dacă:

- nu produce o alegere observabilă;
- rupe gate-ul 1 host + 3 clienți separați;
- depășește bugetul fără fallback;
- cere duplicarea unui owner;
- nu poate fi testată ori migrată;
- depinde de conținut imposibil la ritmul real;
- creează risc juridic/licență neclară;
- există doar pentru a imita un alt joc.
