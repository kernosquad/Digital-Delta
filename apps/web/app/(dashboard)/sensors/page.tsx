'use client';

import { AreaChartOutlined, PlusOutlined, ReloadOutlined } from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Button,
  DatePicker,
  Form,
  InputNumber,
  Modal,
  Select,
  Table,
  Tag,
  Typography,
} from 'antd';
import { useState } from 'react';

import { api } from '@/lib/api';
import type { Location, RoutePrediction, SensorReading, SensorReadingType } from '@/types';

const { Title, Text } = Typography;

const READING_COLORS: Record<SensorReadingType, string> = {
  rainfall_mm: 'blue',
  water_level_cm: 'cyan',
  wind_speed_kmh: 'purple',
  soil_saturation_pct: 'orange',
  temperature_c: 'red',
};

const READING_UNITS: Record<SensorReadingType, string> = {
  rainfall_mm: 'mm',
  water_level_cm: 'cm',
  wind_speed_kmh: 'km/h',
  soil_saturation_pct: '%',
  temperature_c: '°C',
};

interface SensorReadingInput {
  location_id: number;
  reading_type: SensorReadingType;
  value: number;
  recorded_at: string;
  source?: 'sensor' | 'mock_api' | 'manual';
}

export default function SensorsPage() {
  const queryClient = useQueryClient();
  const [ingestModalOpen, setIngestModalOpen] = useState(false);
  const [form] = Form.useForm<{
    readings: (SensorReadingInput & { recorded_at_picker: unknown })[];
  }>();

  const {
    data: readings,
    isLoading,
    isError,
    refetch,
    dataUpdatedAt,
  } = useQuery<SensorReading[]>({
    queryKey: ['sensor-readings'],
    queryFn: () => api.get<SensorReading[]>('/sensors/readings').then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const { data: predictions } = useQuery<RoutePrediction[]>({
    queryKey: ['route-predictions'],
    queryFn: () => api.get<RoutePrediction[]>('/sensors/predictions').then(r => r.data),
    refetchInterval: 60_000,
    staleTime: 30_000,
  });

  const { data: locations } = useQuery<Location[]>({
    queryKey: ['locations'],
    queryFn: () => api.get<Location[]>('/locations').then(r => r.data),
    staleTime: 60_000,
  });

  const ingestMutation = useMutation({
    mutationFn: (readings: SensorReadingInput[]) =>
      api.post('/sensors/readings', { readings }).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sensor-readings'] });
      queryClient.invalidateQueries({ queryKey: ['route-predictions'] });
      setIngestModalOpen(false);
      form.resetFields();
    },
  });

  const locationOptions = (locations ?? []).map(l => ({
    value: l.id,
    label: `${l.node_code} — ${l.name}`,
  }));

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const readingColumns = [
    {
      title: 'Location',
      key: 'location',
      render: (_: unknown, r: SensorReading) => (
        <span className="text-dd-gray-700 text-sm">{r.location_name ?? `#${r.location_id}`}</span>
      ),
    },
    {
      title: 'Type',
      dataIndex: 'reading_type',
      key: 'reading_type',
      render: (t: SensorReadingType) => <Tag color={READING_COLORS[t]}>{t.replace(/_/g, ' ')}</Tag>,
    },
    {
      title: 'Value',
      key: 'value',
      render: (_: unknown, r: SensorReading) => (
        <span className="tabular-nums font-semibold text-dd-gray-900">
          {r.value}{' '}
          <span className="text-dd-gray-400 font-normal text-xs">
            {READING_UNITS[r.reading_type]}
          </span>
        </span>
      ),
      sorter: (a: SensorReading, b: SensorReading) => a.value - b.value,
    },
    {
      title: 'Source',
      dataIndex: 'source',
      key: 'source',
      render: (s: string) => (
        <Tag color={s === 'manual' ? 'orange' : s === 'sensor' ? 'green' : 'blue'}>{s}</Tag>
      ),
    },
    {
      title: 'Recorded At',
      dataIndex: 'recorded_at',
      key: 'recorded_at',
      render: (t: string) => (
        <span className="tabular-nums text-xs text-dd-gray-600">
          {new Date(t).toLocaleString()}
        </span>
      ),
      sorter: (a: SensorReading, b: SensorReading) =>
        new Date(a.recorded_at).getTime() - new Date(b.recorded_at).getTime(),
    },
  ];

  const predictionColumns = [
    {
      title: 'Edge',
      key: 'edge',
      render: (_: unknown, p: RoutePrediction) => (
        <span className="font-mono font-medium text-sm">{p.edge_code}</span>
      ),
    },
    {
      title: 'Impassability Risk',
      dataIndex: 'impassability_probability',
      key: 'risk',
      render: (prob: number) => {
        const pct = Math.round(prob * 100);
        const color = prob > 0.7 ? 'red' : prob > 0.4 ? 'orange' : 'green';
        return (
          <div className="flex items-center gap-2">
            <Tag color={color}>{pct}%</Tag>
            <span className="text-xs text-dd-gray-500">
              {prob > 0.7 ? 'High risk' : prob > 0.4 ? 'Medium' : 'Low'}
            </span>
          </div>
        );
      },
      sorter: (a: RoutePrediction, b: RoutePrediction) =>
        b.impassability_probability - a.impassability_probability,
      defaultSortOrder: 'descend' as const,
    },
    {
      title: 'Predicted At',
      dataIndex: 'predicted_at',
      key: 'predicted_at',
      render: (t: string) => (
        <span className="tabular-nums text-xs text-dd-gray-600">
          {new Date(t).toLocaleString()}
        </span>
      ),
    },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            <AreaChartOutlined className="mr-2 text-dd-primary-500" />
            Sensor Data & ML Predictions
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated ? `Updated ${lastUpdated} · feeds M7 route-decay classifier` : 'Loading…'}
          </Text>
        </div>
        <div className="flex gap-2">
          <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
            Refresh
          </Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setIngestModalOpen(true)}>
            Ingest Readings
          </Button>
        </div>
      </div>

      {isError && (
        <Alert message="Failed to load sensor data." type="error" showIcon className="mb-4" />
      )}

      {/* ML Predictions */}
      {(predictions ?? []).length > 0 && (
        <div className="mb-6">
          <Title level={5} className="mb-3!">
            Route Impassability Predictions
          </Title>
          <Table
            dataSource={predictions}
            columns={predictionColumns}
            rowKey="edge_id"
            size="small"
            pagination={{ pageSize: 5 }}
            rowClassName={(p: RoutePrediction) =>
              p.impassability_probability > 0.7 ? 'bg-red-50!' : ''
            }
          />
        </div>
      )}

      {/* Sensor Readings */}
      <Title level={5} className="mb-3!">
        Recent Sensor Readings
      </Title>
      <Table
        dataSource={readings ?? []}
        columns={readingColumns}
        rowKey="id"
        loading={isLoading}
        size="small"
        pagination={{ pageSize: 20, showSizeChanger: true }}
        scroll={{ x: 600 }}
      />

      {/* ── Ingest Modal ─────────────────────────────────────────── */}
      <Modal
        title="Ingest Sensor Readings"
        open={ingestModalOpen}
        onCancel={() => {
          setIngestModalOpen(false);
          form.resetFields();
        }}
        onOk={() => form.submit()}
        okText="Submit Readings"
        confirmLoading={ingestMutation.isPending}
        width={600}
        destroyOnClose
      >
        <Text className="text-dd-gray-600! text-sm block mb-4">
          Batch-ingest environmental sensor readings. These feed the M7 ML classifier for route
          impassability prediction.
        </Text>
        <Form
          form={form}
          layout="vertical"
          onFinish={values => {
            const readings = (values.readings ?? []).map(
              (r: SensorReadingInput & { recorded_at_picker: { toISOString: () => string } }) => ({
                location_id: r.location_id,
                reading_type: r.reading_type,
                value: r.value,
                recorded_at: r.recorded_at_picker?.toISOString() ?? new Date().toISOString(),
                source: r.source ?? 'manual',
              })
            );
            ingestMutation.mutate(readings);
          }}
        >
          <Form.List name="readings" initialValue={[{}]}>
            {(fields, { add, remove }) => (
              <>
                {fields.map(({ key, name, ...rest }) => (
                  <div key={key} className="border border-dd-gray-200 rounded-lg p-3 mb-3">
                    <div className="flex justify-between mb-2">
                      <Text className="text-dd-gray-700! font-medium text-sm">
                        Reading #{name + 1}
                      </Text>
                      {fields.length > 1 && (
                        <Button danger size="small" onClick={() => remove(name)}>
                          Remove
                        </Button>
                      )}
                    </div>
                    <Form.Item
                      {...rest}
                      name={[name, 'location_id']}
                      label="Location"
                      rules={[{ required: true }]}
                    >
                      <Select options={locationOptions} showSearch placeholder="Select location" />
                    </Form.Item>
                    <div className="flex gap-3">
                      <Form.Item
                        {...rest}
                        name={[name, 'reading_type']}
                        label="Type"
                        rules={[{ required: true }]}
                        className="flex-1"
                      >
                        <Select
                          options={[
                            { value: 'rainfall_mm', label: 'Rainfall (mm)' },
                            { value: 'water_level_cm', label: 'Water Level (cm)' },
                            { value: 'wind_speed_kmh', label: 'Wind Speed (km/h)' },
                            { value: 'soil_saturation_pct', label: 'Soil Saturation (%)' },
                            { value: 'temperature_c', label: 'Temperature (°C)' },
                          ]}
                        />
                      </Form.Item>
                      <Form.Item
                        {...rest}
                        name={[name, 'value']}
                        label="Value"
                        rules={[{ required: true }]}
                        className="w-28"
                      >
                        <InputNumber className="w-full!" placeholder="0.0" step={0.1} />
                      </Form.Item>
                    </div>
                    <div className="flex gap-3">
                      <Form.Item
                        {...rest}
                        name={[name, 'recorded_at_picker']}
                        label="Recorded At"
                        rules={[{ required: true }]}
                        className="flex-1"
                      >
                        <DatePicker showTime className="w-full!" />
                      </Form.Item>
                      <Form.Item
                        {...rest}
                        name={[name, 'source']}
                        label="Source"
                        className="w-36"
                        initialValue="manual"
                      >
                        <Select
                          options={[
                            { value: 'manual', label: 'Manual' },
                            { value: 'sensor', label: 'Sensor' },
                            { value: 'mock_api', label: 'Mock API' },
                          ]}
                        />
                      </Form.Item>
                    </div>
                  </div>
                ))}
                <Button type="dashed" onClick={() => add({})} block icon={<PlusOutlined />}>
                  Add another reading
                </Button>
              </>
            )}
          </Form.List>
          {ingestMutation.isError && (
            <Alert message="Failed to ingest readings." type="error" showIcon className="mt-3" />
          )}
        </Form>
      </Modal>
    </div>
  );
}
