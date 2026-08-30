# ADR-0003 — Replication Backend Selection

**Status:** Proposed
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** M3 four-bubble spike
**Supersedes:** none
**Superseded by:** none

## Context

Four players may separate across a large world, giving each simulation bubble a different set of relevant Actors. UE 5.8.2 provides standard replication, Replication Graph, and Iris, but their labels, maturity, and integration differ. A premature choice could block Shipping or create unnecessary coupling.

## Alternatives

1. Standard replication with relevancy, dormancy, and conditions.
2. Standard replication plus Replication Graph for routing and relevancy.
3. Iris in a separate spike.

## Proposed recommendation

- Standard replication is the mandatory fallback.
- First measure one host plus three clients both together and separated.
- Adopt Replication Graph only when it provides a necessary benefit and passes build, late-join, reconnect, and packaged tests in UE 5.8.2.
- Test Iris only when the baseline fails or its potential advantage justifies the risk.
- Domains expose commands and read models without depending on a single replication backend.

## Metrics/gate required before acceptance

- server frame time and replication time;
- bandwidth per client and total bandwidth;
- replicated Actor/subobject counts;
- snapshot size and late-join time;
- dormancy/relevancy correctness;
- 100–200 ms latency plus packet loss;
- memory and stability in a packaged host plus three clients;
- demonstrated fallback.

## Revisit trigger

The representative workload changes materially, or a future UE version changes maturity or compatibility. An engine upgrade is never performed in the same task.
