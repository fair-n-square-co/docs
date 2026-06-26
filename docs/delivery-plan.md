# Fair N Square — Delivery Plan (Bigger Picture, MVP & Stages)

> **Status:** Draft for review · **Last updated:** 2026-06-20 · **Owner:** Jaspreet Singh
>
> This document turns the flat backlog in [`../ROADMAP.md`](../ROADMAP.md) and the goals in
> [`../product/spec/1-MVP-scope.md`](../product/spec/1-MVP-scope.md) into a **sequenced delivery plan**:
> the bigger picture, a crisply-scoped MVP, and the stages that get us there and beyond.
>
> **Companion docs:** Jira mapping → [`./jira-mvp-mapping.md`](./jira-mvp-mapping.md) ·
> AWS deployment, distributed system & OpenTofu IaC → [`./aws-architecture.md`](./aws-architecture.md) ·
> repo roundup & cleanup → [`./repos.md`](./repos.md).

---

## 1. The Bigger Picture

**What we're building.** Fair N Square is an open-source, free expense-splitting app (a Splitwise
alternative) built deliberately with enterprise-grade architecture. There are **two intertwined
goals**, and it's important to keep them distinct:

1. **Product goal** — ship a genuinely useful expense splitter: groups, friends, expenses, splits,
   balances, settle-up, debt simplification.
2. **Learning goal** — practice building complex systems with real boundaries: a React BFF, a
   separate Auth service and Core service, gRPC/connectRPC, Postgres, CI/CD, and observability —
   deployed for real on free tiers.

These goals pull in opposite directions on speed. The strategy below resolves that tension: **honor
the real architecture, but cut a thin vertical slice through it first**, then harden and widen.

### Target architecture (from the ADRs)

```
            ┌────────────────────────────────────────────────────────────┐
  Browser ──┤  React (UI) + BFF/SSR — sessions via WorkOS AuthKit        │
            └───────────────┬───────────────────────────┬────────────────┘
                            │ gRPC/connectRPC            │ gRPC/connectRPC
                   ┌────────▼─────────┐         ┌────────▼─────────┐
                   │  Auth Service    │◄────────│  Core Service    │
                   │  (Go)            │  M2M    │  (Go, modular     │
                   │  user record,    │  token  │  monolith)        │
                   │  profiles, JWKs, │         │  groups, friends, │
                   │  FGA (future)    │         │  expenses, ledger,│
                   └────────┬─────────┘         │  settlement, todos│
                            │                   └────────┬──────────┘
                       ┌────▼────┐                  ┌────▼────┐
                       │ Auth DB │                  │ Core DB │
                       │ (PG)    │                  │ (PG)    │
                       └─────────┘                  └─────────┘
```

Source ADRs: [`../design/records/2-system-design-v1.md`](../design/records/2-system-design-v1.md),
[`../design/records/5-use-react-for-frontend.md`](../design/records/5-use-react-for-frontend.md),
[`../design/records/4-use-workos-for-auth.md`](../design/records/4-use-workos-for-auth.md).

### Where we are today

Already **done** (per Jira FNS):

- ✅ Local dev environment, tooling (Go, Node, Docker) — *FNS-2*
- ✅ Third-party service selection — revised to **WorkOS, Postgres, AWS** (orig. Better Auth/Fly.io) — *FNS-3*
- ✅ Repository & `apis` (proto contracts) repository structure — *FNS-4*
- ✅ Auth service project scaffold — *FNS-8*
- ✅ SvelteKit project setup — *FNS-15* *(to be re-scaffolded on React, ADR-5)*
- ✅ Authentication UI (login/signup screens) — *FNS-16*

In short: **scaffolding exists; no end-to-end feature works yet.** The Auth flow isn't wired to a
real backend, the Core service hasn't been created, and there's no database schema or deployment.

---

## 2. MVP Definition

**MVP thesis:** *A user can sign up, connect with friends, create a group, record shared expenses
(split equally / by exact amounts / by percentage), see who owes whom, simplify the debts, and
settle up — running on the real two-service gRPC architecture, deployed publicly.*

If that loop works end-to-end and is deployed, the MVP is a success. Everything else is sequencing.

### In scope for MVP

