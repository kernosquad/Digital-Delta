'use client';

import {
  ExclamationCircleOutlined,
  PlusOutlined,
  ReloadOutlined,
  SearchOutlined,
} from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Badge,
  Button,
  Form,
  Input,
  InputNumber,
  Modal,
  Select,
  Skeleton,
  Space,
  Table,
  Tag,
  Typography,
} from 'antd';
import { useMemo, useState } from 'react';

import { api } from '@/lib/api';
import type { InventoryRow, PriorityClass, SupplyCategory, SupplyItem } from '@/types';

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

const CATEGORY_COLORS: Record<SupplyCategory, string> = {
  medical: 'red',
  food: 'green',
  water: 'blue',
  shelter: 'purple',
  equipment: 'orange',
  other: 'default',
};

const LOW_STOCK_THRESHOLD = 10;

interface CreateItemBody {
  name: string;
  category: SupplyCategory;
  unit: string;
  weight_per_unit_kg: number;
  priority_class: PriorityClass;
  sla_hours: number;
}

export default function SupplyPage() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [priorityFilter, setPriorityFilter] = useState<PriorityClass | 'all'>('all');
  const [addItemOpen, setAddItemOpen] = useState(false);
  const [addItemForm] = Form.useForm<CreateItemBody>();

  const { data, isLoading, isError, refetch, dataUpdatedAt } = useQuery<InventoryRow[]>({
    queryKey: ['inventory'],
    queryFn: () => api.get<InventoryRow[]>('/supply/inventory').then(r => r.data),
    refetchInterval: 60_000,
    staleTime: 30_000,
  });

  const {
    data: items,
    isLoading: itemsLoading,
    refetch: refetchItems,
  } = useQuery<SupplyItem[]>({
    queryKey: ['supply-items'],
    queryFn: () => api.get<SupplyItem[]>('/supply/items').then(r => r.data),
    staleTime: 30_000,
  });

  const createItemMutation = useMutation({
    mutationFn: (body: CreateItemBody) =>
      api.post<SupplyItem>('/supply/items', body).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['supply-items'] });
      queryClient.invalidateQueries({ queryKey: ['inventory'] });
      setAddItemOpen(false);
      addItemForm.resetFields();
    },
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

  const inventoryColumns = [
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

  const itemColumns = [
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      render: (name: string) => <span className="font-medium text-dd-gray-900">{name}</span>,
    },
    {
      title: 'Category',
      dataIndex: 'category',
      key: 'category',
      render: (c: SupplyCategory) => <Tag color={CATEGORY_COLORS[c]}>{c}</Tag>,
    },
    {
      title: 'Unit',
      dataIndex: 'unit',
      key: 'unit',
      render: (u: string) => <span className="text-dd-gray-600 text-sm">{u}</span>,
    },
    {
      title: 'Weight/unit',
      dataIndex: 'weight_per_unit_kg',
      key: 'weight',
      render: (w: number) => <span className="tabular-nums text-sm">{w} kg</span>,
    },
    {
      title: 'Priority',
      dataIndex: 'priority_class',
      key: 'priority',
      render: (p: PriorityClass) => <Tag color={PRIORITY_COLORS[p]}>{PRIORITY_LABELS[p]}</Tag>,
    },
    {
      title: 'SLA',
      dataIndex: 'sla_hours',
      key: 'sla',
      render: (h: number) => <span className="text-dd-gray-600 text-sm">{h}h</span>,
    },
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      render: (id: number) => (
        <span className="font-mono text-xs text-dd-gray-400 select-all">#{id}</span>
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
        <Space>
          <Button
            icon={<ReloadOutlined />}
            onClick={() => {
              refetch();
              refetchItems();
            }}
            loading={isLoading}
          >
            Refresh
          </Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setAddItemOpen(true)}>
            Add Supply Item
          </Button>
        </Space>
      </div>

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

      {/* Inventory filters */}
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

      {/* Inventory table */}
      {isLoading ? (
        <Skeleton active paragraph={{ rows: 8 }} />
      ) : (
        <Table
          dataSource={rows}
          columns={inventoryColumns}
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
          className="mb-8"
        />
      )}

      {/* Supply Items catalog */}
      <div className="flex items-center justify-between mb-3">
        <Title level={5} className="mb-0!">
          Supply Item Catalog
        </Title>
        <Text className="text-dd-gray-500! text-xs">IDs are used in mission cargo assignments</Text>
      </div>
      {itemsLoading ? (
        <Skeleton active paragraph={{ rows: 4 }} />
      ) : (
        <Table
          dataSource={items ?? []}
          columns={itemColumns}
          rowKey="id"
          size="small"
          pagination={{ pageSize: 10, showSizeChanger: true }}
          scroll={{ x: 600 }}
        />
      )}

      {/* ── Add Supply Item Modal ──────────────────────────────── */}
      <Modal
        title="Add Supply Item"
        open={addItemOpen}
        onCancel={() => {
          setAddItemOpen(false);
          addItemForm.resetFields();
        }}
        onOk={() => addItemForm.submit()}
        okText="Create Item"
        confirmLoading={createItemMutation.isPending}
        destroyOnClose
        width={480}
      >
        <Form form={addItemForm} layout="vertical" onFinish={v => createItemMutation.mutate(v)}>
          <Form.Item name="name" label="Item Name" rules={[{ required: true }]}>
            <Input placeholder="e.g. Oral Rehydration Salts" />
          </Form.Item>
          <div className="flex gap-3">
            <Form.Item
              name="category"
              label="Category"
              rules={[{ required: true }]}
              className="flex-1"
            >
              <Select
                options={[
                  { value: 'medical', label: 'Medical' },
                  { value: 'food', label: 'Food' },
                  { value: 'water', label: 'Water' },
                  { value: 'shelter', label: 'Shelter' },
                  { value: 'equipment', label: 'Equipment' },
                  { value: 'other', label: 'Other' },
                ]}
              />
            </Form.Item>
            <Form.Item name="unit" label="Unit" rules={[{ required: true }]} className="w-28">
              <Input placeholder="packs" />
            </Form.Item>
          </div>
          <div className="flex gap-3">
            <Form.Item
              name="weight_per_unit_kg"
              label="Weight/unit (kg)"
              rules={[{ required: true }]}
              className="flex-1"
            >
              <InputNumber min={0} step={0.1} className="w-full!" placeholder="0.5" />
            </Form.Item>
            <Form.Item
              name="sla_hours"
              label="SLA Hours"
              rules={[{ required: true }]}
              className="flex-1"
            >
              <InputNumber min={1} className="w-full!" placeholder="2" />
            </Form.Item>
          </div>
          <Form.Item name="priority_class" label="Priority Class" rules={[{ required: true }]}>
            <Select
              options={[
                { value: 'p0_critical', label: 'P0 Critical' },
                { value: 'p1_high', label: 'P1 High' },
                { value: 'p2_standard', label: 'P2 Standard' },
                { value: 'p3_low', label: 'P3 Low' },
              ]}
            />
          </Form.Item>
          {createItemMutation.isError && (
            <Alert message="Failed to create supply item." type="error" showIcon />
          )}
        </Form>
      </Modal>
    </div>
  );
}
