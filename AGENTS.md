# AGENTS.md - Agent Operating Guidelines

Welcome AI Agent. This repository is built on strict Hexagonal / Domain-Driven Design (DDD) principles.

## Non-Negotiable Rules
1. **Never import framework packages in Domain**: `src/**/domain` must contain ZERO imports from `@nestjs/*`, `typeorm`, `express`, etc.
2. **Never inject repositories directly into controllers**: Controllers must execute an Application Use Case.
3. **Always use injection tokens**: When injecting a repository into a use case, use `@Inject(TOKEN_NAME)` with tokens from `src/shared/constants/injection-tokens.ts`.
4. **Transactions via Unit of Work**: Never import TypeORM `EntityManager` or `QueryRunner` into use cases. Inject `@Inject(UNIT_OF_WORK)` instead.
5. **CQRS Query Bypass**: Queries may bypass Domain Aggregates to read projections directly, but must never produce side effects.
6. **Never expose ORM entities to Domain or Application**: ORM entities belong exclusively in `infrastructure/persistence/<driver>/entities/`.
7. **Always follow the 3-Tier Validation Strategy**: DTOs for syntax (400), Value Objects for invariants (422), Use Cases for context (404/409).
8. **Follow the Testing Matrix**: Zero mocks in domain tests; mock port interfaces in application tests; test state mutations.

Refer to:
- `.agents/rules/architecture.md`
- `.agents/skills/ddd-nestjs/SKILL.md`
