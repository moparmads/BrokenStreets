# BS-PERF-002-P1 — PC Renderer Test Baseline

**Status:** Automated PASS; creator visual acceptance pending

**Scenario:** Renderer-configured P1 precursor for [BS-PERF-002 — Representative Street](../BENCHMARK_SCENARIOS.md)

**Task:** [BS-013B — PC Configuration and Renderer Baseline](../../Tasks/BS-013B-PC-Renderer-Baseline.md)

**Captured:** August 31, 2026

## Verdict

**PASS for the reversible PC renderer test baseline; not a production-performance pass.** The exact packaged candidate used the approved DX12/SM6 renderer and `BS-PC-Recommended-P0` preset, loaded the benchmark fixture, completed three comparable captures, and met the provisional informational threshold in every run. No stable frame exceeded 50 or 100 ms.

The fixture is still a stationary, single-player greybox on high-end creator hardware. These numbers do not promise final Manhattan performance, minimum hardware, or a player-facing Recommended preset. Final renderer and hardware acceptance remains gated by representative art.

## Candidate identity

| Field | Value |
|---|---|
| Candidate commit | `b646af33b1676088adae9dbb320f01c4a9ba9d27` |
| Candidate tree | `d0984c6f083280a62bc5d292b156b462b45cddde` |
| Config tree | `67fc0de9d562f5bb87d8ca549c6ce18404161649` |
| Content tree | `41343e24397b32d46f6f51c4fc5269c8005c6fdb` |
| Source tree | `1b7850b3b6330e9fece6a41b8b35f34d7f9e3ec1` |
| Engine | Unreal Engine 5.8.2, CL `56702186`, Epic Launcher build |
| Build | Win64 Development, exact-map package |
| Map | `/Game/BS/Maps/Benchmark/L_Benchmark_Street` |
| Source map payload | 61,422 bytes; SHA-256/LFS OID `7a5a1f47db15d4ba0e808303695fcc8d3b308b7ebfcda9e5203403178b61aaff` |

## Renderer and preset contract

| Field | Pinned value |
|---|---|
| Platform / RHI / shader model | Win64 / DX12 / SM6 |
| Global illumination / reflections | Software Lumen |
| Shadows | Virtual Shadow Maps |
| Geometry / anti-aliasing | Nanite support / TSR |
| Ray tracing | Project hardware ray tracing and Lumen hardware ray tracing disabled |
| Materials | Substrate enabled, Blendable GBuffer |
| Preset | `BS-PC-Recommended-P0` |
| Presentation | 1920×1080 windowed, 100% screen percentage |
| Scalability | High, every `sg.*` group set to `2` |
| VSync / Dynamic Resolution / frame cap | Off / Off / uncapped |
| Default Editor/game/server map | `/Game/BS/Maps/Test/L_TestGym_Core` |

The configuration audit passed 52/52 checks. Input SHA-256 values were `e79eedf1c682849455648e5df6b0ae5e769c3afd66cd527ed43e7222027520b8` for `DefaultEngine.ini`, `2d109a035c972b6b64f19f4447923d6eca9970f2d0c29ec40560ff38214401a8` for `DefaultGameUserSettings.ini`, and `becd928ffded9f6771e12e6237a4de1a4993cb87b611f6810dbeff7ae4fdc561` for `BrokenStreets.uproject`.

## Machine and method

| Field | Observed value |
|---|---|
| OS | Windows 11 25H2, build `10.0.26200.9168` |
| CPU | AMD Ryzen 9 9950X, 16 cores / 32 logical processors |
| GPU | NVIDIA GeForce RTX 3090, 24,576 MiB installed VRAM |
| Driver | NVIDIA `591.86` (`32.0.15.9186`), January 20, 2026 |
| System memory | approximately 61.41 GiB usable |
| Players / topology | one local standalone player; no network workload |

Each run was a fresh launch of the same archived executable with the exact map and preset recorded in the log. Each capture retained 3,600 frames; the first 600 were excluded, leaving 3,000 stable frames. Percentiles use linear interpolation over sorted stable samples. The camera remained at the start position, so this is deterministic boot-and-idle rendering rather than traversal or streaming.

## Frame results

| Run | Stable frames | Mean (ms) | p50 (ms) | p95 (ms) | p99 (ms) | Max (ms) | >50 ms | >100 ms |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 01 | 3,000 | 6.0258 | 5.9005 | 9.3129 | 9.8980 | 10.4266 | 0 | 0 |
| 02 | 3,000 | 5.5224 | 5.3757 | 8.6581 | 9.1303 | 9.6906 | 0 | 0 |
| 03 | 3,000 | 5.5164 | 5.3888 | 8.5920 | 9.0020 | 9.6739 | 0 | 0 |
| Median run | 3,000 | 5.5224 | 5.3757 | 8.6581 | 9.1303 | 9.6906 | 0 | 0 |

The mean-frame spread was 0.5094 ms, or 9.22% of the median-run mean. That variation is retained rather than hidden.

## Pipeline timings

Each cell is `p50 / p95 / p99 / max` in milliseconds.

| Run | Game thread | Render thread | GPU |
|---|---|---|---|
| 01 | `1.0168 / 1.3092 / 1.4852 / 3.6559` | `5.7670 / 11.8720 / 12.7223 / 14.3367` | `5.4736 / 6.1934 / 6.5296 / 7.1386` |
| 02 | `1.0347 / 1.3202 / 1.5077 / 2.1162` | `5.2197 / 10.7499 / 11.7488 / 12.4969` | `4.9411 / 5.6169 / 5.7516 / 6.2846` |
| 03 | `1.0118 / 1.2804 / 1.4659 / 1.8667` | `5.2618 / 10.7304 / 11.5109 / 12.5848` | `4.9432 / 5.6153 / 5.7516 / 6.4451` |

