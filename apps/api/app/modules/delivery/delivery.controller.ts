import { inject } from '@adonisjs/core';

import { DeliveryService } from './delivery.service.js';
import { createReceiptValidator } from './delivery.validator.js';

import type { HttpContext } from '@adonisjs/core/http';

@inject()
export default class DeliveryController {
  constructor(private deliveryService: DeliveryService) {}

  async checkNonce(ctx: HttpContext) {
    return this.deliveryService.checkNonce(ctx);
  }

  async createReceipt(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(createReceiptValidator);
    return this.deliveryService.createReceipt(ctx, payload);
  }

  async showReceipt(ctx: HttpContext) {
    return this.deliveryService.showReceipt(ctx);
  }

  async receiptsByMission(ctx: HttpContext) {
    return this.deliveryService.receiptsByMission(ctx);
  }
}
