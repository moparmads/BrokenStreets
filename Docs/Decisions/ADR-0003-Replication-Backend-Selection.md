# ADR-0003 — Replication Backend Selection

**Status:** Proposed
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** M3 four-bubble spike
**Supersedes:** none
**Superseded by:** none

## Context

Patru jucători se pot separa pe o lume mare, iar fiecare bulă poate avea actori relevanți diferiți. UE 5.8.2 oferă standard replication, Replication Graph și Iris, dar etichetele/maturitatea și integrarea diferă. Alegerea prematură poate bloca Shipping ori produce coupling inutil.

## Alternative

1. Standard replication + relevancy/dormancy/conditions.
2. Standard replication + Replication Graph pentru routing/relevancy.
3. Iris în spike separat.

## Recomandare propusă

- Standard replication este fallback-ul obligatoriu.
- Se măsoară mai întâi workload-ul 1 host + 3 clienți împreună și separați.
- Replication Graph se adoptă numai dacă oferă un avantaj necesar și trece build/late join/reconnect/packaged tests în UE 5.8.2.
- Iris se testează numai dacă baseline-ul nu trece ori avantajul potențial justifică riscul.
- Domeniile expun comenzi/read models fără a depinde de un backend unic.

## Metrici/gate ce trebuie completate înainte de acceptare

- server frame time și replication time;
- bandwidth per client și total;
- replicated actor/subobject counts;
- snapshot size și late-join time;
- dormancy/relevancy correctness;
- 100–200 ms latency + packet loss;
- memory și stability în packaged host + 3 clients;
- fallback demonstrat.

## Revisit trigger

Workload-ul reprezentativ se schimbă material ori o versiune UE viitoare schimbă maturitatea/compatibilitatea. Upgrade-ul nu se face în același task.
