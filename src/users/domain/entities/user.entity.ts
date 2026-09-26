import { BaseEntity } from '../../../shared/domain/base.entity';
import { Email } from '../value-objects/email.vo';
import { UserRole } from '../value-objects/user-role.vo';
import { ValidationError } from '../../../shared/errors/domain-error';

export interface UserProps {
  id: string;
  email: Email;
  name: string;
  role: UserRole;
  isActive: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export class UserEntity extends BaseEntity {
  private _email: Email;
  private _name: string;
  private _role: UserRole;
  private _isActive: boolean;

  private constructor(props: UserProps) {
    super(props.id, props.createdAt, props.updatedAt);
    this._email = props.email;
    this._name = props.name;
    this._role = props.role;
    this._isActive = props.isActive;
  }

  public static create(props: { id: string; email: Email; name: string; role?: UserRole }): UserEntity {
    if (!props.name || props.name.trim().length === 0) {
      throw new ValidationError('User name cannot be empty');
    }

    return new UserEntity({
      id: props.id,
      email: props.email,
      name: props.name.trim(),
      role: props.role ?? UserRole.USER,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  public static restore(props: UserProps): UserEntity {
    return new UserEntity(props);
  }

  public get email(): Email {
    return this._email;
  }

  public get name(): string {
    return this._name;
  }

  public get role(): UserRole {
    return this._role;
  }

  public get isActive(): boolean {
    return this._isActive;
  }

  public updateName(name: string): void {
    if (!name || name.trim().length === 0) {
      throw new ValidationError('User name cannot be empty');
    }
    this._name = name.trim();
    this.touch();
  }

  public deactivate(): void {
    if (!this._isActive) {
      return;
    }
    this._isActive = false;
    this.touch();
  }

  public activate(): void {
    if (this._isActive) {
      return;
    }
    this._isActive = true;
    this.touch();
  }
}
