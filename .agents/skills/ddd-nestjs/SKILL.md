---
name: ddd-nestjs
description: Comprehensive instructions and code templates for adding new features using the project's Domain-Driven Design (DDD) architecture in NestJS.
---

# DDD Feature Implementation Guide

When adding a new feature or bounded context to this codebase, follow this systematic workflow strictly in order.

## Implementation Workflow

```
1. Domain Layer     -> Value Objects -> Entities -> Repository Ports -> Errors -> Events
2. Application Layer-> Request/Response DTOs -> Mappers -> Use Cases (Commands/Queries)
3. Infrastructure   -> ORM Entities -> Persistence Mappers -> Repository Adapters
4. Interfaces       -> HTTP Request/Response DTOs -> Controllers -> Feature Module
5. Tests            -> Unit Tests (Entity, Use Case) -> E2E Tests
```

---

## Step 1: Domain Layer (Pure TypeScript)

### 1.1 Value Object
Value Objects are immutable and define their own validation rules.

```typescript
// src/<domain>/domain/value-objects/email.vo.ts
import { DomainError } from '../../../shared/errors/domain-error';

export class InvalidEmailError extends DomainError {
  constructor(email: string) {
    super(`Invalid email address: ${email}`, 'INVALID_EMAIL');
  }
}

export class Email {
  private static readonly EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  private constructor(private readonly _value: string) {}

  public get value(): string {
    return this._value;
  }

  public static create(email: string): Email {
    const trimmed = email ? email.trim().toLowerCase() : '';
    if (!this.EMAIL_REGEX.test(trimmed)) {
      throw new InvalidEmailError(email);
    }
    return new Email(trimmed);
  }

  public equals(other: Email): boolean {
    return other !== null && other !== undefined && this._value === other._value;
  }
}
```

### 1.2 Domain Entity
Entities have identity and enforce business invariants.

```typescript
// src/<domain>/domain/entities/user.entity.ts
import { BaseEntity } from '../../../shared/domain/base.entity';
import { Email } from '../value-objects/email.vo';

export interface UserProps {
  id: string;
  email: Email;
  name: string;
  isActive: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export class UserEntity extends BaseEntity {
  private _email: Email;
  private _name: string;
  private _isActive: boolean;

  private constructor(props: UserProps) {
    super(props.id, props.createdAt, props.updatedAt);
    this._email = props.email;
    this._name = props.name;
    this._isActive = props.isActive;
  }

  public static create(props: Omit<UserProps, 'createdAt' | 'updatedAt'>): UserEntity {
    return new UserEntity({
      ...props,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static restore(props: UserProps): UserEntity {
    return new UserEntity(props);
  }

  public get email(): Email { return this._email; }
  public get name(): string { return this._name; }
  public get isActive(): boolean { return this._isActive; }

  public updateName(name: string): void {
    if (!name || name.trim().length === 0) {
      throw new Error('Name cannot be empty');
    }
    this._name = name.trim();
    this.touch();
  }

  public deactivate(): void {
    this._isActive = false;
    this.touch();
  }
}
```

### 1.3 Repository Port (Interface)
Defines contract without implementation details.

```typescript
// src/<domain>/domain/repositories/user-repository.interface.ts
import { UserEntity } from '../entities/user.entity';
import { Email } from '../value-objects/email.vo';

export interface IUserRepository {
  findById(id: string): Promise<UserEntity | null>;
  findByEmail(email: Email): Promise<UserEntity | null>;
  save(user: UserEntity): Promise<void>;
  delete(id: string): Promise<void>;
}
```

---

## Step 2: Application Layer (Use Cases & DTOs)

### 2.1 Use Case
Injects domain repository port via injection token.

```typescript
// src/<domain>/application/use-cases/create-user.use-case.ts
import { Injectable, Inject } from '@nestjs/common';
import { USER_REPOSITORY } from '../../../shared/constants/injection-tokens';
import { IUserRepository } from '../../domain/repositories/user-repository.interface';
import { Email } from '../../domain/value-objects/email.vo';
import { UserEntity } from '../../domain/entities/user.entity';
import { UserAlreadyExistsError } from '../../domain/errors/user-already-exists.error';
import { CreateUserInputDto, UserResponseDto } from '../dtos/user.dto';
import { UserMapper } from '../mappers/user.mapper';
import { randomUUID } from 'crypto';

@Injectable()
export class CreateUserUseCase {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: IUserRepository,
  ) {}

  async execute(dto: CreateUserInputDto): Promise<UserResponseDto> {
    const emailVo = Email.create(dto.email);
    const existing = await this.userRepository.findByEmail(emailVo);
    if (existing) {
      throw new UserAlreadyExistsError(dto.email);
    }

    const user = UserEntity.create({
      id: randomUUID(),
      email: emailVo,
      name: dto.name,
      isActive: true,
    });

    await this.userRepository.save(user);
    return UserMapper.toResponse(user);
  }
}
```

