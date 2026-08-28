# ADR-0004 — Instanced Private Properties

**Status:** Proposed
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** M3 four-interior spike
**Supersedes:** none
**Superseded by:** none

## Context

Apartamentele private pot folosi loading mascat și pot avea același template pentru mai mulți owners. Patru jucători trebuie să poată fi simultan în patru interioare diferite, iar prietenii autorizați pot vizita aceeași instanță. Server travel nu poate muta un singur jucător fără a afecta sesiunea.

## Recomandare propusă

- `PropertyTemplateId` descrie interiorul comun; `PropertyInstanceId` identifică proprietatea personală.
- Instanțele sunt materializate în sloturi izolate în același world autoritativ.
- Un loading screen individual maschează încărcarea și teleportul.
- Visitors intră în aceeași `PropertyInstanceId` după permission validation.
- Mobilierul folosește `ItemInstanceId` + transform + ownership/container, fără coliziuni între template-uri identice.
- Tehnologia concretă (Level Instance/Data Layers/alt runtime) nu este aleasă înainte de spike.

## Gate obligatoriu

Patru instanțe simultane trebuie să demonstreze izolare pentru:

- visuals/occlusion;
- audio;
- collision/physics;
- nav/AI;
- replication/relevancy;
- permissions/visitors;
- IDs/save;
- load/unload/memory caps.

## Fallback

Reducerea numărului de instanțe simultane, slot pool mai strict, interioare simplificate ori acces secvențial controlat. Nu folosim server travel individual imposibil și nu pretindem izolare per-player prin Data Layers globale fără dovadă.
