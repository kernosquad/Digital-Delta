import { inject } from '@adonisjs/core';

import {
  loginValidator,
  otpSetupValidator,
  otpVerifyValidator,
  provisionKeyValidator,
  registerValidator,
  verifyEmailValidator,
} from './auth.validator.js';

import type { AuthService } from './auth.service.js';
import type { HttpContext } from '@adonisjs/core/http';

@inject()
export default class AuthController {
  constructor(private authService: AuthService) {}

  async login(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(loginValidator);
    return this.authService.login(ctx, payload);
  }

  async register(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(registerValidator);
    return this.authService.register(ctx, payload);
  }

  async logout(ctx: HttpContext) {
    return this.authService.logout(ctx);
  }

  async me(ctx: HttpContext) {
    return this.authService.me(ctx);
  }

  async setupOtp(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(otpSetupValidator);
    return this.authService.setupOtp(ctx, payload);
  }

  async verifyOtp(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(otpVerifyValidator);
    return this.authService.verifyOtp(ctx, payload);
  }

  async provisionKey(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(provisionKeyValidator);
    return this.authService.provisionKey(ctx, payload);
  }

  async verifyEmail(ctx: HttpContext) {
    const payload = await ctx.request.validateUsing(verifyEmailValidator);
    return this.authService.verifyEmail(ctx, payload);
  }

  async resendVerification(ctx: HttpContext) {
    return this.authService.resendVerification(ctx);
  }
}
