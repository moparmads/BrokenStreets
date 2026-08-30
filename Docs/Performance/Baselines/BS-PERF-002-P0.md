# BS-PERF-002-P0 — Benchmark Street Placeholder Baseline

**Status:** Provisional capture-pipeline evidence only

**Scenario:** Precursor P0 for [BS-PERF-002 — Representative Street](../BENCHMARK_SCENARIOS.md)

**Task:** [BS-013 — Benchmark Street Placeholder](../../Tasks/BS-013-Benchmark-Street.md)

**Captured:** August 30, 2026

## Verdict

**PASS for the profiling pipeline; not a production-performance pass.** The exact packaged candidate loaded the benchmark map, produced three comparable 3,600-frame CSV captures and three non-empty Unreal trace files, and completed CPU/GPU trace analysis. The placeholder contains only a floor, sky, lighting, and four Engine cubes. Its frame rate must not be used to promise Manhattan performance, freeze hardware requirements, or claim that Broken Streets is optimized.

Creator visual/traversal acceptance passed on August 30, 2026. Renderer/scalability decisions remain owned by BS-013B and the representative baseline remains owned by BS-021.

## Candidate identity

| Field | Value |
|---|---|
| Candidate commit | `a25a7621f4b91b6dc3c405f78d11f6abce46f498` |
| Runtime/content tree | `88ae8e05d294d7846048b7fcc182cdd0a5a9bf0b` |
| Engine | Unreal Engine 5.8.2, CL `56702186`, Epic Launcher build |
| Build | Win64 Development, packaged explicit-map archive |
| Map | `/Game/BS/Maps/Benchmark/L_Benchmark_Street` |
| Source map payload | 61,422 bytes; SHA-256/LFS OID `7a5a1f47db15d4ba0e808303695fcc8d3b308b7ebfcda9e5203403178b61aaff` |
| Fixture | 14 actors; 80 m route; four Engine-cube masses; no custom gameplay |

The package contains the exact benchmark map in IoStore. The Core and Network TestGym source payloads remained byte-identical at SHA-256 `008fdcaef2fe3d4765ba95ccd8b7be03af445ff7083eeec5ba38f883e5f2730d` and `a501767fdcc89bd7811c7f109fe719b59eacf3a534a16ba95a5c7aaf57cd05ff` respectively.

## Machine and runtime configuration

| Field | Observed value |
|---|---|
| OS | Windows 11 25H2, build `10.0.26200.9168` |
| CPU | AMD Ryzen 9 9950X, 16 cores / 32 logical processors |
| GPU | NVIDIA GeForce RTX 3090, 24,576 MiB installed VRAM |
| Driver | NVIDIA `591.86` (`32.0.15.9186`), January 20, 2026 |
| System memory | 65,939,009,536 bytes, approximately 61.41 GiB usable |
| Installed SSD models | Kingston NV3 2 TB and Lexar NM790 2 TB; the evidence did not preserve the physical-disk mapping for drive `F:` |
| RHI / feature level | D3D12 / SM6 |
| Presentation | 1920×1080 windowed, VSync off, 100% screen percentage, uncapped |
| Scalability | Every `sg.*` group pinned to quality `3` by runtime command |
| Ray tracing | Measured as found in current project configuration; not accepted as a production decision |
| Players / topology | One local standalone player; no network workload |

## Method

Each run was a new launch of the same archived executable with the exact map named on the command line. CSV GPU statistics and named events were enabled. Trace channels were `cpu`, `gpu`, `frame`, `bookmark`, `loadtime`, `file`, `rendercommands`, and `rhicommands`. Each capture retained 3,600 frames; the first 600 were excluded, leaving 3,000 stable frames per run. Percentiles use linear interpolation over the sorted stable samples.

The player/camera remained at the start position during automated capture. This measures deterministic boot-and-idle rendering of the fixture, not traversal or streaming. Process working set was sampled externally at approximately 200 ms. Raw logs, CSV files, traces, and the package remain ignored under `Saved/`; only this compact report is versioned.

## Frame results

| Run | Stable frames | Mean frame (ms) | Mean FPS | p50 (ms) | p95 (ms) | p99 (ms) | Max (ms) | >50 ms | >100 ms |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 01 | 3,000 | 6.8821 | 145.30 | 6.7838 | 10.3611 | 10.9000 | 12.1888 | 0 | 0 |
| 02 | 3,000 | 6.5804 | 151.97 | 6.5114 | 10.1469 | 10.5987 | 11.1162 | 0 | 0 |
| 03 | 3,000 | 6.6180 | 151.10 | 6.5528 | 10.1943 | 10.6761 | 11.3367 | 0 | 0 |
| Median run | 3,000 | 6.6180 | 151.10 | 6.5528 | 10.1943 | 10.6761 | 11.3367 | 0 | 0 |

The mean-frame range is 0.3017 ms, or approximately 4.56% of the median run. No stable frame exceeded either provisional hitch marker. These facts describe this empty placeholder only; no FPS threshold is used to pass BS-013.

## Pipeline timings

Each cell is `p50 / p95 / p99 / max` in milliseconds.

| Run | Game thread | Render thread | GPU |
|---|---|---|---|
| 01 | `1.0564 / 1.3335 / 1.5970 / 3.9770` | `6.6792 / 13.5166 / 14.5194 / 16.1174` | `6.1672 / 6.9205 / 7.2605 / 7.8595` |
| 02 | `1.0536 / 1.3360 / 1.5534 / 2.2606` | `6.3488 / 13.0888 / 13.8470 / 15.0650` | `5.6040 / 6.2338 / 6.5023 / 6.8042` |
| 03 | `1.0484 / 1.3248 / 1.5068 / 2.2181` | `6.4180 / 13.1005 / 14.1302 / 15.0025` | `5.6296 / 6.3023 / 6.5316 / 6.8749` |

