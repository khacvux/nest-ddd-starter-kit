import { EntityNotFoundError } from '../../../shared/errors/domain-error';

export class UserNotFoundError extends EntityNotFoundError {
  constructor(idOrEmail: string) {
    super('User', idOrEmail);
  }
}
