# Documentation index

This file routes readers through the project documentation. It contains no new design decisions.

| Document | Truth it owns | When to read it |
|---|---|---|
| `AGENTS.md` | permanent agent operating contract | before any work |
| `Docs/STATUS.md` | what actually exists, active task, and next step | at the start of every task |
| `Docs/VISION.md` | product promise and experience pillars | design, scope, prioritization |
| `Docs/DECISIONS.md` | confirmed product decisions and open-decision status | before designing a system |
| `Docs/PENDING_DECISIONS.md` | material open questions grouped by gate | when a milestone can measure them |
| `Docs/NON_GOALS.md` | what is not being built now | estimation and scope protection |
| `Docs/ARCHITECTURE.md` | technical boundaries and cross-system flows | before architectural code or configuration |
| `Docs/SYSTEM_OWNERSHIP.md` | who may modify each runtime truth | any task spanning several domains |
| `Docs/ROADMAP.md` | future order, dependencies, and gates | planning and selecting the next task |
| `Docs/REFERENCE_POLICY.md` | clean-room, copyright, and licensing rules | research, content, or external dependencies |
| `Docs/Build/TOOLCHAIN.md` | tool versions and build procedures | setup, build, regeneration, upgrade |
| `Docs/Build/PLUGIN_AND_LICENSE_MANIFEST.md` | plugins/dependencies and their licenses | before any external integration |
| `Docs/Systems/README.md` | catalog of existing system documents | before creating or changing a system |
| `Docs/Systems/SYSTEM_TEMPLATE.md` | required system-design structure | when a system becomes `Ready` |
| `Docs/Systems/Core.md` | typed identity and Gameplay Tags contracts owned by Core | any task that introduces IDs or tags |
| `Docs/Decisions/README.md` | ADR rules and decision index | difficult-to-reverse cross-system decisions |
| `Docs/Tasks/README.md` | task-packet states and rules | selecting and tracking a task |
| `Docs/Tasks/TASK_TEMPLATE.md` | contract for a `BS-###` task | before implementation |
| active `Docs/Tasks/BS-###-*.md` packet | outcome, authorized scope, and evidence for the current task | throughout the task |
| `Docs/Tasks/BS-014-Stable-Identifiers-And-Gameplay-Tags.md` | implemented M2 identity and Gameplay Tags contract plus evidence | when changing Core IDs/tags or reviewing BS-014 |
| `Docs/Tasks/BS-014A-Portable-Unreal-Engine-Association.md` | implemented portable UE association correction and evidence | when changing the engine association or reviewing BS-014A |
| `Docs/Tasks/BS-015-Core-Observability-And-Feature-Flags.md` | implemented Core observability and rollout-control contract plus evidence | when changing Core logs/flags or reviewing BS-015 |
| active `Docs/Tasks/BS-016-Build-Content-Save-Compatibility.md` | build/content/save compatibility scope, defaults, and evidence | throughout BS-016 |
| `Docs/Workflows/CODEX_TASK_WORKFLOW.md` | complete execution process | any code or asset change |
| `Docs/Workflows/DEFINITION_OF_DONE.md` | universal gate and conditional verification | before handoff/merge |
| `Docs/Workflows/USER_COMPILE_GUIDE.md` | exact creator compilation steps | after C++ changes |
| `Docs/Workflows/EDITOR_INSTRUCTION_STANDARD.md` | format for manual steps | any handoff involving Unreal Editor |
| `Docs/Workflows/GIT_WORKFLOW.md` | branch, commit, merge, and rollback | any versioned task |
| `Docs/Workflows/RECOVERY_AND_ROLLBACK.md` | clean clone, backup, and restoration | recovery drill or incident |
| `Docs/Testing/TEST_STRATEGY.md` | test levels and multiplayer matrix | acceptance design and verification |
| `Docs/Performance/BUDGETS.md` | measured/provisional targets and budgets | any hot path or benchmark |
| `Docs/Performance/BENCHMARK_SCENARIOS.md` | standard comparable scenarios | profiling and scaling gates |
| `Docs/Performance/Baselines/BS-PERF-002-P1.md` | current provisional PC renderer measurement | BS-013B verification and future renderer comparisons |

## Navigation rules

- Separate authority across three axes: the request + task packet say what is authorized; repository + evidence + STATUS say what exists; DECISIONS/ADR/system/architecture say what must be built.
- Do not read the entire roadmap for a typo or an isolated documentation change.
- For product design, read only the relevant `DECISIONS.md` section plus `VISION.md` and `NON_GOALS.md`.
- For code, read architecture, ownership, the system document, and relevant ADRs.
- Documents under `Docs/Archive/` are non-normative. Canonical documents win when they differ.
- Planned documentation does not prove implementation. The verified commit, code/config/content, and reproducible evidence define reality; `STATUS.md` must summarize and correct any mismatch.
