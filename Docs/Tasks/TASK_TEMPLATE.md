# BS-### — [Task title]

**Status:** Draft
**Owner:** Madalin Gavrila
**Branch:** `[type]/BS-###-[name]`
**Base commit:** `[hash]`
**Roadmap milestone:** M#
**System docs:** [links]

## Observable outcome

Ce poate vedea/testa creatorul după task?

## Why now

Ce dependență folosește și ce deblochează?

## In scope

- ...

## Out of scope

- ...

## Dependencies and required decisions

- tasks/gates;
- confirmed decisions;
- proposed/default values;
- ADRs.

## Allowed files/domains

- paths/systems permise;
- modificări interzise/nelegate.

## Authority/network impact

- owner/server/client;
- RPC/audience/relevancy;
- late join/reconnect/disconnect;
- `N/A + motiv` dacă nu atinge networking.

## Persistence/migration impact

- store/schema/version/migration/recovery;
- `N/A + motiv` dacă nu atinge persistarea.

## Performance budget

- update model;
- CPU/memory/network/content bounds;
- scenario/metric/threshold;
- `N/A + motiv` dacă nu este hot path.

## Blueprint/Editor impact

- assets/config/manual setup;
- Editor open/closed;
- validation.

## Acceptance criteria

1. **Given** ... **When** ... **Then** ...
2. ...

## Automated verification

- build target/config;
- unit/automation/functional/network/persistence/performance;
- exact command/action;
- expected result.

## Manual acceptance

Pași exacți conform `Docs/Workflows/EDITOR_INSTRUCTION_STANDARD.md`, cu PASS/FAIL.

## Risks and rollback

- base commit;
- riscuri;
- rollback/revert plan;
- save/content compatibility.

## Docs/ADR updates

- ...

## Verification evidence

| Data | Candidate commit | Runtime/content tree | Build/test/trace | Rezultat | Executat de |
|---|---|---|---|---|---|
| | | | | | |

Orice schimbare ulterioară în C++, Config, Content, `.uproject`, pluginuri ori build scripts marchează dovada candidatului `INVALIDATED` până la rerularea verificărilor relevante. Un commit ulterior exclusiv de evidence/docs poate referi tree-ul neschimbat.

## Final handoff

- schimbări;
- verificări trecute/omise;
- pași creator;
- log/captură cerută la fail;
- risc și next task.
