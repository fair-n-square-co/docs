# Fair N Square — Jira ↔ MVP Mapping (Proposed)

> Companion to [`./delivery-plan.md`](./delivery-plan.md). This maps the existing **FNS** Jira tickets
> onto the delivery stages and proposes labels/versions so the board reflects the MVP cut.
>
> **Nothing in Jira has been changed.** This is a proposal to apply manually (or to approve before
> I apply it).

## Proposed taxonomy

**Fix Version:** `0.1.0-mvp` for everything in Stages 0–6.

**Labels** (one per ticket):

| Label | Meaning | Stages |
| --- | --- | --- |
| `mvp-foundation` | Plumbing that unblocks the MVP | Stage 0–1 |
| `mvp-core` | The core money loop | Stage 2–4 |
| `mvp-features` | Extra features requested in MVP | Stage 5 |
| `mvp-launch` | Production readiness for launch | Stage 6 |
| `post-mvp` | Deferred | P1–P3 |

## Stage → ticket mapping

### Stage 0 — Foundation `mvp-foundation`
- FNS-5 Database Setup
- FNS-25 Core Service Project Setup
- FNS-6 CI/CD Pipeline Setup
- FNS-601 Container Configuration *(partial — local docker-compose only; rest → Stage 6)*

### Stage 1 — Auth & Identity `mvp-foundation`
- FNS-9 Third-Party Auth Integration (WorkOS AuthKit; was Better Auth)
- FNS-11 Session Management
- FNS-10 User Profile Management (backend)
- FNS-17 User Profile UI
- FNS-13 M2M Token Service
- FNS-26 User Integration Layer (Core ↔ Auth)

### Stage 2 — Groups & Friends `mvp-core`
- FNS-28 Friends/Contacts Management Backend
- FNS-20 Friends/Contacts Management UI
- FNS-27 Groups Management Backend
- FNS-19 Groups Management UI

### Stage 3 — Expenses & Splitting `mvp-core`
- FNS-29 Expense Management Backend *(single-currency portion; multi-currency → Stage 5)*
- FNS-21 Expenses Management UI

### Stage 4 — Balances & Settlement `mvp-core`
- FNS-30 Balance Calculation & Ledger System *(single-currency portion)*
- FNS-31 Settlement System (incl. debt simplification)
- FNS-22 Balance & Settlement UI

### Stage 5 — MVP Feature Completion `mvp-features`
- FNS-29 / FNS-30 — multi-currency extensions *(see "ticket gaps" below)*
- FNS-29 / FNS-21 — attachments & comments extensions
- FNS-32 Todo List Feature Backend
- FNS-23 Todo List Feature UI

### Stage 6 — Production Readiness `mvp-launch`
- FNS-601 Container Configuration *(remainder)*
- FNS-602 Production Infrastructure Setup
- FNS-603 Environment Configuration
- FNS-604 Deployment Automation
- FNS-703 API Security *(rate limiting, validation, CORS)*
- FNS-702 Data Privacy *(TLS in transit only for MVP)*
- FNS-501 Logging Infrastructure *(structured logging only)*
- FNS-502 Metrics & Monitoring *(health checks + uptime only)*
- FNS-57 Unit Testing *(split + ledger)*
- FNS-59 End-to-End Testing *(critical journeys)*

### Post-MVP `post-mvp`
- **P1:** FNS-12 (FGA/ReBAC), FNS-36/37/38 (metrics/tracing/alerting), FNS-39 (perf setup), FNS-46/47/48/49/50 (security & compliance), FNS-58/60/61 (integration/perf/UAT), FNS-904
- **P2:** FNS-52 (reporting), FNS-53 (categories), FNS-54 (push notifications)
- **P3:** FNS-804 (mobile), MCP server (no ticket yet)

### Already Done (no change)
FNS-2, FNS-3, FNS-4, FNS-8, FNS-15, FNS-16 + subtasks FNS-68..72.

### Cross-cutting (apply throughout, not a stage)
- FNS-33 Data Migration & Seeding — seed data per stage as needed (`mvp-core`)
- FNS-1, FNS-7, FNS-14, FNS-24, FNS-34, FNS-40, FNS-45 — Epics; leave as-is
- FNS-62–67 (Docs & Launch) — pull FNS-63/66 into `mvp-launch`; rest `post-mvp`

## Suggested ticket gaps to add

The current backlog is a flat 1:1 of the old roadmap and is missing a few MVP-shaped items:

1. **Split multi-currency out of FNS-29/30** into its own story (e.g. *"Multi-currency support for
   expenses & ledger"*) so the core can ship single-currency first.
2. **File storage provider selection** — currently buried in FNS-3/102; make it a small `mvp-features`
   task blocking attachments.
3. **gRPC/proto plumbing & connectRPC wiring** for the Core service — implied by FNS-25 but worth an
   explicit sub-task.
4. **`docker-compose` local stack** — split from FNS-601 as a `mvp-foundation` task (it's needed in
   Stage 0, long before production containerization).

## How to apply

Approve this and I can apply the labels + `0.1.0-mvp` fix version and create the gap tickets via the
Jira API, or you can apply them manually from the table above.
