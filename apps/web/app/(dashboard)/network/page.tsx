'use client';

import { ClusterOutlined, PlusOutlined, ReloadOutlined, WarningOutlined } from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Badge,
  Button,
  Col,
  Form,
  Input,
  InputNumber,
  Modal,
  Popconfirm,
  Progress,
  Row,
  Select,
  Space,
  Statistic,
  Switch,
  Table,
  Tag,
  Typography,
} from 'antd';
import { useMemo, useState } from 'react';

import { api } from '@/lib/api';
import type { NetworkEdge, RouteType } from '@/types';

const { Title, Text } = Typography;

const ROUTE_COLORS: Record<RouteType, string> = {
  road: 'blue',
  river: 'cyan',
  airway: 'purple',
};

const ROUTE_ICONS: Record<RouteType, string> = {
  road: '🛣️',
  river: '🌊',
  airway: '✈️',
};

interface CreateEdgeBody {
  edge_code: string;
  source_location_id: number;
  target_location_id: number;
  route_type: RouteType;
  base_travel_mins: number;
  max_payload_kg?: number;
  allowed_vehicles?: string[];
}

interface UpdateStatusBody {
  is_flooded?: boolean;
  is_blocked?: boolean;
  current_travel_mins?: number;
  risk_score?: number;
  reason?: 'flood' | 'recede' | 'ml_prediction' | 'manual_override' | 'chaos_engine';
}

