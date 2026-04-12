import { createHash } from 'node:crypto'

import { DateTime } from 'luxon'

import type { HttpContext } from '@adonisjs/core/http'

import AuthLog from '#models/auth_log'
import User from '#models/user'

import type { WebLoginType } from './web_auth.validator.js'

// ── Shared audit helper (same chain as mobile auth) ──────────────────────────
type AuthEventType = AuthLog['eventType']

async function appendAuditLog(
  eventType: AuthEventType,
  opts: {
    userId?: number
    deviceId?: string
    ipAddress?: string
    payload?: Record<string, unknown>
  } = {}
) {
  const last = await AuthLog.query().orderBy('id', 'desc').first()
  const previousHash = last?.eventHash ?? '0'.repeat(64)

  const eventData = {
    eventType,
    userId: opts.userId ?? null,
    deviceId: opts.deviceId ?? null,
    ipAddress: opts.ipAddress ?? null,
    payload: opts.payload ?? null,
    previousHash,
    createdAt: DateTime.now(),
  }

  const eventHash = createHash('sha256').update(JSON.stringify(eventData)).digest('hex')
  await AuthLog.create({ ...eventData, eventHash })
}

// ── Service ───────────────────────────────────────────────────────────────────

export class WebAuthService {
  /**
   * POST /api/web/auth/login
   *
   * Session-based login for the admin web dashboard.
   * Issues a server-side session cookie (adonis-session) — no JWT token returned.
   * Only roles that can manage the system (camp_commander, supply_manager, sync_admin)
   * are permitted to log in via the web dashboard.
   */
  async login(ctx: HttpContext, payload: WebLoginType) {
    const { request, response, auth } = ctx

    const WEB_ALLOWED_ROLES = ['camp_commander', 'supply_manager', 'sync_admin', 'drone_operator']

    let user: User
    try {
      user = await User.verifyCredentials(payload.email, payload.password)
    } catch {
      await appendAuditLog('login_fail', {
        ipAddress: request.ip(),
        payload: { email: payload.email, source: 'web' },
      })
      return response.status(401).sendError('Invalid email or password')
    }

    if (user.status !== 'active') {
      return response.status(403).sendError('Account is suspended or inactive')
    }

    if (!WEB_ALLOWED_ROLES.includes(user.role)) {
      return response.status(403).sendError('Field volunteers cannot access the web dashboard')
    }

    // Create server-side session
    await auth.use('web').login(user)
    await user.merge({ lastSeenAt: DateTime.now() }).save()

    await appendAuditLog('login_success', {
      userId: user.id,
      ipAddress: request.ip(),
      payload: { email: user.email, source: 'web' },
    })

    return response.sendFormatted(
      {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          status: user.status,
        },
      },
      'Logged in successfully'
    )
  }

  /**
   * POST /api/web/auth/logout
   * Destroys the server session and clears the session cookie.
   */
  async logout(ctx: HttpContext) {
    const { response, auth } = ctx
    const user = auth.use('web').user!

    await appendAuditLog('logout', {
      userId: user.id,
      payload: { source: 'web' },
    })

    await auth.use('web').logout()
    return response.sendFormatted(null, 'Logged out')
  }

  /**
   * GET /api/web/auth/me
   * Returns the currently authenticated web session user.
   */
  async me(ctx: HttpContext) {
    const { response, auth } = ctx
    const user = auth.use('web').user!

    return response.sendFormatted({
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
      last_seen_at: user.lastSeenAt,
    })
  }
}
