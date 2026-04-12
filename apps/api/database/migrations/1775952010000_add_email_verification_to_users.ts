import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Adds email verification columns to the users table.
 * email_verification_code  — 6-digit one-time code sent via Resend on signup
 * email_verification_expires_at — 15-minute TTL
 * email_verified_at        — set when code is confirmed; NULL = unverified
 */
export default class extends BaseSchema {
  async up() {
    this.schema.alterTable('users', (table) => {
      table.string('email_verification_code', 6).nullable();
      table.datetime('email_verification_expires_at').nullable();
      table.datetime('email_verified_at').nullable();
    });
  }

  async down() {
    this.schema.alterTable('users', (table) => {
      table.dropColumn('email_verification_code');
      table.dropColumn('email_verification_expires_at');
      table.dropColumn('email_verified_at');
    });
  }
}
