import type { UserRole } from '#models/user';
import type { HttpContext } from '@adonisjs/core/http';
import type { NextFn } from '@adonisjs/core/types/http';

/**
 * Role-Based Access Control middleware (M1.3).
 *
 * Usage in routes.ts:
 *   .use(middleware.role(['sync_admin', 'supply_manager']))
 *
 * The auth middleware must run BEFORE this middleware (it populates ctx.auth.user).
 * If no roles are provided, any authenticated user is allowed through.
 */
export default class RoleMiddleware {
  async handle(ctx: HttpContext, next: NextFn, options: { roles?: UserRole[] } = {}) {
    const user = ctx.auth.user;

    // Auth middleware guarantees user is set — this is a safety fallback
    if (!user) {
      return ctx.response.unauthorized({ error: 'Unauthenticated' });
    }

    // Soft-deleted or suspended users are rejected
    if (user.status !== 'active') {
      return ctx.response.forbidden({ error: 'Account is not active' });
    }

    // If no role restriction, pass through
    if (!options.roles || options.roles.length === 0) {
      return next();
    }

    if (!options.roles.includes(user.role as UserRole)) {
      return ctx.response.forbidden({
        error: 'Insufficient permissions',
        required: options.roles,
        current: user.role,
      });
    }

    return next();
  }
}
