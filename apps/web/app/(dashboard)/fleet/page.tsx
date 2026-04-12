'use client';

import {
  CarOutlined,
  DeploymentUnitOutlined,
  ReloadOutlined,
  RocketOutlined,
  SearchOutlined,
} from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import {
  Alert,
  Badge,
  Button,
  Card,
  Col,
  Input,
  Row,
  Select,
  Skeleton,
  Statistic,
  Table,
  Tag,
  Typography,
} from 'antd';
import { useMemo, useState } from 'react';

import { api } from '@/lib/api';
import type { Vehicle, VehicleStatus, VehicleType } from '@/types';

const { Title, Text } = Typography;

const TYPE_ICONS: Record<VehicleType, React.ReactNode> = {
  truck: <CarOutlined />,
  boat: '⛵',
  drone: <DeploymentUnitOutlined />,
  motorcycle: '🏍',
  helicopter: '🚁',
};

const STATUS_CONFIG: Record<
  VehicleStatus,
  { color: string; badge: 'processing' | 'success' | 'default' | 'error'; label: string }
> = {
  in_mission: { color: 'blue', badge: 'processing', label: 'In Mission' },
  idle: { color: 'green', badge: 'success', label: 'Idle' },
  offline: { color: 'default', badge: 'default', label: 'Offline' },
  maintenance: { color: 'orange', badge: 'error', label: 'Maintenance' },
};

