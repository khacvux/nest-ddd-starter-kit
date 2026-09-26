# CLAUDE.md

This file provides authoritative guidance to Claude Code, Antigravity, and AI agents working on this repository.

## 1. Project Overview & Architecture
This project is an enterprise-grade NestJS starter kit adhering strictly to **Domain-Driven Design (DDD)** and **Hexagonal Architecture**.

- **Dependency Direction**: `Interfaces` -> `Application` -> `Domain` <- `Infrastructure`
- **Domain Layer**: 100% Pure TypeScript. No framework dependencies (`@nestjs/*`, `typeorm`, etc.).
- **Application Layer**: Use Cases orchestrate business logic. Injects ports via DI tokens.
- **Infrastructure Layer**: Implements ports via adapters. Contains ORM entities (`*.orm-entity.ts`).
- **Interfaces Layer**: HTTP Controllers validate DTOs and delegate to Use Cases.

Read `.agents/rules/architecture.md` for strict architectural rules.
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

## 3. Key Patterns & Conventions
- **Dependency Injection**: Always use `Symbol` tokens declared in `src/shared/constants/injection-tokens.ts`.
- **Validation**: Use `class-validator` and `class-transformer` in Request DTOs.
- **Error Handling**: Throw domain errors extending `DomainError`. The global `DomainExceptionFilter` maps them to HTTP responses automatically.
- **ORM Separation**: Never name TypeORM entities `*.entity.ts`. Always use `*.orm-entity.ts` and map to/from domain entities using `*.mapper.ts`.
- **API Documentation**: Interactive Swagger docs available at `http://localhost:3000/api/docs`.
