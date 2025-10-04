This directory hosts the decision records made for fair n square project.

- A record is categorised and structured using directories.
- A record is made by creating ADR or Architecture decision record.
- A record consists of Summary, Context, Decision, Consequences.
- When creating a record, think about
  - goals
  - constraints
  - assumptions
  - trade-offs
  - alternatives
  - related decisions
  - references
- The name of an ADR should be the serial number followed by a short description of the decision.
  - Example: 1-use-sveltekit-for-frontend.md

## Decision Records types

### System design

System design is a high level design for the the entire system. We will use the terminology 'System' to describe a part/dependency of a product. Examples of systems are a web server, vendor service, a database, a microservice, web/app client etc.

We capture how we build systems using an ADR. The reason for this is to create a standard approach to building similar systems. For example, we can have a standard approach to building microservices.
To not constraint the choices for implementation, we will not capture the implementation details in system design. But rather, we want to capture decisions like, but not limited to, logging, monitoring, tracing, error handling, api design etc.

PS: choice of language falls under implementation detail and should not be enforced in system design. It should rather be captured as a suggestion, if necessasary.

### Component design

Component design is a low level design for a system. We will use the terminology 'Component' to describe how a system is designed/assembled and describe the behaviour of the components. Think of a component as a class or a module in a codebase. It is encouraged to embed component design within the repo a system is implemented. It can either be it's own docs directory within the repo, it can be a wiki or it can be embedded within the codebase itself. As the system grows, the complexity grows as well. A component design should be a single document that evolves along with the system.
