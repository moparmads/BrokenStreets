# Architecture Decision Records

ADRs preserve technical decisions that are cross-system, expensive, or difficult to reverse. They are not used for prices, damage numbers, UI spacing, or other tuning values.

## Statuses

- `Proposed` — recommendation awaiting approval or prototype evidence;
- `Accepted` — active decision;
- `Rejected` — analyzed and declined;
- `Superseded` — replaced by the referenced ADR;
- `Deprecated` — retained for compatibility but no longer extended.

Codex may create a `Proposed` ADR. A material product decision becomes `Accepted` only after Madalin chooses it; a purely technical decision may be accepted after the measured gate defined by the ADR passes.

Do not rewrite an old ADR to hide history. Create a new one and use `Superseded by`.

## Index

| ADR | Title | Status | Validation gate |
|---|---|---|---|
| ADR-0001 | Portable Character Ownership | Accepted | M4 portability/recovery |
| ADR-0002 | Private Steam Listen Server | Accepted | M3 Steam + M4 sessions |
| ADR-0003 | Replication Backend Selection | Proposed | M3 four-bubble benchmark |
| ADR-0004 | Instanced Private Properties | Proposed | M3 four-interior isolation |
| ADR-0005 | Renderer and Scalability Baseline | Accepted | BS-013B test baseline / M15 final benchmark |

## When an ADR is mandatory

- network topology/backend/relevancy;
- save schema/protocol/conflict policy;
- module/plugin/third-party dependency;
- World Partition/server streaming/interior architecture;
- renderer/scalability baseline;
- cross-system owner/boundary;
- technology that can block Shipping or migration.
