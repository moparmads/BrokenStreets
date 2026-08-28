# Strategia de testare

Testarea demonstrează corectitudinea pe aceeași topologie și același build în care va rula produsul. PIE este feedback rapid, nu acceptare finală pentru Steam, cook, save recovery ori patru bule.

## 1. Niveluri

### Pure/unit-style automation

Pentru logică fără World când este posibil:

- money integer math;
- typed IDs și validation;
- state transitions;
- weight/capacity/permissions;
- transaction idempotency;
- serialization helpers/migrations;
- deterministic selection/seeds.

### Engine automation

- UObject/data behavior;
- Asset Manager/definitions;
- settings/tags/redirects;
- schema/registry;
- command validation;
- content/data validators.

### Functional map tests

- interaction;
- player/vehicle;
- job/police/AI;
- property/interior;
- integration între owners;
- project-owned TestGym fixtures.

### Network tests

- listen server + clients multiprocess;
- authority/RPC/relevancy;
- late join/reconnect;
- together/separated bubbles;
- latency/loss/disconnect;
- privacy owner-only/public.

### Persistence/fault tests

- save/load/migration;
- crash în etapele I/O;
- corrupt/stale/conflict;
- duplicate commands;
- rollback/recovery.

### Performance/soak

- Unreal Insights și counters;
- representative packaged workload;
- memory/streaming/network growth;
- traversare și sesiuni lungi.

## 2. Gate universal per task de cod

- `BrokenStreetsEditor | Win64 | Development` build;
- testele țintite;
- Data Validation dacă există data/assets;
- zero warning/log spam nou;
- un test omis declarat cu motiv/risc;
- bug important → regression test când este fezabil;
- test/debug code exclus din Shipping.

## 3. Matrice multiplayer

Pentru un feature autoritativ/replicat:

| Scenariu | Scop |
|---|---|
| solo | aceeași regulă fără client remote |
| 1 host + 1 client | boundary și state de bază |
| 1 host + 3 clienți | limita totală de patru jucători |
| toți împreună | contention și public relevancy |
| toți separați | four-bubble CPU/memory/streaming/relevancy |
| late join | snapshot/read-model complet |
| reconnect | reservation/recovery/idempotency |
| disconnect mid-command | cancel/commit/report corect |
| 100–200 ms latency | prediction/UX/command correctness |
| packet loss moderat | retry și state reconstruction |
| invalid/spam client | server validation/rate limit |

PIE/multi-process local este smoke. Feature gate folosește packaged Development și automatizare multiprocess (Gauntlet când BS-009+ o introduce). Steam gate folosește minimum două PC-uri, două conturi și două rețele reale. Înainte de content lock: patru PC-uri reale, host hardware-etalon + trei clienți remote.

## 4. Persistență și tranzacții

Teste obligatorii după relevanță:

- același `TransactionId` trimis de 100 ori produce un singur rezultat;
- expected revision vechi este refuzat/reconciliat explicit;
- disconnect între pași ajunge la commit/rollback/report, nu stare tăcut parțială;
- crash înainte și după capture/serialize/temp write/flush/read-back/checksum/replace/manifest commit;
- temp/truncated/corrupt/invalid checksum;
- temp pe același volum, manifest neactualizat prematur și fallback newest-to-oldest la generația committed validă;
- golden migrations păstrează StableIds;
- ProfileEpoch conflict și stale receipt;
- CharacterActiveTime nu sare după offline, alt host/world clock/timezone;
- `LastAppliedActiveTime` nu dublează efectul;
- itemul nu poate exista în două containere;
- VehicleRecord/PropertyRecord nu se clonează la materializare;
- două PropertyInstanceIds cu același template nu împart storage/decor;
- world cell unload/reload nu pierde actor/state autoritativ;
- compatibility handshake refuză build/content/schema incompatibil cu recovery message.

## 5. Performance

Acceptarea folosește:

- packaged Development ori Shipping-like;
- commit/build/engine/driver/hardware/preset/resolution fixate;
- minimum trei rulări comparabile;
- warm-up declarat;
- p50/p95/p99/max pentru GT, RT și GPU după disponibilitate;
- hitches și longest frames;
- working set, VRAM, loaded cells, actors/components/AI/physics counts;
- network bandwidth, RPC/replication counts și snapshot sizes;
- trace/counters păstrate cu nume standard.

Ținta provizorie normală la 60 FPS urmărește p95 ≤ 13,33 ms pentru pipeline-ul limitativ ca rezervă de 20%, dar bugetele finale se îngheață numai după Benchmark Street pe hardware-etalon. Nu falsificăm PASS prin Frame Generation.

## 6. Determinism și fixtures

- TestGym folosește seed/date controlate.
- Fiecare test curăță starea creată ori folosește world/save separat.
- Ora, vremea, numărul participanților și latency profile sunt explicite.
- DefinitionIds/InstanceIds de test sunt stabile și nu se confundă cu content production.
- Un test nu depinde de ordinea altui test.
- Flaky test nu este ignorat; se marchează și se repară ori se scoate justificat din gate.

## 7. Security/abuse scope

Co-op-ul privat acceptă editarea intenționată a save-ului, dar partea server a listen serverului trebuie să refuze, inclusiv pentru clientul local al host-ului:

- RPC fără permisiune/identitate;
- distanță/stare/target invalid;
- payload/cardinality peste limită;
- spam fără rate limit;
- client-provided money/item/job/damage result;
- stale/replayed command ce ar dubla rezultatul;
- access la date private ale altui jucător.

## 8. Evidence

Task packet-ul salvează:

```text
Commit/build:
Test name/command:
Topology:
Map/seed:
Latency/loss:
Hardware/preset:
Expected:
Actual:
PASS/FAIL:
Log/trace/report path:
Warnings/skips:
```

Rapoartele generate grele rămân în `Saved/` ori storage-ul aprobat; în Git intră numai baseline summaries mici și utile, fără date sensibile.

Evidence-ul este legat de candidate commit/tree. Dacă după test se schimbă orice input runtime — C++, Config, Content, `.uproject`, plugin ori build script — dovada devine `INVALIDATED` și verificările relevante se repetă. Un commit ulterior numai cu task/status/evidence poate referi candidatul verificat, cu lista explicită a fișierelor runtime neschimbate.
