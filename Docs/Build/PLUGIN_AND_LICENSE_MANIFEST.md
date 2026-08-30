# Plugin and License Manifest

Every external plugin, SDK, font, audio file, asset pack, code library, or binary must be recorded here before integration and commit. No entry means the dependency is not approved.

## Current baseline

| Name | Type | Version/source | Scope | License/terms | Reason | Status |
|---|---|---|---|---|---|---|
| Unreal Engine | Engine | Epic Games Launcher, UE 5.8.2 | build/runtime/editor | Unreal Engine EULA applicable to the account | project engine | Approved |
| ModelingToolsEditorMode | built-in Epic plugin | shipped with UE 5.8.2 | Editor only | included with the Unreal Engine distribution | modeling/editor tools available in the Blank project | Approved |
| Git | developer tool | 2.53.0.windows.3 | local development | Git distribution license | version control | Approved |
| Git LFS | developer tool | 3.7.1 | local/GitHub | Git LFS distribution license + GitHub plan | asset versioning | Approved |

No Marketplace plugins, third-party SDKs, asset packs, or external code are currently approved in the repository.

## Checklist before adding a dependency

1. Demonstrated problem and why Unreal/the project cannot solve it sufficiently.
2. Alternatives: in-house implementation, built-in Epic plugin, external plugin, or deferral.
3. Exact compatibility with UE 5.8.2, Win64, cook, and Shipping.
4. Official source, pinned version, and checksum/tag/commit when possible.
5. Verified license, commercial rights, attribution, and redistribution terms.
6. Source/debug-symbol access and a plan if the dependency is abandoned.
7. Impact on build time, binary size, startup, memory, networking, and save data.
8. Security/privacy review for every network/account/telemetry SDK.
9. Clean-clone and packaged-build test.
10. Explicit Madalin approval plus a task/ADR when architectural.

## Rules

- Never copy plugins from other projects without source and license evidence.
- Do not enable plugins because they “might be useful.”
- An Editor plugin does not become a Runtime dependency.
- Floating/latest versions are forbidden in reproducible builds.
- Removing a dependency includes migration and cleanup of asset references/configuration.
- Research content never becomes a dependency.

## New-entry template

```text
Name:
Type:
Version / commit / checksum:
Official source:
License and commercial rights:
Attribution required:
Runtime / Editor / Developer only:
Reason and rejected alternatives:
UE 5.8.2 compatibility evidence:
Build/cook/package evidence:
Security/privacy notes:
Rollback/removal plan:
Approval and task/ADR:
```