| Area | Included |
| --- | --- |
| **Identity** | Google login via WorkOS AuthKit, sessions in the BFF, basic profile |
| **Authorization** | **Simple ownership/membership checks** (am I a member of this group?). *Not* full ReBAC. |
| **Social graph** | Friend requests (pending/accepted/rejected), groups, add/remove members |
| **Expenses** | Add/edit/delete expense; split **equal / exact / percentage**; notes |
| **Money** | Balance engine (who owes whom), settle-up, **debt simplification** |
| **Multi-currency** | Record expenses in different currencies with conversion *(MVP-Features stage)* |
| **Attachments & comments** | Receipt photo/PDF upload + comments on expenses *(MVP-Features stage)* |
| **Group todos** | Group todo lists with task assignment *(MVP-Features stage)* |
| **Platform** | Containerized, deployed to AWS (ECS Fargate), basic logging + health checks, core E2E tests |

> The bottom four rows were explicitly requested as part of the MVP. They are real work, so they're
> sequenced into a dedicated **MVP-Features** stage *after* the core money loop is proven — they
> extend the core rather than block it.

### Explicitly OUT of MVP (deferred to Post-MVP)

- Full fine-grained authorization / ReBAC (OpenFGA / Permit.io) — MVP uses simple membership checks
- Distributed tracing, full metrics dashboards, alerting/on-call, SLAs
- Advanced reporting, analytics, CSV/PDF export
- Transaction categories
- Push notifications, in-app chat
- Native mobile apps, offline support, MCP server for AI agents
- Performance/load testing, formal security audit & penetration testing

### MVP success criteria

- Multiple real users can sign up and use the system end-to-end.
- The full money loop (expense → balance → simplify → settle) is correct and verifiable.
- The app is publicly reachable, mobile-responsive, and survives a redeploy.
- Core flows are covered by automated E2E tests in CI.

---

## 3. Delivery Stages

Stages are ordered by dependency. Each ends at a **checkpoint** you can demo. Stages 0–6 (including
the deploy-first **Stage 0.5**) constitute the MVP; P1–P3 are post-MVP.

### Stage 0 — Foundation completion *(unblocks everything)*
Finish the plumbing the rest of the work stands on. Stage 0 gets the app building and running *end-to-end locally*; the **first AWS deploy happens next, in Stage 0.5** (a thin walking skeleton), **not** at the end. We deploy the skeleton early so every feature stage merges onto a live system and the hardest work (AWS/ECS/ALB/RDS/IAM/TLS) is de-risked first — *not* discovered at launch.

- **Repo hygiene** (see [`./repos.md`](./repos.md)): create **`core`** (fold in `ledger`), archive/delete the dead/legacy repos. The `apis` contracts repo keeps its name (no rename to `proto`). `auth-api` is still a verbatim "Go API Template" — treat Stage 1 as greenfield there. *(The `infra` repo is deferred to Stage 6.)*
- Database setup: Auth DB + Core DB schemas, migration tooling (Drizzle/goose), connection pooling — *FNS-5*
- Core service scaffold: Go project, gRPC/connectRPC server, proto layout, DB wiring — *FNS-25*
- CI (build/test/lint only, no deploy): per-service pipelines in GitHub Actions, in each repo's own `.github/workflows` — *FNS-6*
- Local stack: `docker-compose` for Postgres + services for local dev — *FNS-601 (partial)*

**Checkpoint:** every service builds in CI; `docker-compose up` brings the stack up locally with empty DBs.

### Stage 0.5 — Walking Skeleton & First Deploy *(MVP — deploy-first)* — *Epic FNS-137*
Cut the thinnest possible vertical slice through the real architecture and **deploy it to AWS**. This is the "get everything set up and deployed, then add features" milestone — it exists so deployment is proven *before* the feature stages, not after them.

- `webapp`: re-scaffold on **React + BFF** (bare shell, off SvelteKit per ADR-5) — *FNS-138*
- WorkOS AuthKit **hosted** login + sessions in the BFF (Google) — *FNS-91*
- `core`: one trivial connectRPC endpoint (`GetMe`/`Hello`) + BFF call rendered in the UI — *FNS-139*
- `docker-compose` local stack of the **bare-minimum** services — *FNS-90*
- Create the `infra` repo: OpenTofu skeleton + reusable CI/CD — *FNS-85*
- **Minimal** AWS infra: ECS Fargate (webapp+core), 1 ALB, 1 RDS, ECR — *FNS-140 (subset of FNS-112)*
- Deploy the skeleton to AWS via GitHub Actions + OIDC — *FNS-141 (subset of FNS-114)*

