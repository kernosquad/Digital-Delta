import { inject } from '@adonisjs/core'
import { storeHandoffValidator, completeHandoffValidator } from './handoff.validator.js'
import type { HandoffService } from './handoff.service.js'
import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class HandoffController {
  constructor(private handoffService: HandoffService) {}

  async index(ctx: HttpContext) {
    return this.handoffService.index(ctx)
  }

  async show(ctx: HttpContext) {
    return this.handoffService.show(ctx)
  }

  async store(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(storeHandoffValidator)
    return this.handoffService.store(ctx, payload)
  }

  async complete(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(completeHandoffValidator)
    return this.handoffService.complete(ctx, payload)
  }
}
