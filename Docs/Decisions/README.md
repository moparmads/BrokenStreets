# Architecture Decision Records

ADR-urile păstrează decizii tehnice cross-system, costisitoare ori greu de inversat. Nu sunt folosite pentru prețuri, damage numbers, UI spacing sau alte valori de tuning.

## Statusuri

- `Proposed` — recomandare în așteptarea aprobării/prototipului;
- `Accepted` — decizie activă;
- `Rejected` — analizată și refuzată;
- `Superseded` — înlocuită de ADR-ul indicat;
- `Deprecated` — încă există pentru compatibilitate, dar nu se extinde.

Codex poate crea `Proposed`. O decizie de produs materială devine `Accepted` numai după alegerea lui Madalin; o decizie pur tehnică poate fi acceptată după gate-ul măsurat prevăzut în ADR.

Nu rescrie un ADR vechi pentru a ascunde istoria. Creează unul nou și folosește `Superseded by`.

## Index

| ADR | Titlu | Status | Validation gate |
|---|---|---|---|
| ADR-0001 | Portable Character Ownership | Accepted | M4 portability/recovery |
| ADR-0002 | Private Steam Listen Server | Accepted | M3 Steam + M4 sessions |
| ADR-0003 | Replication Backend Selection | Proposed | M3 four-bubble benchmark |
| ADR-0004 | Instanced Private Properties | Proposed | M3 four-interior isolation |
| ADR-0005 | Renderer and Scalability Baseline | Proposed | BS-013B test baseline / M15 final benchmark |

## Când este obligatoriu

- network topology/backend/relevancy;
- save schema/protocol/conflict policy;
- module/plugin/third-party dependency;
- World Partition/server streaming/interior architecture;
- renderer/scalability baseline;
- owner/graniță cross-system;
- tehnologie ce poate bloca Shipping ori migration.
