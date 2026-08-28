# System Ownership

Ownership înseamnă cine poate modifica adevărul runtime, nu cine lucrează la fișier. Orice stare are un singur writer. Un consumer cere schimbarea printr-o comandă tipizată și primește rezultat/eveniment/read model.

## Dimensiunile ownership-ului

- **Storage owner:** tipul/serviciul care păstrează starea în memorie.
- **Runtime mutation authority:** singurul domeniu care poate valida și modifica acea stare.
- **Persistence owner:** domeniul produce snapshotul semantic; Save orchestrează versiunea și I/O.
- **Replication audience:** public, owner-only, party, relevant-only ori server-only.

Aceste roluri pot locui temporar în același Actor/Subsystem, dar nu se confundă conceptual.

**Terminologie:** `host` este jucătorul/PC-ul care rulează listen serverul. În coloana Runtime authority, `server` înseamnă exclusiv partea server a acelui proces. Clientul local al host-ului trece prin aceleași validări ca orice client remote.

## Matricea domeniilor

| Domeniu | Adevăr deținut | Runtime authority | Persistență | Audience implicit | Consumatori / comenzi publice | Dependențe interzise |
|---|---|---|---|---|---|---|
| Core | typed IDs, results/errors, time types, tags, feature flags | local/server după tip; fără gameplay global | config/version metadata | după consumator | toate domeniile folosesc primitive | nu depinde de gameplay/UI |
| Identity/Profile | AccountId binding, CharacterId, character slots, Portable Profile revision | server validează runtime; clientul deține fișierul local | PortableCharacterProfile | owner-only/server | Online, Save, Player cer identity/profile snapshot | nu acceptă profilul clientului ca adevăr neverificat |
| Online/Session | lobby, invite, join, member state, reservation | server pentru sesiune; platforma pentru identity/lobby | config + minimal session recovery | party/public summary | UI și Save consumă lifecycle events | nu modifică economie/inventar |
| Network | RPC policy, relevancy, facades, compatibility handshake | server | config/ADR, nu gameplay save | variabil | toate domeniile replicate | nu devine ownerul semantic al stării |
| World | world clock, weather, district/world state, streaming coordination | server/world owner | HostWorldSave | public/relevant | Needs, AI, Traffic, Events | nu modifică CharacterActiveTime personal |
| Player | possession, locomotion state, input intent, camera gameplay parity | server pentru movement/gameplay; local pentru presentation | profil/settings unde e necesar | public/relevant + local | Interaction, Combat, UI | nu deține bani/save/catalog |
| Appearance | body preset, outfit record, jewelry, visual/social signature | server validează echiparea | Portable Profile | public subset + owner private | AI, Law, UI | nu mută iteme fără Inventory/Ownership |
| Interaction | focus target, verb eligibility, timed action lifecycle | server validează acțiunea | numai acțiuni ce cer recovery | owner/relevant | emite commands către domeniul țintă | nu aplică direct bani/item state |
| Items | definitions și instance metadata | server pentru instanțe; definitions immutable | item records prin ownerul containerului | owner/relevant | Inventory, Shops, Jobs | nu decide container, bani ori ownership |
| Inventory | locația unică a itemului, containers, capacity/weight | server | Portable Profile/Vehicle/Property/World după container | owner/authorized | Move/Add/Remove cu precondiții | nu modifică bani ori drepturi de ownership |
| Ownership | owner, access rights, keys, permissions, transfer | server | recordul bunului | owner/authorized/public summary | Inventory, Vehicles, Properties, Trade | nu mută itemul și nu debitează bani direct |
| Economy | legal cash, bank, dirty cash, EconomyTransactionLedger | server | Portable Profile + journal/receipts | owner-only | debit/credit/transfer/quote results | nu creează item, job ori drept de proprietate |
| Progression | level, licenses, unlocks, progression awards applied | server | Portable Profile | owner-only/public summary selectiv | Jobs/Activities emit award request | nu calculează payout monetar |
| Shops | catalog view, stock/offers, order lifecycle | server/world owner | HostWorldSave unde stock persistă | requester/public catalog | cere tranzacții coordinatorului | nu scrie wallet/inventory |
| Jobs | definitions, JobInstance, participants, objectives, outcome | server/session owner | HostWorldSave/SessionCommitJournal; receipt în profil | participants/public summary | cere rewards, incidents, progression | nu scrie direct bani/heat/profile |
| Legality | clasificarea acțiunii și Incident/heat request | server | incident temporar; cazier prin domeniul relevant | relevant/owner | Police/Factions consumă Incident | nu spawn-ează poliție și nu aplică damage |
| Police | response tier, dispatch, pursuit, arrest state | server | active state world/session; outcome/cazier persistent coordonat | relevant/public + owner | consumă Incident, cere AI/Consequences | nu inventează crime, bani ori confiscări |
| Factions | reputație per familie, access, retaliation | server | Portable Profile + world NPC state separat | owner/relevant | Jobs, AI, Dialogue | nu modifică Economy direct |
| Needs | hunger, thirst, sleep, bladder, hygiene | server, din CharacterActiveTime | Portable Profile | owner-only + efecte publice minime | Player/Health/UI consumă effects | nu controlează world clock/sleep vote |
| Health | health, hit zones, wounds, downed/revive | server | Portable Profile pentru injury persistent | relevant + owner detail | Combat/Consequences/UI | nu aplică fee/confiscare |
| Consequences | orchestration downed/arrest → hospital/prison → release | server | session/world + receipts personale | participant/relevant | cere mutații de la Health/Economy/Inventory | nu dublează adevărul domeniilor chemate |
| Combat | attack intent, weapon operation, hit resolution | server | weapon state prin Inventory/Items; stats unde e cazul | relevant | cere damage la Health și Incident la Legality | nu modifică health/heat direct |
| Vehicles | VehicleRecord semantic, runtime vehicle, seats, fuel, condition, trunk link | server | Portable Profile/approved store | relevant + owner detail | Ownership, Inventory, World | nu deține conținutul trunkului; Inventory îl deține |
| Properties | PropertyRecord, instance rights, visitors, decor/storage placement | server | Portable Profile + materialization world state | authorized/relevant | Ownership, Economy, Inventory | nu scrie wallet sau item location direct |
| AI Foundation | nav/perception/state tasks, spawn anchors, simulation tier | server | doar NPC important/world deltas | relevant | Police, Population, Jobs, Factions | nu deține lege/job/economie |
| Population | ambient records, spawn, promote/demote, crowd budget | server | statistical/world state minim | relevant | World, Legality presentation | NPC ambient nu devine profil persistent implicit |
| Traffic | flow records, promote/demote, physical traffic budget | server | statistical/world state minim | relevant | World, Police, Vehicles | nu deține vehicule personale |
| World Events | eligibility, cooldown, event instance, budget | server/world owner | HostWorldSave dacă persistă | relevant/participants | Jobs, World, AI | nu ocolește owners pentru rewards/incidents |
| UI | view models, focus, layout, local navigation | local | user settings numai | local | trimite intents și prezintă read models | nicio mutație gameplay directă |
| Audio | mixes, routing, occlusion, radio presentation | local + metadata server limitată | settings/content | local/relevant | World, Vehicle, UI | nu schimbă state gameplay prin audio event |
| Save | schema registry, capture coordination, migration, checksum, I/O, generations | server/local după store | fișierele aprobate | server/local only | cere snapshot de la owners | nu calculează reguli ori rezolvă tăcut conflicte |
| Build/Tools | build, cook, validation, profiling, automation | developer/editor | rapoarte și config versionat | developer | toate domeniile | nu intră ca dependency runtime Shipping |

