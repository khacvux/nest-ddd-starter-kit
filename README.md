# 🏗️ NestJS DDD Starter Kit

A production-ready, enterprise-grade **NestJS** starter kit adhering strictly to **Domain-Driven Design (DDD)** and **Hexagonal (Ports and Adapters)** architecture, pre-configured with **TypeORM**, **PostgreSQL**, and complete **AI Agent Rules & Skills** (Claude Code, Antigravity, Cursor, Copilot).

---

## 🌟 Highlights

- 💎 **Strict Hexagonal / DDD Architecture**: Complete separation of concerns into Domain, Application, Infrastructure, and Interfaces.
- 🛡️ **Zero Framework Dependencies in Domain**: Pure TypeScript business logic, entities, value objects, and ports.
- 🔌 **Ports & Adapters (Hexagonal)**: Infrastructure adapters implement domain ports via TypeScript interfaces and NestJS `Symbol` injection tokens.
- 🗄️ **TypeORM with PostgreSQL**: Separated ORM entities (`*.orm-entity.ts`) with automated bi-directional persistence mappers.
- 🐳 **Dockerized Database**: Instant local PostgreSQL environment via `docker-compose`.
- 🤖 **Built-in AI Agent Rules & Skills**: Pre-configured with `.agents/rules/architecture.md`, `.agents/skills/ddd-nestjs/SKILL.md`, `CLAUDE.md`, and `AGENTS.md`.
- 📖 **Interactive OpenAPI / Swagger**: Pre-configured API documentation at `/api/docs`.
- 🧪 **Full Test Suite**: Unit tests for domain entities, value objects, use cases, and E2E tests with Jest.

---

## 🏛️ Architecture & Folder Structure

Each feature or bounded context (e.g. `users`) is structured into 4 distinct layers:

```
src/
├── app.module.ts
├── main.ts
├── shared/                                # Cross-cutting concerns & base classes
│   ├── constants/
│   │   └── injection-tokens.ts            # Symbol tokens for DI
│   ├── domain/
│   │   ├── base.entity.ts                 # Base Entity class
│   │   ├── value-object.base.ts           # Base ValueObject class
│   │   └── domain-event.interface.ts      # Domain Event contract
│   ├── errors/
│   │   └── domain-error.ts                # Base DomainError & standard errors
│   ├── http/
│   │   └── filters/
│   │       └── domain-exception.filter.ts # Maps DomainErrors to HTTP statuses
│   └── infrastructure/
│       └── database/
│           └── database.module.ts         # TypeORM PostgreSQL configuration
│
└── users/                                 # Sample Bounded Context
    ├── domain/                            # PURE TypeScript (ZERO framework imports)
    │   ├── entities/
    │   │   └── user.entity.ts             # Domain aggregate root
    │   ├── value-objects/
    │   │   ├── email.vo.ts                # Self-validating immutable value object
    │   │   └── user-role.vo.ts
    │   ├── repositories/
    │   │   └── user-repository.interface.ts # Port (contract)
    │   ├── errors/
    │   │   ├── user-not-found.error.ts
    │   │   └── user-already-exists.error.ts
    │   └── events/
    │       └── user-created.event.ts
    │
    ├── application/                       # Orchestration & Use Cases
    │   ├── dtos/
    │   │   ├── create-user.dto.ts
    │   │   └── user-response.dto.ts
    │   ├── mappers/
    │   │   └── user.mapper.ts             # Maps Domain Entity -> Response DTO
    │   └── use-cases/
    │       ├── create-user.use-case.ts
    │       └── get-user-by-id.use-case.ts
    │
    ├── infrastructure/                    # Adapters & Technical Details
    │   └── persistence/
    │       └── typeorm/
    │           ├── entities/
    │           │   └── user.orm-entity.ts # Database Schema (never leaks to Domain)
    │           ├── mappers/
    │           │   └── user-persistence.mapper.ts # Maps ORM <-> Domain Entity
    │           └── repositories/
    │               └── typeorm-user.repository.ts # Adapter implementing Port
    │
    └── interfaces/                        # Delivery Layer (HTTP/REST)
        ├── http/
        │   ├── controllers/
        │   │   └── users.controller.ts    # Delegates to Use Cases
        │   └── dtos/
        │       └── create-user.request.dto.ts # Validated using class-validator
        └── modules/
            └── users.module.ts            # NestJS DI wiring
```

---

## 🚦 Dependency Rules

```
   [Interfaces]  -->  [Application]  -->  [Domain]  <--  [Infrastructure]
  (Controllers)       (Use Cases)       (Entities)         (Adapters)
```

1. **Domain Layer**:
   - Zero framework dependencies.
   - Contains business logic, value objects, entities, and repository ports.
2. **Application Layer**:
   - Orchestrates domain entities and ports.
   - Contains Use Cases and DTOs. Depends only on Domain and `@nestjs/common` (for DI).
3. **Infrastructure Layer**:
   - Contains technical implementations (TypeORM entities, repositories, 3rd party SDKs).
   - Implements ports from Domain.
4. **Interfaces Layer**:
   - Controllers handle HTTP routing, deserialization, and call Use Cases.
   - Controllers NEVER access repositories directly.

---

## 🚀 Getting Started

### 1. Prerequisites
- Node.js >= 20.x
- Docker & Docker Compose (for PostgreSQL)

### 2. Installation
```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env
```

### 3. Start Database
```bash
docker-compose up -d
```

### 4. Run Application
```bash
# Development mode with hot-reload
npm run start:dev

# Production build
npm run build
npm run start:prod
```

### 5. Access Endpoints & Docs
- **Swagger Documentation**: [http://localhost:3000/api/docs](http://localhost:3000/api/docs)
- **Health Check**: [http://localhost:3000/health](http://localhost:3000/health)
- **Create User**: `POST http://localhost:3000/users`
- **Get User**: `GET http://localhost:3000/users/:id`

---

## 🧪 Testing

```bash
# Run unit tests
npm run test

# Run tests in watch mode
npm run test:watch

# Test coverage
npm run test:cov

# End-to-end tests
npm run test:e2e
```

---

## 🤖 AI Agent Integration

This repository includes first-class rules and skills for AI pair programmers:

- **`.agents/rules/architecture.md`**: Architecture invariants, naming conventions, and layer constraints.
- **`.agents/skills/ddd-nestjs/SKILL.md`**: Step-by-step workflow and templates for generating new DDD features.
- **`CLAUDE.md`**: Context file for Claude Code.
- **`AGENTS.md`**: Universal instructions for agentic assistants.
