# Live Design

The **current truth** about how Fair N Square works, organised by **domain** — independent of which
service implements it. These documents evolve in place: when something changes, update the doc here
so it always reflects reality.

This is the counterpart to [`design/records/`](../design/records/):

| | `live/<domain>/` | `design/records/` |
| --- | --- | --- |
| Answers | **WHAT IS** — current state | **WHY** — the decision and its trade-offs |
| Lifecycle | Edited **in place** | **Append-only**; superseded, never rewritten |
| Organised by | Domain (`auth/`, `frontend/`, …) | Sequential ADR number |

## Conventions

- One folder per domain (e.g. `auth/`, `frontend/`, `expenses/`, `groups/`, `ledger/`).
- Each domain has an `overview.md` as its entry point; split into more files only as it grows.
- A living doc should read as the present state. Replace stale statements; don't pile on caveats.
- When a change is the result of a hard-to-reverse trade-off, record the *why* as an ADR in
  `design/records/` and link to it from here. Live docs say *what is*; ADRs say *why*.
