import router from '@adonisjs/core/services/router';

import { middleware } from '#start/kernel';

const HandoffController = () => import('./handoff.controller.js');

router
  .group(() => {
    router.get('/', [HandoffController, 'index']);
    router.get('/:id', [HandoffController, 'show']);
    router
      .group(() => {
        router.post('/', [HandoffController, 'store']);
        router.patch('/:id/complete', [HandoffController, 'complete']);
      })
      .use(middleware.role({ roles: ['drone_operator', 'supply_manager', 'sync_admin'] }));
  })
  .prefix('/api/handoff')
  .use(middleware.auth({ guards: ['jwt'] }));
