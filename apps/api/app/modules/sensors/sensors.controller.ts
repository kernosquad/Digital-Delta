import { inject } from '@adonisjs/core'

import { SensorsService } from './sensors.service.js'
import { ingestSensorValidator } from './sensors.validator.js'

import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class SensorsController {
  constructor(private sensorsService: SensorsService) {}

  async ingest(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(ingestSensorValidator)
    return this.sensorsService.ingest(ctx, payload)
  }

  async readings(ctx: HttpContext) {
    return this.sensorsService.readings(ctx)
  }

  async predictions(ctx: HttpContext) {
    return this.sensorsService.predictions(ctx)
  }

  async prediction(ctx: HttpContext) {
    return this.sensorsService.prediction(ctx)
  }

  async rainfallFeatures(ctx: HttpContext) {
    return this.sensorsService.rainfallFeatures(ctx)
  }

  async generatePredictions(ctx: HttpContext) {
    return this.sensorsService.generatePredictions(ctx)
  }
}
