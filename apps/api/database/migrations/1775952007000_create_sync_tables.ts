import { BaseSchema } from '@adonisjs/lucid/schema';

/**
 * Group 7 — Distributed Sync & Mesh Networking
 * Tables: sync_nodes, crdt_operations, sync_conflicts, mesh_messages, mesh_relay_logs
 *
 * Offline sync:
 *   sync_nodes       → YES (device registry, needed for encryption)
 *   crdt_operations  → YES (append-only delta log synced via delta-sync protocol)
 *   sync_conflicts   → NO  (resolved server-side, pushed back as crdt_operations)
 *   mesh_messages    → YES (store-and-forward, TTL-bounded)
 *   mesh_relay_logs  → NO  (server-only telemetry)
 *
 * Covers: Module 2 (M2.1 CRDT, M2.2 Vector Clocks, M2.3 Conflict Resolution, M2.4 BT/WiFi Sync)
 *         Module 3 (M3.1 Store-and-Forward, M3.2 Dual-Role, M3.3 E2E Encryption)
 */
export default class extends BaseSchema {
  async up() {
    // ------------------------------------------------------------ sync_nodes
    // Registered devices participating in the mesh.
    // A node can be a mobile handset (client) or act as a relay (M3.2).
    // is_relay is toggled dynamically based on battery/proximity heuristics.
    this.schema.createTable('sync_nodes', (table) => {
      table.increments('id').notNullable();
      table.string('node_uuid', 100).notNullable().unique(); // stable device UUID
      table
        .integer('user_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL');
      table
        .enum('node_type', ['mobile', 'relay', 'base_station'])
        .notNullable()
        .defaultTo('mobile');
      table.text('public_key').notNullable(); // Ed25519 / RSA-2048 public key for E2E
      table.decimal('battery_level', 5, 2).nullable(); // 0–100 (M8.4 throttling)
      table.boolean('is_relay').notNullable().defaultTo(false); // current role (M3.2)
      table.datetime('last_seen_at').nullable();
      table.datetime('created_at').notNullable();
      table.datetime('updated_at').nullable();

      table.index(['user_id'], 'idx_sync_nodes_user');
      table.index(['is_relay', 'last_seen_at'], 'idx_sync_nodes_relay_seen');
    });

    // -------------------------------------------------------- crdt_operations
    // Append-only CRDT operation ledger (M2.1 + M2.2).
    // Every mutation on inventory, delivery_receipts, or mission status that
    // originates on a mobile device is recorded here.
    // vector_clock: JSON snapshot { "node-uuid": counter } at time of operation.
    // Delta sync (M2.4): transmit only rows where synced_at IS NULL since last clock.
    this.schema.createTable('crdt_operations', (table) => {
      table.bigIncrements('id').notNullable();
      table.string('operation_uuid', 100).notNullable().unique(); // UUID generated on-device
      table
        .integer('sync_node_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('sync_nodes')
        .onDelete('RESTRICT');
      table.enum('op_type', ['increment', 'decrement', 'set', 'delete', 'merge']).notNullable();
      table.string('entity_type', 60).notNullable(); // table name: 'inventory', 'delivery_receipts', …
      table.bigInteger('entity_id').unsigned().notNullable(); // PK of the affected row
      table.string('field_name', 100).notNullable(); // column being mutated
      table.json('old_value').nullable();
      table.json('new_value').notNullable();
      table.json('vector_clock').notNullable(); // causal ordering (M2.2)
      table.boolean('is_conflicted').notNullable().defaultTo(false);
      table.boolean('is_resolved').notNullable().defaultTo(false);
      table.datetime('created_at').notNullable(); // local device time of mutation
      table.datetime('synced_at').nullable(); // server receipt time (NULL = not yet synced)

      table.index(['entity_type', 'entity_id'], 'idx_crdt_entity');
      table.index(['sync_node_id', 'created_at'], 'idx_crdt_node_time');
      table.index(['is_conflicted', 'is_resolved'], 'idx_crdt_conflict_state');
      table.index(['synced_at'], 'idx_crdt_synced_at');
    });

    // --------------------------------------------------------- sync_conflicts
    // Surfaced when two crdt_operations update the same field with incompatible
    // vector clocks. Visualised in the dashboard (M2.3) for manual resolution
    // or auto-merged via LWW / application-level semantics.
    this.schema.createTable('sync_conflicts', (table) => {
      table.increments('id').notNullable();
      table
        .bigInteger('op_a_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('crdt_operations')
        .onDelete('CASCADE');
      table
        .bigInteger('op_b_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('crdt_operations')
        .onDelete('CASCADE');
      table.string('entity_type', 60).notNullable();
      table.bigInteger('entity_id').unsigned().notNullable();
      table.string('field_name', 100).notNullable();
      table.json('value_a').notNullable();
      table.json('value_b').notNullable();
      table.enum('resolution', ['a_wins', 'b_wins', 'merged', 'manual']).nullable();
      table.json('resolved_value').nullable();
      table
        .integer('resolved_by_user_id')
        .unsigned()
        .nullable()
        .references('id')
        .inTable('users')
        .onDelete('SET NULL');
      table.datetime('resolved_at').nullable();
      table.datetime('created_at').notNullable();

      table.index(['entity_type', 'entity_id'], 'idx_conflicts_entity');
      table.index(['resolution'], 'idx_conflicts_resolution');
    });

    // --------------------------------------------------------- mesh_messages
    // Store-and-forward encrypted messages between nodes (M3.1 + M3.3).
    // encrypted_payload: AES-256-GCM ciphertext using recipient's public key.
    // A message survives relay-node offline periods up to ttl_hours.
    // hop_count is incremented by each relay; rejected when >= max_hops.
    this.schema.createTable('mesh_messages', (table) => {
      table.bigIncrements('id').notNullable();
      table.string('message_uuid', 100).notNullable().unique(); // UUID, used for dedup
      table
        .integer('sender_node_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('sync_nodes')
        .onDelete('RESTRICT');
      table
        .integer('recipient_node_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('sync_nodes')
        .onDelete('RESTRICT');
      table
        .enum('message_type', [
          'crdt_delta',
          'delivery_receipt',
          'mission_update',
          'alert',
          'sync_ack',
        ])
        .notNullable();
      // AES-256-GCM encrypted; only recipient can decrypt (M3.3)
      table.specificType('encrypted_payload', 'MEDIUMBLOB').notNullable();
      table.string('payload_hash', 64).notNullable(); // SHA-256 for integrity check
      table.tinyint('ttl_hours').unsigned().notNullable().defaultTo(24);
      table.tinyint('hop_count').unsigned().notNullable().defaultTo(0);
      table.tinyint('max_hops').unsigned().notNullable().defaultTo(10);
      table.boolean('is_delivered').notNullable().defaultTo(false);
      table.datetime('delivered_at').nullable();
      table.datetime('created_at').notNullable();
      table.datetime('expires_at').notNullable(); // created_at + ttl_hours

      table.index(['sender_node_id', 'is_delivered'], 'idx_msg_sender_delivered');
      table.index(['recipient_node_id', 'is_delivered'], 'idx_msg_recipient_delivered');
      table.index(['expires_at'], 'idx_msg_expires');
      table.index(['message_type'], 'idx_msg_type');
    });

    // ------------------------------------------------------ mesh_relay_logs
    // Records each hop a message passes through. Server-only telemetry.
    this.schema.createTable('mesh_relay_logs', (table) => {
      table.bigIncrements('id').notNullable();
      table
        .bigInteger('mesh_message_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('mesh_messages')
        .onDelete('CASCADE');
      table
        .integer('relay_node_id')
        .unsigned()
        .notNullable()
        .references('id')
        .inTable('sync_nodes')
        .onDelete('RESTRICT');
      table.datetime('relayed_at').notNullable();

      table.index(['mesh_message_id'], 'idx_relay_logs_message');
      table.index(['relay_node_id', 'relayed_at'], 'idx_relay_logs_node_time');
    });
  }

  async down() {
    this.schema.dropTableIfExists('mesh_relay_logs');
    this.schema.dropTableIfExists('mesh_messages');
    this.schema.dropTableIfExists('sync_conflicts');
    this.schema.dropTableIfExists('crdt_operations');
    this.schema.dropTableIfExists('sync_nodes');
  }
}
