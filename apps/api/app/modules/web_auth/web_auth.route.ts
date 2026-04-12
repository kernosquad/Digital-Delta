import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const WebAuthController = () => import('./web_auth.controller.js')

// ── Public web auth routes ────────────────────────────────────────────────────
router
  .group(() => {
    router.post('/login', [WebAuthController, 'login'])
  })
  .prefix('/api/web/auth')

// ── Session-protected web auth routes ─────────────────────────────────────────
router
  .group(() => {
    router.post('/logout', [WebAuthController, 'logout'])
    router.get('/me', [WebAuthController, 'me'])
  })
  .prefix('/api/web/auth')
  .use(middleware.auth({ guards: ['web'] }))

// ── Admin-only routes ─────────────────────────────────────────────────────────
router
  .group(() => {
    router.get('/audit-logs', [WebAuthController, 'auditLogs'])
  })
  .prefix('/api/web/auth')
  .use(middleware.auth({ guards: ['web'] }))
  .use(middleware.role({ roles: ['sync_admin', 'camp_commander'] }))
