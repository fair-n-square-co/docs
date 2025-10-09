# MVP Scope: Fair N Square

## Overview

Fair N Square came out of necessisity of building a payment splitting system like Splitwise since it is now very limited for free use. The goal of this MVP is to build/deploy with enterprise grade architecture and design principles. The goal is also to learn how to build complex systems with clear boundaries and good practices. The end-to-end system will be open source and free to use for everyone.

## Goals & Objectives

### Primary Goals

- As a user, I want to be able to create an account and login securely.
- As a user, I want to be able to create and manage groups.
- As a user, I want to be able to add/manage my friends/contacts.
- As a user, I want to be able to add expenses and split them among group members in multiple currencies.
- As a user, I want to be able to choose different split methods (equal, exact amounts, percentages).
- As a user, I want to be able to edit/delete expenses.
- As a user, I want to be able to add comments/notes to expenses.
- As a user, I want to be able to attach attachements like photos/pdf to expenses.
- As a user, I want to be able to view group balances and individual member balances.
- As a user, I want to be able to view my balance and transaction history.
- As a user, I want to be able to settle up with other group members.
- As a user, I should have the ability simplify debts within the group.
- As a user, I want to also have an ability to create multiple todo lists for the group.
- As a user, I want to assign tasks to group members.
- As a user, I want to be able to manage group settings and preferences.
- As a developer, I want to build systems using enterprise principles like documenting design decisions, making sure there is clear separation of concerns, and following coding standards.
- As a developer, I want to use advanced concepts like gRPC, microservices, CI/CD, monitoring, logging etc to build and deploy the system.
- The system built should be scalable and maintainable.
- The system should follow best practices in security and data privacy.
- The system has latest technologies for observability, monitoring, logging, and alerting.
- Key success metrics include user adoption rates and transaction volume.
- Target launch date is set for Q4 2025.

### Out of scope for MVP

- Push notification system (can still have add it as a stretch goal if required)
- Advanced reporting, analytics, export transaction list etc.
- Transaction categories
- In-app chat or messaging system.
- Performance testing/load testing.
- Mobile apps (can be added in future)
- MCP server for AI agents

## Target Audience

- Individuals who frequently share expenses with friends, family, or roommates.
- Small groups or communities looking for a simple way to manage shared expenses.
- Tech-savvy users who appreciate open-source solutions and value data privacy.
- Users dissatisfied with existing solutions like Splitwise due to limitations or costs.
- Users looking for a free, reliable, and easy-to-use expense splitting application.

## Technical Requirements

Some of the advanced technical requirements can be out of scope, but we want to design our systems to ensure we achieve these goals in the future.

- Platform(s): Web (SvelteKit)
- Backend: Microservices architecture using gRPC
- Database: Standard database solution popular in big enterprise (e.g., PostgreSQL, Cloud Spanner etc.)
- Third-party integrations like WorkOS for authentication, openFGA/permit.io for authorization etc.
- There will be SLAs for uptime, response time, and data consistency.
- Security: End-to-end encryption, secure authentication, and data privacy/security.
- Scalability: The system should be able to handle increasing number of users and transactions without performance degradation.
- Maintainability: Code should be modular, well-documented, and follow coding standards
- Observability: Implement monitoring, logging, and alerting to ensure system health and performance.
- CI/CD: Automated testing and deployment pipelines to ensure rapid and reliable releases.

## Dependencies

- We would need to choose multiple third party services for authentication, authorization, database, hosting, file storage etc.
- Something like turso for multi-tenant database could be interesting to explore.
- We would need to choose a hosting provider for deploying our services.
- We would need to choose a logging/monitoring solution.
- We would need to choose a CI/CD solution.

## Risks & Assumptions

### Risks

- Building a complex system with advanced concepts might lead to delays in development.
- Integrating multiple third-party services could introduce dependencies and potential points of failure.
- Ensuring data privacy and security could be challenging, especially with sensitive financial data.

### Assumptions

- We won't have much traffic. It is build for learning purposes, for us, by us.
- We would possibly host a lot of the services on free tier to keep the cost low.
- For other o11y services, we could get a free tier for OSS projects.
- We will be using third party services for authentication/authorization to keep the scope manageable.

## Timeline

We are gonna follow kanban and maybe even waterfall. The target dates don't really mean anything. The goal is to build a working product with good practices and principles.

| Milestone         | Target Date | Status |
| ----------------- | ----------- | ------ |
| Design completion |             |        |
| Development start |             |        |
| Alpha release     |             |        |
| Beta release      |             |        |
| MVP launch        |             |        |

## Success Criteria

- Metric 1: We can have multiple users sign up and use the system
- Metric 2: We can keep the system uptime above 99.9%
- Metric 3: We can handle at least 1000 transactions per day without performance degradation

## Next Steps

- [ ] Identify and finalize third-party services for authentication, authorization, database, hosting, and file storage.
- [ ] Set up the development environment and tools. This will include local deployment of services like database, auth provider, o11y tools etc.
- [ ] Complete the design phase, including system architecture, data models, and API specifications.
- [ ] Setup end-to-end deployment of the service with basic login/logout functionality.
- [ ] Setup CI/CD pipelines for automated testing and deployment.
- [ ] Begin development of core features as per the defined goals and objectives.
- [ ] Integrate monitoring, logging, and alerting for system observability with hosted service.
- [ ] Add more features with faster iteration times, improving user experience, and ensuring system stability.