export default function FleetPage() {
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<VehicleType | 'all'>('all');
  const [statusFilter, setStatusFilter] = useState<VehicleStatus | 'all'>('all');

  const { data, isLoading, isError, refetch, dataUpdatedAt } = useQuery<Vehicle[]>({
    queryKey: ['vehicles'],
    queryFn: () => api.get<Vehicle[]>('/vehicles').then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const vehicles = useMemo(() => {
    if (!data) return [];
    return data.filter(v => {
      const matchesType = typeFilter === 'all' || v.type === typeFilter;
      const matchesStatus = statusFilter === 'all' || v.status === statusFilter;
      const term = search.toLowerCase();
      const matchesSearch = !term || v.name.toLowerCase().includes(term);
      return matchesType && matchesStatus && matchesSearch;
    });
  }, [data, search, typeFilter, statusFilter]);

  const counts = useMemo(
    () => ({
      total: data?.length ?? 0,
      inMission: data?.filter(v => v.status === 'in_mission').length ?? 0,
      idle: data?.filter(v => v.status === 'idle').length ?? 0,
      offline: data?.filter(v => v.status === 'offline').length ?? 0,
    }),
    [data]
  );

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const columns = [
    {
      title: 'Vehicle',
      key: 'name',
      render: (_: unknown, v: Vehicle) => (
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-dd-gray-100 flex items-center justify-center text-dd-gray-600 text-base shrink-0">
            {TYPE_ICONS[v.type]}
          </div>
          <div>
            <div className="font-medium text-dd-gray-900">{v.name}</div>
            <div className="text-xs text-dd-gray-500 capitalize">{v.type}</div>
          </div>
        </div>
      ),
      sorter: (a: Vehicle, b: Vehicle) => a.name.localeCompare(b.name),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: VehicleStatus) => {
        const cfg = STATUS_CONFIG[status];
        return (
          <div className="flex items-center gap-2">
            <Badge status={cfg.badge} />
            <Tag color={cfg.color}>{cfg.label}</Tag>
          </div>
        );
      },
      sorter: (a: Vehicle, b: Vehicle) => a.status.localeCompare(b.status),
    },
    {
      title: 'Capacity',
      dataIndex: 'capacity_kg',
      key: 'capacity_kg',
      render: (kg: number | null) => (
        <span className="tabular-nums text-dd-gray-700">
          {kg != null ? kg.toLocaleString() : '—'} {kg != null ? 'kg' : ''}
        </span>
      ),
      sorter: (a: Vehicle, b: Vehicle) => (a.capacity_kg ?? 0) - (b.capacity_kg ?? 0),
    },
    {
      title: 'Last GPS',
      key: 'gps',
      render: (_: unknown, v: Vehicle) =>
        v.last_gps_lat && v.last_gps_lng ? (
          <div className="font-mono text-xs text-dd-gray-600">
            {parseFloat(v.last_gps_lat).toFixed(4)}, {parseFloat(v.last_gps_lng).toFixed(4)}
            {v.last_gps_at && (
              <div className="text-dd-gray-400 text-xs">
                {new Date(v.last_gps_at).toLocaleTimeString()}
              </div>
            )}
          </div>
        ) : (
          <Text className="text-dd-gray-400!">—</Text>
        ),
    },
    {
      title: 'Notes',
      dataIndex: 'notes',
      key: 'notes',
      render: (notes: string | null) =>
        notes ? (
          <Text className="text-dd-gray-600! text-sm">{notes}</Text>
        ) : (
          <Text className="text-dd-gray-400!">—</Text>
        ),
      ellipsis: true,
    },
  ];

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            Fleet & Drones
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated ? `Updated ${lastUpdated} · auto-refreshes every 30s` : 'Loading…'}
          </Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
          Refresh
        </Button>
      </div>

      {isError && (
        <Alert message="Failed to load fleet data." type="error" showIcon className="mb-4" />
      )}

      {/* Summary cards */}
      <Row gutter={[16, 16]} className="mb-6">
        <Col xs={12} sm={6}>
          <Card>
            {isLoading ? (
              <Skeleton.Input active />
            ) : (
              <Statistic
                title="Total Fleet"
                value={counts.total}
                prefix={<CarOutlined />}
                styles={{ content: { color: '#374151' } }}
              />
            )}
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            {isLoading ? (
              <Skeleton.Input active />
            ) : (
              <Statistic
                title="In Mission"
                value={counts.inMission}
                prefix={<RocketOutlined />}
                styles={{ content: { color: '#2563eb' } }}
              />
            )}
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            {isLoading ? (
              <Skeleton.Input active />
            ) : (
              <Statistic
                title="Idle"
                value={counts.idle}
                styles={{ content: { color: '#17b26a' } }}
              />
            )}
          </Card>
        </Col>
        <Col xs={12} sm={6}>
          <Card>
            {isLoading ? (
              <Skeleton.Input active />
            ) : (
              <Statistic
                title="Offline"
                value={counts.offline}
                styles={{ content: { color: '#98a2b3' } }}
              />
            )}
          </Card>
        </Col>
      </Row>

      {/* Filters */}
      <div className="flex items-center gap-3 mb-4 flex-wrap">
        <Input
          prefix={<SearchOutlined className="text-dd-gray-400" />}
          placeholder="Search vehicle name…"
          value={search}
          onChange={e => setSearch(e.target.value)}
          allowClear
          className="max-w-xs"
        />
        <Select
          value={typeFilter}
          onChange={v => setTypeFilter(v)}
          style={{ width: 140 }}
          options={[
            { value: 'all', label: 'All types' },
            { value: 'truck', label: 'Truck' },
            { value: 'boat', label: 'Boat' },
            { value: 'drone', label: 'Drone' },
            { value: 'motorcycle', label: 'Motorcycle' },
            { value: 'helicopter', label: 'Helicopter' },
          ]}
        />
        <Select
          value={statusFilter}
          onChange={v => setStatusFilter(v)}
          style={{ width: 150 }}
          options={[
            { value: 'all', label: 'All statuses' },
            { value: 'in_mission', label: 'In Mission' },
            { value: 'idle', label: 'Idle' },
            { value: 'offline', label: 'Offline' },
            { value: 'maintenance', label: 'Maintenance' },
          ]}
        />
        {vehicles.length > 0 && (
          <Text className="text-dd-gray-500! text-sm ml-auto">
            {vehicles.length} vehicle{vehicles.length !== 1 ? 's' : ''}
          </Text>
        )}
      </div>

      {/* Table */}
      {isLoading ? (
        <Skeleton active paragraph={{ rows: 6 }} />
      ) : (
        <Table
          dataSource={vehicles}
          columns={columns}
          rowKey="id"
          pagination={{ pageSize: 15, showSizeChanger: true }}
          size="middle"
          scroll={{ x: 600 }}
          className="pagination"
        />
      )}
    </div>
  );
}
