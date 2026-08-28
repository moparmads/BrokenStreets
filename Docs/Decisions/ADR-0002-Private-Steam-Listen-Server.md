# ADR-0002 — Private Steam Listen Server

**Status:** Accepted
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** roadmap / M3–M4
**Supersedes:** none
**Superseded by:** none

## Context

Broken Streets trebuie să funcționeze complet solo și cu creatorul plus trei prieteni. Nu se dorește server dedicat, configurare de router ori infrastructură publică în v1. Lansarea inițială este Steam-only.

## Decizie

- Solo folosește aceleași reguli autoritative, fără a crea o arhitectură offline separată.
- Co-op-ul folosește un listen server pe PC-ul host-ului.
- `Host` denumește jucătorul/PC-ul care rulează sesiunea; autoritatea gameplay aparține părții server. Clientul local al host-ului folosește aceleași command/RPC validation paths ca un client remote.
- Limita funcțională este maximum patru jucători în total: `1 host + 0–3 clients`.
- Sesiunile sunt private/invite-only prin Steam.
- Conectarea trebuie să funcționeze fără port forwarding manual, validată pe două rețele reale.
- Join-in-progress și reconnect fac parte din v1.
- Nu există tether; host-ul poate simula patru zone/interioare/joburi.
- Dedicated servers și cross-store nu intră în v1.

Host migration rămâne o decizie separată `Proposed`; recomandarea v1 este fără host migration, cu save și session close la shutdown normal.

## Consecințe pozitive

- cost operațional redus și co-op simplu între prieteni;
- server-side authority clar, inclusiv pentru acțiunile jucătorului host;
- Steam oferă identity/invites/transportul ce trebuie validat;
- scope fix pentru bugete și teste.

## Costuri și limite

- host-ul are cerințe CPU/RAM mai mari;
- sesiunea depinde de host și conexiunea lui;
- patru bule fără tether sunt riscul principal de scalare;
- Steam behavior nu poate fi acceptat numai prin PIE/LAN.

## Validation gate

- packaged build pe două PC-uri, două conturi Steam și două rețele;
- apoi host + trei clienți pentru four-bubble tests;
- reconnect, host normal shutdown și host crash;
- fără port forwarding manual.

## Approval

Acceptat prin cerințele explicite ale creatorului: Steam-only, co-op privat, fără server dedicat, creator + trei prieteni.
