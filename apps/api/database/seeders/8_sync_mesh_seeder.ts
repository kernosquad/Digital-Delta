import { BaseSeeder } from '@adonisjs/lucid/seeders'
import { DateTime } from 'luxon'

import CrdtOperation from '#models/crdt_operation'
import MeshMessage from '#models/mesh_message'
import MeshRelayLog from '#models/mesh_relay_log'
import SyncConflict from '#models/sync_conflict'
import SyncNode from '#models/sync_node'
import User from '#models/user'

/**
 * Seed CRDT sync nodes and mesh messages (Module 2, 3).
 *
 * M2.2 — Vector clock entries per node
 * M2.3 — Pre-existing conflict to demonstrate resolution UI
 * M2.4 — Actual delta sync nodes registered per device
 *
 * M3.1 — Store-and-forward messages in transit
 * M3.2 — Dual-role node assignments (relay vs client)
 * M3.3 — E2E encrypted message payloads
 *
 * Device registry:
 *   NODE-SRV-001 — Server sync node (base_station, authoritative relay)
 *   NODE-A-CMD   — Camp Commander's phone (relay)
 *   NODE-B-SUP   — Supply Manager's phone (relay)
 *   NODE-C-DRN   — Drone Operator's phone (client)
 *   NODE-D-VOL   — Field Volunteer's phone (client)
 */
