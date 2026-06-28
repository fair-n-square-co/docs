# Fair N Square — AWS Architecture, Distributed System & IaC

> **Status:** Draft for review · **Last updated:** 2026-06-20
>
> This document explores deploying Fair N Square on **AWS** (as a deliberate learning exercise),
> evolving it into a genuinely **distributed system**, and provisioning it with **OpenTofu**.
> It supersedes the earlier "Fly.io for now" note in the ADRs for the learning track — Fly.io
> remains a valid simpler fallback. Companion: [`./delivery-plan.html`](./delivery-plan.html),
> [`./repos.html`](./repos.html).

---

## 1. Goals & guardrails

The north star: **learn real AWS primitives (VPC, ALB, ECS, RDS, IAM, async messaging, observability)
without drowning in ops or blowing past free-tier.** Every choice below is filtered through that.

- Honor the existing architecture (React BFF + Auth service + Core service + gRPC + 2 Postgres DBs).
- Add distributed-system pieces **because a feature needs them**, not for résumé bingo.
- Keep a low-traffic learning deployment around **$45–60/mo**; set a Budgets alarm at $50 on day one.

---

## 2. Compute: why ECS Fargate

Three long-lived services all want persistent connections (gRPC/HTTP2), which fights a request-priced
FaaS model. The realistic field:

| Option | Verdict | Why |
| --- | --- | --- |
| **ECS Fargate** | ✅ **Recommended** | Teaches the real AWS container stack (task defs, services, target groups, IAM task roles, Cloud Map, ALB) without managing nodes/control plane. Fargate Spot ~70% off for workers. |
| App Runner | ❌ Wrong fit | Scale-to-zero is nice, but weak VPC/private-networking, awkward gRPC, and it *hides* the networking/IAM you want to learn. Good for one public web app, not a 3-service mesh. |
| EKS | ❌ Overkill | You'd learn Kubernetes, not "AWS." ~$73/mo control-plane fee, no free tier. |
| Lightsail | ❌ Anti-learning | A Fly.io-like abstraction that hides AWS — defeats the purpose. |
| EC2 / ECS-on-EC2 | ⚠️ Later | A good *second* lesson (capacity providers, cheaper compute). Start on Fargate. |

**Decision:** one ECS cluster, Fargate, services `bff`, `auth`, `core`, `worker`. Images in **ECR**.

