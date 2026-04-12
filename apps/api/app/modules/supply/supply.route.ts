import router from '@adonisjs/core/services/router'
import { middleware } from '#start/kernel'

const SupplyController = () => import('./supply.controller.js')

router
  .group(() => {
    router.get('/items', [SupplyController, 'indexItems'])
    router.get('/inventory', [SupplyController, 'indexInventory'])
    router.get('/inventory/:locationId', [SupplyController, 'showInventory'])
    router
      .group(() => {
        router.post('/items', [SupplyController, 'storeItem'])
        router.patch('/inventory/:locationId/:itemId', [SupplyController, 'updateStock'])
      })
      .use(middleware.role(['supply_manager', 'sync_admin', 'camp_commander']))
  })
  .prefix('/api/supply')
  .use(middleware.auth({ guards: ['jwt'] }))
