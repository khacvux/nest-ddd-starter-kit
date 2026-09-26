# AGENTS.md - Agent Operating Guidelines

Welcome AI Agent. This repository is built on strict Hexagonal / Domain-Driven Design (DDD) principles.

## Non-Negotiable Rules
1. **Never import framework packages in Domain**: `src/**/domain` must contain ZERO imports from `@nestjs/*`, `typeorm`, `express`, etc.
2. **Never inject repositories directly into controllers**: Controllers must execute an Application Use Case.
3. **Always use injection tokens**: When injecting a repository into a use case, use `@Inject(TOKEN_NAME)` with tokens from `src/shared/constants/injection-tokens.ts`.
4. **Never expose ORM entities to Domain or Application**: ORM entities belong exclusively in `infrastructure/persistence/<driver>/entities/`.
5. **Always add unit tests**: Test domain entities for business logic and use cases with mocked repository ports.

Refer to:
- `.agents/rules/architecture.md`
- `.agents/skills/ddd-nestjs/SKILL.md`