### The gRPC / HTTP2 gotcha
- **Browser → BFF:** standard ALB, HTTPS/HTTP2 listener, **target group protocol HTTP1** (the React BFF/Node server is HTTP/1.1).
- **Browsers never speak gRPC directly** — all browser traffic goes to the BFF, which does server-side connectRPC to the Go services (matches the ADR's BFF pattern).
- **BFF → Auth/Core and service-to-service (real gRPC/HTTP2):** use **Cloud Map** (service discovery, DNS-based, no per-LB hourly charge) instead of internal ALBs. connect-go round-robins over the A records. Add one internal ALB with a `GRPC` target group later *only* if you specifically want that lesson. Avoid NLB.

---

## 3. Networking & security

- **VPC**, 2 AZs.
  - **Public subnets (2):** ALB only.
  - **Private subnets (2):** all Fargate tasks + RDS, no public IPs.
- **Egress (the big cost lesson):** a **NAT Gateway is ~$32/mo + data** — the sneakiest cost here.
  Prefer **VPC interface/gateway endpoints** (ECR api+dkr, S3 gateway [free], Secrets Manager, SSM,
  CloudWatch Logs) so AWS-internal traffic skips NAT. For tiny envs a `t4g.nano` NAT instance / fck-nat
  is often cheapest; tear down dev when idle.
- **TLS:** **ACM** cert on the ALB HTTPS listener (free, auto-renew). Internal traffic stays plaintext
  HTTP/2 inside the VPC for now (revisit mTLS later).
- **DNS:** **Route 53** hosted zone (~$0.50/mo), ALIAS → ALB.
- **Security-group chain (least privilege):** `ALB SG (443 from world)` → `BFF SG (app port from ALB SG)`
  → `Auth/Core SG (gRPC from BFF SG / each other)` → `RDS SG (5432 from service SGs)`.
- **Secrets:** **SSM Parameter Store** (SecureString, free) for config + most secrets; **Secrets Manager**
  for the DB credential you want auto-rotated. Injected into tasks via the execution role.
- **IAM:** distinct **task execution role** (pull ECR, read secrets, write logs) and **per-service task role**
  (e.g. Core's task role gets `sqs:SendMessage` + `s3:PutObject` on its buckets only).

---

## 4. Data: RDS Postgres, one instance, two DBs

- **One `db.t4g.micro` (Graviton) RDS Postgres instance, two logical databases** (`fairnsquare_auth`,
  `fairnsquare_core`), each with its own role/connection string. The free tier covers exactly **one**
  instance; two logical DBs still honor the ADR's "two databases, no cross-DB joins" boundary.
- Single-AZ to start (Multi-AZ doubles cost — enable later as the HA lesson).
- **Later distributed lesson:** split Core onto a second instance, optionally **Aurora Serverless v2**
  (scale-to-zero / auto-pause, ~15s resume) to learn independent scaling/failure isolation.
- Skip **RDS Proxy** for now (it costs money and blocks Aurora auto-pause).

---

## 5. Distributed-system upgrades (tied to real features)

| Piece | What in this app uses it | Why |
| --- | --- | --- |
| **EventBridge + SQS + Worker** | On expense create/edit/delete, Core emits `ExpenseRecorded`; rules fan to SQS; a Worker recomputes **group balances** + reruns **debt simplification**, then enqueues notifications. | Decouples writes from expensive recompute; retries + **DLQ** give correctness for a money ledger. The single best distributed lesson; nearly free at low volume. **Start here.** |
| **SNS** | Notification fan-out ("added to group", "expense recorded", "settle-up reminder") → email/push, SQS for durable in-app. | Canonical fan-out; pairs with the events above. |
| **S3** | Receipt/attachment storage; BFF issues **pre-signed PUT URLs** so browsers upload directly. | Textbook object storage; basically free; later S3 events → thumbnail/OCR Lambda. |
| **Cloud Map** | Internal gRPC service discovery (already in topology). | Your service-discovery lesson. |
| **ADOT + X-Ray + CloudWatch** | ADOT Collector **sidecar** per task; OTel in Go + React BFF; traces → X-Ray, metrics/logs → CloudWatch; Container Insights. | A request browser→BFF→Core→SQS→worker→DB is exactly where distributed tracing earns its keep. |
| **ElastiCache (Redis/Valkey)** | *Defer.* Cache computed balances; idempotency keys for SQS consumers; rate-limit state. | Real uses, but ~$12/mo and not needed yet. Adopt for the caching/idempotency lesson. |

**Skip for now:** Step Functions, App Mesh, multi-region, DynamoDB (data is relational), API Gateway
(ALB + BFF covers the edge).

---

## 6. Target architecture diagram

```
                          Internet
                             │  HTTPS/HTTP2 (ACM cert)
                             ▼
                      ┌───────────────┐
   Route 53 ─────────▶│  Public ALB   │   (public subnets, 2 AZs)
   (ALIAS)            └───────┬───────┘
─────────────────────────────┼──────────────────────────────  PUBLIC TIER
                             │  HTTP/1.1  (TG protocol HTTP1)
                             ▼
                   ┌──────────────────┐
                   │ React app BFF/SSR│  (Fargate, private subnet)
                   │  + ADOT sidecar  │   sessions via WorkOS AuthKit
                   └───┬──────────┬───┘
        connectRPC/    │          │   connectRPC/gRPC (HTTP2)
        gRPC (HTTP2)   │          │   via Cloud Map DNS
        via Cloud Map  ▼          ▼
            ┌──────────────┐  ┌──────────────┐
            │ Auth Service │  │ Core Service │   (Fargate, private subnets)
            │ Go + ADOT    │◀▶│ Go + ADOT    │   svc-to-svc gRPC (JWK validate)
            └──────┬───────┘  └──┬────────┬──┘
                   │ 5432        │ 5432   │ emits events
                   ▼             ▼        ▼
            ┌────────────────────────┐  ┌─────────────────┐
            │  RDS Postgres (1 inst) │  │   EventBridge    │
            │  ├ auth DB             │  │   (event router) │
            │  └ core DB             │  └───┬─────────┬────┘
            └────────────────────────┘      │ rules   │
─────────────────────────────────────────  │         │  ───── PRIVATE / DATA TIER
   (all private subnets, SG-chained)        ▼         ▼
                                       ┌────────┐  ┌────────┐
                                       │  SQS   │  │  SNS   │
                                       │ balance│  │ notify │
                                       │ recalc │  │ fanout │
                                       └───┬────┘  └────────┘
                                           ▼
                                   ┌──────────────────┐
                                   │ Worker (Fargate) │  recompute balances,
                                   │  ledger/settle   │  debt-simplification
                                   └──────────────────┘

  Side stores:  S3 (receipt attachments, pre-signed URLs from BFF)
  Egress:       VPC interface/gateway endpoints (ECR, S3, Secrets, Logs) — no NAT
  Secrets:      SSM Parameter Store / Secrets Manager → injected via task exec role
  Telemetry:    ADOT sidecars → X-Ray (traces) + CloudWatch (metrics/logs)
  Edge TLS:     ACM on ALB;  DNS: Route 53
```

---

## 7. Provisioning with OpenTofu

**Use OpenTofu, not Terraform.** For an open-source learning project: MPL 2.0 under the Linux
Foundation (vs HashiCorp's BSL), drop-in HCL/provider/state compatibility, and it has features
Terraform lacks that help here — **native state encryption**, write-only/ephemeral attributes. Pin the
CLI and `hashicorp/aws` provider versions. Everything below is identical whether you type `tofu` or `terraform`.

### Repo & layout
A dedicated **`fair-n-square-co/infra`** repo (infra is cross-cutting; don't fragment it across service
repos). App code stays in service repos; their CI pushes images to ECR and triggers deploys.

```
infra/
├── bootstrap/                  # one-time: S3 state bucket + KMS (local backend)
├── modules/
│   ├── networking/            # VPC, public+private subnets, IGW, endpoints, SGs
│   ├── ecr/                   # repos: bff, auth, core, worker
│   ├── alb/                   # ALB, HTTPS listener, ACM, target groups
│   ├── ecs-cluster/
│   ├── ecs-service/           # reusable: task def + service + TG + autoscaling
│   ├── rds/                   # reusable Postgres (auth_db, core_db)
│   ├── messaging/             # EventBridge bus + rules, SQS queues + DLQ, SNS topics
│   └── secrets/               # SSM/Secrets Manager containers + IAM access
├── environments/
│   ├── dev/   (backend.tf  main.tf  variables.tf  dev.tfvars  outputs.tf)
│   ├── staging/               # add later
│   └── prod/                  # add later
├── .github/workflows/  (plan.yml on PR, apply.yml on merge — env-gated)
└── .tflint.hcl
```

- **Environment separation:** **directory-per-env** (explicit, safe blast radius). Avoid workspaces
  (easy to apply to the wrong env); skip Terragrunt (overkill for 1–2 devs). Start with just `dev`.
- **Reused modules:** `ecs-service` (×4 services) and `rds` (×1, two DBs) are parameterized and called
  multiple times.

### Remote state & locking
- **S3 backend with native lockfile** — `use_lockfile = true` (GA). **No DynamoDB lock table** (deprecated).
- Bucket: versioning on, public access blocked, **SSE-KMS**, TLS-enforced, access restricted to the CI
  role + admins. Optionally layer OpenTofu native state encryption on top.
- **Bootstrap the chicken-and-egg:** a `bootstrap/` root creates the bucket+KMS with a local backend,
  apply once, then migrate env roots to the S3 backend.

### Secrets without leaking into state
Anything Tofu reads/sets becomes plaintext in state. In order of preference:
1. **Don't let Tofu hold the secret** — create empty Secrets Manager / SSM SecureString *containers*,
   populate values out-of-band; ECS reads them at runtime via task-def `secrets` (valueFrom = ARN).
2. **RDS:** `manage_master_user_password = true` → RDS + Secrets Manager manage/rotate it; Tofu never
   sees it. Prefer this over `random_password` (which stores plaintext in state).
3. **OpenTofu write-only/ephemeral attributes** for must-pass-through secrets.
4. Mark variables `sensitive = true`; never commit real `*.tfvars`; rely on encrypted state regardless.

### CI/CD — GitHub Actions + OIDC (no long-lived keys)
- **OIDC federation:** IAM OIDC provider + role trust-scoped to `repo:fair-n-square-co/infra:*`;
  `aws-actions/configure-aws-credentials` with `role-to-assume` + `id-token: write`.
- **PR → plan:** `fmt -check`, `init`, `validate`, **tflint** + **trivy**, `tofu plan -out=tfplan`,
  post summary as PR comment, upload encrypted plan artifact.
- **Merge → apply:** download the *same* plan artifact and `tofu apply tfplan`. Gate prod behind a
  **GitHub Environment with required reviewers**. Use `concurrency` groups per env.
- Skip Atlantis/Spacelift/TFC for now (overkill for two people).

### Shared service CI — reusable workflows in `.github`
The infra `plan`/`apply` workflows above are repo-local. **Service** CI (Go build/test/lint, CodeQL)
is factored out once into the org repo **`fair-n-square-co/.github`** and consumed by each service via
`workflow_call`, so a new Go service gets full CI in ~10 lines instead of copy-pasting a pipeline.

- **`go-ci.yml`** — lint (golangci-lint), build+vet, test, **govulncheck**, and an optional integration
  pass. Inputs (`go-version-file`, `golangci-lint-version`, `run-integration`, `integration-packages`,
  …) carry sane defaults. Repo-specific jobs (e.g. `core`'s sqlc/mocks codegen-drift check) stay in the
  caller workflow alongside the `uses:` job.
- **`codeql.yml`** — CodeQL analysis of Go source **and** the repo's own Actions workflows. The reusable
  workflow declares the permissions it needs; GitHub intersects them with what the caller grants.
- **Versioning:** published behind a moving major tag **`@v1`** (immutable `v1.0.0` anchor underneath).
  Callers pin `…/go-ci.yml@v1`; patch/minor fixes move the `v1` tag with no caller change. A
  `.github/zizmor.yml` `ref-pin` policy allows first-party (`fair-n-square-co/*`) tag refs while keeping
  all third-party actions pinned to a full commit SHA.
- **First adopter:** `core`. Roll out to `auth-api` and other Go services as they come online.

### Build order
1. **Bootstrap state** (S3 + KMS) → migrate env roots to S3 backend.
2. **OIDC + IAM** (GitHub provider, CI role, ECS exec/task roles).
3. **Networking** (VPC, subnets, endpoints, SGs).
4. **Data** (RDS, two DBs, master-managed secret) + **ECR**.
5. **Edge + services** (ACM + Route53 validation, ALB, cluster, ×4 `ecs-service`).
6. **Messaging** (EventBridge/SQS/SNS + Worker).
7. **CI** (plan/apply workflows; hand image-push to service repos).

### Gotchas for this stack
- **ECS task-def churn:** let Tofu own *infrastructure* (cluster, service, networking, IAM) and the app
  pipeline own the *image/task-def revision*; set `lifecycle { ignore_changes = [task_definition] }`.
- **ALB + gRPC:** target group `protocol_version = "GRPC"` (default HTTP/1.1 silently fails gRPC); gRPC
  health-check matcher (status `0`/`12`).
- **RDS:** private subnets, DB subnet group ≥2 AZs, SG-to-SG ingress (not CIDRs), no public IP.
- **ACM/Route53:** `validation_method = "DNS"` + `aws_acm_certificate_validation`; cert in the ALB's region; first apply hangs a few min on validation.
- **NAT cost:** single NAT gateway (one AZ) or NAT instance or VPC endpoints; `tofu destroy` dev when idle.
- **Fargate:** `awsvpc` networking (each task = an ENI; watch subnet IPs); `enable_execute_command` for debugging; `deployment_circuit_breaker` with rollback; RDS `deletion_protection` off in dev so `destroy` works.

---

## 8. Suggested learning progression

1. **Foundations** — ECR + one Fargate service (BFF) behind a public ALB, ACM + Route 53, Budgets alarm.
2. **VPC done right** — private subnets, SG chains, VPC endpoints instead of NAT.
3. **Data** — RDS Postgres (free tier), two DBs, secrets in Parameter Store, task roles.
4. **Service mesh-lite** — add Auth + Core as Fargate services, Cloud Map for internal gRPC.
5. **Observability** — ADOT sidecars → X-Ray + CloudWatch, Container Insights.
6. **Async (the real leap)** — EventBridge + SQS + Worker for balance recalculation / debt simplification, with DLQ + idempotency.
7. **Attachments + notifications** — S3 pre-signed uploads; SNS fan-out.
8. **Optional advanced** — Aurora Serverless v2 for Core (scale-to-zero), ElastiCache for cached balances, Multi-AZ RDS, ECS-on-EC2 capacity provider, internal ALB with `GRPC` target group, IaC for all of it.

---

## 9. Cost reality (low-traffic, us-east-1)

| Service | Free tier? | Rough monthly |
| --- | --- | --- |
| ECS Fargate (3–4 small tasks) | No | ~$25–35 (use Spot for worker; scale to 1 task) |
| Public ALB | No | ~$16–18 |
| RDS db.t4g.micro single-AZ | Yes (12 mo) | $0 → ~$12–15 |
| NAT Gateway | No | ~$32 ⚠️ — **avoid via VPC endpoints** |
| ECR / Route 53 / ACM | partial / no / free | ~$0–1 / ~$0.50 / $0 |
| SQS / SNS / EventBridge | generous | ~$0 |
| S3 / CloudWatch / X-Ray | partial | ~$0–3 |
| ElastiCache (if added) | No | ~$12 |

**Lean learning setup ≈ $45–60/mo.** The two biggest levers: the ALB (~$18) and avoiding NAT (~$32).
Set a **Budgets** alarm at $50 first.

---

## Sources
- [Fargate vs App Runner (cloudonaut)](https://cloudonaut.io/fargate-vs-apprunner/) · [ALB end-to-end HTTP/2 + gRPC (AWS)](https://aws.amazon.com/blogs/aws/new-application-load-balancer-support-for-end-to-end-http-2-and-grpc) · [Cloud Map service discovery for Fargate](https://containersonaws.com/pattern/service-discovery-fargate-microservice-cloud-map/)
- [Aurora Serverless v2 auto-pause](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2-auto-pause.html) · [EventBridge vs SNS vs SQS](https://arpadt.com/articles/eb-sns-sqs) · [ADOT Collector on ECS](https://aws-otel.github.io/docs/setup/ecs/)
- [OpenTofu vs Terraform 2026 (Encore)](https://encore.dev/articles/opentofu-vs-terraform-2026) · [S3 native state locking](https://www.bschaatsbergen.com/s3-native-state-locking) · [GitHub OIDC + AWS + Terraform](https://www.firefly.ai/academy/integrating-oidc-with-github-action-to-manage-terraform-deployment-on-aws) · [Avoiding secrets in TF state](https://oneuptime.com/blog/post/2025-12-18-terraform-avoid-secrets-in-state/view) · [ECS task-def revisions in TF](https://oneuptime.com/blog/post/2026-02-23-how-to-handle-ecs-task-definition-revisions-in-terraform/view)
