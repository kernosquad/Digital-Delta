'use client';

import { PlusOutlined, ReloadOutlined, RocketOutlined, WarningOutlined } from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Button,
  Col,
  Drawer,
  Form,
  Input,
  InputNumber,
  Modal,
  Row,
  Select,
  Space,
  Table,
  Tag,
  Typography,
} from 'antd';
import { useState } from 'react';

import { api } from '@/lib/api';
import type { Location, Mission, MissionStatus, PriorityClass, Vehicle } from '@/types';

const { Title, Text } = Typography;

const STATUS_COLORS: Record<MissionStatus, string> = {
  planned: 'blue',
  active: 'green',
  completed: 'default',
  preempted: 'orange',
  cancelled: 'red',
};

const PRIORITY_COLORS: Record<PriorityClass, string> = {
  p0_critical: 'red',
  p1_high: 'orange',
  p2_standard: 'blue',
  p3_low: 'default',
};

const PRIORITY_LABELS: Record<PriorityClass, string> = {
  p0_critical: 'P0 Critical',
  p1_high: 'P1 High',
  p2_standard: 'P2 Standard',
  p3_low: 'P3 Low',
};

// Valid transitions from each status
const NEXT_STATUSES: Partial<Record<MissionStatus, MissionStatus[]>> = {
  planned: ['active', 'cancelled'],
  active: ['completed', 'cancelled'],
};

interface CreateMissionBody {
  origin_location_id: number;
  destination_location_id: number;
  vehicle_id: number;
  driver_id?: number;
  priority_class: PriorityClass;
  notes?: string;
  cargo: { supply_item_id: number; quantity: number }[];
}

