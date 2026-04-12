import { inject } from '@adonisjs/core'

import { HandoffService } from './handoff.service.js'
import {
  storeHandoffValidator,
  completeHandoffValidator,
  rendezvousValidator,
  simulateProtocolValidator,
} from './handoff.validator.js'

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

  async reachability(ctx: HttpContext) {
    return this.handoffService.reachability(ctx)
  }

  async computeRendezvous(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(rendezvousValidator)
    return this.handoffService.computeRendezvous(ctx, payload)
  }

  async simulateProtocol(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(simulateProtocolValidator)
    return this.handoffService.simulateProtocol(ctx, payload)
  }
}
