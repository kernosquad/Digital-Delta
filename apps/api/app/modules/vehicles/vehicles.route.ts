import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const VehiclesController = () => import('./vehicles.controller.js')

router
  .group(() => {
    router.get('/', [VehiclesController, 'index'])
    router.get('/:id', [VehiclesController, 'show'])
    // Vehicle status updates: drone_operator (their own drone), managers, sync_admin
    router.patch('/:id', [VehiclesController, 'update']).use(
      middleware.role({
        roles: ['drone_operator', 'supply_manager', 'camp_commander', 'sync_admin'],
      })
    )
    router
      .group(() => {
        router.post('/', [VehiclesController, 'store'])
      })
      .use(middleware.role({ roles: ['sync_admin', 'supply_manager'] }))
  })
  .prefix('/api/vehicles')
  .use(middleware.auth({ guards: ['jwt', 'web'] }))
