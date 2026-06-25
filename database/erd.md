# Core — Database ERD

This is the schema owned by the **core** service. Only the columns needed to understand
friendships (primary keys and foreign keys) are shown; see the migrations in the `core`
repo for the full column list.

```mermaid
erDiagram
    user {
        uuid id PK
        text auth_subject
    }
    friendship {
        uuid id PK
        uuid user_a FK
        uuid user_b FK
        text status
        uuid status_actor_id FK
    }
    friend_event {
        uuid id PK
        uuid friendship_id FK
        uuid actor_id FK
        text type
    }
    user ||--o{ friendship : "user_a"
    user ||--o{ friendship : "user_b"
    user ||--o{ friendship : "status_actor_id"
    friendship ||--o{ friend_event : ""
    user ||--o{ friend_event : "actor_id"
```

## Lean by design

Core does **not** own user identity or profile data. Authentication is handled by an external
provider (**WorkOS**) and the canonical user record + profile live in the separate **Authx**
service (see ADR-2 and ADR-4). The `user` table here is only a local reference:

- `id` — our own generated UUID, which every foreign key points at. We own this keyspace, so
  it never depends on the auth provider (the provider must be swappable per ADR-4).
- `auth_subject` — the external auth subject (the token `sub` / Authx user id). This is the
  only external identifier we store; no name, email, phone, or other profile data.

All foreign keys to `user` cascade on delete, so removing a user automatically removes their
friendships and event history. Token validation / auth middleware is deferred to **FNS-87**;
until then core simply receives a user id.

## Friendship lifecycle

Friendships use a **current-state + history** model rather than a single overloaded table:

- **`friendship`** holds the *current* state for a pair of users — exactly one row per pair, with
  the pair stored in a fixed order so a single record represents the relationship regardless of who
  initiated it. `status` moves `pending` → `accepted`/`rejected`/`cancelled`/`blocked`, and
  `status_actor_id` records *who* caused the current status (e.g. the requester while `pending`, the
  blocker while `blocked`), which is how direction is preserved despite the ordered, symmetric pair.
- **`friend_event`** is the append-only history — one row per lifecycle action
  (`requested`, `accepted`, `rejected`, `cancelled`, `blocked`, `unblocked`), each carrying the
  `actor_id` who performed it. Request, friendship, and block are all just events on the same
  friendship instead of separate tables.

Updating current state and appending the matching history event happen together, keeping the two
consistent. The authoritative schema lives in the migrations of the `core` repo.

## Future modules

Groups, expenses, and other domains will be added to this ERD as they are built. Today the schema
covers users and friendships only.
