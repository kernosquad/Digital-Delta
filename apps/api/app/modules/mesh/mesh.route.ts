import router from '@adonisjs/core/services/router'
import { middleware } from '#start/kernel'

const MeshController = () => import('./mesh.controller.js')

router
  .group(() => {
    router.post('/messages', [MeshController, 'send'])
    router.get('/messages/pending', [MeshController, 'pending'])
    router.post('/messages/:uuid/ack', [MeshController, 'acknowledge'])
    router.post('/messages/:uuid/relay', [MeshController, 'relay'])
  })
  .prefix('/api/mesh')
  .use(middleware.auth({ guards: ['jwt'] }))
