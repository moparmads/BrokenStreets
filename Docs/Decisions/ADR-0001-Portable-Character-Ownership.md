# ADR-0001 — Portable Character Ownership

**Status:** Accepted
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** roadmap / M4
**Supersedes:** none
**Superseded by:** none

## Context

Fiecare jucător își creează propriul personaj și trebuie să își continue progresul când intră în lumea unui prieten. Lumea aparține host-ului, dar banii, obiectele, vehiculele, proprietățile, reputația și progresul personal nu trebuie pierdute ori resetate la schimbarea host-ului.

Nu există backend autoritar. Co-op-ul este privat, iar editarea intenționată a save-ului local este acceptată.

## Decizie

- Progresul personal confirmat aparține `PortableCharacterProfile`, păstrat de jucător.
- Starea world-owned aparține `HostWorldSave`.
- Cât sesiunea rulează, partea server a listen serverului este singurul runtime mutation authority și urmărește commits prin `SessionCommitJournal`; clientul local al host-ului nu ocolește validarea.
- Vehiculele și proprietățile portabile sunt recorduri; Actorii/instanțele din lumea curentă sunt materializări temporare.
- Profilul prezentat de un guest este input neîncrezător și este validat înainte de materializare.
- Absența personajului nu avansează needs, rent, debt ori alte sisteme personale; acestea folosesc `CharacterActiveTime`.
- Fără backend, sistemul promite recovery și detectarea conflictelor best-effort, nu atomicitate perfectă cross-PC.

Politica exactă pentru un commit ambiguu după crash rămâne un Decision Packet înainte de M4; recomandarea este în `Docs/PENDING_DECISIONS.md`.

## Consecințe pozitive

- personajul are continuitate între prieteni;
- host world și player progress nu se suprascriu reciproc;
- recordurile pot fi validate, migrate și materializate determinist;
- arhitectura este compatibilă cu trișarea acceptată fără a ignora coruperea accidentală.

## Costuri și limite

- reconcilierea este mai complexă decât un save numai la host;
- două PC-uri fără backend nu pot avea commit distribuit perfect;
- orice feature persistent trebuie împărțit explicit în personal/world/session;
- QA include crash, stale revision și conflict UX.

## Validation gate

M3/M4 trebuie să demonstreze profile epochs/revisions/receipts, crash-safe local save, conflict detectat și portability între două lumi. Eșecul reduce ce este portabil înainte să introducă un backend neaprobat.

## Approval

Acceptat prin cerințele explicite ale creatorului: personajul, banii, inventarul și bunurile continuă în lumea altui jucător; lumea host-ului rămâne separată.
