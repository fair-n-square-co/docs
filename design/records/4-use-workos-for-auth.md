---
title: Use WorkOS (AuthKit) for Authentication
status: Proposed
date: 2026-06-21
---

# 4. Use WorkOS (AuthKit) for Authentication

## 🔍 Context

ADR-3 chose Better Auth (self-managed, in the SvelteKit backend). Since then our priorities have shifted:

- The goal of this phase is to **learn React and AWS**, not authentication. We want to spend our limited
  time on the frontend and the AWS / distributed-systems / IaC work, not on building and hardening auth.
- The frontend is moving to **React** (a separate decision that supersedes ADR-1's SvelteKit choice — to
  be recorded in its own ADR). Better Auth's main advantage was native SvelteKit integration, which no
  longer applies.
- Self-managing auth carries ~1.5–2 weeks of initial setup plus ongoing ownership: email deliverability,
  abuse/bot protection, MFA, secure session config, and security patching — effort we do not want to
  spend now.
- We still want to avoid expensive providers and vendor lock-in, and keep authorization (ReBAC) in our
  own service.

## ✅ Decision

We will use **WorkOS AuthKit** as our authentication (identity provider) for user sign-in, replacing
Better Auth.

To keep effort low and lock-in minimal, we adopt three rules:

1. **WorkOS AuthKit handles authentication only** — hosted login UI, social/Google login, sessions, MFA.
   We integrate via its React SDK / hosted AuthKit, writing minimal auth UI.
2. **Google-only (social/passwordless) login to start.** We will not store passwords. No password hashes
   means no painful hash-export migration if we ever change providers.
3. **Our Authx (user) service owns the canonical user record.** We keep our own `users` table keyed by a
   stable internal ID; the WorkOS user id (`sub`) / email is only a link to it. WorkOS is treated as a
   swappable, standards-based (OIDC) authentication source.

Our separate **Authx (user) Service** continues to own (unchanged from ADR-3):
- Fine-grained authorization (RBAC/ReBAC) — e.g. OpenFGA / Permit.io / WorkOS FGA in the future
- User profile management and the canonical user record
- Complex permission / entitlement evaluation

Backend services (Go Core service) validate WorkOS-issued tokens via JWKS; M2M / service-to-service auth
is handled by our Authx service (or WorkOS M2M) as before.

## 🎯 Consequences

### ➕ Positive
- **Minimal auth effort** — hosted AuthKit + Google-only means almost no auth code/UI; we focus on React + AWS.
- **Free at our scale** — AuthKit is free up to 1,000,000 MAU; a hobby/learning app will never pay.
- **No password management** — no hashes, reset flows, or deliverability headaches to own.
- **Low lock-in by design** — standard OIDC + we own the user record, so the provider is swappable later
  (Clerk, Cognito, Better Auth, …) without a data migration.
- **Built-in security** — MFA, social, passkeys, attack protection are the provider's responsibility.
- **Room to grow** — enterprise SSO/SCIM and FGA available later if ever needed.

### ➖ Negative
- **External dependency / managed service** — reverses ADR-3's "reduce external dependencies" goal; we
  rely on WorkOS uptime.
- **Less control & less auth learning** — we no longer implement auth ourselves (acceptable given the
  goal is React/AWS learning).
- **Some vendor coupling** — mitigated, not eliminated, by OIDC + owning the user record.
- **Google-only limits sign-in initially** — users without Google are excluded until we add another
  AuthKit connection (easy to add later).

### Migration Impact
- **Supersedes ADR-3 (Better Auth).** Since we are still early, impact is minimal.
- Auth DB schema simplifies: no credential/password storage; keep a `users` table linking internal id ↔
  WorkOS `sub`/email.
- Update system-design diagrams to show WorkOS AuthKit as the IdP and the BFF/React integration.
- Implement token validation (JWKS) in backend services and define how the Authx service provisions/links
  the canonical user on first login (JIT provisioning).

## Implementation Notes

### Authentication flow
1. React app initiates login → redirect to WorkOS AuthKit (Google).
2. User authenticates with Google via AuthKit.
3. AuthKit returns to our BFF with an auth code; BFF exchanges it for tokens/session.
4. On first login, the Authx service creates/links the canonical user (`users` row) by email/`sub` (JIT).
5. Session/token used for subsequent requests; backend services validate via WorkOS JWKS.

### Authorization flow (unchanged)
1. Request arrives with a validated token (subject = our internal user id).
2. Authx service evaluates permissions/entitlements (RBAC/ReBAC).
3. Decision returned to the requesting service.

## 🔄 Alternatives Considered

### Better Auth (status quo, ADR-3)
- **✅ Pros:** free, self-hosted, no lock-in, max control & learning.
- **❌ Cons:** ~1.5–2 weeks setup + ongoing security/abuse/email ownership; its SvelteKit-native edge is
  moot now the frontend is React. Too much effort for a phase focused on React/AWS.

### Clerk
- **✅ Pros:** best-in-class React DX, fast to integrate, free ~10k MAU.
- **❌ Cons:** higher lock-in and cost beyond hobby scale; smaller free tier than WorkOS.

### Kinde
- **✅ Pros:** good DX + React SDK; feature-rich free tier (MFA/social) up to ~10.5k MAU.
- **❌ Cons:** lower free ceiling than WorkOS; no advantage over WorkOS for our case.

### AWS Cognito
- **✅ Pros:** AWS-native (fits AWS learning), cheap.
- **❌ Cons:** rough developer experience — fights the "don't spend time on auth" goal. We'll learn AWS
  via infra (ECS/RDS/Terraform) instead.

### Auth0
- **✅ Pros:** generous 25k MAU free tier, mature.
- **❌ Cons:** steep price cliff beyond free; highest exit cost (deliberately hard password-hash export).
  Our Google-only + own-record strategy reduces this, but WorkOS is cheaper and less locked-in.

### Supabase Auth
- **✅ Pros:** 50k MAU free, OSS, self-hostable, low lock-in.
- **❌ Cons:** pulls toward the Supabase platform; AuthKit is lower-effort for our React-only need.

## 📚 References
- [WorkOS AuthKit](https://workos.com/) · [WorkOS Pricing](https://workos.com/pricing) — AuthKit free to
  1M MAU (verified 2026-06-21)
- [WorkOS AuthKit docs](https://workos.com/docs/authkit)
- [How OpenID Connect works](https://openid.net/developers/how-connect-works/)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- Supersedes [ADR-3: Use Better Auth for Authentication](./3-use-betterauth-for-auth.md)

## 📝 Change Record
| Date       | Author         | Description                          |
| ---------- | -------------- | ------------------------------------ |
| 2026-06-21 | Jaspreet Singh | Initial creation; supersedes ADR-3   |
