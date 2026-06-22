# [Fair n Square] - Technical Design

---

## Tech Stack
- **Frontend**: React (meta-framework keeping the BFF/SSR role) — see [ADR-5](./design/records/5-use-react-for-frontend.md)
- **Auth**: WorkOS AuthKit (Google-only to start) — see [ADR-4](./design/records/4-use-workos-for-auth.md)
- **Backend**: Go
- **API Layer**: gRPC + connectRPC + REST(per need basis)
- **Database**: Postgres (for backend service)
- **Infrastructure**: AWS (ECS Fargate, RDS) via OpenTofu — see [aws-architecture](./docs/aws-architecture.md). Fly.io remains a simpler fallback.

## Architecture desicions
Design decisions are made in [design](./design/) directory

## Live design
The current state of the system, organised by domain, lives in [live](./live/). Live docs say *what
is*; ADRs in [design/records](./design/records/) say *why*.
