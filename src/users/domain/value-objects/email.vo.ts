import { ValidationError } from '../../../shared/errors/domain-error';

export class Email {
  private static readonly EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  private constructor(private readonly _value: string) {}

  public get value(): string {
    return this._value;
  }

  public static create(email: string): Email {
    if (!email) {
      throw new ValidationError('Email cannot be empty');
    }
    const normalized = email.trim().toLowerCase();
    if (!this.EMAIL_REGEX.test(normalized)) {
      throw new ValidationError(`Invalid email address format: '${email}'`);
    }
    return new Email(normalized);
  }

  public equals(other?: Email | null): boolean {
    if (!other) return false;
    return this._value === other._value;
  }

  public toString(): string {
    return this._value;
  }
}
