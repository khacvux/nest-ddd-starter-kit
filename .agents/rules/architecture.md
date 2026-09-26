# Architecture Rules

This project adheres to a Strict Domain-Driven Design (DDD) Hexagonal Architecture.

## 1. Dependency Rule
Dependencies must point **inward** toward the Domain layer within each bounded context:

- `src/<domain>/domain`: **PURE TypeScript**. **MUST NOT** import from `@nestjs/*`, TypeORM, application, infrastructure, or interfaces. Zero framework dependencies.
- `src/<domain>/application`: **Orchestration**. **MUST NOT** import from infrastructure or interfaces. May import from `domain` and `@nestjs/common` (for `@Injectable()`, `@Inject()`).
- `src/<domain>/infrastructure`: **Implementation & Adapters**. Fulfills ports. May import from `domain`, `application`, TypeORM, and third-party libraries.
- `src/<domain>/interfaces`: **Delivery (HTTP/CLI/Events)**. May import from `application` and `domain`. **MUST NOT** import from `infrastructure` directly, except in module wiring (`*.module.ts`).
- `src/shared`: Cross-cutting concerns, base classes (`BaseEntity`, `ValueObject`, `DomainError`), DI tokens, and global filters/infrastructure.

---

## 2. Naming Conventions

| Component | File Extension | Example |
| :--- | :--- | :--- |
| **Domain Entity** | `.entity.ts` | `user.entity.ts` |
| **Value Object** | `.vo.ts` | `email.vo.ts` |
| **Repository Port** | `-repository.interface.ts` | `user-repository.interface.ts` |
| **Domain Error / Event** | `.error.ts` / `.event.ts` | `user-not-found.error.ts` |
| **Use Case / DTO / Mapper** | `.use-case.ts` / `.dto.ts` / `.mapper.ts` | `create-user.use-case.ts` |
| **ORM Entity** | `.orm-entity.ts` | `user.orm-entity.ts` *(NEVER .entity.ts)* |
| **Repository Adapter** | `.repository.ts` | `typeorm-user.repository.ts` |
| **Controller / Request DTO**| `.controller.ts` / `.request.dto.ts` | `users.controller.ts` |
| **NestJS Module** | `.module.ts` | `users.module.ts` |

---

## 3. Layer Specific Rules

### Domain
- Encapsulate state with private fields; expose getters or readonly properties.
- State mutation occurs strictly via expressive methods (e.g. `user.changePassword()`, never raw setters).
- Invariants are enforced in factory methods (`create`, `restore`) and Value Objects.
- Repositories are expressed strictly as interfaces (`IUserRepository`).

### Application
- Use Cases represent a single business command/query with an `execute()` method.
- Inject repository ports via `@Inject(TOKEN)` using Symbol tokens from `src/shared/constants/injection-tokens.ts`.
- Orchestration pattern: load aggregate -> invoke domain method -> persist aggregate -> publish events / return DTO.

### Infrastructure
- Database entities MUST be named `*.orm-entity.ts` and reside in `infrastructure/persistence/<driver>/entities/`.
- Database schemas must not leak into the domain. Use `*.mapper.ts` to map between ORM and Domain entities.
- Adapters implement repository ports defined in the domain layer.

### Interfaces
- Controllers handle HTTP delivery: deserialize request, validate DTOs, execute Use Cases, return HTTP response.
- Controllers **MUST NOT** communicate directly with Repositories.
- Controllers **MUST NOT** contain business logic. Annotate with Swagger decorators (`@ApiOperation`, `@ApiResponse`).

---

## 4. Error Handling
- Throw domain errors (extending `DomainError`) from Domain and Application layers.
- The global `DomainExceptionFilter` catches all `DomainError` subclasses and maps them to HTTP status codes.

---

## 5. CQRS & Event Handling

### 5.1 Command vs. Query Segregation
| Concern | Commands (Write) | Queries (Read) |
| :--- | :--- | :--- |
| **Intent** | Mutate state, trigger domain logic | Retrieve data without side effects |
| **Domain Usage** | **MANDATORY**. Loads Aggregate Root | **OPTIONAL**. May bypass Domain layer |
| **Data Source** | Domain Repository Port (`IUserRepository`) | Read Model Port or database projections / raw SQL |
| **Return Value** | Minimal (ID, Command DTO, or `void`) | Tailored Read DTOs (optimized for client) |
| **Transaction** | Wrapped in Unit of Work / Transaction | Read-only / Non-transactional |

- Queries **MUST NOT** load heavy Aggregates merely to return data. Project directly to Read DTOs.
- Queries **MUST NEVER** produce side-effects or alter database state.

### 5.2 Domain Events vs. Integration Events
| Attribute | Domain Events | Integration Events |
| :--- | :--- | :--- |
| **Scope** | Internal to bounded context | Across bounded contexts / external systems |
| **Transport** | In-memory bus (e.g. `EventEmitter2`) | Message broker (RabbitMQ, Kafka) |
| **Location** | `domain/events/` (Pure TypeScript) | `shared/contracts/` (Integration DTOs) |
| **Dispatch** | Synchronous or in-process | **Transactional Outbox Pattern** |

