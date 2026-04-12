import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const UsersController = () => import('./users.controller.js')

router
  .group(() => {
    router.get('/', [UsersController, 'index'])
    router.get('/:id', [UsersController, 'show'])
    router
      .group(() => {
        router.patch('/:id/role', [UsersController, 'updateRole'])
        router.patch('/:id/status', [UsersController, 'updateStatus'])
      })
      .use(middleware.role({ roles: ['sync_admin'] }))
  })
  .prefix('/api/users')
  .use(middleware.auth({ guards: ['jwt', 'web'] }))
