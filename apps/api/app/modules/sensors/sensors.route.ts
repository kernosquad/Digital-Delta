import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const SensorsController = () => import('./sensors.controller.js')

router
  .group(() => {
    router.post('/readings', [SensorsController, 'ingest'])
    router.get('/readings', [SensorsController, 'readings'])
    router.get('/features/rainfall', [SensorsController, 'rainfallFeatures'])
    router.get('/predictions', [SensorsController, 'predictions'])
    router.get('/predictions/:routeId', [SensorsController, 'prediction'])
    router.post('/predictions/generate', [SensorsController, 'generatePredictions'])
  })
  .prefix('/api/sensors')
  .use(middleware.auth({ guards: ['jwt', 'web'] }))
