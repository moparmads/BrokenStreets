# Remaining material open decisions

This file is a queue of Decision Packets, not a new questionnaire. The product decisions below do not block the current foundation. Codex asks when the next task directly depends on a choice.

Legend: `Recommended` is the current technical direction, not creator acceptance.

## Resolved foundation operations

| ID | Confirmed decision | Evidence/task |
|---|---|---|
| OPS-01A | Independent Git/LFS layer uses `E:/BrokenStreets_RepositoryBackup` on the separate physical disk; daily 19:00 plus manual checkpoints; 30 Git generations; LFS objects never auto-delete; warn below 100 GiB; no additional local encryption | BS-010A |
| OPS-01B | Source Art uses a versioned local layer on `E:` plus a complete repository/Source Art checkpoint on the approved 1 TB LaCie USB drive; the drive is unencrypted by creator choice, is safely disconnected and stored separately after a successful checkpoint, and uses no paid provider; content objects are never auto-deleted; capacity is reviewed at 300 GiB Source Art or below 150 GiB free | BS-013A |

## Before Identity / Session / Save MVP

| Source ID | Decision | Recommended | Required before |
|---|---|---|---|
| D61 | Host migration in v1? | No; normal shutdown saves and closes the session | Steam session MVP |
| D62 | Reconnect reservation | 120 seconds as a data-driven test value | reconnect implementation |
| D65 | Pause | solo may stop the world; multiplayer menus do not stop it | pause/menu behavior |
| D66 | Friendly fire / PvP | allies; friendly fire configurable later, no PvP/sabotage | combat input/security |
| D72 | Conflict/commit without backend | last bilaterally confirmed checkpoint wins; unconfirmed result rolls back/reports; cross-host conflict asks the player | portable-profile transaction spike |
| D73–74 | Save/manual UX and generations | autosave + safety save; at least 5 checksum-protected generations | save UI/recovery |

## Before the first walking slice

| Source ID | Decision | Recommended | Required before |
|---|---|---|---|
| D144 | First legal job | walking courier/delivery | JobDefinition 1 |
| D146 | Job discovery | phone + simple physical point/NPC | job UI |
| D149–150 | Co-op/scaling | everyone can do everything; data-driven objectives/route/time/reward, no health inflation | 1/2/4 acceptance |
| D151 | Reconnect during a job | reservation, resume same instance, then reconcile without duplication | job reconnect |
| D152 | Payout/failure | visible individual payout; no full payout on failure; consequences remain | reward contract |

## Before vehicles

| Source ID | Decision | Recommended | Required before |
|---|---|---|---|
| D179 | Vehicle recovery | remains where it is during the session; after restart it is deterministically recoverable in the garage | VehicleRecord persistence |
| D180 | Keys/permissions/hotwire | key record + temporary permissions + timed hotwire action | ownership integration |
| D185 | v1 traffic rules | traffic lights, serious collision, dangerous driving, theft, and simple stop | traffic/police integration |

## Before the illegal reaction slice

| Source ID | Decision | Recommended | Required before |
|---|---|---|---|
| D145 | First illegal activity | steal/recover a package from a restricted area | Illegal JobDefinition 1 |
| D160 | Police tiers | Attention, Pursuit, Armed Response, Manhunt; no helicopter in v1 | Police state model |
| D163 | Complicity | only after concrete assistance, never proximity alone | party law rules |

## Before health/prison/needs

| Source ID | Decision | Recommended | Required before |
|---|---|---|---|
| D105 | Downed window/revive cap | 60 seconds and one revive/incident only as test values | Health tuning playtest |
| D106/D122 | Hospital/arrest losses | bank is safe; percentages are tuning; confiscation goes through Economy/Inventory owners | Consequences transaction |
| D166 | Prison loop | 3–12 minutes, simple activities, no v1 prison break; bail/visits/disconnect set by playtest | Prison design |

## Before properties and extended aspiration

| Source ID | Decision | Recommended | Required before |
|---|---|---|---|
| D142 | Businesses | post-Early Access; physical activity, no offline income | business roadmap |
| D199 | DCC and numeric pipeline | creator's applications + budgets measured in Benchmark Street | mass art import |

## Before Early Access content lock

| Source ID | Decision | Recommended | Required before |
|---|---|---|---|
| D187 | Permanent/contextual HUD | contextual and configurable | UI production lock |
| D192 | Voice chat | group voice candidate; proximity/phone later | platform feature lock |
| D194 | Personal music | local-only; no rebroadcast | audio feature lock |
| D195 | Languages | English source; additional localization only after content scope and demand are measured | content lock |
| D200 | Commercial threshold | one finished district; recalculate quantities after the vertical slice | Early Access commitment |

## Closing a decision

1. Codex presents context, up to three alternatives, and a recommendation.
2. The creator chooses or requests a prototype.
3. Update `DECISIONS.md` from `PROPOSED — APPROVAL REQUIRED` to `CONFIRMED` or `REJECTED`.
4. If the choice is architectural and difficult to reverse, accept or supersede an ADR.
5. The dependent task becomes `Ready`.

Do not request every answer now. A decision made before real evidence is often weaker than a reversible default.
