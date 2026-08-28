# Broken Streets

Broken Streets este un life/crime sandbox original construit în Unreal Engine 5.8.2 pentru Windows PC și Steam. Poate fi jucat complet solo sau în co-op privat de maximum patru jucători în total: un listen-server host și cel mult trei clienți.

Jucătorul începe fără bani și își construiește propria viață prin joburi legale ori ilegale. Lumea reacționează la risc, statut și ilegalitate, iar progresul economic este transformat în vehicule, haine, bijuterii, proprietăți și echipamente tot mai valoroase.

## Starea actuală

Proiectul este un baseline C++ gol. Nu există încă gameplay Broken Streets, hartă de producție ori sisteme implementate. Vezi [starea proiectului](Docs/STATUS.md) înainte de orice task.

## Căi locale

- Proiect: `F:/BrokenStreets`
- Engine instalat: `F:/UE_5.8.2/UE_5.8`
- Source Art separat: `F:/BrokenStreets_SourceArt`
- Repository privat: `https://github.com/moparmads/BrokenStreets`

Engine-ul instalat și Source Art nu fac parte din acest repository.

## Documentație

Începe cu [indexul documentației](Docs/INDEX.md). Regulile permanente pentru Codex sunt în [AGENTS.md](AGENTS.md).

Documentele canonice nu au sufixe de versiune; Git păstrează istoricul. Fișierele din `Docs/Archive/` sunt context istoric, nu surse normative.

## Workflow

- Madalin Gavrila deține direcția jocului și produce asset-urile 3D.
- Codex scrie și modifică C++, config, teste și documentație.
- Madalin compilează și execută pașii vizuali în Unreal Editor folosind instrucțiuni exacte.
- `main` rămâne buildabil; fiecare rezultat coerent folosește un branch și un task `BS-###`.
- C++ deține gameplay-ul autoritativ/persistent/replicat; Blueprint rămâne strat subțire de prezentare și configurare.

## Originalitate

Referințele la jocuri existente descriu numai experiențe dorite. Codul, asset-urile, harta, UI-ul, textele, personajele și brandurile Broken Streets sunt originale. Vezi [politica de referințe](Docs/REFERENCE_POLICY.md).
