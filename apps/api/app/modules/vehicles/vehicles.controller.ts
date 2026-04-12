import { inject } from '@adonisjs/core'
import { storeVehicleValidator, updateVehicleValidator } from './vehicles.validator.js'
import type { VehiclesService } from './vehicles.service.js'
import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class VehiclesController {
  constructor(private vehiclesService: VehiclesService) {}

  async index(ctx: HttpContext) {
    return this.vehiclesService.index(ctx)
  }

  async show(ctx: HttpContext) {
    return this.vehiclesService.show(ctx)
  }

  async store(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(storeVehicleValidator)
    return this.vehiclesService.store(ctx, payload)
  }

  async update(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(updateVehicleValidator)
    return this.vehiclesService.update(ctx, payload)
  }
}
