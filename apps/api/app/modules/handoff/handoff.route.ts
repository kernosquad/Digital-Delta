import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const HandoffController = () => import('./handoff.controller.js')

router
  .group(() => {
    router.get('/', [HandoffController, 'index'])
    router.get('/:id', [HandoffController, 'show'])
    // M8.1 — reachability analysis (read-only, any authenticated role)
    router.get('/analysis/reachability', [HandoffController, 'reachability'])
    router
      .group(() => {
        router.post('/', [HandoffController, 'store'])
        router.patch('/:id/complete', [HandoffController, 'complete'])
        // M8.2 — optimal rendezvous computation
        router.post('/rendezvous/compute', [HandoffController, 'computeRendezvous'])
        // M8.3 — full handoff coordination protocol simulation
        router.post('/protocol/simulate', [HandoffController, 'simulateProtocol'])
      })
      .use(middleware.role({ roles: ['drone_operator', 'supply_manager', 'sync_admin'] }))
  })
  .prefix('/api/handoff')
  .use(middleware.auth({ guards: ['jwt', 'web'] }))
