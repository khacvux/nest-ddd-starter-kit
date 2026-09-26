/**
 * Dependency Injection Tokens (Symbols)
 *
 * Always use these tokens to inject domain repository ports and external
 * service abstractions into Application Use Cases.
 */
export const USER_REPOSITORY = Symbol('USER_REPOSITORY');
export const UNIT_OF_WORK = Symbol('UNIT_OF_WORK');
export const EVENT_BUS = Symbol('EVENT_BUS');
