import { IDomainEvent } from '../../../shared/domain/domain-event.interface';

export class UserCreatedEvent implements IDomainEvent {
  public readonly eventName = 'UserCreated';
  public readonly occurredOn = new Date();

  constructor(
    public readonly aggregateId: string,
    public readonly email: string,
    public readonly name: string,
  ) {}
}
