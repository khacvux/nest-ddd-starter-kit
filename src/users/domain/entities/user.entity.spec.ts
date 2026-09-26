import { UserEntity } from './user.entity';
import { Email } from '../value-objects/email.vo';
import { UserRole } from '../value-objects/user-role.vo';
import { ValidationError } from '../../../shared/errors/domain-error';

describe('UserEntity Domain Entity', () => {
  const validEmail = Email.create('alex@example.com');

  it('should create a new user entity with valid properties', () => {
    const user = UserEntity.create({
      id: 'uuid-123',
      email: validEmail,
      name: 'Alex Developer',
      role: UserRole.USER,
    });

    expect(user.id).toBe('uuid-123');
    expect(user.email.value).toBe('alex@example.com');
    expect(user.name).toBe('Alex Developer');
    expect(user.role).toBe(UserRole.USER);
    expect(user.isActive).toBe(true);
    expect(user.createdAt).toBeInstanceOf(Date);
  });

  it('should throw ValidationError if name is empty', () => {
    expect(() =>
      UserEntity.create({
        id: 'uuid-123',
        email: validEmail,
        name: '   ',
      }),
    ).toThrow(ValidationError);
  });

  it('should update user name and update updatedAt timestamp', () => {
    const user = UserEntity.create({
      id: 'uuid-123',
      email: validEmail,
      name: 'Old Name',
    });

    user.updateName('New Name');
    expect(user.name).toBe('New Name');
  });

  it('should deactivate and activate user correctly', () => {
    const user = UserEntity.create({
      id: 'uuid-123',
      email: validEmail,
      name: 'Alex',
    });

    user.deactivate();
    expect(user.isActive).toBe(false);

    user.activate();
    expect(user.isActive).toBe(true);
  });
});
