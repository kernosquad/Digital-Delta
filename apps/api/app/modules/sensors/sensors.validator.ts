import vine from '@vinejs/vine';

import type { Infer } from '@vinejs/vine/types';

export const ingestSensorValidator = vine.compile(
  vine.object({
    readings: vine.array(
      vine.object({
        location_id: vine.number().min(0),
        reading_type: vine.enum([
          'rainfall_mm',
          'water_level_cm',
          'wind_speed_kmh',
          'soil_saturation_pct',
          'temperature_c',
        ] as const),
        value: vine.number(),
        recorded_at: vine.string(),
        source: vine
          .enum(['sensor', 'mock_api', 'manual'] as const)
          .optional()
          .requiredWhen(() => false),
      })
    ),
  })
);
export type IngestSensorType = Infer<typeof ingestSensorValidator>;
