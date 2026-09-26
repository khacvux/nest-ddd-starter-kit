import { ConflictError } from '../../../shared/errors/domain-error';

export class UserAlreadyExistsError extends ConflictError {
  constructor(email: string) {
    super(`User with email '${email}' already exists`);
  }
}