- Domain Events **MUST NOT** reference external message broker SDKs.
- **Transactional Outbox**: Save events to an `outbox` table in the same DB transaction. A worker relays them to the broker. **NEVER** publish directly to a message broker inside an active database transaction.

---

## 6. Transaction Management & Unit of Work (UoW)

Database transactions are implementation details that **MUST NOT** leak into Domain Entities or Application Use Cases.

### 6.1 UoW Port Contract
```typescript
// src/shared/application/ports/unit-of-work.port.ts
export interface IUnitOfWork {
  execute<T>(work: () => Promise<T>): Promise<T>;
}
```

### 6.2 Transaction Rules
1. **Transaction Boundary**: Defined in the **Application Use Case**, never in Controllers or Domain Entities.
2. **No Direct ORM Imports**: Use Cases **MUST NOT** import TypeORM `QueryRunner`, `DataSource`, or `EntityManager`.
3. **Usage Pattern**: Inject `IUnitOfWork` via `@Inject(UNIT_OF_WORK)`:
```typescript
@Injectable()
export class RegisterUserUseCase {
  constructor(
    @Inject(UNIT_OF_WORK) private readonly uow: IUnitOfWork,
    @Inject(USER_REPOSITORY) private readonly userRepo: IUserRepository,
  ) {}

  async execute(dto: RegisterUserDto): Promise<void> {
    await this.uow.execute(async () => {
      await this.userRepo.save(user);
    });
  }
}
```

---

## 7. Validation Strategy

| Tier | Layer | Mechanism | Responsibility | Error / HTTP Status |
| :--- | :--- | :--- | :--- | :--- |
| **1. Syntactic** | Interfaces (HTTP) | `class-validator` on DTOs | Shape, types, required fields, basic regex | `BadRequestException` (400) |
| **2. Semantic** | Domain | Value Objects & Entity invariants | Domain rules (e.g. age limits, valid email) | `ValidationError` (422) |
| **3. Contextual** | Application | Use Case + Repository Port | Uniqueness, foreign keys, existence | `ConflictError` (409) / `EntityNotFoundError` (404) |

- **Self-Protecting Domain**: Never rely solely on DTO validation; Value Objects and Entities must reject invalid states.
- **DTOs validate shape, not domain rules**: DTO ensures input is a string; Value Object ensures valid domain invariant.

---

## 8. Testing Strategy

### 8.1 Testing Matrix
| Layer | Test Type | File Extension | Mocking Boundary | Assertions |
| :--- | :--- | :--- | :--- | :--- |
| **Domain** | Unit | `*.spec.ts` | **ZERO MOCKS**. Pure TypeScript. | Invariants, factory methods, state mutations, errors. |
| **Application** | Unit | `*.spec.ts` | Mock Ports (`IUserRepository`, `IUnitOfWork`). | Orchestration flow, port calls, error propagation. |
| **Infrastructure** | Integration | `*.integration-spec.ts`| Test DB (Testcontainers/in-memory). | Queries, mappings, schema constraints, rollbacks. |
| **Interfaces** | E2E | `*.e2e-spec.ts` | `supertest`. Mock external services only. | HTTP status, validation pipes, filters, routing. |

### 8.2 Mocking Rules
1. **Never mock Domain Entities or Value Objects**: Instantiate real domain models in tests.
2. **Mock by Interface/Port**: Mock `IUserRepository`, never concrete classes (`TypeOrmUserRepository`).
3. **Assert State Mutations**: Always verify entity state changes alongside return values.

---

## 9. Dependency Injection & Composition

NestJS modules act solely as the composition root wiring ports to adapters.

### 9.1 Rules
1. **Symbol Tokens**: Every port has a Symbol in `src/shared/constants/injection-tokens.ts`.
2. **Module Binding**: Modules bind ports to adapters using custom providers:
```typescript
@Module({
  imports: [TypeOrmModule.forFeature([UserOrmEntity])],
  controllers: [UsersController],
  providers: [
    CreateUserUseCase,
    { provide: USER_REPOSITORY, useClass: TypeOrmUserRepository },
  ],
  exports: [USER_REPOSITORY],
})
export class UsersModule {}
```
3. **Port Injection**: Always use `@Inject(PORT_SYMBOL)` in Use Cases:
```typescript
constructor(@Inject(USER_REPOSITORY) private readonly userRepo: IUserRepository) {}
```

### 9.2 Anti-Patterns
- ❌ **Direct Adapter Injection**: `constructor(private readonly repo: TypeOrmUserRepository)` leaks infrastructure.
- ❌ **String Tokens**: Use `Symbol` tokens to prevent collisions.
- ❌ **Injecting Repositories into Controllers**: Controllers must only invoke Use Cases.
