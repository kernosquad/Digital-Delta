import db from '@adonisjs/lucid/services/db';

import type { UserRole } from '#models/user';
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
      return response.status(403).sendError('Account is suspended or inactive');
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
    return response.sendFormatted(
      {
        token: token.token,
        token_type: 'Bearer',
        expires_in: 86400,
        user: { id: user.id, name: user.name, email: user.email, role: user.role },
      },
      'Login successful'
    );
  }

  async register({ response }: HttpContext, payload: RegisterType) {
    const existing = await User.findBy('email', payload.email);
    if (existing) {
      return response.status(409).sendError('Email already registered');
    }
    const user = await User.create({
      name: payload.name,
      email: payload.email,
      phone: payload.phone ?? null,
      password: payload.password,
      role: (payload.role ?? 'field_volunteer') as UserRole,
      status: 'active',
    });
    return response
      .status(201)
      .sendFormatted(
        { user: { id: user.id, name: user.name, email: user.email, role: user.role } },
        'Account created. Proceed to OTP setup and key provisioning.'
      );
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
    return response.sendFormatted('Logged out');
  }

  async me({ auth, response }: HttpContext) {
    const user = auth.user!;
    return response.sendFormatted({
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
    return response.sendFormatted(
      { device_id: payload.device_id, user_id: user.id },
      'OTP setup — implement with otplib or speakeasy'
    );
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
      return response.status(404).sendError('No OTP configured for this device');
    }
    // TODO: decrypt stored secret and verify code
    await db.table('auth_logs').insert({
      user_id: user.id,
      event_type: 'otp_success',
      device_id: payload.device_id,
      event_hash: '',
      created_at: new Date(),
    });
    return response.sendFormatted({ verified: true });
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
    return response
      .status(201)
      .sendFormatted({ device_id: payload.device_id }, 'Public key registered');
  }
}
