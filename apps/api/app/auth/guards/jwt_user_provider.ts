import { symbols } from '@adonisjs/auth';

import type { JwtGuardUser, JwtUserProviderContract } from './jwt.js';

import User from '#models/user';

class JwtUserAdapter implements JwtGuardUser<User> {
  constructor(private user: User) {}

  getId(): string | number | bigint {
    return this.user.id;
  }

  getOriginal(): User {
    return this.user;
  }
}

export class LucidJwtUserProvider implements JwtUserProviderContract<User> {
  declare [symbols.PROVIDER_REAL_USER]: User;

  async createUserForGuard(user: User): Promise<JwtGuardUser<User>> {
    return new JwtUserAdapter(user);
  }

  async findById(identifier: string | number | bigint): Promise<JwtGuardUser<User> | null> {
    const user = await User.find(Number(identifier));
    if (!user) return null;
    return new JwtUserAdapter(user);
  }
}
