---
title: Use React for the Frontend
status: Proposed
date: 2026-06-21
---

# 5. Use React for the Frontend

## 🔍 Context

ADR-1 chose SvelteKit — primarily for its lightweight DX and the learning opportunity — with the UI and
backend (BFF/SSR) in one framework. Two things have since changed:

- The current learning goal is explicitly to **learn React and AWS**. React is the framework we now want
  hands-on experience with.
- We are adopting **WorkOS AuthKit** for authentication (ADR-4), so SvelteKit's main remaining advantage —
  native Better Auth integration — no longer applies.

We have an existing SvelteKit `webapp`, so switching has a real (but early-stage) cost. ADR-1 itself
listed "new framework and no past experience" as a negative; React removes that gap.

## ✅ Decision

We will use **React** for the frontend, replacing SvelteKit.

- Use a React meta-framework with a server (e.g. **Next.js** or **TanStack Start**) to keep the
  **BFF/SSR pattern** from ADR-2: the frontend server is the backend-for-frontend that holds the session,
  integrates WorkOS AuthKit, and talks to the Go services over connectRPC/gRPC. (A thin Node/Hono BFF +
  React SPA is an acceptable alternative.)
- Keep the architectural rule from ADR-1/ADR-2 unchanged: **the frontend layer solves only UI/BFF
  concerns; business logic stays in the Core service.**
- Integrate **WorkOS AuthKit** via its React SDK + the BFF (per ADR-4).

The exact framework (Next.js vs TanStack Start vs SPA+BFF) is an implementation detail to confirm at build
time; the decision here is **React + retain the BFF pattern**.

## 🎯 Consequences

### ➕ Positive
- Hands-on **React** experience (the stated learning goal); largest ecosystem and component/library availability.
- First-class SDKs for our chosen tools (WorkOS, etc.).
- Retains SSR + BFF benefits via a React meta-framework.
- Easier path to React Native later if we ever do mobile.

### ➖ Negative
- **Reverses ADR-1** and discards the existing SvelteKit `webapp` scaffold (drizzle/storybook/playwright
  setup must be re-created).
- React is more boilerplate than Svelte (ADR-1's original concern).
- The exact React stack (Next.js / TanStack / SPA+BFF) is still open.

### Migration Impact
- Supersedes ADR-1.
- Re-scaffold the frontend repo (`webapp`) on React; re-port the auth UI to WorkOS AuthKit (small, since
  AuthKit is hosted).
- Update system-design docs and diagrams to show React + BFF + WorkOS.

## 🔄 Alternatives Considered

### Stay on SvelteKit (ADR-1)
- **✅ Pros:** existing scaffold, less boilerplate, no rework.
- **❌ Cons:** doesn't serve the React learning goal; its Better-Auth/SvelteKit synergy is gone now we use WorkOS.

### Next.js (now)
- **✅ Pros:** closest 1:1 replacement for SvelteKit's SSR+BFF; huge ecosystem; WorkOS has Next examples.
- **❌ Cons:** heavier conventions; we defer the exact-framework choice to build time.

### TanStack Start
- **✅ Pros:** modern, type-safe, lighter than Next for an SPA-leaning app.
- **❌ Cons:** younger / less battle-tested than Next.

## 📚 References
- [React](https://react.dev/) · [Next.js](https://nextjs.org/) · [TanStack Start](https://tanstack.com/start)
- [WorkOS AuthKit + React](https://workos.com/docs/authkit)
- Supersedes [ADR-1: Use Web/SvelteKit for Frontend](./1-use-sveltekit-for-frontend.md); related to
  [ADR-4: Use WorkOS for Authentication](./4-use-workos-for-auth.md)

## 📝 Change Record
| Date       | Author         | Description                        |
| ---------- | -------------- | ---------------------------------- |
| 2026-06-21 | Jaspreet Singh | Initial creation; supersedes ADR-1 |
