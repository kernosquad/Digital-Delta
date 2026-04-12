import router from '@adonisjs/core/services/router';

import { middleware } from '#start/kernel';

const TriageController = () => import('./triage.controller.js');

router
  .group(() => {
    router.get('/decisions', [TriageController, 'decisions']);
    router.get('/missions/:id/sla', [TriageController, 'slaStatus']);
    router
      .group(() => {
        router.post('/missions/:id/evaluate', [TriageController, 'evaluate']);
      })
      .use(middleware.role({ roles: ['supply_manager', 'sync_admin'] }));
  })
  .prefix('/api/triage')
  .use(middleware.auth({ guards: ['jwt'] }));