## Memory observations

| Run | CSV physical used max (MB) | CSV virtual used max (MB) | CSV GPU local used max (MB) | External peak working set (MiB) |
|---|---:|---:|---:|---:|
| 01 | 1,679.26 | 3,981.29 | 2,404.17 | 1,784.20 |
| 02 | 1,653.28 | 3,971.03 | 2,401.05 | 1,810.63 |
| 03 | 1,639.82 | 3,975.59 | 2,402.67 | 1,821.24 |
| Median | 1,653.28 | 3,975.59 | 2,402.67 | 1,810.63 |

These are process/CSV observations, not a frozen RAM or VRAM budget.

## Verification and trace integrity

- Runner self-test: 6/6 passed.
- `Tools/BS.cmd All`: `PASS_WITH_SKIPS`; Build and Automation passed; 3/3 project maps validated; Cook reported zero project-owned omission and zero warning.
- Exact-map Map Check: 0 errors and 0 warnings.
- Win64 Development Build/Cook/Stage/Package/Archive: UAT exit 0, Cook 0 errors and 0 warnings.
- Every runtime log loaded and brought up `/Game/BS/Maps/Benchmark/L_Benchmark_Street`, captured 3,600 frames, requested exit status 0 through `CsvProfiler.ExitAfterCsvProfiling`, and reached `PreExit Game` without a fatal/crash marker.
- The process observer nevertheless returned Windows code `777003` for all three unattended captures. Because the Engine logs show the controlled status-0 exit but the outer code is unexplained, a separate creator launch/normal-close checkpoint was required.
- The creator checkpoint launched the same archived executable and exact map, remained responsive during inspection/traversal, and closed through `Alt+F4` with Windows exit code `0`. The retained 96,140-byte log has SHA-256 `C296C735551CE131715D7502713CCDFC20F7A7A95791089C4C02D58CDE256390`, contains the exact-map load and complete normal shutdown, and contains no fatal/crash marker.
- Unreal Insights opened Run 01 and completed analysis in 2.01 seconds for a 28.57-second session: 73 CPU threads, 4,751 timers, 22,271,463 CPU scopes, 3 GPU queues, and 153 GPU timers.
- Insights also reported 30,638 invalid `MemAlloc` tag-tracker events, four load-time warnings, and microsecond-scale GPU event-order warnings. CPU/GPU timing analysis completed, but allocation-level memory analysis is rejected for this baseline. Memory values above come only from CSV counters and external working-set sampling.

## Retained local evidence

Raw root: `Saved/Performance/BS-013/a25a762/`

Package: `Saved/Packages/BS-013/a25a762-candidate1/Windows/`

Automation summary: `Saved/Automation/BS-009/20260830T181234Z-12420-92bdf7b7/run.json`

Map Check: `Saved/Verification/BS-013/a25a762/MapCheck/Unreal.log`

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Run 01 log | 107,841 | `BA6725F40AB1BB1ACE34394B0C7805C69790948F5CA34B6CC21A4F3BE7BB07CD` |
| Run 01 CSV | 7,625,783 | `796EC8AF6D9EE59A6E7D0D8E06BEE575BB8AF5510754E0EDCDE875F9965B939F` |
| Run 01 trace | 135,361,155 | `4495D180AC5A6B54CEDEB8F34EA88FC62F84872C277DB5D784EE83C4092896D1` |
| Run 01 Insights log | 46,280 | `A94FF034903439E6044567BD0990E5059D7BA80F010105813D43852142B0CC9A` |
| Run 02 log | 107,840 | `DB6BDACC9D1FAA94439BF0918D0C8B73C1C776340871CAFE0A0C8C58623FE6C9` |
| Run 02 CSV | 7,610,140 | `1F1D44917F13AB747FCCFE537ABEAFB27F655068437D75223CA7EEFD20439925` |
| Run 02 trace | 135,113,906 | `32D1ADEF77657776DD9F2DCE92F6CBAA87B020311FB137A1E1EFD5017E4EC106` |
| Run 03 log | 107,841 | `E1D782AAC36693099CA4171DCBEB71EE22A71A7B1102BE0980975362AF3A86BF` |
| Run 03 CSV | 7,609,591 | `687A4831AD460BF9E6116CF60A52D9E07099C0B13BBBE93C0F67465DF5932A31` |
| Run 03 trace | 135,197,012 | `FB2AB2521F9444FEBA3A66A671696E6662FC8BA804E758F49DF8DA047989979C` |
| Package bootstrap executable | 171,520 | `4478A64EAB3E5E946CC08086ECA9EA52155F45D6FAE72ACFAD9F37684121C241` |
| Packaged game executable | — | `3AA27441D6F10D23AC96C3186D2ACA0CA20F882827F51FA7736D879FDCFC0C65` |

## Limitations and next action

- High-end creator hardware, one empty greybox, one player, a stationary camera, Development build, and current unapproved renderer settings make this unsuitable for Minimum/Recommended hardware claims.
- There is no production geometry, material library, Nanite/LOD/HLOD workload, World Partition traversal, traffic, crowd, AI, physics, vehicles, weather, audio load, UI load, save work, or multiplayer.
- The automated process-exit-code discrepancy and Insights allocation-tag errors are preserved rather than normalized away.
- Madalin completed the ignored packaged visual/traversal launcher with exit code `0`. BS-013 may integrate and establish only that the capture pipeline works. BS-013B and BS-021 must replace this precursor with configuration decisions and representative evidence.
