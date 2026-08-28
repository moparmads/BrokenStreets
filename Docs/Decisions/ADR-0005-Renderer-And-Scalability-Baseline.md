# ADR-0005 — Renderer and Scalability Baseline

**Status:** Proposed
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** BS-013B test baseline / M15 representative benchmark final
**Supersedes:** none
**Superseded by:** none

## Context

Blank/Maximum wizardul a activat Ray Tracing și Substrate. Aceste setări nu reprezintă o decizie măsurată. Produsul urmărește realism vizual ridicat, dar FPS/stabilitatea și un preset Low accesibil au prioritate.

## Alternative

1. software/Lumen baseline fără hardware RT obligatoriu;
2. hardware RT ca opțiune High/Ultra;
3. hardware RT obligatoriu pentru toate presetările;
4. Substrate integral ori selectiv versus material pipeline clasic.

## Recomandare propusă

- Minimum/Low nu depinde de hardware Ray Tracing sau Frame Generation.
- High/Ultra poate activa RT numai dacă benchmark-ul justifică și are fallback clar.
- Lumen/VSM/Nanite/Substrate/TSR și alternativele se măsoară pe aceeași representative street.
- Gameplay entities rămân identice între presetări; numai cosmetic/ambient density se reduce.
- Nu blocăm valorile înainte de un workload apropiat de artă finală.

## Gate

Pentru fiecare preset/hardware fixăm:

- driver, resolution/internal scale și build;
- p50/p95/p99/max GT/RT/GPU;
- VRAM/working set;
- shader/PSO/streaming hitches;
- imagine comparativă și defecte vizibile;
- 20% headroom target în scenariul normal unde este posibil.

## Task imediat

BS-011 creează map-ul project-owned, iar BS-013B transformă setările accidentale într-un config PC-only explicit de test și consemnează rezultatul inițial. Acceptarea rendererului final are loc după Representative Street cu artă relevantă în M15.
