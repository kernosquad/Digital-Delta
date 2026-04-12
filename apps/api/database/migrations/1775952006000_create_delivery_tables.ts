import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 6 — Proof of Delivery (PoD)
 * Tables: delivery_receipts, used_nonces
 *
 * Offline sync: YES (critical for PoD — must work with zero connectivity)
 * Covers: Module 5 (M5.1 QR Handshake, M5.2 Replay Protection, M5.3 Receipt Chain)
 */
export default class extends BaseSchema {
  async up() {
    // ------------------------------------------------------- delivery_receipts
    // Cryptographically signed, hash-chained PoD records.
    //
    // Flow (M5.1):
    //   1. Driver generates QR containing: mission_id, sender_pubkey, payload_hash,
    //      qr_nonce, timestamp — all signed with driver's private key.
    //   2. Recipient scans, verifies signature, counter-signs.
    //   3. Record inserted with both signatures.
    //
    // Hash chain (M5.3):
    //   previous_receipt_hash → SHA-256 of the previous receipt row
    //   receipt_hash          → SHA-256 of this row (excluding itself)
    //   Chain is appended to CRDT ledger and propagated to all syncing nodes.
    this.schema.createTable('delivery_receipts', (table) => {
      table.bigIncrements('id').notNullable();
      table
        .integer('mission_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('missions')
        .onDelete('RESTRICT');
      table
        .integer('recipient_location_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('locations')
        .onDelete('RESTRICT');
      table
        .integer('received_by_user_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL'); // camp commander who scanned
      table
        .integer('driver_user_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL');
      table.string('qr_nonce', 128).notNullable().unique(); // single-use nonce (M5.2)
      table.text('driver_signature').notNullable(); // base64 driver sig over payload
      table.text('recipient_signature').nullable(); // base64 recipient counter-sig
      table.string('payload_hash', 64).notNullable(); // SHA-256 of cargo manifest
      table.boolean('is_verified').notNullable().defaultTo(false);
      table.datetime('verified_at').nullable();
      table.bigInteger('crdt_sequence').unsigned().nullable(); // position in CRDT ledger
      table.string('previous_receipt_hash', 64).nullable(); // hash chain link
      table.string('receipt_hash', 64).notNullable(); // SHA-256 of this record
      table.datetime('created_at').notNullable();

      table.index(['mission_id'], 'idx_receipts_mission');
      table.index(['crdt_sequence'], 'idx_receipts_crdt_seq');
      table.index(['receipt_hash'], 'idx_receipts_hash');
      table.index(['is_verified', 'created_at'], 'idx_receipts_verified_time');
    });

    // ----------------------------------------------------------- used_nonces
    // Tracks consumed QR nonces to prevent replay attacks (M5.2).
    // Append-only — a nonce, once seen, is never removed.
    // Mobile SQLite keeps its own copy for offline replay rejection.
    this.schema.createTable('used_nonces', (table) => {
      table.bigIncrements('id').notNullable();
      table.string('nonce', 128).notNullable().unique();
      table
        .bigInteger('delivery_receipt_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('delivery_receipts')
        .onDelete('RESTRICT');
      table.datetime('created_at').notNullable();

      table.index(['nonce'], 'idx_nonces_nonce');
    });
  }

  async down() {
    this.schema.dropTableIfExists('used_nonces');
    this.schema.dropTableIfExists('delivery_receipts');
  }
}
