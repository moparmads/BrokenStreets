# Decizii materiale rămase deschise

Acest fișier este o coadă de `Decision Packets`, nu un chestionar nou. Deciziile de produs de mai jos nu blochează fundația curentă; alegerea operațională OPS-01 devine necesară numai la task-ul ei. Codex întreabă când următorul task depinde direct de alegere.

Legendă: `Recommended` este direcția tehnică actuală, nu acceptarea creatorului.

## Înainte de backup-ul independent

| ID | Decizie | Recommended | Devine necesară înainte de |
|---|---|---|---|
| OPS-01 | Mediu/provider, capacitate, retenție și criptare pentru copia independentă Git/LFS și Source Art | mediu local separat plus copie versionată off-site; restore fără GitHub verificat | BS-010A și BS-013A |

## Înainte de Identity / Session / Save MVP

| ID sursă | Decizie | Recommended | Devine necesară înainte de |
|---|---|---|---|
| D61 | Host migration în v1? | Nu; shutdown normal salvează și închide sesiunea | Steam session MVP |
| D62 | Reconnect reservation | 120 secunde ca valoare de test, data-driven | reconnect implementation |
| D65 | Pauză | solo poate opri lumea; multiplayer nu oprește lumea din meniu | pause/menu behavior |
| D66 | Friendly fire / PvP | aliați; friendly fire configurabil ulterior, fără PvP/sabotaj | combat input/security |
| D72 | Conflict/commit fără backend | ultimul checkpoint confirmat bilateral câștigă; rezultat neconfirmat rollback/report; conflict cross-host cere alegere | portable profile transaction spike |
| D73–74 | UX save/manual și generații | autosave + safety save; minimum 5 generații cu checksum | save UI/recovery |

## Înainte de primul walking slice

| ID sursă | Decizie | Recommended | Devine necesară înainte de |
|---|---|---|---|
| D144 | Primul job legal | curierat/livrare pe jos | JobDefinition 1 |
| D146 | Descoperirea jobului | telefon + punct/NPC fizic simplu | job UI |
| D149–150 | Co-op/scaling | fiecare poate face orice; obiective/route/time/reward data-driven, fără health inflation | 1/2/4 acceptance |
| D151 | Reconnect în job | rezervare, reluare aceeași instanță, apoi reconciliere fără duplicare | job reconnect |
| D152 | Payout/eșec | payout individual afișat; fără payout complet la eșec; consecințele rămân | reward contract |

## Înainte de vehicule

| ID sursă | Decizie | Recommended | Devine necesară înainte de |
|---|---|---|---|
| D179 | Recovery vehicul | rămâne unde este în sesiune; după restart este recuperabil determinist în garaj | VehicleRecord persistence |
| D180 | Chei/permisiuni/hotwire | key record + permisiuni temporare + hotwire timed action | ownership integration |
| D185 | Reguli rutiere v1 | semafor, coliziune gravă, condus periculos, furt și stop simplu | traffic/police integration |

## Înainte de illegal reaction slice

| ID sursă | Decizie | Recommended | Devine necesară înainte de |
|---|---|---|---|
| D145 | Prima activitate ilegală | furt/recuperare colet într-o zonă restricționată | Illegal JobDefinition 1 |
| D160 | Treptele poliției | Attention, Pursuit, Armed Response, Manhunt; fără elicopter v1 | Police state model |
| D163 | Complicitate | numai după ajutor concret, nu proximitate | party law rules |

## Înainte de health/prison/needs

| ID sursă | Decizie | Recommended | Devine necesară înainte de |
|---|---|---|---|
| D105 | Downed window/revive cap | 60 sec și un revive/incident doar ca test | Health tuning playtest |
| D106/D122 | Pierderi hospital/arrest | banca sigură; procentele sunt tuning, confiscarea prin ownerii Economy/Inventory | Consequences transaction |
| D166 | Prison loop | 3–12 minute, activități simple, fără prison break v1; bail/vizite/disconnect prin playtest | Prison design |

## Înainte de proprietăți și aspirație extinsă

| ID sursă | Decizie | Recommended | Devine necesară înainte de |
|---|---|---|---|
| D142 | Businesses | post-Early Access; activitate fizică, fără venit offline | business roadmap |
| D199 | DCC și pipeline numeric | programele creatorului + bugete măsurate în Benchmark Street | import masiv de artă |

## Înainte de Early Access content lock

| ID sursă | Decizie | Recommended | Devine necesară înainte de |
|---|---|---|---|
| D187 | HUD permanent/contextual | contextual și configurabil | UI production lock |
| D192 | Voice chat | group voice candidat; proximity/phone ulterior | platform feature lock |
| D194 | Muzică personală | local-only; fără retransmitere | audio feature lock |
| D195 | Limbi | English source, Romanian candidat; toate textele localizabile | content lock |
| D200 | Prag comercial | un district finit; cantitățile se recalculează după vertical slice | Early Access commitment |

## Cum se închide o decizie

1. Codex prezintă contextul, maximum trei alternative și recomandarea.
2. Creatorul alege sau cere prototip.
3. Se actualizează `DECISIONS.md` din `PROPUS — NECESITĂ APROBARE` în `CONFIRMAT` ori `RESPINS`.
4. Dacă alegerea este arhitecturală și greu de inversat, se acceptă/supersedează un ADR.
5. Task-ul dependent devine `Ready`.

Nu cerem toate aceste răspunsuri acum; decizia luată înainte de date reale este adesea mai slabă decât un default reversibil.
