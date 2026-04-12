import { inject } from '@adonisjs/core';

import { DashboardService } from './dashboard.service.js';

import type { HttpContext } from '@adonisjs/core/http';

@inject()
export default class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  async stats(ctx: HttpContext) {
    return this.dashboardService.stats(ctx);
  }

  async stream(ctx: HttpContext) {
    return this.dashboardService.stream(ctx);
  }
}
