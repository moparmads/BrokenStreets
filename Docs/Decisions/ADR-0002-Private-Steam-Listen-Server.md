# ADR-0002 — Private Steam Listen Server

**Status:** Accepted
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** roadmap / M3–M4
**Supersedes:** none
**Superseded by:** none

## Context

Broken Streets must work completely solo and in co-op for the creator plus three friends. V1 does not use dedicated servers, router configuration, or public infrastructure. The initial release is Steam-only.

## Decision

- Solo uses the same authoritative rules instead of a separate offline architecture.
- Co-op uses a listen server on the host player's PC.
- `Host` names the player/PC running the session; gameplay authority belongs to the server side. The host's local client uses the same command/RPC validation paths as a remote client.
- The functional limit is four total players: `1 host + 0–3 clients`.
- Sessions are private and invite-only through Steam.
- Joining must work without manual port forwarding and must be validated across two real networks.
- Join-in-progress and reconnect are part of v1.
- There is no tether; the host may simulate four areas, interiors, or jobs.
- Dedicated servers and cross-store play are outside v1.

Host migration remains a separate `Proposed` decision. The v1 recommendation is no host migration, with save and session closure during a normal shutdown.

## Positive consequences

- low operational cost and straightforward co-op between friends;
- clear server-side authority, including the host player's actions;
- Steam supplies identity, invites, and transport that can be validated;
- fixed scope for budgets and testing.

## Costs and limits

- the host has higher CPU and RAM requirements;
- the session depends on the host and their connection;
- four untethered simulation bubbles are the primary scaling risk;
- Steam behavior cannot be accepted from PIE or LAN testing alone.

## Validation gate

- packaged build on two PCs, two Steam accounts, and two networks;
- then one host plus three clients for four-bubble tests;
- reconnect, normal host shutdown, and host crash;
- no manual port forwarding.

## Approval

Accepted from the creator's explicit requirements: Steam-only private co-op, no dedicated server, creator plus three friends.