export default function MissionsPage() {
  const queryClient = useQueryClient();
  const [statusFilter, setStatusFilter] = useState<MissionStatus | 'all'>('all');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [preemptTarget, setPreemptTarget] = useState<{ id: number; code: string } | null>(null);
  const [createForm] = Form.useForm<CreateMissionBody>();
  const [preemptForm] = Form.useForm<{ preempting_mission_id: number; reason?: string }>();

  const {
    data: missions,
    isLoading,
    isError,
    refetch,
    dataUpdatedAt,
  } = useQuery<Mission[]>({
    queryKey: ['missions-mgmt', statusFilter],
    queryFn: () =>
      api
        .get<Mission[]>('/missions', {
          params: statusFilter !== 'all' ? { status: statusFilter } : {},
        })
        .then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const { data: locations } = useQuery<Location[]>({
    queryKey: ['locations'],
    queryFn: () => api.get<Location[]>('/locations').then(r => r.data),
    staleTime: 60_000,
  });

  const { data: vehicles } = useQuery<Vehicle[]>({
    queryKey: ['vehicles'],
    queryFn: () => api.get<Vehicle[]>('/vehicles').then(r => r.data),
    staleTime: 30_000,
  });

  const createMutation = useMutation({
    mutationFn: (body: CreateMissionBody) => api.post<Mission>('/missions', body).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['missions-mgmt'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      setDrawerOpen(false);
      createForm.resetFields();
    },
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: number; status: MissionStatus }) =>
      api.patch(`/missions/${id}/status`, { status }).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['missions-mgmt'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  const preemptMutation = useMutation({
    mutationFn: ({
      id,
      preempting_mission_id,
      reason,
    }: {
      id: number;
      preempting_mission_id: number;
      reason?: string;
    }) => api.post(`/missions/${id}/preempt`, { preempting_mission_id, reason }).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['missions-mgmt'] });
      queryClient.invalidateQueries({ queryKey: ['triage-decisions'] });
      setPreemptTarget(null);
      preemptForm.resetFields();
    },
  });

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const locationOptions = (locations ?? []).map(l => ({
    value: l.id,
    label: `${l.node_code} — ${l.name}`,
  }));

  const idleVehicleOptions = (vehicles ?? [])
    .filter(v => v.status === 'idle')
    .map(v => ({ value: v.id, label: `${v.name} (${v.type})` }));

  const columns = [
    {
      title: 'Mission',
      key: 'mission',
      render: (_: unknown, m: Mission) => (
        <div>
          <div className="font-mono font-medium text-dd-gray-900 text-sm">{m.mission_code}</div>
          <div className="text-xs text-dd-gray-500">
            {m.origin_name} → {m.destination_name}
          </div>
        </div>
      ),
      sorter: (a: Mission, b: Mission) => a.mission_code.localeCompare(b.mission_code),
    },
    {
      title: 'Priority',
      dataIndex: 'priority_class',
      key: 'priority',
      render: (p: PriorityClass) => <Tag color={PRIORITY_COLORS[p]}>{PRIORITY_LABELS[p]}</Tag>,
      sorter: (a: Mission, b: Mission) => {
        const order: Record<PriorityClass, number> = {
          p0_critical: 0,
          p1_high: 1,
          p2_standard: 2,
          p3_low: 3,
        };
        return order[a.priority_class] - order[b.priority_class];
      },
    },
    {
      title: 'Status',
      key: 'status',
      render: (_: unknown, m: Mission) => {
        const nexts = NEXT_STATUSES[m.status];
        if (!nexts?.length) {
          return <Tag color={STATUS_COLORS[m.status]}>{m.status}</Tag>;
        }
        return (
          <Select
            value={m.status}
            size="small"
            style={{ minWidth: 120 }}
            loading={statusMutation.isPending}
            options={[
              { value: m.status, label: <Tag color={STATUS_COLORS[m.status]}>{m.status}</Tag> },
              ...nexts.map(s => ({
                value: s,
                label: <Tag color={STATUS_COLORS[s]}>{s}</Tag>,
              })),
            ]}
            onChange={val => statusMutation.mutate({ id: m.id, status: val })}
          />
        );
      },
    },
    {
      title: 'Vehicle',
      key: 'vehicle',
      render: (_: unknown, m: Mission) => (
        <span className="text-dd-gray-700 capitalize text-sm">
          {m.vehicle_name} ({m.vehicle_type})
        </span>
      ),
    },
    {
      title: 'SLA Deadline',
      dataIndex: 'sla_deadline',
      key: 'deadline',
      render: (d: string, m: Mission) => (
        <div>
          <div
            className={`tabular-nums text-xs ${m.sla_breached ? 'text-red-600 font-semibold' : 'text-dd-gray-600'}`}
          >
            {new Date(d).toLocaleString()}
          </div>
          {m.sla_breached && (
            <Tag color="red" className="mt-0.5! text-xs">
              Breached
            </Tag>
          )}
        </div>
      ),
      sorter: (a: Mission, b: Mission) =>
        new Date(a.sla_deadline).getTime() - new Date(b.sla_deadline).getTime(),
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, m: Mission) =>
        m.status === 'active' ? (
          <Button
            size="small"
            danger
            icon={<WarningOutlined />}
            onClick={() => setPreemptTarget({ id: m.id, code: m.mission_code })}
          >
            Preempt
          </Button>
        ) : null,
    },
  ];

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            <RocketOutlined className="mr-2 text-dd-primary-500" />
            Mission Control
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated ? `Updated ${lastUpdated} · auto-refreshes every 30s` : 'Loading…'}
          </Text>
        </div>
        <Space>
          <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
            Refresh
          </Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setDrawerOpen(true)}>
            New Mission
          </Button>
        </Space>
      </div>

      {isError && (
        <Alert message="Failed to load missions." type="error" showIcon className="mb-4" />
      )}

      {/* Status filter */}
      <div className="flex items-center gap-3 mb-4">
        <Select
          value={statusFilter}
          onChange={v => setStatusFilter(v)}
          style={{ width: 160 }}
          options={[
            { value: 'all', label: 'All statuses' },
            { value: 'planned', label: 'Planned' },
            { value: 'active', label: 'Active' },
            { value: 'completed', label: 'Completed' },
            { value: 'preempted', label: 'Preempted' },
            { value: 'cancelled', label: 'Cancelled' },
          ]}
        />
        {missions && (
          <Text className="text-dd-gray-500! text-sm ml-auto">
            {missions.length} mission{missions.length !== 1 ? 's' : ''}
          </Text>
        )}
      </div>

      <Table
        dataSource={missions ?? []}
        columns={columns}
        rowKey="id"
        loading={isLoading}
        pagination={{ pageSize: 20, showSizeChanger: true }}
        size="middle"
        scroll={{ x: 750 }}
        rowClassName={(m: Mission) => (m.sla_breached ? 'bg-red-50!' : '')}
        className="pagination"
      />

      {/* ── Create Mission Drawer ───────────────────────────────── */}
      <Drawer
        title="Create New Mission"
        placement="right"
        width={500}
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
              Create Mission
            </Button>
          </div>
        }
      >
        <Form
          form={createForm}
          layout="vertical"
          onFinish={values => createMutation.mutate(values)}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="origin_location_id" label="Origin" rules={[{ required: true }]}>
                <Select options={locationOptions} placeholder="Select origin" showSearch />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="destination_location_id"
                label="Destination"
                rules={[{ required: true }]}
              >
                <Select options={locationOptions} placeholder="Select destination" showSearch />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="vehicle_id"
            label="Vehicle (idle vehicles only)"
            rules={[{ required: true }]}
          >
            <Select
              options={idleVehicleOptions}
              placeholder={
                idleVehicleOptions.length === 0 ? 'No idle vehicles available' : 'Select vehicle'
              }
              disabled={idleVehicleOptions.length === 0}
            />
          </Form.Item>

          <Form.Item name="priority_class" label="Priority Class" rules={[{ required: true }]}>
            <Select
              options={[
                { value: 'p0_critical', label: 'P0 Critical — 2h SLA' },
                { value: 'p1_high', label: 'P1 High — 6h SLA' },
                { value: 'p2_standard', label: 'P2 Standard — 24h SLA' },
                { value: 'p3_low', label: 'P3 Low — 72h SLA' },
              ]}
            />
          </Form.Item>

          <Form.Item name="notes" label="Notes">
            <Input.TextArea rows={2} placeholder="Optional mission notes" />
          </Form.Item>

          {/* Dynamic cargo list */}
          <div className="mb-2">
            <Text className="text-dd-gray-700! font-medium text-sm">Cargo Items</Text>
            <Text className="text-dd-gray-400! text-xs block">
              Supply item IDs are visible on the Supply Inventory page.
            </Text>
          </div>
          <Form.List name="cargo">
            {(fields, { add, remove }) => (
              <>
                {fields.map(({ key, name, ...rest }) => (
                  <div key={key} className="flex gap-2 items-start mb-2">
                    <Form.Item
                      {...rest}
                      name={[name, 'supply_item_id']}
                      rules={[{ required: true, message: 'Item ID required' }]}
                      className="flex-1 mb-0!"
                    >
                      <InputNumber min={1} placeholder="Supply item ID" className="w-full!" />
                    </Form.Item>
                    <Form.Item
                      {...rest}
                      name={[name, 'quantity']}
                      rules={[{ required: true, message: 'Qty required' }]}
                      className="w-28 mb-0!"
                    >
                      <InputNumber min={1} placeholder="Qty" className="w-full!" />
                    </Form.Item>
                    <Button danger size="small" onClick={() => remove(name)} className="mt-1!">
                      ✕
                    </Button>
                  </div>
                ))}
                <Button
                  type="dashed"
                  onClick={() => add()}
                  block
                  icon={<PlusOutlined />}
                  className="mt-1!"
                >
                  Add cargo item
                </Button>
              </>
            )}
          </Form.List>

          {createMutation.isError && (
            <Alert
              message="Failed to create mission. Check all required fields."
              type="error"
              showIcon
              className="mt-4"
            />
          )}
        </Form>
      </Drawer>

      {/* ── Preempt Modal ───────────────────────────────────────── */}
      <Modal
        title={`Preempt Mission ${preemptTarget?.code ?? ''}`}
        open={!!preemptTarget}
        onCancel={() => {
          setPreemptTarget(null);
          preemptForm.resetFields();
        }}
        onOk={() => preemptForm.submit()}
        okText="Confirm Preemption"
        okButtonProps={{ danger: true, loading: preemptMutation.isPending }}
        destroyOnClose
      >
        <Text className="text-dd-gray-600! block mb-4 text-sm">
          Enter the ID of the higher-priority mission that will take this mission&apos;s vehicle.
          This decision is logged to the triage audit trail.
        </Text>
        <Form
          form={preemptForm}
          layout="vertical"
          onFinish={values => {
            if (!preemptTarget) return;
            preemptMutation.mutate({
              id: preemptTarget.id,
              preempting_mission_id: values.preempting_mission_id,
              reason: values.reason,
            });
          }}
        >
          <Form.Item
            name="preempting_mission_id"
            label="Preempting Mission ID"
            rules={[{ required: true, message: 'Required' }]}
          >
            <InputNumber
              min={1}
              className="w-full!"
              placeholder="ID of the higher-priority mission"
            />
          </Form.Item>
          <Form.Item name="reason" label="Rationale (logged to triage audit)">
            <Input.TextArea
              rows={2}
              placeholder="e.g. P0 medical emergency requires vehicle reallocation"
            />
          </Form.Item>
        </Form>
        {preemptMutation.isError && (
          <Alert
            message="Preemption failed. Check mission ID."
            type="error"
            showIcon
            className="mt-2"
          />
        )}
      </Modal>
    </div>
  );
}
