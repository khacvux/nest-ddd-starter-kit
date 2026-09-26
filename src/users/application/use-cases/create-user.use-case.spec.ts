import { CreateUserUseCase } from './create-user.use-case';
import { IUserRepository } from '../../domain/repositories/user-repository.interface';
import { UserAlreadyExistsError } from '../../domain/errors/user-already-exists.error';
import { Email } from '../../domain/value-objects/email.vo';
import { UserEntity } from '../../domain/entities/user.entity';

describe('CreateUserUseCase', () => {
  let useCase: CreateUserUseCase;
  let mockUserRepository: jest.Mocked<IUserRepository>;

  beforeEach(() => {
    mockUserRepository = {
      findById: jest.fn(),
      findByEmail: jest.fn(),
      save: jest.fn(),
      delete: jest.fn(),
    };

    useCase = new CreateUserUseCase(mockUserRepository);
  });

  it('should create and save a new user successfully', () => {
    mockUserRepository.findByEmail.mockResolvedValue(null);
    mockUserRepository.save.mockResolvedValue();

    return useCase
      .execute({
        email: 'newuser@example.com',
        name: 'New User',
        role: 'USER',
      })
      .then((result) => {
        expect(result.email).toBe('newuser@example.com');
        expect(result.name).toBe('New User');
        expect(result.isActive).toBe(true);
        expect(mockUserRepository.save).toHaveBeenCalledTimes(1);
      });
  });

  it('should throw UserAlreadyExistsError when email is already taken', async () => {
    const existing = UserEntity.create({
      id: 'existing-id',
      email: Email.create('existing@example.com'),
      name: 'Existing',
    });
    mockUserRepository.findByEmail.mockResolvedValue(existing);

    await expect(
      useCase.execute({
        email: 'existing@example.com',
        name: 'Another User',
      }),
    ).rejects.toThrow(UserAlreadyExistsError);

    expect(mockUserRepository.save).not.toHaveBeenCalled();
  });
});
