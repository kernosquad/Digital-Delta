import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import DeliveryReceipt from '#models/delivery_receipt';
import Location from '#models/location';
import Mission from '#models/mission';
import Vehicle from '#models/vehicle';

export type HandoffStatus = 'scheduled' | 'in_progress' | 'completed' | 'failed';

export default class HandoffEvent extends BaseModel {
  static table = 'handoff_events';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare missionId: number;

  @column()
  declare droneVehicleId: number;

  @column()
  declare groundVehicleId: number;

  @column()
  declare rendezvousLocationId: number | null;

  @column()
  declare rendezvousLat: number;

  @column()
  declare rendezvousLng: number;

  @column()
  declare status: HandoffStatus;

  @column()
  declare deliveryReceiptId: number | null;

  @column.dateTime()
  declare scheduledAt: DateTime;

  @column.dateTime()
  declare completedAt: DateTime | null;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Mission)
  declare mission: BelongsTo<typeof Mission>;

  @belongsTo(() => Vehicle, { foreignKey: 'droneVehicleId' })
  declare droneVehicle: BelongsTo<typeof Vehicle>;

  @belongsTo(() => Vehicle, { foreignKey: 'groundVehicleId' })
  declare groundVehicle: BelongsTo<typeof Vehicle>;

  @belongsTo(() => Location, { foreignKey: 'rendezvousLocationId' })
  declare rendezvousLocation: BelongsTo<typeof Location>;

  @belongsTo(() => DeliveryReceipt)
  declare deliveryReceipt: BelongsTo<typeof DeliveryReceipt>;
}
