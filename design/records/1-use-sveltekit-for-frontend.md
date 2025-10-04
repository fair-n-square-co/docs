---
title: Use Web/Sveltekit for Frontend
status: Proposed
date: 2025-10-03
---

# 1. Use Web/SvelteKit for Frontend

## Context

To build this new system, we want to pick a UI framework. We want to analyse which UI framework is best suited for our needs. We want to consider the following factors:

- User experience to onboard
- Developer experience and product iteration
- Learning opportunity

As we start building the fair-n-square product, we want to pick a UI framework that is easy to work with, has less friction as we are not experts in frontend and is not frontend agnostic.

## Decision

We will use sveltekit for frontend. It works on browser, which makes it platform agnostic.

## Consequences

There are a few things that we will need to think about

- It is pretty new compared to something like React + Next.js. Which means we have to learn this.
- We will want to use sveltekit to its fullest, so it has both frontend + backend component. Which means two things
  - We have the capability to do server side rendering, which is good for SEO and performance
  - We will have to be careful what we put on the server side. We want to keep the scope of frontend tied just to solve frontend problems. We don't want to put business logic on the server side of sveltekit.

### Positive

- Sveltekit is easy to use, feels closer to Javascript/Typescript + HTML model than other frameworks
- SSR will be fast to render on mobile
- Using web framework instead of mobile app helps to reduce friction to onboard users

### Negative

- New framework and no past experience
- No native app might limit some capabilities

## Alternatives Considered

### Native apps

#### Pros

- Have better data persistance
- Will have better performance since UI is already part of the app

#### Cons

- Will either need to use something like flutter to build cross platform app or build two separate apps
- Higher developer friction as we need to comply with app stores
- need to pay fees for apple app store

### React/Vue

#### Pros

- Familiar frameworks, which means we are not learning new framework and quicker first implementation
- A huge community, lots of components/libraries to use
- Battle tested in real world

#### Cons

- React/Vue project feel really bloated
- Next.js is pretty close to svelte conceptually as it also does SSR, but it still uses React which has very bloated syntax and complicates things way too much
- Learning something new would be really exciting

## Change Record

| Date       | Author         | Description      |
| ---------- | -------------- | ---------------- |
| 2025-10-04 | Jaspreet Singh | Initial creation |
