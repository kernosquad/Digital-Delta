import { inject } from '@adonisjs/core'
import { pushValidator, resolveConflictValidator, registerNodeValidator } from './sync.validator.js'
import type { SyncService } from './sync.service.js'
import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class SyncController {
  constructor(private syncService: SyncService) {}

  async push(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(pushValidator)
    return this.syncService.push(ctx, payload)
  }

  async pull(ctx: HttpContext) {
    return this.syncService.pull(ctx)
  }

  async conflicts(ctx: HttpContext) {
    return this.syncService.conflicts(ctx)
  }

  async resolveConflict(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(resolveConflictValidator)
    return this.syncService.resolveConflict(ctx, payload)
  }

  async nodes(ctx: HttpContext) {
    return this.syncService.nodes(ctx)
  }

  async registerNode(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(registerNodeValidator)
    return this.syncService.registerNode(ctx, payload)
  }
}
