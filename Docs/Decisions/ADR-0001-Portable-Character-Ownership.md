# ADR-0001 — Portable Character Ownership

**Status:** Accepted
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** roadmap / M4
**Supersedes:** none
**Superseded by:** none

## Context

Each player creates a personal character and must retain that character's progress when joining a friend's world. The world belongs to the host, but money, items, vehicles, properties, reputation, and personal progression must not be lost or reset when the host changes.

There is no authoritative backend. Co-op is private, and intentional local save editing is accepted.

## Decision

- Confirmed personal progress belongs to the player-owned `PortableCharacterProfile`.
- World-owned state belongs to `HostWorldSave`.
- While a session is running, the listen server's server side is the only runtime mutation authority and tracks commits through `SessionCommitJournal`; the host's local client does not bypass validation.
- Portable vehicles and properties are records; Actors or instances in the current world are temporary materializations.
- A guest-provided profile is untrusted input and is validated before materialization.
- Character absence does not advance needs, rent, debt, or other personal systems; they use `CharacterActiveTime`.
- Without a backend, the system promises recovery and best-effort conflict detection, not perfect cross-PC atomicity.

The exact policy for an ambiguous post-crash commit remains a Decision Packet before M4; the recommendation is recorded in `Docs/PENDING_DECISIONS.md`.

## Positive consequences

- the character remains continuous between friends' worlds;
- host-world state and player progress do not overwrite one another;
- records can be validated, migrated, and materialized deterministically;
- the architecture accommodates accepted cheating without ignoring accidental corruption.

## Costs and limits

- reconciliation is more complex than a host-only save;
- two PCs without a backend cannot provide a perfect distributed commit;
- every persistent feature must be explicitly divided into personal, world, and session state;
- QA includes crashes, stale revisions, and conflict UX.

## Validation gate

M3/M4 must demonstrate profile epochs/revisions/receipts, crash-safe local saves, detected conflicts, and portability between two worlds. Failure reduces the portable scope before introducing an unapproved backend.

## Approval

Accepted from the creator's explicit requirements: the character, money, inventory, and possessions continue in another player's world while the host's world remains separate.
