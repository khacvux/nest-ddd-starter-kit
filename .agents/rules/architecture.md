# Architecture Rules

This project adheres to a Strict Domain-Driven Design (DDD) Hexagonal Architecture.

## 1. Dependency Rule
Dependencies must point **inward** toward the Domain layer within each bounded context (e.g., `users`):

- `src/<domain>/domain`: **PURE TypeScript**.
  - **MUST NOT** import from `@nestjs/*`, TypeORM, database drivers, application, infrastructure, or interfaces layers.
  - Zero framework dependencies. Business logic and invariants only.
- `src/<domain>/application`: **Orchestration & Application Logic**.
  - **MUST NOT** import from infrastructure or interfaces.
  - May import from `domain` and `@nestjs/common` (only for `@Injectable()` and `@Inject()`).
- `src/<domain>/infrastructure`: **Technical Implementation & Adapters**.
  - Implements ports defined in `domain` or `application`.
  - May import from `domain`, `application`, TypeORM, database drivers, and third-party SDKs.
- `src/<domain>/interfaces`: **Delivery Mechanisms (HTTP/Controllers/CLI/Events)**.
  - May import from `application` (Use Cases, DTOs) and `domain` (Errors, Enums).
  - **MUST NOT** import from `infrastructure` directly, except in NestJS module wiring (`*.module.ts`) to bind providers.
- `src/shared`: **Cross-cutting concerns & foundational abstractions**.
  - Base classes for Entity, ValueObject, and DomainError.
  - Injection tokens (`src/shared/constants/injection-tokens.ts`).
  - Global HTTP filters, pipes, and shared infrastructure (database, logging).

---

## 2. Naming Conventions

| Component | File Extension | Example |
| :--- | :--- | :--- |
| **Domain Entity** | `.entity.ts` | `user.entity.ts` |
| **Value Object** | `.vo.ts` | `email.vo.ts` |
| **Repository Port (Interface)** | `-repository.interface.ts` | `user-repository.interface.ts` |
| **Domain Error** | `.error.ts` | `user-not-found.error.ts` |
| **Domain Event** | `.event.ts` | `user-created.event.ts` |
| **Use Case** | `.use-case.ts` | `create-user.use-case.ts` |
| **Application DTO** | `.dto.ts` | `create-user.dto.ts` |
| **Application Mapper** | `.mapper.ts` | `user.mapper.ts` |
| **ORM Entity** | `.orm-entity.ts` | `user.orm-entity.ts` *(NEVER .entity.ts)* |
| **Repository Adapter** | `.repository.ts` | `typeorm-user.repository.ts` |
| **HTTP Controller** | `.controller.ts` | `users.controller.ts` |
| **Request/Response DTO** | `.request.dto.ts` / `.response.dto.ts` | `create-user.request.dto.ts` |
| **NestJS Module** | `.module.ts` | `users.module.ts` |

---

## 3. Layer Specific Rules

### Domain
- Domain entities encapsulate state using private fields with getters or readonly properties.
- State mutation happens exclusively through expressive domain methods (e.g. `user.changePassword(...)`, never raw setters).
- Invariants must be validated inside Value Object and Entity factory methods (`create`, `restore`).
- Repositories are expressed strictly as interfaces (`IUserRepository`).

### Application
- Use Cases implement a single business action with an `execute()` method.
- Use Cases inject repository interfaces using `@Inject(USER_REPOSITORY)` with Symbol tokens from `src/shared/constants/injection-tokens.ts`.
- Use Cases orchestrate: load entity -> invoke domain business method -> persist entity -> publish event / return DTO.

### Infrastructure
- Database entities MUST be named `*.orm-entity.ts` and live in `infrastructure/persistence/<driver>/entities/`.
- Database schemas must not leak into the domain. Use a dedicated `*.mapper.ts` to map between ORM entity and Domain entity.
- Repositories in infrastructure implement the interface defined in `domain/repositories/`.

### Interfaces
- Controllers are strictly delivery layer: deserialize request, validate using DTOs, execute Use Case, map result to HTTP response.
- Controllers **MUST NOT** communicate directly with Repositories.
- Controllers **MUST NOT** contain business logic.
- Always annotate Swagger decorators (`@ApiOperation`, `@ApiResponse`) for auto-documentation.

---

## 4. Error Handling
- Throw domain errors (extending `DomainError`) from Domain and Application layers.
- The global `DomainExceptionFilter` catches all `DomainError` instances and maps them to appropriate HTTP status codes (400, 401, 403, 404, 409, 422).
