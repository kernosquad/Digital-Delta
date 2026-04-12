import vine from '@vinejs/vine';

import type { Infer } from '@vinejs/vine/types';

export const loginValidator = vine.compile(
  vine.object({
    email: vine.string().email().trim().toLowerCase(),
    password: vine.string().minLength(8),
  })
);
export type LoginType = Infer<typeof loginValidator>;

export const registerValidator = vine.compile(
  vine.object({
    name: vine.string().minLength(2).maxLength(100).trim(),
    email: vine.string().email().trim().toLowerCase(),
    phone: vine.string().mobile().optional(),
    password: vine.string().minLength(8),
    role: vine
      .enum([
        'field_volunteer',
        'supply_manager',
        'drone_operator',
        'camp_commander',
        'sync_admin',
      ] as const)
      .optional(),
  })
);
export type RegisterType = Infer<typeof registerValidator>;

export const otpVerifyValidator = vine.compile(
  vine.object({
    code: vine.string().fixedLength(6),
    device_id: vine.string().minLength(10).maxLength(100),
  })
);
export type OtpVerifyType = Infer<typeof otpVerifyValidator>;

export const otpSetupValidator = vine.compile(
  vine.object({
    device_id: vine.string().minLength(10).maxLength(100),
    algorithm: vine.enum(['totp', 'hotp'] as const).optional(),
  })
);
export type OtpSetupType = Infer<typeof otpSetupValidator>;

export const provisionKeyValidator = vine.compile(
  vine.object({
    device_id: vine.string().minLength(10).maxLength(100),
    public_key: vine.string().minLength(100),
    key_type: vine.enum(['rsa_2048', 'ed25519'] as const),
  })
);
export type ProvisionKeyType = Infer<typeof provisionKeyValidator>;

export const verifyEmailValidator = vine.compile(
  vine.object({
    code: vine.string().fixedLength(6),
  })
);
export type VerifyEmailType = Infer<typeof verifyEmailValidator>;
