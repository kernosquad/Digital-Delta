import { inject } from '@adonisjs/core'

import { updateRoleValidator, updateStatusValidator } from './users.validator.js'

import type { UsersService } from './users.service.js'
import type { HttpContext } from '@adonisjs/core/http'

@inject()
export default class UsersController {
  constructor(private usersService: UsersService) {}

  async index(ctx: HttpContext) {
    return this.usersService.index(ctx)
  }

  async show(ctx: HttpContext) {
    return this.usersService.show(ctx)
  }

  async updateRole(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(updateRoleValidator)
    return this.usersService.updateRole(ctx, payload)
  }

  async updateStatus(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(updateStatusValidator)
    return this.usersService.updateStatus(ctx, payload)
  }
}