export default function NetworkPage() {
  const queryClient = useQueryClient();
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [statusModal, setStatusModal] = useState<NetworkEdge | null>(null);
  const [routeFilter, setRouteFilter] = useState<RouteType | 'all'>('all');
  const [createForm] = Form.useForm<CreateEdgeBody>();
  const [statusForm] = Form.useForm<UpdateStatusBody>();

  const {
    data: edges,
    isLoading,
    isError,
    refetch,
    dataUpdatedAt,
  } = useQuery<NetworkEdge[]>({
    queryKey: ['network-edges'],
    queryFn: () => api.get<NetworkEdge[]>('/network/edges').then(r => r.data),
    refetchInterval: 15_000,
    staleTime: 10_000,
  });

  const createMutation = useMutation({
    mutationFn: (body: CreateEdgeBody) =>
      api.post<NetworkEdge>('/network/edges', body).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['network-edges'] });
      setCreateModalOpen(false);
      createForm.resetFields();
    },
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateStatusBody }) =>
      api.patch(`/network/edges/${id}/status`, body).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['network-edges'] });
      setStatusModal(null);
      statusForm.resetFields();
    },
  });

  // Quick-toggle flood for a single edge
  const quickFloodToggle = (edge: NetworkEdge) =>
    statusMutation.mutate({
      id: edge.id,
      body: {
        is_flooded: !edge.is_flooded,
        reason: edge.is_flooded ? 'recede' : 'flood',
      },
    });

  const filtered = useMemo(
    () => (edges ?? []).filter(e => routeFilter === 'all' || e.route_type === routeFilter),
    [edges, routeFilter]
  );

  const floodedCount = edges?.filter(e => e.is_flooded).length ?? 0;
  const blockedCount = edges?.filter(e => e.is_blocked).length ?? 0;
  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const columns = [
    {
      title: 'Edge',
      key: 'edge',
      render: (_: unknown, e: NetworkEdge) => (
        <div>
          <div className="font-mono font-medium text-dd-gray-900 text-sm">{e.edge_code}</div>
          <div className="text-xs text-dd-gray-500">
            {e.source_name ?? `#${e.source_location_id}`} →{' '}
            {e.target_name ?? `#${e.target_location_id}`}
          </div>
        </div>
      ),
    },
    {
      title: 'Type',
      dataIndex: 'route_type',
      key: 'route_type',
      render: (t: RouteType) => (
        <Tag color={ROUTE_COLORS[t]}>
          {ROUTE_ICONS[t]} {t}
        </Tag>
      ),
    },
    {
      title: 'Travel Time',
      key: 'travel',
      render: (_: unknown, e: NetworkEdge) => (
        <div>
          <span className="tabular-nums text-dd-gray-900 font-medium">
            {e.current_travel_mins ?? e.base_travel_mins}m
          </span>
          {e.current_travel_mins && e.current_travel_mins !== e.base_travel_mins && (
            <div className="text-xs text-dd-gray-400">base: {e.base_travel_mins}m</div>
          )}
        </div>
      ),
      sorter: (a: NetworkEdge, b: NetworkEdge) =>
        (a.current_travel_mins ?? a.base_travel_mins) -
        (b.current_travel_mins ?? b.base_travel_mins),
    },
    {
      title: 'Risk',
      dataIndex: 'risk_score',
      key: 'risk',
      render: (score: number | null) =>
        score != null ? (
          <div className="w-20">
            <Progress
              percent={Math.round(score * 100)}
              size="small"
              strokeColor={score > 0.7 ? '#f04438' : score > 0.4 ? '#f79009' : '#17b26a'}
              showInfo={false}
            />
            <span className="text-xs text-dd-gray-500">{(score * 100).toFixed(0)}%</span>
          </div>
        ) : (
          <Text className="text-dd-gray-400!">—</Text>
        ),
      sorter: (a: NetworkEdge, b: NetworkEdge) => (a.risk_score ?? 0) - (b.risk_score ?? 0),
    },
    {
      title: 'Status',
      key: 'status',
      render: (_: unknown, e: NetworkEdge) => (
        <div className="flex flex-col gap-1">
          {e.is_flooded && <Tag color="red">Flooded</Tag>}
          {e.is_blocked && <Tag color="orange">Blocked</Tag>}
          {!e.is_flooded && !e.is_blocked && <Tag color="green">Clear</Tag>}
        </div>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, e: NetworkEdge) => (
        <Space size="small">
          <Popconfirm
            title={e.is_flooded ? 'Mark road as clear?' : 'Mark road as flooded?'}
            onConfirm={() => quickFloodToggle(e)}
            okText="Yes"
            okButtonProps={{ danger: !e.is_flooded }}
          >
            <Button
              size="small"
              type={e.is_flooded ? 'default' : 'primary'}
              danger={!e.is_flooded}
              icon={<WarningOutlined />}
            >
              {e.is_flooded ? 'Clear' : 'Flood'}
            </Button>
          </Popconfirm>
          <Button
            size="small"
            onClick={() => {
              setStatusModal(e);
              statusForm.setFieldsValue({
                is_flooded: e.is_flooded,
                is_blocked: e.is_blocked,
                current_travel_mins: e.current_travel_mins ?? e.base_travel_mins,
                risk_score: e.risk_score ?? undefined,
                reason: 'manual_override',
              });
            }}
          >
            Edit
          </Button>
        </Space>
      ),
    },
  ];

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            <ClusterOutlined className="mr-2 text-dd-primary-500" />
            Route Network
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated ? `Updated ${lastUpdated} · auto-refreshes every 15s` : 'Loading…'}
          </Text>
        </div>
        <Space>
          <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
            Refresh
          </Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateModalOpen(true)}>
            Add Edge
          </Button>
        </Space>
      </div>

      {/* Status alerts */}
      {floodedCount > 0 && (
        <Alert
          message={`${floodedCount} flooded route${floodedCount > 1 ? 's' : ''} — VRP engine will avoid these edges`}
          type="error"
          showIcon
          icon={<WarningOutlined />}
          className="mb-4"
        />
      )}
      {isError && (
        <Alert message="Failed to load network data." type="error" showIcon className="mb-4" />
      )}

      {/* Summary stats */}
      <Row gutter={[16, 16]} className="mb-4">
        {[
          { label: 'Total Edges', value: edges?.length ?? 0, color: '#374151' },
          { label: 'Flooded', value: floodedCount, color: '#f04438' },
          { label: 'Blocked', value: blockedCount, color: '#f79009' },
          {
            label: 'Clear',
            value: (edges?.length ?? 0) - floodedCount - blockedCount,
            color: '#17b26a',
          },
        ].map(({ label, value, color }) => (
          <Col key={label} xs={12} sm={6}>
            <div className="bg-white rounded-lg p-3 border border-dd-gray-200">
              <Statistic
                title={label}
                value={value}
                styles={{ content: { color, fontSize: 22 } }}
              />
            </div>
          </Col>
        ))}
      </Row>

      {/* Filter */}
      <div className="flex items-center gap-3 mb-4">
        <Select
          value={routeFilter}
          onChange={v => setRouteFilter(v)}
          style={{ width: 140 }}
          options={[
            { value: 'all', label: 'All types' },
            { value: 'road', label: '🛣️ Road' },
            { value: 'river', label: '🌊 River' },
            { value: 'airway', label: '✈️ Airway' },
          ]}
        />
        <Text className="text-dd-gray-500! text-sm ml-auto">
          {filtered.length} edge{filtered.length !== 1 ? 's' : ''}
        </Text>
      </div>

      <Table
        dataSource={filtered}
        columns={columns}
        rowKey="id"
        loading={isLoading}
        size="middle"
        pagination={{ pageSize: 20 }}
        scroll={{ x: 700 }}
        rowClassName={(e: NetworkEdge) =>
          e.is_flooded ? 'bg-red-50!' : e.is_blocked ? 'bg-orange-50!' : ''
        }
        className="pagination"
      />

      {/* ── Create Edge Modal ──────────────────────────────────── */}
      <Modal
        title="Add Network Edge"
        open={createModalOpen}
        onCancel={() => {
          setCreateModalOpen(false);
          createForm.resetFields();
        }}
        onOk={() => createForm.submit()}
        okText="Create Edge"
        confirmLoading={createMutation.isPending}
        width={520}
      >
        <Form form={createForm} layout="vertical" onFinish={v => createMutation.mutate(v)}>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="edge_code" label="Edge Code" rules={[{ required: true }]}>
                <Input placeholder="E.g. E-N1-N3" style={{ textTransform: 'uppercase' }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="route_type" label="Route Type" rules={[{ required: true }]}>
                <Select
                  options={[
                    { value: 'road', label: '🛣️ Road' },
                    { value: 'river', label: '🌊 River' },
                    { value: 'airway', label: '✈️ Airway' },
                  ]}
                />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item
                name="source_location_id"
                label="Source Location ID"
                rules={[{ required: true }]}
              >
                <InputNumber min={1} className="w-full!" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="target_location_id"
                label="Target Location ID"
                rules={[{ required: true }]}
              >
                <InputNumber min={1} className="w-full!" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item
                name="base_travel_mins"
                label="Base Travel (mins)"
                rules={[{ required: true }]}
              >
                <InputNumber min={1} className="w-full!" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="max_payload_kg" label="Max Payload (kg)">
                <InputNumber min={0} className="w-full!" placeholder="Optional" />
              </Form.Item>
            </Col>
          </Row>
          {createMutation.isError && (
            <Alert message="Failed to create edge." type="error" showIcon />
          )}
        </Form>
      </Modal>

      {/* ── Edit Status Modal ──────────────────────────────────── */}
      <Modal
        title={`Update Edge: ${statusModal?.edge_code ?? ''}`}
        open={!!statusModal}
        onCancel={() => {
          setStatusModal(null);
          statusForm.resetFields();
        }}
        onOk={() => statusForm.submit()}
        okText="Update"
        confirmLoading={statusMutation.isPending}
        destroyOnClose
      >
        <Form
          form={statusForm}
          layout="vertical"
          onFinish={values => {
            if (!statusModal) return;
            statusMutation.mutate({ id: statusModal.id, body: values });
          }}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="is_flooded" label="Flooded" valuePropName="checked">
                <Switch checkedChildren="Yes" unCheckedChildren="No" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="is_blocked" label="Blocked" valuePropName="checked">
                <Switch checkedChildren="Yes" unCheckedChildren="No" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="current_travel_mins" label="Current Travel (mins)">
                <InputNumber min={0} className="w-full!" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="risk_score" label="Risk Score (0–1)">
                <InputNumber min={0} max={1} step={0.01} className="w-full!" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="reason" label="Reason">
            <Select
              options={[
                { value: 'flood', label: 'Flood' },
                { value: 'recede', label: 'Water receded' },
                { value: 'ml_prediction', label: 'ML prediction' },
                { value: 'manual_override', label: 'Manual override' },
                { value: 'chaos_engine', label: 'Chaos engine' },
              ]}
            />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