---

## Step 3: Infrastructure Layer (TypeORM & Adapters)

### 3.1 ORM Entity
Contains database annotations. Suffix with `.orm-entity.ts`.

```typescript
// src/<domain>/infrastructure/persistence/typeorm/entities/user.orm-entity.ts
import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class UserOrmEntity {
  @PrimaryColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  name: string;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
```

### 3.2 Persistence Mapper
Maps bidirectionally between ORM and Domain entities.

```typescript
// src/<domain>/infrastructure/persistence/typeorm/mappers/user-persistence.mapper.ts
import { UserEntity } from '../../../../domain/entities/user.entity';
import { Email } from '../../../../domain/value-objects/email.vo';
import { UserOrmEntity } from '../entities/user.orm-entity';

export class UserPersistenceMapper {
  static toDomain(orm: UserOrmEntity): UserEntity {
    return UserEntity.restore({
      id: orm.id,
      email: Email.create(orm.email),
      name: orm.name,
      isActive: orm.isActive,
      createdAt: orm.createdAt,
      updatedAt: orm.updatedAt,
    });
  }

  static toOrm(domain: UserEntity): UserOrmEntity {
    const orm = new UserOrmEntity();
    orm.id = domain.id;
    orm.email = domain.email.value;
    orm.name = domain.name;
    orm.isActive = domain.isActive;
    orm.createdAt = domain.createdAt;
    orm.updatedAt = domain.updatedAt;
    return orm;
  }
}
```

### 3.3 Repository Adapter
Implements `IUserRepository` using TypeORM.

```typescript
// src/<domain>/infrastructure/persistence/typeorm/repositories/typeorm-user.repository.ts
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IUserRepository } from '../../../../domain/repositories/user-repository.interface';
import { UserEntity } from '../../../../domain/entities/user.entity';
import { Email } from '../../../../domain/value-objects/email.vo';
import { UserOrmEntity } from '../entities/user.orm-entity';
import { UserPersistenceMapper } from '../mappers/user-persistence.mapper';

@Injectable()
export class TypeOrmUserRepository implements IUserRepository {
  constructor(
    @InjectRepository(UserOrmEntity)
    private readonly repo: Repository<UserOrmEntity>,
  ) {}

  async findById(id: string): Promise<UserEntity | null> {
    const entity = await this.repo.findOneBy({ id });
    return entity ? UserPersistenceMapper.toDomain(entity) : null;
  }

  async findByEmail(email: Email): Promise<UserEntity | null> {
    const entity = await this.repo.findOneBy({ email: email.value });
    return entity ? UserPersistenceMapper.toDomain(entity) : null;
  }

  async save(user: UserEntity): Promise<void> {
    const ormEntity = UserPersistenceMapper.toOrm(user);
    await this.repo.save(ormEntity);
  }

  async delete(id: string): Promise<void> {
    await this.repo.delete(id);
  }
}
```

---

## Step 4: Interfaces Layer (Controllers & Module)

### 4.1 Controller
Handles HTTP requests, parameter extraction, and delegates directly to Use Cases.

```typescript
// src/<domain>/interfaces/http/controllers/users.controller.ts
import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { CreateUserUseCase } from '../../../application/use-cases/create-user.use-case';
import { CreateUserRequestDto } from '../dtos/create-user.request.dto';
import { UserResponseDto } from '../../../application/dtos/user.dto';

@ApiTags('Users')
@Controller('users')
export class UsersController {
  constructor(private readonly createUserUseCase: CreateUserUseCase) {}

  @Post()
  @ApiOperation({ summary: 'Register a new user' })
  @ApiResponse({ status: 201, type: UserResponseDto })
  async create(@Body() body: CreateUserRequestDto): Promise<UserResponseDto> {
    return this.createUserUseCase.execute(body);
  }
}
```

### 4.2 Module Wiring
Binds use cases, controllers, and repository tokens.

```typescript
// src/<domain>/interfaces/modules/users.module.ts
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { USER_REPOSITORY } from '../../../shared/constants/injection-tokens';
import { UserOrmEntity } from '../../infrastructure/persistence/typeorm/entities/user.orm-entity';
import { TypeOrmUserRepository } from '../../infrastructure/persistence/typeorm/repositories/typeorm-user.repository';
import { CreateUserUseCase } from '../../application/use-cases/create-user.use-case';
import { UsersController } from '../http/controllers/users.controller';

@Module({
  imports: [TypeOrmModule.forFeature([UserOrmEntity])],
  controllers: [UsersController],
  providers: [
    CreateUserUseCase,
    {
      provide: USER_REPOSITORY,
      useClass: TypeOrmUserRepository,
    },
  ],
  exports: [USER_REPOSITORY],
})
export class UsersModule {}
```