The render thread was the limiting measured pipeline. Its worst p95 was 11.8720 ms, below the provisional 13.33 ms informational target. This target applies only to this fixture and machine.

## Memory observations

| Run | CSV physical max (MB) | CSV virtual max (MB) | CSV GPU local max (MB) | External peak working set (MiB) |
|---|---:|---:|---:|---:|
| 01 | 1,590.80 | 3,219.32 | 1,720.84 | 1,632.82 |
| 02 | 1,573.53 | 3,189.40 | 1,720.59 | 1,590.68 |
| 03 | 1,565.53 | 3,196.45 | 1,719.34 | 1,584.21 |

The reported local GPU budget counter reached 23,554 MB and the system GPU budget counter reached 45,732.34 MB. Some rows in Runs 01 and 02 reported zero while telemetry was unavailable; peak non-zero observations are retained. These values are measurements, not frozen RAM or VRAM budgets.

## Verification and package integrity

- Windows PowerShell 5.1 parsed every changed renderer script.
- Renderer audit self-test passed 5/5, including deliberately invalid settings, secret-redaction, plugin-enable, and preset-drift fixtures.
- Evolving Unreal CSV parser self-test passed.
- Existing runner self-test passed 6/6; its intentional native-failure and timeout probes were correctly contained.
- `Tools/BS.cmd All` returned `PASS_WITH_SKIPS`: Doctor, Generate, Build, Automation, Data Validation, and Cook gates passed; controlled Engine-only cook omissions remained classified.
- Exact-map Map Check completed with 0 errors and 0 warnings.
- Win64 Development Build/Cook/Stage/Package/Archive completed with UAT exit code 0; Cook reported 0 errors and 0 warnings.
- The package contains no SM5-named output, Android File Server payload, or `SecurityToken=` text. The IoStore project descriptor retains the literal name `AndroidFileServer` only as an explicit disabled plugin declaration; no plugin binary loaded and no UAT or runtime log references it.
- All three Engine logs contain the exact map and renderer markers, reach controlled normal shutdown, and contain no fatal/crash marker.
- The external observer returned unexplained code `777003` for all three unattended runs even though the Engine logs report status-0 shutdown. Creator visual acceptance therefore remains mandatory.

Package root: `Saved/Packages/BS-013B/b646af3-20260830T210716Z/Windows/`

Automation summary: `Saved/Automation/BS-009/20260830T210558Z-36328-89b6f45a/run.json`

Map Check: `Saved/Verification/BS-013B/b646af3/MapCheck/Unreal.log`

Capture summary: `Saved/Performance/BS-013B/b646af3-20260830T210814Z/capture-summary.json`

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| UAT log | — | `156993a9891e305666b9416ebb0f3bbb40ce1e5647012579c9cedcdcf5530029` |
| Package bootstrap executable | — | `4478a64eab3e5e946cc08086eca9ea52155f45d6fae72acfad9f37684121c241` |
| Packaged game executable | — | `0de1bf119e53ba45f88ab76365e5d2c9663a3de45bdb735437ca5cc8453dc281` |
| Package pak / ucas / utoc | — | `86dc9c7eb4a11044020d9ef9161500d3cd89cae38f9676e4de3ff540c7cd0c02` / `7f09a19f5897dcd06af027cd2a00abed0270a1c9b7dae8edd2a8162ba4a892b9` / `3f3ddc93626f30d53a47501a001e6be26f25c28cd99f412e36663f6c8a951b5e` |
| Run 01 log / CSV / trace | 119,798 / 7,446,548 / 125,181,249 | `9bdfb83f335ae25f713ea528b5bcfad4c3df7c41d54170d78b8dcf800d720e07` / `f24221821aa2a0e5d55ae99bed65496cd6b4faeecc88c812ac512e9f5195fc3a` / `9ced74ca2c7e8982e4fa472d2ec96040cf55fb02c8a47ff68aecb908fe4839b0` |
| Run 02 log / CSV / trace | 119,115 / 7,448,722 / 124,637,478 | `7f90e03a40a691999136aa59539194461c0df9d6967398775959e52612721189` / `9c7ac442843941dc0a674e598f910374de1193b428007e0d12053cf8bff094ef` / `8d6cc5c91d05bd97ddfc6fe9761edd52310f497a2233805a987bb8e0cc1f25c9` |
| Run 03 log / CSV / trace | 119,798 / 7,454,224 / 124,717,106 | `a32471aa10868ec1f95943b05ec1ead9bf632275f03d399575e9d2d0b7c9a955` / `cc5643c3711d669c67135c575a90d87e968b2a42c9529de826126c255ce69e0e` / `8542f80357667efb98ba824b4a5cd27c32c291f600cdb9e897cb9da396d37a3c` |

## Limitations and next action

- The map contains only 14 greybox actors, a floor, sky, lighting, and four Engine cubes.
- There is no representative geometry, material library, Nanite/LOD/HLOD workload, World Partition traversal, traffic, crowd, AI, vehicles, weather, interiors, UI, audio load, save work, or multiplayer.
- The camera was stationary and the build was Development, not a production Shipping build.
- High-end creator hardware cannot establish Minimum or Recommended specifications.
- Unreal Insights traces are retained but were not used to claim allocation-level memory correctness for this pass.
- Madalin must compile the unchanged candidate, open the prepared packaged visual checkpoint, confirm the fixture is visible and responsive, and close it normally. Only then may BS-013B become Done and integrate into `main`.
