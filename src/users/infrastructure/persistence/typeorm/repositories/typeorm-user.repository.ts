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
    const orm = await this.repo.findOneBy({ id });
    return orm ? UserPersistenceMapper.toDomain(orm) : null;
  }

  async findByEmail(email: Email): Promise<UserEntity | null> {
    const orm = await this.repo.findOneBy({ email: email.value });
    return orm ? UserPersistenceMapper.toDomain(orm) : null;
  }

  async save(user: UserEntity): Promise<void> {
    const orm = UserPersistenceMapper.toOrm(user);
    await this.repo.save(orm);
  }

  async delete(id: string): Promise<void> {
    await this.repo.delete(id);
  }
}
