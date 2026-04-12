import { inject } from '@adonisjs/core';

import { LocationsService } from './locations.service.js';
import { storeLocationValidator, updateLocationStatusValidator } from './locations.validator.js';

import type { HttpContext } from '@adonisjs/core/http';

@inject()
export default class LocationsController {
  constructor(private locationsService: LocationsService) {}

  async index(ctx: HttpContext) {
    return this.locationsService.index(ctx);
  }

  async show(ctx: HttpContext) {
    return this.locationsService.show(ctx);
  }

  async store(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(storeLocationValidator);
    return this.locationsService.store(ctx, payload);
  }

  async updateStatus(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(updateLocationStatusValidator);
    return this.locationsService.updateStatus(ctx, payload);
  }
}
