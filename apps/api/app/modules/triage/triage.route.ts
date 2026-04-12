import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const TriageController = () => import('./triage.controller.js')

router
  .group(() => {
    router.get('/decisions', [TriageController, 'decisions'])
    router.get('/taxonomy', [TriageController, 'taxonomy'])
    router.get('/missions/:id/sla', [TriageController, 'slaStatus'])
    router.get('/predict-breach', [TriageController, 'predictSlaBreach'])
    router
      .group(() => {
        router.post('/missions/:id/evaluate', [TriageController, 'evaluate'])
        router.post('/missions/:id/auto-preempt', [TriageController, 'autoPreempt'])
      })
      .use(middleware.role({ roles: ['supply_manager', 'sync_admin', 'field_volunteer'] }))
  })
  .prefix('/api/triage')
  .use(middleware.auth({ guards: ['jwt', 'web'] }))
