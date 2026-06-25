# Friendship Database Design

## Overview

This document describes how the **core** service models friendships. The design uses a
**current-state + history** split: a `friendship` table holds the current state for each pair
of users, and an append-only `friend_event` table records every lifecycle action. Request,
friendship, and block are all events on the same friendship rather than separate tables.

See [`database/erd.md`](../../database/erd.md) for the diagram. The authoritative schema lives in
the migrations of the `core` repo.

## Context: a lean, WorkOS-aligned `user`

Core does not own identity. Authentication is handled by WorkOS and the canonical user record
lives in the Authx service (ADR-2, ADR-4). Core keeps only a local reference:

- **our own `id`** — every foreign key points here, so the schema never depends on the auth
  provider's keyspace (the provider must be swappable).
- **the external auth subject** (the token `sub`) — the only external identifier we store; no name,
  email, phone, or other profile data is duplicated.

## Schema

Two tables, each single-purpose:

- **`friendship` — current state.** One row per pair of users. The pair is stored in a fixed order
  so a single record represents the relationship regardless of who initiated it. `status` moves
  `pending` → `accepted`/`rejected`/`cancelled`/`blocked`, and `status_actor_id` records who caused
  the current status (the requester while `pending`, the blocker while `blocked`, …). This preserves
  direction even though the pair is stored ordered and symmetric.
- **`friend_event` — append-only history.** One row per lifecycle action (`requested`, `accepted`,
  `rejected`, `cancelled`, `blocked`, `unblocked`), each carrying the `actor_id` who performed it.
  The full lifecycle of a friendship — including block/unblock cycles — is reconstructable from this
  log.

See the migrations in the `core` repo for the authoritative columns, constraints, and indexes.

## Key design features

1. **Referential integrity / cascade** — deleting a user removes their friendships and event
   history automatically.
2. **Ordered pair** — storing the pair in a fixed order dedupes `(A, B)` and `(B, A)` without an
   expression index, keeping reads and constraints simple.
3. **Direction preserved** — `status_actor_id` (current) and `friend_event.actor_id` (per event)
   capture who did what, which an ordered symmetric pair alone cannot express.
4. **Evolvable states** — `status`/`type` are stored as plain text values, so adding a new state is
   a one-line migration rather than an enum alteration.
5. **One friendship, many events** — request, accept/reject, cancel, block, and unblock are all
   events on a single friendship row, not separate tables.

## Why not a single `friendship_requests` table?

An earlier exploration stored everything in one table keyed by `(requester_id, recipient_id)` with
a `LEAST/GREATEST` unique index. That approach was rejected because:

- the expression index made symmetric reads and constraints awkward;
- one table had to mean *request*, *friendship*, and *block* simultaneously, and a `blocked`
  status mixed with `pending`/`accepted` complicated the unique index;
- it kept only the latest state, losing the history of who did what and when.

Splitting current state (`friendship`) from history (`friend_event`) keeps each table
single-purpose, makes lookups index-friendly, and records the full lifecycle.
