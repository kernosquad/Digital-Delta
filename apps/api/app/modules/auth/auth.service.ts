import { createHash } from 'node:crypto';

import { DateTime } from 'luxon';
import {
  generateSecret as otpGenSecret,
  generateURI as otpGenURI,
  verifySync as otpVerify,
} from 'otplib';

import type { UserRole } from '#models/user';
import type {
  LoginType,
  OtpSetupType,
  OtpVerifyType,
  ProvisionKeyType,
  RegisterType,
} from './auth.validator.js';
import type { HttpContext } from '@adonisjs/core/http';

import AuthLog from '#models/auth_log';
import OtpSecret from '#models/otp_secret';
import User from '#models/user';
import UserKey from '#models/user_key';
import { EventBus } from '#services/event_bus';

// ── M1.4 Hash-chained audit trail ─────────────────────────────────────────
type AuthEventType = AuthLog['eventType'];

async function appendAuditLog(
  eventType: AuthEventType,
  opts: {
    userId?: number;
    deviceId?: string;
    ipAddress?: string;
    payload?: Record<string, unknown>;
  } = {}
) {
  const last = await AuthLog.query().orderBy('id', 'desc').first();
  const previousHash = last?.eventHash ?? '0'.repeat(64);

  const eventData = {
    eventType,
    userId: opts.userId ?? null,
    deviceId: opts.deviceId ?? null,
    ipAddress: opts.ipAddress ?? null,
    payload: opts.payload ?? null,
    previousHash,
    createdAt: DateTime.now(),
  };

  // SHA-256 of the canonical event data (without the hash field itself)
  const eventHash = createHash('sha256').update(JSON.stringify(eventData)).digest('hex');

  await AuthLog.create({ ...eventData, eventHash });
}

// ── Service ───────────────────────────────────────────────────────────────

