import { inject } from '@adonisjs/core'
import { storeEdgeValidator, edgeStatusValidator } from './network.validator.js'
import type { NetworkService } from './network.service.js'
import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class NetworkController {
  constructor(private networkService: NetworkService) {}

  async graph(ctx: HttpContext) {
    return this.networkService.graph(ctx)
  }

  async edges(ctx: HttpContext) {
    return this.networkService.edges(ctx)
  }

  async showEdge(ctx: HttpContext) {
    return this.networkService.showEdge(ctx)
  }

  async compute(ctx: HttpContext) {
    return this.networkService.compute(ctx)
  }

  async storeEdge(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(storeEdgeValidator)
    return this.networkService.storeEdge(ctx, payload)
  }

  async updateEdgeStatus(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(edgeStatusValidator)
    return this.networkService.updateEdgeStatus(ctx, payload)
  }
}
