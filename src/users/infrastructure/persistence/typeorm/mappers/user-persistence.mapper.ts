import { UserEntity } from '../../../../domain/entities/user.entity';
import { Email } from '../../../../domain/value-objects/email.vo';
import { UserRole } from '../../../../domain/value-objects/user-role.vo';
import { UserOrmEntity } from '../entities/user.orm-entity';

export class UserPersistenceMapper {
  static toDomain(orm: UserOrmEntity): UserEntity {
    return UserEntity.restore({
      id: orm.id,
      email: Email.create(orm.email),
      name: orm.name,
      role: orm.role as UserRole,
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
    orm.role = domain.role;
    orm.isActive = domain.isActive;
    orm.createdAt = domain.createdAt;
    orm.updatedAt = domain.updatedAt;
    return orm;
  }
}
