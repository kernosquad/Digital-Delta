import router from '@adonisjs/core/services/router';

import { middleware } from '#start/kernel';

const SyncController = () => import('./sync.controller.js');

router
  .group(() => {
    router.post('/push', [SyncController, 'push']);
    router.get('/pull', [SyncController, 'pull']);
    router.get('/conflicts', [SyncController, 'conflicts']);
    router.post('/conflicts/:id/resolve', [SyncController, 'resolveConflict']);
    router.get('/nodes', [SyncController, 'nodes']);
    router.post('/nodes/register', [SyncController, 'registerNode']);
  })
  .prefix('/api/sync')
  .use(middleware.auth({ guards: ['jwt'] }));
