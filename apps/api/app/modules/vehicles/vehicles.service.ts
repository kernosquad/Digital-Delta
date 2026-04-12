import db from '@adonisjs/lucid/services/db'
import { EventBus } from '#services/event_bus'
import type { HttpContext } from '@adonisjs/core/http'
import type { StoreVehicleType, UpdateVehicleType } from './vehicles.validator.js'

export class VehiclesService {
  async index(ctx: HttpContext) {
    const type = ctx.request.input('type')
    const status = ctx.request.input('status')
    const query = db.from('vehicles')
    if (type) query.where('type', type)
    if (status) query.where('status', status)
    return ctx.response.ok({ data: await query })
  }

  async show(ctx: HttpContext) {
    const vehicle = await db.from('vehicles').where('id', ctx.params.id).firstOrFail()
    return ctx.response.ok({ data: vehicle })
  }

  async store(ctx: HttpContext, payload: StoreVehicleType) {
    const [id] = await db
      .table('vehicles')
      .insert({ ...payload, status: 'idle', created_at: new Date(), updated_at: new Date() })
    return ctx.response.created({ data: await db.from('vehicles').where('id', id).first() })
  }

  async update(ctx: HttpContext, payload: UpdateVehicleType) {
    const vehicle = await db.from('vehicles').where('id', ctx.params.id).firstOrFail()
    if (ctx.auth.user!.role !== 'sync_admin' && vehicle.operator_id !== ctx.auth.user!.id) {
      return ctx.response.forbidden({ error: 'Can only update your own vehicle' })
    }
    await db
      .from('vehicles')
      .where('id', ctx.params.id)
      .update({ ...payload, updated_at: new Date() })
    EventBus.publish('vehicle_update', { vehicleId: Number(ctx.params.id), ...payload })
    return ctx.response.ok({ message: 'Vehicle updated' })
  }
}