export default class SyncMeshSeeder extends BaseSeeder {
  async run() {
    const now = DateTime.now()

    const commander = await User.findByOrFail('email', 'commander@digitaldelta.io')
    const supplyMgr = await User.findByOrFail('email', 'supply@digitaldelta.io')
    const droneOp = await User.findByOrFail('email', 'drone@digitaldelta.io')
    const volunteer = await User.findByOrFail('email', 'volunteer@digitaldelta.io')
    const admin = await User.findByOrFail('email', 'admin@digitaldelta.io')

    // ── Sync nodes ────────────────────────────────────────────────────────────
    const nodes = await SyncNode.createMany([
      {
        nodeUuid: 'NODE-SRV-001',
        userId: admin.id,
        nodeType: 'base_station',
        publicKey: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3srv001==',
        batteryLevel: null,
        isRelay: true,
        lastSeenAt: now,
      },
      {
        nodeUuid: 'NODE-A-CMD',
        userId: commander.id,
        nodeType: 'mobile',
        publicKey: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3nodeA==',
        batteryLevel: 78.5,
        isRelay: true,
        lastSeenAt: now.minus({ minutes: 8 }),
      },
      {
        nodeUuid: 'NODE-B-SUP',
        userId: supplyMgr.id,
        nodeType: 'mobile',
        publicKey: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3nodeB==',
        batteryLevel: 54.0,
        isRelay: true,
        lastSeenAt: now.minus({ minutes: 23 }),
      },
      {
        nodeUuid: 'NODE-C-DRN',
        userId: droneOp.id,
        nodeType: 'mobile',
        publicKey: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3nodeC==',
        batteryLevel: 31.2,
        isRelay: false,
        lastSeenAt: now.minus({ minutes: 47 }),
      },
      {
        nodeUuid: 'NODE-D-VOL',
        userId: volunteer.id,
        nodeType: 'mobile',
        publicKey: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3nodeD==',
        batteryLevel: 88.0,
        isRelay: false,
        lastSeenAt: now.minus({ minutes: 3 }),
      },
    ])

    const nodeMap = new Map(nodes.map((n) => [n.nodeUuid, n]))
    const srv = nodeMap.get('NODE-SRV-001')!
    const cmd = nodeMap.get('NODE-A-CMD')!
    const sup = nodeMap.get('NODE-B-SUP')!
    const drn = nodeMap.get('NODE-C-DRN')!
    const vol = nodeMap.get('NODE-D-VOL')!

    // ── CRDT Operations (vector clocks) ───────────────────────────────────────
    // op_type 'set' covers field-level updates (equivalent to an LWW-register write).
    const ops = await CrdtOperation.createMany([
      // Supply Manager decrements antivenom stock at N2 (node B)
      {
        operationUuid: 'op-b-001-antivenom-n2',
        syncNodeId: sup.id,
        opType: 'set',
        entityType: 'inventory',
        entityId: 1,
        fieldName: 'quantity',
        oldValue: 40,
        newValue: 35,
        vectorClock: { 'NODE-B-SUP': 1 },
        isConflicted: false,
        isResolved: false,
        createdAt: now.minus({ hours: 3 }),
        syncedAt: now.minus({ hours: 2, minutes: 45 }),
      },
      // Camp Commander updates water stock at N1 (node A)
      {
        operationUuid: 'op-a-001-water-n1',
        syncNodeId: cmd.id,
        opType: 'set',
        entityType: 'inventory',
        entityId: 5,
        fieldName: 'quantity',
        oldValue: 10000,
        newValue: 8500,
        vectorClock: { 'NODE-A-CMD': 1 },
        isConflicted: false,
        isResolved: false,
        createdAt: now.minus({ hours: 2, minutes: 30 }),
        syncedAt: now.minus({ hours: 2 }),
      },
      // Conflicting update — both A and B update food stock at N2 simultaneously (M2.3 demo)
      {
        operationUuid: 'op-a-002-food-n2-conflict',
        syncNodeId: cmd.id,
        opType: 'set',
        entityType: 'inventory',
        entityId: 6,
        fieldName: 'quantity',
        oldValue: 1500,
        newValue: 1250,
        vectorClock: { 'NODE-A-CMD': 2 },
        isConflicted: true,
        isResolved: false,
        createdAt: now.minus({ hours: 1, minutes: 30 }),
        syncedAt: now.minus({ hours: 1, minutes: 20 }),
      },
      {
        operationUuid: 'op-b-002-food-n2-conflict',
        syncNodeId: sup.id,
        opType: 'set',
        entityType: 'inventory',
        entityId: 6,
        fieldName: 'quantity',
        oldValue: 1500,
        newValue: 1180,
        vectorClock: { 'NODE-B-SUP': 2 },
        isConflicted: true,
        isResolved: false,
        createdAt: now.minus({ hours: 1, minutes: 28 }),
        syncedAt: now.minus({ hours: 1, minutes: 18 }),
      },
      // Drone op updates vehicle battery (offline read, synced later)
      {
        operationUuid: 'op-c-001-drone-battery',
        syncNodeId: drn.id,
        opType: 'set',
        entityType: 'vehicles',
        entityId: 5,
        fieldName: 'battery_level',
        oldValue: 100,
        newValue: 72.5,
        vectorClock: { 'NODE-C-DRN': 1 },
        isConflicted: false,
        isResolved: false,
        createdAt: now.minus({ hours: 1 }),
        syncedAt: now.minus({ minutes: 50 }),
      },
    ])

    // ── Sync Conflict (M2.3) ──────────────────────────────────────────────────
    const opA = ops.find((o) => o.operationUuid === 'op-a-002-food-n2-conflict')!
    const opB = ops.find((o) => o.operationUuid === 'op-b-002-food-n2-conflict')!

    await SyncConflict.create({
      opAId: opA.id,
      opBId: opB.id,
      entityType: 'inventory',
      entityId: 6,
      fieldName: 'quantity',
      valueA: 1250,
      valueB: 1180,
      resolution: null,
      createdAt: now.minus({ hours: 1, minutes: 15 }),
    })

    // ── Mesh Messages (M3.1 — Store-and-Forward) ──────────────────────────────
    // encryptedPayload is MEDIUMBLOB; Buffer.from() wraps the demo plaintext string.
    // msg-005 is a server broadcast — routed to the commander node as primary relay.
    const messages = await MeshMessage.createMany([
      {
        messageUuid: 'msg-001-antivenom-alert',
        senderNodeId: cmd.id,
        recipientNodeId: sup.id,
        messageType: 'alert',
        encryptedPayload: Buffer.from(
          'ENC:AES256-GCM:v1:3a7f9b2c...URGENT: Antivenom critically low at N3. Dispatch immediately.'
        ),
        payloadHash: 'sha256:a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
        ttlHours: 24,
        hopCount: 1,
        maxHops: 5,
        isDelivered: false,
        createdAt: now.minus({ minutes: 45 }),
        expiresAt: now.minus({ minutes: 45 }).plus({ hours: 24 }),
      },
      {
        messageUuid: 'msg-002-route-update',
        senderNodeId: sup.id,
        recipientNodeId: vol.id,
        messageType: 'alert',
        encryptedPayload: Buffer.from(
          'ENC:AES256-GCM:v1:5c8d1e3f...Route E3 now HIGH RISK. Use drone relay for N4 deliveries.'
        ),
        payloadHash: 'sha256:b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7',
        ttlHours: 24,
        hopCount: 2,
        maxHops: 4,
        isDelivered: true,
        deliveredAt: now.minus({ hours: 1 }),
        createdAt: now.minus({ hours: 1, minutes: 20 }),
        expiresAt: now.minus({ hours: 1, minutes: 20 }).plus({ hours: 24 }),
      },
      {
        messageUuid: 'msg-003-pod-confirmation',
        senderNodeId: vol.id,
        recipientNodeId: cmd.id,
        messageType: 'delivery_receipt',
        encryptedPayload: Buffer.from(
          'ENC:AES256-GCM:v1:7e9f2a4b...PoD confirmed. 50x antibiotics delivered at N3. Signed: VOL-001.'
        ),
        payloadHash: 'sha256:c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8',
        ttlHours: 24,
        hopCount: 0,
        maxHops: 6,
        isDelivered: true,
        deliveredAt: now.minus({ hours: 1, minutes: 55 }),
        createdAt: now.minus({ hours: 2 }),
        expiresAt: now.minus({ hours: 2 }).plus({ hours: 24 }),
      },
      {
        messageUuid: 'msg-004-drone-status',
        senderNodeId: drn.id,
        recipientNodeId: cmd.id,
        messageType: 'mission_update',
        encryptedPayload: Buffer.from(
          'ENC:AES256-GCM:v1:9a1b3c5d...Drone D1 battery 72%. ETA to N4 rendezvous: 18 min.'
        ),
        payloadHash: 'sha256:d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9',
        ttlHours: 24,
        hopCount: 1,
        maxHops: 3,
        isDelivered: false,
        createdAt: now.minus({ minutes: 12 }),
        expiresAt: now.minus({ minutes: 12 }).plus({ hours: 24 }),
      },
      {
        messageUuid: 'msg-005-flood-warning',
        senderNodeId: srv.id,
        recipientNodeId: cmd.id, // broadcast — commander node acts as primary relay
        messageType: 'alert',
        encryptedPayload: Buffer.from(
          'ENC:AES256-GCM:v1:2b4d6f8h...BROADCAST: Water level at N4 critical (9.4m). All ground vehicles avoid.'
        ),
        payloadHash: 'sha256:e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0',
        ttlHours: 24,
        hopCount: 0,
        maxHops: 8,
        isDelivered: false,
        createdAt: now.minus({ minutes: 5 }),
        expiresAt: now.minus({ minutes: 5 }).plus({ hours: 24 }),
      },
    ])

    // ── Mesh Relay Logs ────────────────────────────────────────────────────────
    const msgMap = new Map(messages.map((m) => [m.messageUuid, m]))
    const msg002 = msgMap.get('msg-002-route-update')!
    const msg001 = msgMap.get('msg-001-antivenom-alert')!

    await MeshRelayLog.createMany([
      {
        meshMessageId: msg002.id,
        relayNodeId: cmd.id,
        relayedAt: now.minus({ hours: 1, minutes: 15 }),
      },
      {
        meshMessageId: msg001.id,
        relayNodeId: drn.id,
        relayedAt: now.minus({ minutes: 40 }),
      },
    ])
  }
}
