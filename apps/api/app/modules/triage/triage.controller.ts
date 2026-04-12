import { inject } from '@adonisjs/core'
import { evaluateTriageValidator } from './triage.validator.js'
import type { TriageService } from './triage.service.js'
import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class TriageController {
  constructor(private triageService: TriageService) {}

  async decisions(ctx: HttpContext) {
    return this.triageService.decisions(ctx)
  }

  async slaStatus(ctx: HttpContext) {
    return this.triageService.slaStatus(ctx)
  }

  async evaluate(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(evaluateTriageValidator)
    return this.triageService.evaluate(ctx, payload)
  }
}
