# Repository Structure

> **Status:** Draft for review · **Last updated:** 2026-06-22
>
> An audit of the `fair-n-square-co` GitHub org: what each repo is for, what's needed, and what to
> clean up. Companion: [`./delivery-plan.html`](./delivery-plan.html), [`./aws-architecture.html`](./aws-architecture.html).

---

## 1. Inventory (13 repos)

| Repo | Purpose (inferred) | Lang | Last push | State | Verdict |
| --- | --- | --- | --- | --- | --- |
| **webapp** | SvelteKit UI + BFF + Better Auth login (drizzle, storybook, playwright, husky) | TS | 2025-12-15 | Active | **KEEP** — canonical frontend; re-scaffold on React + WorkOS (ADR-5/ADR-4) |
| **apis** | Proto/contracts: `buf` + connectRPC, `proto/fairnsquare`, generated Go+TS | TS | 2025-12-13 | Active | **KEEP** (retain the `apis` name — no rename) |
| **docs** | ADRs, roadmap, product spec, diagrams (this repo) | — | 2026-06-19 | Active | **KEEP** |
| **ledger** | Ledger/transactions service — sqlc + goose | Go/PLpgSQL | 2026-03-18 | Active-ish | **FOLDING into `core`** ([FNS-134](https://loyalt.atlassian.net/browse/FNS-134)) — archive after done |
| **e2e** | Cross-service E2E tests + K8s manifests + docker-compose | Go | 2026-03-18 | Active | **KEEP** (move K8s/infra bits out) |
| **auth-api** | Intended Auth Service (Go) — but README is verbatim "Go API Template"; looks like an **unmodified bootstrap** | Go | 2025-09-30 | Stale/empty-ish | **KEEP but RESET** — barely started |
| **jwt-service** | Throwaway: "create a JWT for testing via Firebase", single `jwt.go` | Go | 2026-06-17 | Tiny util | **MERGE → test helpers, then DELETE** |
| **transactions** | Legacy v0 backend (GORM + Atlas + Fly). Your Makefile style reference | Go | 2024-08 | Stale | **ARCHIVE** |
| **web-app** | Old Next.js frontend attempt | TS | 2025-09-29 | Superseded by `webapp` | **DELETE** (after archive) |
| **app** | Old Flutter mobile bootstrap | Dart | 2024-05-23 | Stale; mobile is post-MVP | **ARCHIVE** |
| **codecov-login** | Throwaway Codecov OAuth helper, single `main.go` | Go | 2024-04-25 | Dead | **DELETE** |
| **demo-repository** | GitHub default demo template, never used | HTML | 2024-03-18 | Dead | **DELETE** |
| **.github** | Org profile | — | 2024-03-18 | Minimal | **KEEP** — flesh out org README |

---

## 2. Mapping to the target architecture (+ gaps)

| Component (from ADRs) | Repo home | Status |
| --- | --- | --- |
| React UI + BFF (+ WorkOS AuthKit login) | `webapp` | ⚠️ exists as SvelteKit; re-scaffold on React (ADR-5) |
| Auth Service (Go) — profiles, JWKs, M2M, future ReBAC | `auth-api` | ⚠️ exists but essentially an empty template; needs real implementation |
| **Core Service** (Go modular monolith) — groups, friends, expenses, settlement, ledger | `core` | ⚠️ Scaffolding in progress ([FNS-133](https://loyalt.atlassian.net/browse/FNS-133), [FNS-134](https://loyalt.atlassian.net/browse/FNS-134)). See [live/core/overview.md](../live/core/overview.md). |
| Proto / contracts | `apis` | ✅ (matches the "Configure Proto Repository" Jira subtask) |
| Two Postgres DBs (Auth, Core) | inside `auth-api` + `core` | ✅ migrations in sqlc/goose style |
| Docs | `docs` | ✅ |
| **Infra / OpenTofu** | **— gap —** | ❌ No infra repo. K8s manifests currently live in `e2e`. |
| E2E | `e2e` | ✅ |

**One gap remaining:**

1. ~~**`core`**~~ — ✅ Being created under [FNS-84](https://loyalt.atlassian.net/browse/FNS-84) (subtasks [FNS-133](https://loyalt.atlassian.net/browse/FNS-133), [FNS-134](https://loyalt.atlassian.net/browse/FNS-134)). `ledger` folding in; archived after.
2. **`infra`** — OpenTofu/AWS (and any k8s), reusable CI/CD workflows. See [`./aws-architecture.html`](./aws-architecture.html).
   Move the K8s manifests out of `e2e` into here.

---

## 3. Cleanup plan (safe order — back up first)

1. **Archive (reversible, keeps history & references):** `transactions` (Makefile reference stays
   accessible when archived), `app` (Flutter), `web-app` (Next.js).
2. **Salvage then remove `jwt-service`:** move `jwt.go` into `e2e` test helpers or `webapp` dev tooling,
   commit, then archive/delete.
3. **Back up private/unique repos** before any delete: `git clone --mirror` `jwt-service` and
   `codecov-login` into `.tmp/`.
4. **Delete dead repos** (zero reusable value): `codecov-login`, `demo-repository`. (Archiving is also
   fine and safer — for a learning project, prefer archive over hard delete.)
5. **Create** `core` and `infra`; **fold** `ledger` into `core`, then archive `ledger`. *(The `apis` contracts repo keeps its name — no rename to `proto`.)*

---

## 4. Recommended final layout

| Repo | One-line purpose |
| --- | --- |
| `webapp` | React UI + BFF; hosts WorkOS AuthKit login & sessions |
| `auth-api` *(consider rename `auth`)* | Go Auth Service: profiles, JWKs, M2M tokens, ReBAC |
| `core` | Go modular-monolith Core Service: groups, friends, expenses, settlement, ledger |
| `apis` | Buf/connectRPC contracts + generated Go/TS clients |
| `infra` *(new)* | OpenTofu/AWS + k8s + reusable CI/CD workflows |
| `e2e` | Cross-service E2E tests |
| `docs` | ADRs, roadmap, product spec, diagrams |
| `.github` | Org profile + shared community-health files |

**Archived (reference only):** `transactions`, `app`. **Deleted:** `web-app`, `ledger` (after merge),
`jwt-service`, `codecov-login`, `demo-repository`.

→ From **13 repos to ~8 active** (+2 archived).

---

## 5. Multi-repo vs monorepo

Your **ADR-2 already accepts** "a lot of boilerplate to manage multiple repos" and "longer to set up
CI/CD for multiple services" *as negatives taken on for the learning value*. That's the deciding factor.

- **Keep multi-repo** if learning multi-service CI/CD, cross-repo proto publishing, and independent
  deploys is the goal (the layout above) — higher learning, higher overhead.
- **Go monorepo** to ship the MVP faster — eliminates the cross-repo proto-versioning pain that's
  brutal for 1–2 people, while still building independent service containers (Buf, Go workspaces,
  bun/Turbo workspaces all support it).

**Concrete recommendation:** **monorepo for code** (`core`, `auth`, `webapp`, `apis`, `infra`, `e2e`
as top-level dirs) **+ keep `docs` separate.** You get ~90% of the architectural learning (modular
monolith, gRPC contracts, multi-service deploys) without the cross-repo coordination tax that dominates
solo work. If you specifically want the cross-repo contract-publishing lesson, keep `apis` split out
and monorepo the rest.

---

*Inventory gathered via `gh repo list fair-n-square-co` on 2026-06-20. Verify archived/private flags
before acting; GitHub repo deletion is irreversible — archive when in doubt.*