export class AuthService {
  /**
   * POST /api/auth/login
   *
   * Online login path (dashboard / initial device setup).
   * Mobile app always sends `device_id`.
   * If the device has an active TOTP secret, `otp_code` is required.
   * Response includes `device_setup` so the client knows what to do next.
   */
  async login(ctx: HttpContext, payload: LoginType) {
    const { request, response, auth } = ctx;
    const deviceId = payload.device_id ?? request.header('X-Device-Id') ?? null;

    // 1. Verify password
    let user: User;
    try {
      user = await User.verifyCredentials(payload.email, payload.password);
    } catch {
      await appendAuditLog('login_fail', {
        ipAddress: request.ip(),
        deviceId: deviceId ?? undefined,
        payload: { email: payload.email },
      });
      return response.status(401).sendError('Invalid email or password');
    }

    if (user.status !== 'active') {
      return response.status(403).sendError('Account is suspended or inactive');
    }

    // 2. TOTP check (RFC 6238) — only when device has an active secret
    if (deviceId) {
      const otpRecord = await OtpSecret.query()
        .where('user_id', user.id)
        .where('device_id', deviceId)
        .where('is_active', true)
        .first();

      if (otpRecord) {
        if (!payload.otp_code) {
          return response.status(422).sendError('OTP code required for this device');
        }
        // epochTolerance: ±30 s window for field-device clock drift
        const result = otpVerify({
          token: payload.otp_code,
          secret: otpRecord.secret,
          epochTolerance: 30,
        });
        if (!result.valid) {
          await appendAuditLog('otp_fail', { userId: user.id, deviceId });
          return response.status(422).sendError('Invalid or expired OTP code');
        }
        await appendAuditLog('otp_success', { userId: user.id, deviceId });
      }
    }

    // 3. Issue JWT
    const token = await auth.use('jwt').generate(user);
    await user.merge({ lastSeenAt: DateTime.now() }).save();

    await appendAuditLog('login_success', {
      userId: user.id,
      deviceId: deviceId ?? undefined,
      ipAddress: request.ip(),
      payload: { email: user.email },
    });

    response.cookie('jwt_token', token.token, {
      httpOnly: true,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24,
    });

    // Tell device what setup is still pending
    let deviceSetup: object | null = null;
    if (deviceId) {
      const hasOtp = await OtpSecret.query()
        .where('user_id', user.id)
        .where('device_id', deviceId)
        .where('is_active', true)
        .first();

      const hasKey = await UserKey.query()
        .where('user_id', user.id)
        .where('device_id', deviceId)
        .where('is_active', true)
        .first();

      deviceSetup = {
        otp_configured: !!hasOtp,
        key_provisioned: !!hasKey,
        next_steps: [
          ...(!hasOtp ? ['POST /api/auth/otp/setup'] : []),
          ...(!hasKey ? ['POST /api/auth/keys/provision'] : []),
        ],
      };
    }

    return response.sendFormatted(
      {
        token: token.token,
        token_type: 'Bearer',
        expires_in: 86400,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          status: user.status,
        },
        device_setup: deviceSetup,
      },
      'Login successful'
    );
  }

  /**
   * POST /api/auth/register
   *
   * Creates the account and returns a JWT immediately so the mobile app
   * can proceed to /otp/setup and /keys/provision in the same online session.
   * Email verification is NOT blocking — not required for offline operation.
   */
  async register(ctx: HttpContext, payload: RegisterType) {
    const { response, auth } = ctx;

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

    const token = await auth.use('jwt').generate(user);

    return response.status(201).sendFormatted(
      {
        token: token.token,
        token_type: 'Bearer',
        expires_in: 86400,
        user: { id: user.id, name: user.name, email: user.email, role: user.role },
        next_steps: ['POST /api/auth/otp/setup', 'POST /api/auth/keys/provision'],
      },
      'Account created. Complete OTP setup and key provisioning to enable offline access.'
    );
  }

  /**
   * POST /api/auth/otp/setup  (JWT required)
   *
   * Generates a per-device TOTP secret (RFC 6238, 160-bit base32).
   * Returns the secret and an otpauth:// URI for QR display.
   * Mobile stores the secret in local SQLite / SecureStorage.
   * Secret is inactive until confirmed via /otp/verify.
   */
  async setupOtp({ response, auth }: HttpContext, payload: OtpSetupType) {
    const user = auth.user!;

    // Deactivate any previous pending secret for this device
    await OtpSecret.query()
      .where('user_id', user.id)
      .where('device_id', payload.device_id)
      .update({ is_active: false });

    const secret = otpGenSecret({ length: 20 }); // 160-bit base32 secret
    const otpauthUri = otpGenURI({ label: user.email, issuer: 'Digital Delta', secret });

    await OtpSecret.create({
      userId: user.id,
      deviceId: payload.device_id,
      secret,
      algorithm: payload.algorithm ?? 'totp',
      hotpCounter: 0,
      isActive: false, // activated only after /otp/verify confirms the first code
      createdAt: DateTime.now(),
    });

    return response.sendFormatted(
      {
        device_id: payload.device_id,
        secret_b32: secret,
        otpauth_uri: otpauthUri,
        algorithm: payload.algorithm ?? 'totp',
        digits: 6,
        step_seconds: 30,
        issuer: 'Digital Delta',
      },
      'TOTP secret generated. Call /otp/verify with the first code to activate offline login.'
    );
  }

  /**
   * POST /api/auth/otp/verify  (JWT required)
   *
   * Validates the first TOTP code after setup (RFC 6238).
   * Activates the secret so the device is cleared for offline-gated logins.
   */
  async verifyOtp({ auth, response }: HttpContext, payload: OtpVerifyType) {
    const user = auth.user!;

    const otpRecord = await OtpSecret.query()
      .where('user_id', user.id)
      .where('device_id', payload.device_id)
      .orderBy('id', 'desc')
      .first();

    if (!otpRecord) {
      return response.status(404).sendError('No OTP secret found. Call /otp/setup first.');
    }

    const result = otpVerify({ token: payload.code, secret: otpRecord.secret, epochTolerance: 30 });
    if (!result.valid) {
      await appendAuditLog('otp_fail', { userId: user.id, deviceId: payload.device_id });
      return response.status(422).sendError('Invalid OTP code. Ensure device clock is synced.');
    }

    await otpRecord.merge({ isActive: true }).save();
    await appendAuditLog('otp_success', { userId: user.id, deviceId: payload.device_id });

    return response.sendFormatted(
      { device_id: payload.device_id, otp_active: true },
      'OTP verified and activated. Device is ready for offline authentication.'
    );
  }

  /**
   * POST /api/auth/keys/provision  (JWT required)
   *
   * Stores the device's Ed25519 / RSA-2048 public key in the shared ledger (M1.2).
   * Private key NEVER leaves the device (Keystore / SecureEnclave).
   * Used by M3.3 for mesh E2E encryption and M5.1 for PoD signature verification.
   */
  async provisionKey({ auth, response }: HttpContext, payload: ProvisionKeyType) {
    const user = auth.user!;

    const existing = await UserKey.query()
      .where('user_id', user.id)
      .where('device_id', payload.device_id)
      .where('is_active', true)
      .first();

    if (existing) {
      await existing.merge({ isActive: false, revokedAt: DateTime.now() }).save();
      await appendAuditLog('key_rotation', { userId: user.id, deviceId: payload.device_id });
    }

    await UserKey.create({
      userId: user.id,
      deviceId: payload.device_id,
      publicKey: payload.public_key,
      keyType: payload.key_type,
      isActive: true,
      createdAt: DateTime.now(),
    });

    await appendAuditLog('key_provision', { userId: user.id, deviceId: payload.device_id });
    EventBus.publish('sensor_update', { type: 'key_provision', userId: user.id });

    return response
      .status(201)
      .sendFormatted(
        { device_id: payload.device_id, key_type: payload.key_type },
        'Public key registered. Device fully provisioned for offline operation.'
      );
  }

  async logout({ response, auth }: HttpContext) {
    const user = auth.user!;
    await appendAuditLog('logout', { userId: user.id });
    response.clearCookie('jwt_token');
    return response.sendFormatted(null, 'Logged out');
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
}
