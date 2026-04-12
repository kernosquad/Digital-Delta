import { defineConfig } from '@adonisjs/auth';
import { sessionGuard, sessionUserProvider } from '@adonisjs/auth/session';

import { JwtGuard } from '../app/auth/guards/jwt_guard.js';
import { LucidJwtUserProvider } from '../app/auth/guards/jwt_user_provider.js';

import type User from '../app/models/user.js';
import type { InferAuthenticators, InferAuthEvents, Authenticators } from '@adonisjs/auth/types';

import env from '#start/env';

const jwtConfig = {
  secret: env.get('APP_KEY'),
};
const userProvider = new LucidJwtUserProvider();

const authConfig = defineConfig({
  default: 'web',
  guards: {
    web: sessionGuard({
      useRememberMeTokens: false,
      provider: sessionUserProvider({
        model: () => import('#models/user'),
      }),
    }),
    jwt: (ctx): JwtGuard<LucidJwtUserProvider, User> => {
      return new JwtGuard(ctx, userProvider, jwtConfig);
    },
  },
});

export default authConfig;

/**
 * Inferring types from the configured auth
 * guards.
 */
declare module '@adonisjs/auth/types' {
  export interface Authenticators extends InferAuthenticators<typeof authConfig> {}
}
declare module '@adonisjs/core/types' {
  interface EventsList extends InferAuthEvents<Authenticators> {}
}
