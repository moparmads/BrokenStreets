# Bugete de performanță

**Status:** provisional până la `L_Benchmark_Street` și PC-etalon.
**Regulă:** `TBD` este mai corect decât un număr inventat. Valorile se îngheață prin task/ADR după măsurare.

## 1. Profiluri țintă

| Profil | Țintă provizorie | Condiții |
|---|---|---|
| Minimum/Low | 1080p, 30 FPS stabil | SSD, 16 GB RAM, upscaling permis, fără Frame Generation necesar |
| Recommended | 1080p, 60 FPS stabil | 32 GB RAM recomandat; hardware exact TBD |
| Host Recommended | aceeași calitate cu rezervă CPU/RAM | 1 host + 3 clienți în patru bule |
| Ultra | realism vizual pentru hardware puternic | nu schimbă gameplay-ul; RT poate fi opțional după ADR |

## 2. Frame budgets

| Target | Frame interval | Working p95 target cu ~20% rezervă | Status |
|---|---:|---:|---|
| 60 FPS | 16,67 ms | 13,33 ms pentru pipeline-ul limitativ în scenariul normal | Provisional |
| 30 FPS | 33,33 ms | 26,67 ms | Provisional |

GT, RT și GPU se raportează separat; FPS-ul este limitat de cel mai lent. p50/p95/p99/max și hitches sunt necesare; media singură nu este suficientă.

## 3. Hitch budgets provizorii

- fără hitch-uri repetate peste 50 ms în traversare normală;
- fără hitch peste 100 ms la intrarea normală într-o celulă după warm-up;
- loading/interior transition targets rămân provisional până la hardware-etalon;
- shader/PSO/asset streaming hitches sunt clasificate separat.

## 4. Runtime invariants

- niciun RPC reliable per frame;
- niciun global actor scan repetat în gameplay;
- niciun sync-load în hot path normal;
- niciun hard reference global ce încarcă întregul catalog;
- economie/ownership/save/job transitions event-driven;
- needs/rare systems nu rulează per frame;
- traffic/crowd îndepărtat nu păstrează Actor/fizică completă;
- UI folosește events/invalidation, nu Blueprint polling;
- Tick este disabled by default și are owner/frequency/budget/evidence când este necesar.

## 5. Bugete ce trebuie măsurate

| Arie | Metrică | Low | Recommended/Host | Freeze gate |
|---|---|---:|---:|---|
| CPU | GT/RT p95/p99 | TBD | TBD | Benchmark Street/four bubbles |
| GPU | GPU p95/p99 | TBD | TBD | Representative art benchmark |
| Memory | process working set | TBD | TBD | four-bubble soak |
| VRAM | peak/resident/evictions | TBD | TBD | renderer ADR |
| Streaming | loaded cells, IO, load/unload time | TBD | TBD | WP spike |
| Network | bandwidth/client/total | TBD | TBD | replication spike |
| Network | initial snapshot/late join | TBD | TBD | replicated feature gate |
| Actors | full/reduced/representation counts | TBD | TBD | population/traffic benchmark |
| AI | active/reduced/statistical | TBD | TBD | AI/Police gate |
| Physics | bodies/vehicles/collision cost | TBD | TBD | vehicle/combat gate |
| Save | snapshot size/capture/serialize/write | TBD | TBD | 10k record test |
| Content | material slots/texture/mesh/LOD | per category TBD | per category TBD | representative asset kit |

## 6. Scalability contract

Low poate reduce:

- ambient crowd/traffic density;
- shadow/reflection/lighting quality;
- cosmetic props/VFX/decals/distance;
- animation/update quality pentru entități ambientale.

Low nu poate elimina ori schimba:

- police/AI relevant;
- witnesses/detectors folosiți de gameplay;
- objectives, loot, interactables și collisions importante;
- visibility esențială pentru stealth/combat;
- job outcomes, economy, save ori simulation rules.

## 7. Raport before/after

```text
Scenario/version:
Commit/build/engine:
Hardware/OS/driver:
Preset/resolution/upscaler:
Topology/map/seed/weather:
Warm-up/runs:
GT p50/p95/p99/max:
RT p50/p95/p99/max:
GPU p50/p95/p99/max:
Hitches:
Working set/VRAM:
Loaded cells/actors/AI/physics:
Bandwidth/snapshot:
Change versus baseline:
PASS/FAIL and fallback:
Trace path:
```

O schimbare nu este numită „optimizare” fără acest context minim.
