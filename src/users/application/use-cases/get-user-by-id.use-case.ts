import { Injectable, Inject } from '@nestjs/common';
import { USER_REPOSITORY } from '../../../shared/constants/injection-tokens';
import { IUserRepository } from '../../domain/repositories/user-repository.interface';
import { UserNotFoundError } from '../../domain/errors/user-not-found.error';
import { UserResponseDto } from '../dtos/user-response.dto';
import { UserMapper } from '../mappers/user.mapper';

@Injectable()
export class GetUserByIdUseCase {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: IUserRepository,
  ) {}

  async execute(id: string): Promise<UserResponseDto> {
    const user = await this.userRepository.findById(id);
    if (!user) {
      throw new UserNotFoundError(id);
    }
    return UserMapper.toResponse(user);
  }
}
