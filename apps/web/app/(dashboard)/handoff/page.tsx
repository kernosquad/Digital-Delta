'use client';

import { CheckCircleOutlined, PlusOutlined, ReloadOutlined, SwapOutlined } from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Badge,
  Button,
  Col,
  DatePicker,
  Drawer,
  Form,
  InputNumber,
  Modal,
  Row,
  Skeleton,
  Statistic,
  Table,
  Tag,
  Typography,
} from 'antd';
import { useState } from 'react';

import { api } from '@/lib/api';
import type { Handoff, HandoffStatus, Vehicle } from '@/types';

const { Title, Text } = Typography;

const STATUS_CONFIG: Record<HandoffStatus, { color: string; label: string }> = {
  scheduled: { color: 'blue', label: 'Scheduled' },
  in_progress: { color: 'orange', label: 'In Progress' },
  completed: { color: 'green', label: 'Completed' },
  failed: { color: 'red', label: 'Failed' },
};

interface CreateHandoffBody {
  mission_id: number;
  drone_vehicle_id: number;
  ground_vehicle_id: number;
  rendezvous_location_id?: number;
  rendezvous_lat: number;
  rendezvous_lng: number;
  scheduled_at: string;
}

export default function HandoffPage() {
  const queryClient = useQueryClient();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [completeModal, setCompleteModal] = useState<number | null>(null);
  const [createForm] = Form.useForm<CreateHandoffBody & { scheduled_at_picker: unknown }>();
  const [completeForm] = Form.useForm<{ delivery_receipt_id?: number }>();

  const {
    data: handoffs,
    isLoading,
    isError,
    refetch,
    dataUpdatedAt,
  } = useQuery<Handoff[]>({
    queryKey: ['handoffs'],
    queryFn: () => api.get<Handoff[]>('/handoff').then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const { data: vehicles } = useQuery<Vehicle[]>({
    queryKey: ['vehicles'],
    queryFn: () => api.get<Vehicle[]>('/vehicles').then(r => r.data),
    staleTime: 30_000,
  });

  const createMutation = useMutation({
    mutationFn: (body: CreateHandoffBody) => api.post<Handoff>('/handoff', body).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['handoffs'] });
      setDrawerOpen(false);
      createForm.resetFields();
    },
  });

  const completeMutation = useMutation({
    mutationFn: ({ id, delivery_receipt_id }: { id: number; delivery_receipt_id?: number }) =>
      api.patch(`/handoff/${id}/complete`, { delivery_receipt_id }).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['handoffs'] });
      setCompleteModal(null);
      completeForm.resetFields();
    },
  });

  const droneOptions = (vehicles ?? [])
    .filter(v => v.type === 'drone')
    .map(v => ({ value: v.id, label: `${v.name} (drone)` }));

  const groundOptions = (vehicles ?? [])
    .filter(v => v.type !== 'drone')
    .map(v => ({ value: v.id, label: `${v.name} (${v.type})` }));

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const counts = {
    total: handoffs?.length ?? 0,
    scheduled: handoffs?.filter(h => h.status === 'scheduled').length ?? 0,
    completed: handoffs?.filter(h => h.status === 'completed').length ?? 0,
  };

  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 60,
      render: (id: number) => <span className="font-mono text-xs text-dd-gray-500">#{id}</span>,
    },
    {
      title: 'Mission',
      key: 'mission',
      render: (_: unknown, h: Handoff) =>
        h.mission_code ? (
          <span className="font-mono font-medium text-sm">{h.mission_code}</span>
        ) : (
          <Text className="text-dd-gray-400!">#{h.mission_id}</Text>
        ),
    },
    {
      title: 'Drone → Ground',
      key: 'vehicles',
      render: (_: unknown, h: Handoff) => (
        <div className="text-sm text-dd-gray-700">
          <span className="font-medium">{h.drone_name ?? `#${h.drone_vehicle_id}`}</span>
          <span className="text-dd-gray-400 mx-1">→</span>
          <span className="font-medium">{h.ground_name ?? `#${h.ground_vehicle_id}`}</span>
        </div>
      ),
    },
    {
      title: 'Rendezvous',
      key: 'rendezvous',
      render: (_: unknown, h: Handoff) => (
        <span className="font-mono text-xs text-dd-gray-600">
          {Number(h.rendezvous_lat).toFixed(4)}, {Number(h.rendezvous_lng).toFixed(4)}
        </span>
      ),
    },
    {
      title: 'Scheduled',
      dataIndex: 'scheduled_at',
      key: 'scheduled_at',
      render: (t: string) => (
        <span className="tabular-nums text-xs text-dd-gray-600">
          {new Date(t).toLocaleString()}
        </span>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (s: HandoffStatus) => {
        const cfg = STATUS_CONFIG[s];
        return <Tag color={cfg.color}>{cfg.label}</Tag>;
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, h: Handoff) =>
        h.status === 'scheduled' || h.status === 'in_progress' ? (
          <Button
            size="small"
            type="primary"
            icon={<CheckCircleOutlined />}
            onClick={() => setCompleteModal(h.id)}
          >
            Complete
          </Button>
        ) : null,
    },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            <SwapOutlined className="mr-2 text-dd-primary-500" />
            Handoff Manager
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated
              ? `Updated ${lastUpdated} · drone-to-ground payload transfers`
              : 'Loading…'}
          </Text>
        </div>
        <div className="flex gap-2">
          <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
            Refresh
          </Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setDrawerOpen(true)}>
            Schedule Handoff
          </Button>
        </div>
      </div>

      {isError && (
        <Alert message="Failed to load handoff data." type="error" showIcon className="mb-4" />
      )}

      {/* Summary */}
      <Row gutter={[16, 16]} className="mb-6">
        {[
          { label: 'Total', value: counts.total, color: '#374151' },
          { label: 'Scheduled', value: counts.scheduled, color: '#2563eb' },
          { label: 'Completed', value: counts.completed, color: '#17b26a' },
        ].map(({ label, value, color }) => (
          <Col key={label} xs={8}>
            <div className="bg-white rounded-lg p-3 border border-dd-gray-200">
              {isLoading ? (
                <Skeleton.Input active size="small" />
              ) : (
                <Statistic
                  title={label}
                  value={value}
                  styles={{ content: { color, fontSize: 22 } }}
                />
              )}
            </div>
          </Col>
        ))}
      </Row>

      <Table
        dataSource={handoffs ?? []}
        columns={columns}
        rowKey="id"
        loading={isLoading}
        size="middle"
        scroll={{ x: 700 }}
        pagination={{ pageSize: 20 }}
        rowClassName={(h: Handoff) => (h.status === 'scheduled' ? 'bg-blue-50!' : '')}
        className="pagination"
      />

      {/* ── Schedule Handoff Drawer ──────────────────────────── */}
      <Drawer
        title="Schedule Drone Handoff"
        placement="right"
        width={480}
        open={drawerOpen}
        onClose={() => {
          setDrawerOpen(false);
          createForm.resetFields();
        }}
        footer={
          <div className="flex justify-end gap-2">
            <Button
              onClick={() => {
                setDrawerOpen(false);
                createForm.resetFields();
              }}
            >
              Cancel
            </Button>
            <Button
              type="primary"
              loading={createMutation.isPending}
              onClick={() => createForm.submit()}
            >
              Schedule
            </Button>
          </div>
        }
      >
        <Alert
          message="Drone-Ground Rendezvous"
          description="The drone will deliver payload to the ground vehicle at the specified GPS coordinates. Both vehicles must be within drone range."
          type="info"
          showIcon
          className="mb-4"
        />
        <Form
          form={createForm}
          layout="vertical"
          onFinish={values => {
            const { scheduled_at_picker, ...rest } = values as CreateHandoffBody & {
              scheduled_at_picker: { toISOString: () => string };
            };
            createMutation.mutate({
              ...rest,
              scheduled_at: scheduled_at_picker?.toISOString() ?? new Date().toISOString(),
            });
          }}
        >
          <Form.Item name="mission_id" label="Mission ID" rules={[{ required: true }]}>
            <InputNumber min={1} className="w-full!" placeholder="Mission ID" />
          </Form.Item>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="drone_vehicle_id" label="Drone Vehicle" rules={[{ required: true }]}>
                <InputNumber min={1} className="w-full!" placeholder="Drone ID" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="ground_vehicle_id"
                label="Ground Vehicle"
                rules={[{ required: true }]}
              >
                <InputNumber min={1} className="w-full!" placeholder="Ground ID" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="rendezvous_lat" label="Rendezvous Lat" rules={[{ required: true }]}>
                <InputNumber
                  min={-90}
                  max={90}
                  step={0.0001}
                  className="w-full!"
                  placeholder="24.8949"
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="rendezvous_lng" label="Rendezvous Lng" rules={[{ required: true }]}>
                <InputNumber
                  min={-180}
                  max={180}
                  step={0.0001}
                  className="w-full!"
                  placeholder="91.8687"
                />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="rendezvous_location_id" label="Rendezvous Location ID (optional)">
            <InputNumber min={1} className="w-full!" placeholder="Known location node ID" />
          </Form.Item>
          <Form.Item name="scheduled_at_picker" label="Scheduled At" rules={[{ required: true }]}>
            <DatePicker showTime className="w-full!" />
          </Form.Item>
          {createMutation.isError && (
            <Alert message="Failed to schedule handoff." type="error" showIcon />
          )}
        </Form>
      </Drawer>

      {/* ── Complete Handoff Modal ──────────────────────────────── */}
      <Modal
        title="Complete Handoff"
        open={completeModal !== null}
        onCancel={() => {
          setCompleteModal(null);
          completeForm.resetFields();
        }}
        onOk={() => completeForm.submit()}
        okText="Mark Complete"
        confirmLoading={completeMutation.isPending}
        destroyOnClose
      >
        <div className="flex items-center gap-2 mb-4">
          <Badge status="processing" color="green" />
          <Text className="text-dd-gray-700!">
            Confirm the drone-to-ground payload transfer was successful. This logs a PoD receipt.
          </Text>
        </div>
        <Form
          form={completeForm}
          layout="vertical"
          onFinish={values => {
            if (completeModal === null) return;
            completeMutation.mutate({ id: completeModal, ...values });
          }}
        >
          <Form.Item name="delivery_receipt_id" label="Delivery Receipt ID (optional)">
            <InputNumber
              min={1}
              className="w-full!"
              placeholder="Link to PoD receipt if available"
            />
          </Form.Item>
        </Form>
        {completeMutation.isError && (
          <Alert message="Failed to complete handoff." type="error" showIcon className="mt-2" />
        )}
      </Modal>
    </div>
  );
}
