import { inject } from '@adonisjs/core'
import { storeItemValidator, updateStockValidator } from './supply.validator.js'
import type { SupplyService } from './supply.service.js'
import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class SupplyController {
  constructor(private supplyService: SupplyService) {}

  async indexItems(ctx: HttpContext) {
    return this.supplyService.indexItems(ctx)
  }

  async storeItem(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(storeItemValidator)
    return this.supplyService.storeItem(ctx, payload)
  }

  async indexInventory(ctx: HttpContext) {
    return this.supplyService.indexInventory(ctx)
  }

  async showInventory(ctx: HttpContext) {
    return this.supplyService.showInventory(ctx)
  }

  async updateStock(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(updateStockValidator)
    return this.supplyService.updateStock(ctx, payload)
  }
}
