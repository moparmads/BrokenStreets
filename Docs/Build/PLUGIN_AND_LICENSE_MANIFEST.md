# Plugin and License Manifest

Orice plugin, SDK, font, audio, asset pack, cod sau binary extern este înregistrat aici înainte de integrare și commit. Absența unei intrări înseamnă că dependența nu este aprobată.

## Baseline curent

| Nume | Tip | Versiune/sursă | Scope | Licență/termeni | Motiv | Status |
|---|---|---|---|---|---|---|
| Unreal Engine | Engine | Epic Games Launcher, UE 5.8.2 | build/runtime/editor | Unreal Engine EULA aplicabilă contului | motorul proiectului | Approved |
| ModelingToolsEditorMode | plugin Epic built-in | livrat cu UE 5.8.2 | Editor only | inclus în distribuția Unreal Engine | unelte de modelare/editor disponibile în proiectul Blank | Approved |
| Git | developer tool | 2.53.0.windows.3 | local development | licența distribuției Git | version control | Approved |
| Git LFS | developer tool | 3.7.1 | local/GitHub | licența distribuției Git LFS + planul GitHub | asset versioning | Approved |

Nu există în prezent pluginuri Marketplace, SDK-uri third-party, asset packs sau cod extern aprobate în repository.

## Checklist înainte de o dependență nouă

1. Problemă demonstrată și motiv pentru care UE/proiectul nu o rezolvă suficient.
2. Alternative: implementare proprie, plugin Epic built-in, plugin extern, amânare.
3. Compatibilitate exactă cu UE 5.8.2, Win64, cook și Shipping.
4. Sursă oficială, versiune pinată și checksum/tag/commit unde este posibil.
5. Licență, drept comercial, attribution și redistribuire verificate.
6. Acces la source/debug symbols și plan dacă proiectul este abandonat.
7. Impact asupra build time, binary size, startup, memory, networking și save.
8. Security/privacy review pentru orice network/account/telemetry SDK.
9. Clean clone și packaged build test.
10. Aprobarea explicită a lui Madalin și task/ADR când este arhitectural.

## Reguli

- Nu copiem pluginuri din alte proiecte fără sursă/licență.
- Nu activăm pluginuri „poate vor fi utile”.
- Un plugin Editor nu devine dependency Runtime.
- O versiune floating/latest este interzisă pentru build reproducibil.
- Eliminarea unei dependențe include migration și cleanup de asset references/config.
- Conținutul de research nu devine dependency.

## Template intrare nouă

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
