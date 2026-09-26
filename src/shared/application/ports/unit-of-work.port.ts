/**
 * Unit of Work Port
 *
 * Provides transaction boundaries in Application Use Cases without leaking
 * infrastructure-specific details (TypeORM, Prisma, etc.).
 */
export interface IUnitOfWork {
  execute<T>(work: () => Promise<T>): Promise<T>;
}
