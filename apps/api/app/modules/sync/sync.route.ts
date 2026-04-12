import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const SyncController = () => import('./sync.controller.js')

router
  .group(() => {
    // Delta push/pull: all authenticated users (offline-first sync)
    router.post('/push', [SyncController, 'push'])
    router.get('/pull', [SyncController, 'pull'])

    // Conflict visibility: camp_commander and sync_admin
    router
      .get('/conflicts', [SyncController, 'conflicts'])
      .use(middleware.role({ roles: ['camp_commander', 'sync_admin'] }))

    // Conflict resolution: sync_admin only
    router
      .post('/conflicts/:id/resolve', [SyncController, 'resolveConflict'])
      .use(middleware.role({ roles: ['sync_admin'] }))

    // Node registry read: camp_commander and sync_admin
    router
      .get('/nodes', [SyncController, 'nodes'])
      .use(middleware.role({ roles: ['camp_commander', 'sync_admin'] }))

    // Node registration: sync_admin only
    router
      .post('/nodes/register', [SyncController, 'registerNode'])
      .use(middleware.role({ roles: ['sync_admin'] }))
  })
  .prefix('/api/sync')
  .use(middleware.auth({ guards: ['jwt', 'web'] }))
