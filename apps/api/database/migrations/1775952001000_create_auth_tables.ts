import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 1 — Auth & Identity
 * Tables: users, user_keys, otp_secrets, auth_logs
 *
 * Offline sync: YES (all four tables are replicated to SQLite on mobile)
 * Covers: Module 1 (M1.1 OTP, M1.2 Key Provisioning, M1.3 RBAC, M1.4 Audit Trail)
 */
export default class extends BaseSchema {
  async up() {
    // ------------------------------------------------------------------ users
    this.schema.createTable('users', (table) => {
      table.increments('id').notNullable();
      table.string('name', 100).notNullable();
      table.string('email', 254).notNullable().unique();
      table.string('phone', 20).nullable().unique();
      table.string('password', 255).notNullable();
      table
        .enum('role', [
          'field_volunteer',
          'supply_manager',
          'drone_operator',
          'camp_commander',
          'sync_admin',
        ])
        .notNullable()
        .defaultTo('field_volunteer');
      table.enum('status', ['active', 'inactive', 'suspended']).notNullable().defaultTo('active');
      table.datetime('last_seen_at').nullable();
      table.datetime('created_at').notNullable();
      table.datetime('updated_at').nullable();
      table.datetime('deleted_at').nullable();

      table.index(['role', 'status'], 'idx_users_role_status');
      table.index(['deleted_at'], 'idx_users_deleted_at');
    });

    // ------------------------------------------------------------ user_keys
    // One key pair per device, per user. Public key stored here for message
    // encryption and PoD signature verification. Private key lives on-device.
    this.schema.createTable('user_keys', (table) => {
      table.increments('id').notNullable();
      table
        .integer('user_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('users')
        .onDelete('CASCADE');
      table.string('device_id', 100).notNullable();
      table.text('public_key').notNullable(); // PEM-encoded RSA-2048 or Ed25519
      table.enum('key_type', ['rsa_2048', 'ed25519']).notNullable().defaultTo('ed25519');
      table.boolean('is_active').notNullable().defaultTo(true);
      table.datetime('created_at').notNullable();
      table.datetime('revoked_at').nullable();

      table.unique(['user_id', 'device_id'], { indexName: 'uq_user_keys_user_device' });
      table.index(['user_id', 'is_active'], 'idx_user_keys_user_active');
    });

    // ---------------------------------------------------------- otp_secrets
    // TOTP/HOTP secrets per device. Must be usable fully offline (RFC 6238/4226).
    this.schema.createTable('otp_secrets', (table) => {
      table.increments('id').notNullable();
      table
        .integer('user_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('users')
        .onDelete('CASCADE');
      table.string('device_id', 100).notNullable();
      table.string('secret', 255).notNullable(); // encrypted Base32 TOTP seed
      table.enum('algorithm', ['totp', 'hotp']).notNullable().defaultTo('totp');
      table.bigInteger('hotp_counter').unsigned().notNullable().defaultTo(0); // HOTP only
      table.boolean('is_active').notNullable().defaultTo(true);
      table.datetime('created_at').notNullable();

      table.unique(['user_id', 'device_id'], { indexName: 'uq_otp_secrets_user_device' });
    });

    // ------------------------------------------------------------- auth_logs
    // Append-only, hash-chained immutable audit trail (M1.4).
    // No UPDATE or DELETE ever issued against this table.
    // previous_hash → SHA-256 of previous row; event_hash → SHA-256 of this row.
    this.schema.createTable('auth_logs', (table) => {
      table.bigIncrements('id').notNullable();
      table
        .integer('user_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL');
      table
        .enum('event_type', [
          'login_success',
          'login_fail',
          'logout',
          'otp_success',
          'otp_fail',
          'key_provision',
          'key_rotation',
          'role_change',
          'session_expire',
        ])
        .notNullable();
      table.string('device_id', 100).nullable();
      table.string('ip_address', 45).nullable();
      table.json('payload').nullable(); // event-specific metadata
      table.string('previous_hash', 64).nullable(); // SHA-256 chain link
      table.string('event_hash', 64).notNullable(); // SHA-256 of this record

      table.datetime('created_at').notNullable();

      table.index(['user_id', 'created_at'], 'idx_auth_logs_user_time');
      table.index(['event_type', 'created_at'], 'idx_auth_logs_type_time');
      table.index(['event_hash'], 'idx_auth_logs_hash');
    });
  }

  async down() {
    this.schema.dropTableIfExists('auth_logs');
    this.schema.dropTableIfExists('otp_secrets');
    this.schema.dropTableIfExists('user_keys');
    this.schema.dropTableIfExists('users');
  }
}
