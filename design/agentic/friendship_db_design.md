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

```sql
CREATE TABLE "user" (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),  -- our id; FKs point here
  auth_subject  text NOT NULL UNIQUE,                        -- external auth subject (token `sub`)
  created_at    timestamptz NOT NULL DEFAULT now()
);
```

We generate our own `id` so foreign keys never depend on the auth provider's keyspace (the
provider must be swappable). The external identifier is stored separately in `auth_subject`; no
profile data is duplicated here.

## Schema

### `friendship` — current state

One row per pair of users. The pair is ordered once at creation, so a plain unique constraint is
enough to dedupe `(A, B)` and `(B, A)` — no `LEAST/GREATEST` expression index.

```sql
CREATE TABLE friendship (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a          uuid NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  user_b          uuid NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  status          text NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','accepted','rejected','cancelled','blocked')),
  status_actor_id uuid REFERENCES "user"(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ordered_users CHECK (user_a < user_b),
  CONSTRAINT unique_pair   UNIQUE (user_a, user_b)
);
CREATE INDEX idx_friendship_user_a ON friendship (user_a, status);
CREATE INDEX idx_friendship_user_b ON friendship (user_b, status);
```

- **`status`** moves `pending` → `accepted` / `rejected` / `cancelled` / `blocked`. It is plain
  `text` guarded by a `CHECK`, so adding a new state is a one-line migration instead of an
  `ALTER TYPE` on an enum.
- **`status_actor_id`** records who caused the current status (the requester while `pending`, the
  blocker while `blocked`, …). This preserves direction even though the pair is stored ordered and
  symmetric.

### `friend_event` — append-only history

```sql
CREATE TABLE friend_event (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  friendship_id uuid NOT NULL REFERENCES friendship(id) ON DELETE CASCADE,
  actor_id        uuid NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  type            text NOT NULL
                    CHECK (type IN ('requested','accepted','rejected','cancelled','blocked','unblocked')),
  created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_friend_event_friendship ON friend_event (friendship_id, created_at);
```

Each action a user takes appends one event with the `actor_id` who performed it. The full
lifecycle of a friendship — including block/unblock cycles — is reconstructable from this log.

## Key design features

1. **Referential integrity / cascade** — every FK to `user` is `ON DELETE CASCADE`, so deleting a
   user removes their friendships and event history automatically.
2. **Ordered pair, plain unique** — `CHECK (user_a < user_b)` + `UNIQUE (user_a, user_b)` dedupes
   the pair without an expression index, keeping reads and constraints simple.
3. **Direction preserved** — `status_actor_id` (current) and `friend_event.actor_id` (per event)
   capture who did what, which an ordered symmetric pair alone cannot express.
4. **Evolvable states** — `text` + `CHECK` for `status`/`type` instead of Postgres enums.
5. **One friendship, many events** — request, accept/reject, cancel, block, and unblock are all
   events on a single friendship row, not separate tables.

## Common operations

Two-write operations are wrapped in a single transaction in the service/repository layer.

**Send a friend request** (create the friendship and its first event):

```sql
-- arguments are pre-ordered so that user_a < user_b
INSERT INTO friendship (user_a, user_b, status, status_actor_id)
VALUES ($1, $2, 'pending', $requester)
RETURNING id;

INSERT INTO friend_event (friendship_id, actor_id, type)
VALUES ($friendship_id, $requester, 'requested');
```

**Accept a request** (update current state and append history):

```sql
UPDATE friendship
SET status = 'accepted', status_actor_id = $recipient
WHERE id = $friendship_id;

INSERT INTO friend_event (friendship_id, actor_id, type)
VALUES ($friendship_id, $recipient, 'accepted');
```

**List a user's accepted friends:**

```sql
SELECT * FROM friendship
WHERE (user_a = $me OR user_b = $me)
  AND status = 'accepted';
```

`idx_friendship_user_a` / `idx_friendship_user_b` cover the `(user, status)` lookup from
either side of the pair.

## Why not a single `friendship_requests` table?

An earlier exploration stored everything in one table keyed by `(requester_id, recipient_id)` with
a `LEAST/GREATEST` unique index. That approach was rejected because:

- the expression index made symmetric reads and constraints awkward;
- one table had to mean *request*, *friendship*, and *block* simultaneously, and a `blocked`
  status mixed with `pending`/`accepted` complicated the unique index;
- it kept only the latest state, losing the history of who did what and when.

Splitting current state (`friendship`) from history (`friend_event`) keeps each table
single-purpose, makes lookups index-friendly, and records the full lifecycle.