> `auth-api` stays a minimal stub here — WorkOS runs the hosted flow. The heavier auth (canonical
> user record, profile CRUD, M2M/JWKS, Core↔Auth token validation) is deliberately **NOT** skeleton
> work and lands in Stage 1.

**🏁 Checkpoint:** a public HTTPS URL where you log in and see data fetched from `core` rendered in the UI. **The app is deployed.**

### Stage 1 — Auth & Identity *(MVP)*
Now that login + a deployed slice exist, build the *real* identity layer on top.

- Canonical user record + JIT provisioning — *FNS-92*
- User profile CRUD in Auth service + profile UI — *FNS-93, FNS-94 (was FNS-10, FNS-17)*
- M2M token service so Core can call Auth on behalf of users; JWK hosting/validation — *FNS-95 (was FNS-13)*
- Core ↔ Auth integration layer: token validation middleware, user context — *FNS-96 (was FNS-26)*

> Hosted login (FNS-91) and basic session management moved **up** to Stage 0.5 — they're skeleton work.

**Checkpoint:** a user signs up, logs in, edits their profile; Core can validate a request's identity via M2M tokens.

### Stage 2 — Groups & Friends *(MVP)*
Build the social graph the money sits on top of.

- Friends backend (request/accept/reject model — see [`../design/agentic/friendship_db_design.md`](../design/agentic/friendship_db_design.md)) + UI — *FNS-28, FNS-20*
- Groups backend (CRUD, membership, settings, soft-delete) + UI — *FNS-27, FNS-19*

**Checkpoint:** a user adds a friend and creates a group with members.

### Stage 3 — Expenses & Splitting *(MVP core)*
The heart of the product. **Single currency** at this stage.

- Expense backend: CRUD, split logic for equal / exact / percentage, validation, history — *FNS-29*
- Expense UI: add/edit/delete form, split selector, detail view, list with filters — *FNS-21*
- Reuse the split algorithm in [`../algo/Split algorithm .pdf`](../algo/) — verify with unit tests.

**Checkpoint:** a member adds an expense to a group and the split is computed and stored correctly.

### Stage 4 — Balances & Settlement *(MVP core — closes the loop)*
- Ledger + balance engine: who-owes-whom, group & per-user balances — *FNS-30*
- Settlement + debt-simplification algorithm; settle-up flow — *FNS-31*
- Balance & settlement UI: group balances, simplify visualization, settle-up, history — *FNS-22*

**🏁 Milestone — MVP Core / Alpha:** the entire money loop works end-to-end on the real architecture.

### Stage 5 — MVP Feature Completion *(MVP)*
The additionally-requested MVP features, layered onto the proven core.

- **Multi-currency:** per-expense currency + conversion in the ledger/balance engine — *extends FNS-29, FNS-30*
- **Attachments & comments:** file storage selection (extends *FNS-3/102*), receipt upload, comments — *extends FNS-29, FNS-21*
- **Group todos:** todo lists + task assignment backend + UI — *FNS-32, FNS-23*

> Recommended priority within this stage: multi-currency → attachments/comments → todos. Todos and
> attachments can slip past launch without breaking the core promise, so treat them as the trim.

**Checkpoint:** expenses in mixed currencies balance correctly; receipts attach; group todos work.

### Stage 6 — Production Readiness *(MVP launch — hardening)*
> **The first deploy already happened in Stage 0.5.** Stage 6 is no longer "stand up AWS for the
> first time" — it's **hardening** the skeleton's minimal footprint (FNS-140/141) into a
> production-grade deployment: multi-AZ, autoscaling, secrets, rollback, security, observability.
> Deployment target stays **AWS** (the learning track), provisioned with **OpenTofu** — see
> [`./aws-architecture.md`](./aws-architecture.md). Fly.io remains a valid simpler fallback.

