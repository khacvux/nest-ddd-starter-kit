import { Email } from './email.vo';
import { ValidationError } from '../../../shared/errors/domain-error';

describe('Email Value Object', () => {
  it('should create a valid email instance and normalize to lowercase', () => {
    const email = Email.create('Test.User@Example.COM');
    expect(email.value).toBe('test.user@example.com');
  });

  it('should throw ValidationError for invalid email addresses', () => {
    expect(() => Email.create('')).toThrow(ValidationError);
    expect(() => Email.create('invalid-email')).toThrow(ValidationError);
    expect(() => Email.create('@missing-local.com')).toThrow(ValidationError);
  });

  it('should compare equality correctly', () => {
    const email1 = Email.create('user@domain.com');
    const email2 = Email.create('user@domain.com');
    const email3 = Email.create('other@domain.com');

    expect(email1.equals(email2)).toBe(true);
    expect(email1.equals(email3)).toBe(false);
  });
});
