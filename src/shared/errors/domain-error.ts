/**
 * Base class for all Domain and Application Errors.
 *
 * Automatically captured and translated to appropriate HTTP status codes
 * by the DomainExceptionFilter.
 */
export class DomainError extends Error {
  public readonly code: string;

  constructor(message: string, code = 'DOMAIN_ERROR') {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class EntityNotFoundError extends DomainError {
  constructor(entityName: string, identifier: string | number) {
    super(`${entityName} with identifier '${identifier}' was not found`, 'ENTITY_NOT_FOUND');
  }
}

export class ConflictError extends DomainError {
  constructor(message: string) {
    super(message, 'CONFLICT_ERROR');
  }
}

export class ValidationError extends DomainError {
  constructor(message: string) {
    super(message, 'VALIDATION_ERROR');
  }
}

export class UnauthorizedDomainError extends DomainError {
  constructor(message = 'Unauthorized action') {
    super(message, 'UNAUTHORIZED_DOMAIN_ERROR');
  }
}