## Operații multi-domeniu

Un `UseCaseCoordinator`/transaction coordinator poate ordona comenzi și compensări, dar nu scrie direct starea ownerilor. Fiecare operație are ID idempotent și rezultat explicit.

Exemple:

- **Purchase:** Shop offer → Economy debit → Items/Inventory materialization → Ownership transfer → receipt/commit.
- **Trade:** bilateral consent → permission lock → Inventory moves → Ownership transfers → Economy transfers opționale → unlock/commit.
- **Hospital:** Consequences starts → Health outcome → Economy fee → Inventory confiscation/move → safe spawn → receipt.
- **Job payout:** Jobs outcome → Economy/Progression requests → SessionCommitJournal receipt → profile export.

La eșec, coordinatorul folosește pași compensabili ori marchează operația pentru recovery; nu presupune că două fișiere pe PC-uri diferite pot fi atomic tranzacționate.

## Reguli de dependență

- Core nu depinde de domenii gameplay.
- Definitions/data pot fi consumate de runtime; runtime nu modifică definitions.
- Economy nu depinde de Jobs; Jobs consumă Economy API.
- Inventory și Ownership sunt separate: locația itemului nu este dreptul asupra lui.
- Progression nu este Economy; level-ul nu modifică damage-ul.
- Legality produce Incident; Police produce răspuns.
- Health produce downed; Police produce arrest; Consequences orchestrează rezultatul.
- Save depinde de snapshot interfaces, nu de implementarea internă a fiecărui owner.
- UI și Audio nu sunt dependencies ale regulilor de domeniu; presentation consumă output.
- Editor/DeveloperTool nu sunt dependencies runtime Shipping.

## Contractul unui document de sistem

Un document real se creează just-in-time din `Docs/Systems/SYSTEM_TEMPLATE.md`, nu ca placeholder gol. El trebuie să fixeze:

- owner și cele patru dimensiuni de ownership;
- commands/events și consumers;
- authority, RPC validation, audience și late join;
- data model, IDs, persistence/migration;
- update model, LOD și bugete;
- Blueprint/Editor surface;
- failures/exploits/recovery;
- teste și acceptance steps;
- dependențe permise/interzise.

Orice modificare ce ar crea doi writers pentru același adevăr este defect arhitectural și necesită redesign/ADR, nu o excepție rapidă.
