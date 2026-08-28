# Catalogul sistemelor

Nu există încă system design documents implementate. Proiectul este baseline C++ gol.

Un document de sistem se creează just-in-time din `SYSTEM_TEMPLATE.md` când task-ul său devine `Ready`. Nu creăm placeholder-e pentru toate sistemele viitoare deoarece ar produce drift și falsa impresie că designul ori codul există.

## Statusuri permise

- `Proposed` — design neaprobat ori netestat;
- `Ready` — deciziile/dependențele/acceptarea sunt suficiente pentru cod;
- `In Progress` — task activ;
- `Needs Owner Verification` — codul este pregătit, creatorul trebuie să compileze/testeze;
- `Implemented` — gate-ul sistemului a trecut;
- `Deprecated` — nu mai trebuie folosit;
- `Superseded` — înlocuit de documentul indicat.

## Convenție de nume

Un document per owner/coherent domain, de exemplu:

- `Core.md`
- `PortableProfile.md`
- `OnlineSession.md`
- `Interaction.md`
- `ItemsInventoryOwnership.md` numai dacă granițele rămân explicit separate în interior;
- `Economy.md`
- `Jobs.md`
- `LegalityPolice.md` numai dacă nu ascunde doi owners;
- `Vehicles.md`

Numele se alege după ownership, nu după un feature UI.

## Index activ

| Sistem | Document | Status | Ultimul gate verificat |
|---|---|---|---|
| — | — | niciun sistem proiectat/implementat încă | — |

La adăugarea unui system doc, actualizează acest tabel și `Docs/STATUS.md` în același task.
