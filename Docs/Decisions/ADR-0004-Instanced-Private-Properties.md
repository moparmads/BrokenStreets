# ADR-0004 — Instanced Private Properties

**Status:** Proposed
**Owner:** Madalin Gavrila
**Date:** 2026-08-28
**Task:** M3 four-interior spike
**Supersedes:** none
**Superseded by:** none

## Context

Private apartments may use masked loading and may share a template across several owners. Four players must be able to occupy four different interiors simultaneously, while authorized friends may visit the same instance. Server travel cannot move a single player without affecting the session.

## Proposed recommendation

- `PropertyTemplateId` describes the shared interior; `PropertyInstanceId` identifies the personal property.
- Instances materialize in isolated slots inside the same authoritative world.
- A per-player loading screen masks loading and teleportation.
- Visitors enter the same `PropertyInstanceId` after permission validation.
- Furniture uses `ItemInstanceId` plus transform plus ownership/container, without collisions between identical templates.
- The concrete technology—Level Instances, Data Layers, or another runtime approach—is not selected before the spike.

## Mandatory gate

Four simultaneous instances must demonstrate isolation for:

- visuals/occlusion;
- audio;
- collision/physics;
- navigation/AI;
- replication/relevancy;
- permissions/visitors;
- IDs/save;
- load/unload/memory caps.

## Fallback

Reduce simultaneous instance count, enforce a stricter slot pool, simplify interiors, or provide controlled sequential access. Do not use impossible per-player server travel or claim per-player isolation through global Data Layers without evidence.
