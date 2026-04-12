import router from '@adonisjs/core/services/router';

import { middleware } from '#start/kernel';

const NetworkController = () => import('./network.controller.js');

router
  .group(() => {
    router.get('/graph', [NetworkController, 'graph']);
    router.get('/edges', [NetworkController, 'edges']);
    router.get('/edges/:id', [NetworkController, 'showEdge']);
    router.get('/compute', [NetworkController, 'compute']);
    router
      .group(() => {
        router.post('/edges', [NetworkController, 'storeEdge']);
        router.patch('/edges/:id/status', [NetworkController, 'updateEdgeStatus']);
      })
      .use(middleware.role({ roles: ['sync_admin', 'supply_manager'] }));
  })
  .prefix('/api/network')
  .use(middleware.auth({ guards: ['jwt'] }));
