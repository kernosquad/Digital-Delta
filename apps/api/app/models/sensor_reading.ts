import { BaseModel, belongsTo, column } from '@adonisjs/lucid/orm';

import type { BelongsTo } from '@adonisjs/lucid/types/relations';
import type { DateTime } from 'luxon';

import Location from '#models/location';

export type ReadingType =
  | 'rainfall_mm'
  | 'water_level_cm'
  | 'wind_speed_kmh'
  | 'soil_saturation_pct'
  | 'temperature_c';

export type ReadingSource = 'sensor' | 'mock_api' | 'manual';

export default class SensorReading extends BaseModel {
  static table = 'sensor_readings';
  static updatedAt = false as const;

  @column({ isPrimary: true })
  declare id: number;

  @column()
  declare locationId: number;

  @column()
  declare readingType: ReadingType;

  @column()
  declare value: number;

  @column.dateTime()
  declare recordedAt: DateTime;

  @column()
  declare source: ReadingSource;

  @column.dateTime()
  declare createdAt: DateTime;

  // ── Relations ──────────────────────────────────────────────────────────
  @belongsTo(() => Location)
  declare location: BelongsTo<typeof Location>;
}
