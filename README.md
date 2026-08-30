# Broken Streets

Broken Streets is an original life/crime sandbox built in Unreal Engine 5.8.2 for Windows PC and Steam. It supports full solo play and private co-op for up to four total players: one listen-server host and up to three clients.

The player starts with no money and builds a personal life through legal or illegal jobs. The world reacts to risk, status, and illegality, while economic progress becomes increasingly valuable vehicles, clothing, jewelry, properties, and equipment.

## Current status

The project is an empty C++ baseline. No Broken Streets gameplay, production map, or game systems exist yet. Read the [project status](Docs/STATUS.md) before starting any task.

## Local paths

- Project: `F:/BrokenStreets`
- Installed engine: `F:/UE_5.8.2/UE_5.8`
- Separate Source Art: `F:/BrokenStreets_SourceArt`
- Private repository: `https://github.com/moparmads/BrokenStreets`

The installed engine and Source Art are not part of this repository.

## Documentation

Start with the [documentation index](Docs/INDEX.md). Permanent Codex rules live in [AGENTS.md](AGENTS.md).

Canonical documents do not use version suffixes; Git preserves history. Files under `Docs/Archive/` are historical context, not normative sources.

## Workflow

- Madalin Gavrila owns the game's direction and produces the 3D assets.
- Codex writes and modifies C++, configuration, tests, and documentation.
- Madalin compiles and performs visual Unreal Editor steps using exact instructions.
- `main` remains buildable; every coherent result uses a branch and a `BS-###` task.
- C++ owns authoritative, persistent, and replicated gameplay; Blueprint remains a thin presentation and configuration layer.

## Originality

References to existing games describe desired experiences only. Broken Streets code, assets, map, UI, text, characters, and brands are original. See the [reference policy](Docs/REFERENCE_POLICY.md).
