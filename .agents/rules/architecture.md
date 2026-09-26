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


---

## 5. CQRS & Event Handling

We enforce Command Query Responsibility Segregation (CQRS) to optimize for both domain integrity and query performance.

### 5.1 Command vs. Query Segregation
| Concern | Commands (Write) | Queries (Read) |
| :--- | :--- | :--- |
| **Intent** | Mutate state, trigger domain behavior | Retrieve data without side effects |
| **Domain Usage** | **MANDATORY**. Loads Aggregate Root, executes business invariants | **OPTIONAL**. May bypass Domain Entities completely |
| **Data Source** | Domain Repository Port (`IUserRepository`) | Read Model Port or optimized database projections / raw SQL |
| **Return Value** | Minimal (Command DTO, ID, or `void`) | Tailored Read DTOs (Flat, optimized for UI / client) |
| **Transaction** | Typically wrapped in a Unit of Work / Transaction | Read-only / Non-transactional |

#### Query Optimization Rule
- Queries **MUST NOT** load heavy Domain Aggregates or execute domain methods simply to return read data.
- Read queries may project directly from database views or ORM queries into application Read DTOs.
- Queries **MUST NEVER** produce side-effects or alter database state.

---

### 5.2 Domain Events vs. Integration Events

| Attribute | Domain Events | Integration Events |
| :--- | :--- | :--- |
| **Scope** | Internal to the current Bounded Context | Across Bounded Contexts or External Systems |
| **Transport** | In-memory event bus (e.g., NestJS `EventEmitter2`) | Distributed Message Broker (RabbitMQ, Kafka) |
| **Dependency** | Pure TypeScript; declared in `domain/events/` | DTO contracts; declared in `shared/contracts/` |
| **Timing** | Emitted synchronously or immediately after write | Dispatched via **Transactional Outbox Pattern** |
| **Naming** | Past-tense action: `UserCreatedEvent` | Past-tense with context: `AuthUserRegisteredIntegrationEvent` |

#### Event Rules
1. **Zero External SDKs in Domain**: Domain Events **MUST NOT** reference RabbitMQ, Kafka, or third-party queue libraries.
2. **Transactional Outbox Pattern**: When an external Integration Event must be published, write the event payload to an `outbox` database table within the same transaction. A dedicated background worker relays events to the message broker. **NEVER** publish directly to an external message broker within an active database transaction.

---

## 6. Transaction Management & Unit of Work (UoW)

Database transactions are technical implementation details that **MUST NOT** leak into Domain Entities or pollute Application Use Cases with infrastructure dependencies (e.g., TypeORM `QueryRunner` or `EntityManager`).

### 6.1 The Unit of Work Port
Declare an abstract Unit of Work contract in the Application/Shared layer:

```typescript
// src/shared/application/ports/unit-of-work.port.ts
export interface IUnitOfWork {
  execute<T>(work: () => Promise<T>): Promise<T>;
}
```

### 6.2 Transaction Rules
1. **Transaction Boundary**: The boundary of a transaction resides strictly in the **Application Use Case**, never in Controllers or Domain Entities.
2. **Repository Consistency**: Repositories executed within a UoW callback must automatically partake in the active transactional context (e.g., using AsyncLocalStorage or transactional repository factories).
3. **No Direct ORM Imports in Use Cases**: Use Cases **MUST NOT** import `EntityManager`, `DataSource`, or `QueryRunner`. Inject `IUnitOfWork` using its injection token:

```typescript
// src/users/application/use-cases/register-user.use-case.ts
@Injectable()
export class RegisterUserUseCase {
  constructor(
    @Inject(UNIT_OF_WORK) private readonly uow: IUnitOfWork,
    @Inject(USER_REPOSITORY) private readonly userRepo: IUserRepository,
  ) {}

  async execute(dto: RegisterUserDto): Promise<void> {
    await this.uow.execute(async () => {
      // All repository calls in this scope participate in the same transaction
      await this.userRepo.save(user);
      await this.outboxRepo.save(event);
    });
  }
}
```

---

## 7. Validation Strategy

We maintain a strict three-tier validation strategy to separate syntactic correctness from semantic business invariants.

