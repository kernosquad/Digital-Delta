'use client';

import { ExclamationCircleOutlined, ReloadOutlined, SearchOutlined } from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import { Alert, Badge, Button, Input, Select, Skeleton, Table, Tag, Typography } from 'antd';
import { useMemo, useState } from 'react';

import { api } from '@/lib/api';
import type { InventoryRow, PriorityClass } from '@/types';

const { Title, Text } = Typography;

const PRIORITY_LABELS: Record<PriorityClass, string> = {
  p0_critical: 'P0 Critical',
  p1_high: 'P1 High',
  p2_standard: 'P2 Standard',
  p3_low: 'P3 Low',
};

const PRIORITY_COLORS: Record<PriorityClass, string> = {
  p0_critical: 'red',
  p1_high: 'orange',
  p2_standard: 'blue',
  p3_low: 'default',
};

const LOW_STOCK_THRESHOLD = 10;

export default function SupplyPage() {
  const [search, setSearch] = useState('');
  const [priorityFilter, setPriorityFilter] = useState<PriorityClass | 'all'>('all');

  const { data, isLoading, isError, refetch, dataUpdatedAt } = useQuery<InventoryRow[]>({
    queryKey: ['inventory'],
    queryFn: () => api.get<InventoryRow[]>('/supply/inventory').then(r => r.data),
    refetchInterval: 60_000,
    staleTime: 30_000,
  });

  const rows = useMemo(() => {
    if (!data) return [];
    return data.filter(row => {
      const matchesPriority = priorityFilter === 'all' || row.priority_class === priorityFilter;
      const term = search.toLowerCase();
      const matchesSearch =
        !term ||
        row.item.toLowerCase().includes(term) ||
        row.location.toLowerCase().includes(term) ||
        row.node_code.toLowerCase().includes(term) ||
        row.category.toLowerCase().includes(term);
      return matchesPriority && matchesSearch;
    });
  }, [data, search, priorityFilter]);

  const criticalLow = rows.filter(
    r =>
      r.priority_class === 'p0_critical' && r.quantity - r.reserved_quantity < LOW_STOCK_THRESHOLD
  ).length;

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const columns = [
    {
      title: 'Location',
      dataIndex: 'location',
      key: 'location',
      render: (name: string, row: InventoryRow) => (
        <div>
          <div className="font-medium text-dd-gray-900">{name}</div>
          <div className="text-xs text-dd-gray-500 font-mono">{row.node_code}</div>
        </div>
      ),
      sorter: (a: InventoryRow, b: InventoryRow) => a.location.localeCompare(b.location),
    },
    {
      title: 'Item',
      dataIndex: 'item',
      key: 'item',
      render: (name: string, row: InventoryRow) => (
        <div>
          <div className="font-medium text-dd-gray-900">{name}</div>
          <div className="text-xs text-dd-gray-500 capitalize">{row.category}</div>
        </div>
      ),
      sorter: (a: InventoryRow, b: InventoryRow) => a.item.localeCompare(b.item),
    },
    {
      title: 'Priority',
      dataIndex: 'priority_class',
      key: 'priority_class',
      render: (p: PriorityClass) => <Tag color={PRIORITY_COLORS[p]}>{PRIORITY_LABELS[p]}</Tag>,
      sorter: (a: InventoryRow, b: InventoryRow) =>
        a.priority_class.localeCompare(b.priority_class),
    },
    {
      title: 'In Stock',
      dataIndex: 'quantity',
      key: 'quantity',
      render: (qty: number, row: InventoryRow) => {
        const available = qty - row.reserved_quantity;
        const isLow = available < LOW_STOCK_THRESHOLD;
        return (
          <div className="flex items-center gap-2">
            <span
              className={`font-semibold tabular-nums ${isLow ? 'text-dd-red-600' : 'text-dd-gray-900'}`}
            >
              {available}
            </span>
            <span className="text-dd-gray-400 text-xs">{row.unit}</span>
            {isLow && <Badge status="error" />}
          </div>
        );
      },
      sorter: (a: InventoryRow, b: InventoryRow) =>
        a.quantity - a.reserved_quantity - (b.quantity - b.reserved_quantity),
    },
    {
      title: 'Reserved',
      dataIndex: 'reserved_quantity',
      key: 'reserved_quantity',
      render: (qty: number, row: InventoryRow) => (
        <span className="text-dd-gray-500 tabular-nums">
          {qty} {row.unit}
        </span>
      ),
    },
    {
      title: 'Total',
      dataIndex: 'quantity',
      key: 'total',
      render: (qty: number, row: InventoryRow) => (
        <span className="text-dd-gray-500 tabular-nums">
          {qty} {row.unit}
        </span>
      ),
    },
  ];

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            Supply Inventory
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated ? `Updated ${lastUpdated} · auto-refreshes every 60s` : 'Loading…'}
          </Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
          Refresh
        </Button>
      </div>

      {/* Critical low stock alert */}
      {criticalLow > 0 && (
        <Alert
          icon={<ExclamationCircleOutlined />}
          message={`${criticalLow} P0 critical item${criticalLow > 1 ? 's' : ''} below ${LOW_STOCK_THRESHOLD} units`}
          description="These items need immediate resupply — check mission cargo assignments."
          type="error"
          showIcon
          className="mb-4"
        />
      )}

      {isError && (
        <Alert message="Failed to load inventory data." type="error" showIcon className="mb-4" />
      )}

      {/* Filters */}
      <div className="flex items-center gap-3 mb-4">
        <Input
          prefix={<SearchOutlined className="text-dd-gray-400" />}
          placeholder="Search item, location, category…"
          value={search}
          onChange={e => setSearch(e.target.value)}
          allowClear
          className="max-w-xs"
        />
        <Select
          value={priorityFilter}
          onChange={v => setPriorityFilter(v)}
          style={{ width: 160 }}
          options={[
            { value: 'all', label: 'All priorities' },
            { value: 'p0_critical', label: 'P0 Critical' },
            { value: 'p1_high', label: 'P1 High' },
            { value: 'p2_standard', label: 'P2 Standard' },
            { value: 'p3_low', label: 'P3 Low' },
          ]}
        />
        {rows.length > 0 && (
          <Text className="text-dd-gray-500! text-sm ml-auto">
            {rows.length} row{rows.length !== 1 ? 's' : ''}
          </Text>
        )}
      </div>

      {/* Table */}
      {isLoading ? (
        <Skeleton active paragraph={{ rows: 8 }} />
      ) : (
        <Table
          dataSource={rows}
          columns={columns}
          rowKey={(row, i) => `${row.node_code}-${row.item}-${i}`}
          pagination={{ pageSize: 20, showSizeChanger: true, showTotal: t => `${t} entries` }}
          size="middle"
          scroll={{ x: 700 }}
          rowClassName={row =>
            row.priority_class === 'p0_critical' &&
            row.quantity - row.reserved_quantity < LOW_STOCK_THRESHOLD
              ? 'bg-dd-red-25!'
              : ''
          }
        />
      )}
    </div>
  );
}
