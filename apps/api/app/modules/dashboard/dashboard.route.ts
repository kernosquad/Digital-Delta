import router from '@adonisjs/core/services/router';

import { middleware } from '#start/kernel';

const DashboardController = () => import('./dashboard.controller.js');

router
  .group(() => {
    router.get('/', [DashboardController, 'stats']);
    router.get('/stream', [DashboardController, 'stream']);
  })
  .prefix('/api/dashboard')
  .use(middleware.auth({ guards: ['jwt'] }));