| Tier | Layer | Mechanism | Responsibility | Error Thrown | HTTP Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Syntactic** | Interfaces (HTTP) | `class-validator`, `class-transformer` on DTOs | Missing fields, string lengths, regex format, primitive type coercion | `BadRequestException` | `400 Bad Request` |
| **2. Semantic (Invariants)** | Domain | Value Objects & Entity factory methods | Self-contained business rules (e.g., age >= 18, valid RFC email, negative balances) | `ValidationError` (extends `DomainError`) | `422 Unprocessable Entity` |
| **3. Contextual** | Application | Use Case + Repository Port | Cross-entity consistency (e.g., duplicate email check, inventory existence) | `ConflictError` / `EntityNotFoundError` | `409 Conflict` / `404 Not Found` |

### Validation Rules
- **Never rely exclusively on DTO validation**: The Domain layer must be self-protecting. If a domain entity or value object can be constructed in an invalid state, the design is flawed.
- **DTOs validate shape, not rules**: DTOs ensure a field is a string and looks like an email. The `Email` Value Object guarantees it complies with domain business invariants.

---

## 8. Testing Strategy

All code must conform to the testing matrix. Mocking boundaries must respect layer isolation.

### 8.1 Testing Matrix

| Layer | Test Type | File Extension | Mocking Boundary | Required Assertions |
| :--- | :--- | :--- | :--- | :--- |
| **Domain** | Unit | `*.spec.ts` | **ZERO MOCKS**. Pure TypeScript. | Invariant violations, factory outputs, state transitions, domain errors. |
| **Application** | Unit | `*.spec.ts` | Mock all Ports (`IUserRepository`, `IUnitOfWork`, `IEventBus`). | Orchestration logic, correct port invocations, error propagation. |
| **Infrastructure** | Integration | `*.integration-spec.ts` | Real DB via Testcontainers / in-memory DB. Mock external HTTP APIs. | SQL constraints, ORM entity mappings, repository queries, transaction rollbacks. |
| **Interfaces** | E2E | `*.e2e-spec.ts` | Use `supertest`. Mock external third-party services only. | HTTP status codes, validation pipes, exception filter responses, route guards. |

### 8.2 Mocking Rules
1. **Never mock Domain Entities or Value Objects**: Always instantiate real domain entities and value objects in unit tests.
2. **Mock by Interface/Port**: Application tests must mock the interface contracts (`IUserRepository`), never the concrete infrastructure class (`TypeOrmUserRepository`).
3. **Test State Mutations**: Domain unit tests must assert both the returned value and internal entity state changes (e.g., `user.isActive` becomes `false` on `user.deactivate()`).

---

## 9. Dependency Injection & Composition

NestJS modules serve solely as the composition root for wiring ports to adapters.

### 9.1 Custom Provider Rules
1. **Symbol Tokens**: Every port **MUST** have a corresponding `Symbol` in `src/shared/constants/injection-tokens.ts`.
2. **Explicit Binding**: Bounded context modules (`*.module.ts`) bind the port symbol to the infrastructure adapter:

```typescript
// src/users/interfaces/modules/users.module.ts
@Module({
  imports: [TypeOrmModule.forFeature([UserOrmEntity])],
  controllers: [UsersController],
  providers: [
    CreateUserUseCase,
    GetUserByIdUseCase,
    {
      provide: USER_REPOSITORY,
      useClass: TypeOrmUserRepository,
    },
  ],
  exports: [USER_REPOSITORY], // Export token symbol if needed by other modules
})
export class UsersModule {}
```

3. **Port Injection**: Always use `@Inject(PORT_SYMBOL)` in Use Case constructors:
```typescript
constructor(
  @Inject(USER_REPOSITORY) private readonly userRepo: IUserRepository,
) {}
```

### 9.2 Anti-Patterns
- ❌ **Direct Adapter Injection**: `constructor(private readonly repo: TypeOrmUserRepository)` leaks infrastructure into application code.
- ❌ **String Tokens**: `provide: 'USER_REPOSITORY'` is prone to collision and typo bugs. Always use `Symbol`.
- ❌ **Injecting Repositories into Controllers**: Controllers must only receive Use Cases.
