# Core Service — Overview

> **Current state as of 2026-06-22.** Edit in place when things change; record *why* in a new ADR.
> See [ADR-2](../../design/records/2-system-design-v1.md) for the system design decisions.

## What it is

The Core Service is a Go modular monolith that owns all business logic: groups, friends, expenses,
settlement, ledger, and todos. It exposes gRPC APIs (via connectRPC) and talks to the Auth Service
for token validation and permissions.

Repository: `github.com/fair-n-square-co/core`

## Module boundaries

Core is organised as one module per domain (`ledger`, `groups`, `friends`, `expenses`,
`settlement`, `todos`). Within a module the dependency direction is **api → service → repository**:
`api` handles gRPC requests and validation, `service` holds the domain logic and defines the
module's public interface, and `repository` owns DB access.

Modules do **not** import each other's packages — they talk to one another through the service
interface, which is the composability seam of the monolith.

## Proto contracts

Proto definitions live in the `apis` repo (`github.com/fair-n-square-co/apis`). Each module's `api`
layer implements the generated gRPC server interface.

## Current modules

| Module | Status | Jira |
| --- | --- | --- |
| `ledger` | Folding in from standalone repo | [FNS-134](https://loyalt.atlassian.net/browse/FNS-134) |
| `groups` | Not started — lands in Stage 2 (Groups & Friends epic) | — |
| `friends` | Not started — lands in Stage 2 (Groups & Friends epic) | — |
| `expenses` | Not started — lands in Stage 3 (Expenses & Splitting epic) | — |
| `settlement` | Not started — lands in Stage 4 (Balances & Settlement epic) | — |
| `todos` | Not started — lands in Stage 5 (MVP Feature Completion) | — |
