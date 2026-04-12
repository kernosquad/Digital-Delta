import type { HttpContext } from '@adonisjs/core/http'

import { webLoginSchema } from './web_auth.validator.js'
import { WebAuthService } from './web_auth.service.js'

const service = new WebAuthService()

export default class WebAuthController {
  async login(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(webLoginSchema)
    return service.login(ctx, payload)
  }

  async logout(ctx: HttpContext) {
    return service.logout(ctx)
  }

  async me(ctx: HttpContext) {
    return service.me(ctx)
  }
}
