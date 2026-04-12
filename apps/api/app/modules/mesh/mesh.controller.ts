import { inject } from '@adonisjs/core'
import { sendValidator } from './mesh.validator.js'
import type { MeshService } from './mesh.service.js'
import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class MeshController {
  constructor(private meshService: MeshService) {}

  async send(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(sendValidator)
    return this.meshService.send(ctx, payload)
  }

  async pending(ctx: HttpContext) {
    return this.meshService.pending(ctx)
  }

  async acknowledge(ctx: HttpContext) {
    return this.meshService.acknowledge(ctx)
  }

  async relay(ctx: HttpContext) {
    return this.meshService.relay(ctx)
  }
}
