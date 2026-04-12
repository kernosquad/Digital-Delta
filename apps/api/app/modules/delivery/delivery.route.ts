import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const DeliveryController = () => import('./delivery.controller.js')

router
  .group(() => {
    router.post('/nonces/check', [DeliveryController, 'checkNonce'])
    router.post('/receipts', [DeliveryController, 'createReceipt'])
    router.get('/receipts/:id', [DeliveryController, 'showReceipt'])
    router.get('/receipts/mission/:missionId', [DeliveryController, 'receiptsByMission'])
    // M5.1 — Driver generates signed QR payload for physical handoff
    router.post('/pod/generate', [DeliveryController, 'generateQrPayload'])
  })
  .prefix('/api/delivery')
  .use(middleware.auth({ guards: ['jwt'] }))
