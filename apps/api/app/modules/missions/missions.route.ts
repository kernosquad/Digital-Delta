import router from '@adonisjs/core/services/router'
import { middleware } from '#start/kernel'

const MissionsController = () => import('./missions.controller.js')

router
  .group(() => {
    router.get('/', [MissionsController, 'index'])
    router.get('/:id', [MissionsController, 'show'])
    router.get('/:id/route', [MissionsController, 'showRoute'])
    router
      .group(() => {
        router.post('/', [MissionsController, 'store'])
        router.patch('/:id/status', [MissionsController, 'updateStatus'])
        router.post('/:id/reroute', [MissionsController, 'reroute'])
        router.post('/:id/preempt', [MissionsController, 'preempt'])
      })
      .use(middleware.role(['supply_manager', 'camp_commander', 'sync_admin']))
  })
  .prefix('/api/missions')
  .use(middleware.auth({ guards: ['jwt'] }))
