import router from '@adonisjs/core/services/router';

import { middleware } from '#start/kernel';

const VehiclesController = () => import('./vehicles.controller.js');

router
  .group(() => {
    router.get('/', [VehiclesController, 'index']);
    router.get('/:id', [VehiclesController, 'show']);
    router.patch('/:id', [VehiclesController, 'update']);
    router
      .group(() => {
        router.post('/', [VehiclesController, 'store']);
      })
      .use(middleware.role({ roles: ['sync_admin', 'supply_manager'] }));
  })
  .prefix('/api/vehicles')
  .use(middleware.auth({ guards: ['jwt'] }));
