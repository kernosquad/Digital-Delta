import router from '@adonisjs/core/services/router';

import { middleware } from '#start/kernel';

const LocationsController = () => import('./locations.controller.js');

router
  .group(() => {
    router.get('/', [LocationsController, 'index']);
    router.get('/:id', [LocationsController, 'show']);
    router
      .group(() => {
        router.post('/', [LocationsController, 'store']);
        router.patch('/:id/status', [LocationsController, 'updateStatus']);
      })
      .use(middleware.role({ roles: ['camp_commander', 'supply_manager', 'sync_admin'] }));
  })
  .prefix('/api/locations')
  .use(middleware.auth({ guards: ['jwt'] }));