- Containerize all services; finalize multi-stage Docker builds — *FNS-111*
- Production-harden the AWS infra via OpenTofu (multi-AZ, autoscaling, NAT-avoidance, SG chaining, staging/prod) — *FNS-112 (hardens FNS-140)*
- Env/secrets management for dev/staging/prod (SSM Parameter Store / Secrets Manager) — *FNS-603*
- Deployment automation hardening: ECS circuit-breaker auto-rollback, env-gated promotion, multi-env pipelines — *FNS-114 (hardens FNS-141)*
- Baseline security: rate limiting, input validation, CORS, TLS everywhere — *FNS-703, FNS-702 (partial)*
- Minimal observability: structured logging + health checks/uptime — *FNS-501, FNS-502 (partial)*
- Core test coverage: unit tests for split/ledger + E2E for critical journeys in CI — *FNS-57, FNS-59*

**🏁 Milestone — MVP Launch:** publicly deployed, monitored at a basic level, core flows tested.

---

## 4. Post-MVP Stages

### P1 — Hardening & Enterprise Architecture
The "learning goal" features that don't block launch but are the point of the project.
See [`./aws-architecture.md`](./aws-architecture.md) §5 and §8 for the full distributed-system track.

- **Async / event-driven** (the real distributed leap): EventBridge + SQS + a Worker for balance recalculation & debt simplification, with DLQ + idempotency — *extends FNS-30/31*
- **S3 pre-signed receipt uploads** + **SNS** notification fan-out — *extends FNS-29*
- Full fine-grained authorization / ReBAC with OpenFGA or Permit.io — *FNS-12*
- Distributed tracing (ADOT → X-Ray) + full metrics dashboards + alerting — *FNS-37, FNS-36, FNS-38*
- Full test pyramid: integration tests, broader E2E, UAT — *FNS-58, FNS-60, FNS-61*
- Security audit, security testing (SAST/DAST), compliance docs — *FNS-46, FNS-49, FNS-50*
- Performance/load testing baseline — *FNS-39, FNS-904*

### P2 — Advanced Product Features
- Advanced reporting + analytics + CSV/PDF export — *FNS-52*
- Transaction categories — *FNS-53*
- Push notifications (Firebase/OneSignal) — *FNS-54*

### P3 — Reach
- Native mobile apps (Flutter/React Native), offline support — *FNS-804*
- MCP server for AI agents

---

## 5. Critical Path & Sequencing Notes

```
Stage 0 ──► Stage 0.5 ──► Stage 1 ──► Stage 2 ──► Stage 3 ──► Stage 4 ──► [Alpha]
            [DEPLOYED]                                           │
                                                                 ├─► Stage 5 (features)
                                                                 └─► Stage 6 (hardening) ──► [MVP Launch]
                                                                                                 │
                                                                                    P1 ─► P2 ─► P3
```

- **Deploy early (Stage 0.5), not late.** A thin walking skeleton goes to AWS *before* the feature
  stages, so every stage merges onto a live, auto-deploying system and the AWS/IaC learning curve is
  paid down first. Stage 6 becomes *hardening*, not first-deploy.
- **Stage 0 is the current bottleneck** — Core service and DB schemas don't exist yet (mostly Done in
  Jira now), and almost every later stage depends on them. Prioritize it, then Stage 0.5.
- **Authorization is deliberately deferred.** Shipping simple membership checks in MVP and full
  ReBAC in P1 is the single biggest scope-saver without hurting the product.
- **Observability is split:** "can I see logs and is it up?" is MVP (Stage 6); tracing/alerting/SLAs
  are P1. Don't let the full o11y epic block launch.
- Stages 5 and 6 can run partly in parallel once Alpha is reached (different surfaces).

---

## 6. Risks & Mitigations

| Risk | Mitigation |
| --- | --- |
| Architecture complexity stalls the product | Thin vertical slice first (Stages 1–4); defer FGA, tracing, multi-repo polish |
| Multi-currency complicates the ledger early | Build the ledger single-currency in Stage 4; add currency in Stage 5 |
| Solo/learning project, unbounded scope | Hard line at "MVP Launch"; everything else is explicitly P1–P3 |
| Free-tier limits on hosting/o11y | Keep MVP footprint small (2 services + 2 DBs); pick OSS-friendly free tiers |

---

## 7. Open Decisions

- **File storage provider** for attachments (Stage 5) — not yet chosen; fold into *FNS-3/102*.
- **Authorization model for MVP** — confirm "membership check in Core" is acceptable vs. a minimal
  FGA integration now.
- **Currency conversion source** — fixed snapshot rate at expense time vs. live FX API.

---

*Living document. Update the checkpoints and milestone dates as stages complete.*
