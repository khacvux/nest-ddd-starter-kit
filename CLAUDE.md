# CLAUDE.md

This file provides authoritative guidance to Claude Code, Antigravity, and AI agents working on this repository.

## 1. Project Overview & Architecture
This project is an enterprise-grade NestJS starter kit adhering strictly to **Domain-Driven Design (DDD)** and **Hexagonal Architecture**.

- **Dependency Direction**: `Interfaces` -> `Application` -> `Domain` <- `Infrastructure`
- **Domain Layer**: 100% Pure TypeScript. No framework dependencies (`@nestjs/*`, `typeorm`, etc.).
- **Application Layer**: Use Cases orchestrate business logic. Injects ports via DI tokens.
- **Infrastructure Layer**: Implements ports via adapters. Contains ORM entities (`*.orm-entity.ts`).
- **Interfaces Layer**: HTTP Controllers validate DTOs and delegate to Use Cases.

Read `.agents/rules/architecture.md` for strict architectural rules (CQRS, UoW, 3-tier validation, testing matrix).
Read `.agents/skills/ddd-nestjs/SKILL.md` for complete step-by-step implementation templates.

---

## 2. Essential Commands

### Development
```bash
npm install            # Install dependencies
npm run start:dev      # Start development server with hot-reload
npm run build          # Build production bundle
npm run start:prod     # Run production bundle
```

### Database & Docker
```bash
docker-compose up -d   # Start local PostgreSQL database
docker-compose down    # Stop database
```

### Code Quality & Testing
```bash
npm run test           # Run unit tests
npm run test:watch     # Run unit tests in watch mode
npm run test:cov       # Generate test coverage
npm run test:e2e       # Run end-to-end tests
npm run lint           # Check and fix lint issues
npm run format         # Format code with Prettier
```

---

## 3. Key Enterprise Patterns & Conventions
- **CQRS**: Commands mutate state through aggregates; Queries may project directly to Read DTOs.
- **Events**: Domain Events stay within the bounded context; Integration Events use the Transactional Outbox Pattern before sending to external brokers (RabbitMQ/Kafka).
- **Transactions**: Managed exclusively via the `IUnitOfWork` port (`UNIT_OF_WORK` token) in Application Use Cases. Never import TypeORM `QueryRunner` into use cases.
- **Validation**: 3-tier strategy: Syntactic (DTOs / 400), Semantic Invariants (Value Objects / 422), Contextual (Use Cases / 409 & 404).
- **Dependency Injection**: Always use `Symbol` tokens declared in `src/shared/constants/injection-tokens.ts`.
- **Testing**: Zero mocks in Domain unit tests; mock interface ports in Application tests; real DB in Infrastructure tests; `supertest` in E2E tests.
- **ORM Separation**: Never name TypeORM entities `*.entity.ts`. Always use `*.orm-entity.ts` and map to/from domain entities using `*.mapper.ts`.
- **API Documentation**: Interactive Swagger docs available at `http://localhost:3000/api/docs`.
