import router from '@adonisjs/core/services/router'

import { middleware } from '#start/kernel'

const DeliveryController = () => import('./delivery.controller.js')

router
  .group(() => {
    // Nonce check & receipt reads: all authenticated roles
    router.post('/nonces/check', [DeliveryController, 'checkNonce'])
    router.get('/receipts/:id', [DeliveryController, 'showReceipt'])
    router.get('/receipts/mission/:missionId', [DeliveryController, 'receiptsByMission'])

    // Submit PoD receipt: roles with submitProofOfDelivery permission
    router.post('/receipts', [DeliveryController, 'createReceipt']).use(
      middleware.role({
        roles: ['field_volunteer', 'supply_manager', 'camp_commander', 'sync_admin'],
      })
    )

    // M5.1 — Generate signed QR payload: drivers (field_volunteer) + drone_operator + managers
    router.post('/pod/generate', [DeliveryController, 'generateQrPayload']).use(
      middleware.role({
        roles: [
          'field_volunteer',
          'drone_operator',
          'supply_manager',
          'camp_commander',
          'sync_admin',
        ],
      })
    )
  })
  .prefix('/api/delivery')
  .use(middleware.auth({ guards: ['jwt'] }))
