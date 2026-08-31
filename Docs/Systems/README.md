# System catalog

Core is the first implemented system-design document. Create each additional system document just in time when its owning task becomes `Ready`; do not add empty placeholders that can drift or falsely imply implementation.

Create a system document just in time from `SYSTEM_TEMPLATE.md` when its task becomes `Ready`. Do not create placeholders for every future system; they would drift and falsely imply that design or code exists.

## Allowed statuses

- `Proposed` — unapproved or untested design;
- `Ready` — decisions, dependencies, and acceptance are sufficient for code;
- `In Progress` — active task;
- `Needs Owner Verification` — code is ready and the creator must compile/test;
- `Implemented` — the system gate passed;
- `Deprecated` — must no longer be used;
- `Superseded` — replaced by the referenced document.

## Naming convention

Use one document per owner/coherent domain, for example:

- `Core.md`
- `PortableProfile.md`
- `OnlineSession.md`
- `Interaction.md`
- `ItemsInventoryOwnership.md` only if its internal boundaries remain explicitly separate;
- `Economy.md`
- `Jobs.md`
- `LegalityPolice.md` only if it does not hide two owners;
- `Vehicles.md`

Choose the name by ownership, not by a UI feature.

## Active index

| System | Document | Status | Last verified gate |
|---|---|---|---|
| Core | [Core.md](Core.md) | In Progress | BS-015 merge `ccbb92d`; post-merge gate and creator acceptance passed; BS-016 active |

When adding a system document, update this table and `Docs/STATUS.md` in the same task.
