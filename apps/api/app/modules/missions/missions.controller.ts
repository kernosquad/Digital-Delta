import { inject } from '@adonisjs/core';

import { MissionsService } from './missions.service.js';
import {
  storeMissionValidator,
  updateStatusValidator,
  preemptValidator,
} from './missions.validator.js';

import type { HttpContext } from '@adonisjs/core/http';

@inject()
export default class MissionsController {
  constructor(private missionsService: MissionsService) {}

  async index(ctx: HttpContext) {
    return this.missionsService.index(ctx);
  }

  async show(ctx: HttpContext) {
    return this.missionsService.show(ctx);
  }

  async showRoute(ctx: HttpContext) {
    return this.missionsService.showRoute(ctx);
  }

  async store(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(storeMissionValidator);
    return this.missionsService.store(ctx, payload);
  }

  async updateStatus(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(updateStatusValidator);
    return this.missionsService.updateStatus(ctx, payload);
  }

  async reroute(ctx: HttpContext) {
    return this.missionsService.reroute(ctx);
  }

  async preempt(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(preemptValidator);
    return this.missionsService.preempt(ctx, payload);
  }
}
