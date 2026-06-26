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
| `mvp-foundation` | Plumbing + the deploy-first walking skeleton | Stage 0–1 (incl. 0.5) |
| `mvp-core` | The core money loop | Stage 2–4 |
| `mvp-features` | Extra features requested in MVP | Stage 5 |
| `mvp-launch` | Production hardening for launch | Stage 6 |
| `post-mvp` | Deferred | P1–P3 |

> **Applied 2026-06-27:** the board now has **Stage 0.5 — Walking Skeleton & First Deploy**
> (Epic **FNS-137**), inserted to deploy a thin slice to AWS *before* the feature stages. See the
> Stage 0.5 section below.

## Stage → ticket mapping

### Stage 0 — Foundation `mvp-foundation` *(Epic FNS-74)*
- FNS-88 Database Setup *(Done)*
- FNS-87 Core Service Project Setup + gRPC plumbing *(Done)*
- FNS-89 CI/CD Pipeline Setup *(Done)*
- FNS-84 Create `core` repo *(Done)*

### Stage 0.5 — Walking Skeleton & First Deploy `mvp-foundation` *(Epic FNS-137 — NEW)*
The deploy-first slice. Build the thinnest vertical cut and ship it to AWS before any feature stage.
- FNS-138 webapp: re-scaffold on React + BFF (bare shell) *(new)*
- FNS-91 WorkOS AuthKit hosted login + sessions *(moved up from Stage 1)*
- FNS-139 core: first connectRPC endpoint (GetMe/Hello) + BFF call *(new)*
- FNS-90 docker-compose local stack *(re-scoped to bare-minimum services)*
- FNS-85 Create `infra` repo (OpenTofu skeleton + reusable CI/CD) *(moved up from Stage 6)*
- FNS-140 Minimal AWS infra: ECS Fargate (webapp+core), 1 ALB, 1 RDS, ECR *(new; subset of FNS-112)*
- FNS-141 Deploy skeleton to AWS via GitHub Actions + OIDC *(new; subset of FNS-114)*

### Stage 1 — Auth & Identity `mvp-foundation` *(Epic FNS-75)*
Hosted login moved up to Stage 0.5; Stage 1 is now the *real* identity layer on top of it.
- FNS-92 Canonical user record + JIT provisioning
- FNS-93 User Profile CRUD (Auth service)
- FNS-94 User Profile UI (React)
- FNS-95 M2M Token Service + JWKS hosting/validation
- FNS-96 User Integration Layer (Core ↔ Auth, token validation)

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

### Stage 6 — Production Readiness (Hardening) `mvp-launch` *(Epic FNS-80)*
> First deploy already shipped in Stage 0.5 — this stage *hardens* it.
- FNS-111 Containerize all services (multi-stage Docker builds)
- FNS-112 AWS infra hardening *(multi-AZ, autoscaling, secrets — hardens FNS-140)*
- FNS-113 Env/secrets management (SSM / Secrets Manager)
- FNS-114 Deployment automation hardening *(circuit-breaker rollback, env-gated — hardens FNS-141)*
- FNS-115 Baseline security *(rate limiting, validation, CORS, TLS)*
- FNS-116 Minimal observability *(structured logging + health checks)*
- FNS-117 Unit Testing *(split + ledger)*
- FNS-118 End-to-End Testing *(critical journeys)*

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

**Stage 0.5 reorg — applied 2026-06-27** via the Jira API: created Epic **FNS-137** + stories
**FNS-138/139/140/141**; moved **FNS-85, FNS-90, FNS-91** under it; annotated **FNS-112/114** as the
production-hardening supersets. Remaining manual step: apply the `0.1.0-mvp` fix version across
Stages 0–6 if you want the board filtered by release.
