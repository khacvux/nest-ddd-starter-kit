import { Injectable, Inject } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { USER_REPOSITORY } from '../../../shared/constants/injection-tokens';
import { IUserRepository } from '../../domain/repositories/user-repository.interface';
import { Email } from '../../domain/value-objects/email.vo';
import { UserRole } from '../../domain/value-objects/user-role.vo';
import { UserEntity } from '../../domain/entities/user.entity';
import { UserAlreadyExistsError } from '../../domain/errors/user-already-exists.error';
import { CreateUserInputDto } from '../dtos/create-user.dto';
import { UserResponseDto } from '../dtos/user-response.dto';
import { UserMapper } from '../mappers/user.mapper';

@Injectable()
export class CreateUserUseCase {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: IUserRepository,
  ) {}

  async execute(input: CreateUserInputDto): Promise<UserResponseDto> {
    const emailVo = Email.create(input.email);

    const existingUser = await this.userRepository.findByEmail(emailVo);
    if (existingUser) {
      throw new UserAlreadyExistsError(input.email);
    }

    const role = input.role === 'ADMIN' ? UserRole.ADMIN : UserRole.USER;

    const user = UserEntity.create({
      id: randomUUID(),
      email: emailVo,
      name: input.name,
      role,
    });

    await this.userRepository.save(user);

    return UserMapper.toResponse(user);
  }
}
