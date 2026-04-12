import db from '@adonisjs/lucid/services/db';

import type {
  LoginType,
  OtpSetupType,
  OtpVerifyType,
  ProvisionKeyType,
  RegisterType,
} from './auth.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import User from '#models/user';
import { EventBus } from '#services/event_bus';

export class AuthService {
  async login(ctx: HttpContext, payload: LoginType) {
    const { request, response, auth } = ctx;
    const user = await User.verifyCredentials(payload.email, payload.password);
    if (user.status !== 'active') {
      return response.forbidden({ error: 'Account is suspended or inactive' });
    }
    const token = await auth.use('jwt').generate(user);
    await db.from('users').where('id', user.id).update({ last_seen_at: new Date() });
    await db.table('auth_logs').insert({
      user_id: user.id,
      event_type: 'login_success',
      device_id: request.header('X-Device-Id'),
      ip_address: request.ip(),
      payload: JSON.stringify({ email: user.email }),
      event_hash: '',
      created_at: new Date(),
    });
    response.cookie('jwt_token', token.token, {
      httpOnly: true,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24,
    });
    return response.ok({
      token: token.token,
      token_type: 'Bearer',
      expires_in: 86400,
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  }

  async register({ response }: HttpContext, payload: RegisterType) {
    const existing = await User.findBy('email', payload.email);
    if (existing) {
      return response.conflict({ error: 'Email already registered' });
    }
    const user = await User.create({
      name: payload.name,
      email: payload.email,
      phone: payload.phone ?? null,
      password: payload.password,
      role: (payload.role ?? 'field_volunteer') as any,
      status: 'active',
    });
    return response.created({
      message: 'Account created. Proceed to OTP setup and key provisioning.',
      user: { id: user.id, name: user.name, email: user.email, role: user.role },
    });
  }

  async logout({ response, auth }: HttpContext) {
    const user = auth.user!;
    await db.table('auth_logs').insert({
      user_id: user.id,
      event_type: 'logout',
      event_hash: '',
      created_at: new Date(),
    });
    response.clearCookie('jwt_token');
    return response.ok({ message: 'Logged out' });
  }

  async me({ auth, response }: HttpContext) {
    const user = auth.user!;
    return response.ok({
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
      last_seen_at: user.lastSeenAt,
    });
  }

  async setupOtp({ response, auth }: HttpContext, payload: OtpSetupType) {
    const user = auth.user!;
    // TODO: generate TOTP secret using otplib
    return response.ok({
      message: 'OTP setup — implement with otplib or speakeasy',
      device_id: payload.device_id,
      user_id: user.id,
    });
  }

  async verifyOtp({ auth, response }: HttpContext, payload: OtpVerifyType) {
    const user = auth.user!;
    const otpRecord = await db
      .from('otp_secrets')
      .where('user_id', user.id)
      .where('device_id', payload.device_id)
      .where('is_active', true)
      .first();
    if (!otpRecord) {
      return response.notFound({ error: 'No OTP configured for this device' });
    }
    // TODO: decrypt stored secret and verify code
    await db.table('auth_logs').insert({
      user_id: user.id,
      event_type: 'otp_success',
      device_id: payload.device_id,
      event_hash: '',
      created_at: new Date(),
    });
    return response.ok({ verified: true });
  }

  async provisionKey({ auth, response }: HttpContext, payload: ProvisionKeyType) {
    const user = auth.user!;
    await db
      .from('user_keys')
      .where('user_id', user.id)
      .where('device_id', payload.device_id)
      .where('is_active', true)
      .update({ is_active: false, revoked_at: new Date() });
    await db.table('user_keys').insert({
      user_id: user.id,
      device_id: payload.device_id,
      public_key: payload.public_key,
      key_type: payload.key_type,
      is_active: true,
      created_at: new Date(),
    });
    await db.table('auth_logs').insert({
      user_id: user.id,
      event_type: 'key_provision',
      device_id: payload.device_id,
      event_hash: '',
      created_at: new Date(),
    });
    EventBus.publish('sensor_update', { type: 'key_provision', userId: user.id });
    return response.created({ message: 'Public key registered', device_id: payload.device_id });
  }
}
