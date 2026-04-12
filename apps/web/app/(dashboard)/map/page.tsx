'use client';

import {
  AlertOutlined,
  BankOutlined,
  CheckCircleOutlined,
  EditOutlined,
  EnvironmentOutlined,
  HomeOutlined,
  MedicineBoxOutlined,
  PlusOutlined,
  ReloadOutlined,
  SearchOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Button,
  Card,
  Col,
  Drawer,
  Form,
  Input,
  InputNumber,
  Modal,
  Progress,
  Row,
  Select,
  Skeleton,
  Switch,
  Tag,
  Tooltip,
  Typography,
} from 'antd';
import { useMemo, useState } from 'react';

import { api } from '@/lib/api';
import type { Location, LocationType } from '@/types';

const { Title, Text } = Typography;

const TYPE_ICONS: Record<LocationType, React.ReactNode> = {
  camp: <HomeOutlined />,
  hospital: <MedicineBoxOutlined />,
  warehouse: <BankOutlined />,
  checkpoint: <EnvironmentOutlined />,
  staging: <EnvironmentOutlined />,
};

const TYPE_COLORS: Record<LocationType, string> = {
  camp: 'green',
  hospital: 'red',
  warehouse: 'blue',
  checkpoint: 'orange',
  staging: 'purple',
};

interface UpdateStatusBody {
  is_flooded?: boolean;
  is_active?: boolean;
  current_occupancy?: number;
}

interface CreateLocationBody {
  node_code: string;
  name: string;
  type: string;
  latitude: number;
  longitude: number;
  capacity?: number;
  notes?: string;
}

function LocationCard({ loc, onEdit }: { loc: Location; onEdit: (loc: Location) => void }) {
  const occupancyPct =
    loc.max_capacity > 0 ? Math.round((loc.current_occupancy / loc.max_capacity) * 100) : 0;

  const occupancyColor =
    occupancyPct >= 90 ? '#f04438' : occupancyPct >= 70 ? '#f79009' : '#17b26a';

  return (
    <Card
      size="small"
      className={`h-full transition-shadow hover:shadow-dd-md! ${loc.is_flooded ? 'border-dd-red-300!' : ''}`}
      extra={
        <Button
          type="text"
          size="small"
          icon={<EditOutlined />}
          onClick={() => onEdit(loc)}
          className="text-dd-gray-400! hover:text-dd-primary-600!"
        />
      }
    >
      <div className="flex items-start justify-between gap-2 mb-3">
        <div className="flex items-center gap-2 min-w-0">
          <div
            className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 text-sm
            ${loc.is_flooded ? 'bg-dd-red-50 text-dd-red-600' : 'bg-dd-primary-50 text-dd-primary-600'}`}
          >
            {TYPE_ICONS[loc.type]}
          </div>
          <div className="min-w-0">
            <div className="font-semibold text-dd-gray-900 text-sm leading-tight truncate">
              {loc.name}
            </div>
            <div className="font-mono text-xs text-dd-gray-500">{loc.node_code}</div>
          </div>
        </div>
        <div className="flex flex-col items-end gap-1 shrink-0">
          <Tag color={TYPE_COLORS[loc.type]} className="text-xs capitalize">
            {loc.type}
          </Tag>
          {loc.is_flooded && (
            <Tag color="red" icon={<AlertOutlined />} className="text-xs">
              FLOODED
            </Tag>
          )}
          {!loc.is_active && (
            <Tag color="default" className="text-xs">
              Inactive
            </Tag>
          )}
        </div>
      </div>

      <div className="flex items-center gap-1 mb-3">
        <EnvironmentOutlined className="text-dd-gray-400 text-xs" />
        <Text className="text-dd-gray-500! font-mono text-xs">
          {parseFloat(loc.lat).toFixed(4)}, {parseFloat(loc.lng).toFixed(4)}
        </Text>
      </div>

      {loc.max_capacity > 0 && (
        <div className="mb-2">
          <div className="flex justify-between mb-1">
            <Text className="text-dd-gray-500! text-xs">Occupancy</Text>
            <Text className="text-xs font-semibold" style={{ color: occupancyColor }}>
              {loc.current_occupancy} / {loc.max_capacity}
            </Text>
          </div>
          <Progress
            percent={occupancyPct}
            strokeColor={occupancyColor}
            showInfo={false}
            size="small"
          />
        </div>
      )}

      {loc.contact_name && (
        <div className="mt-2 pt-2 border-t border-dd-gray-100">
          <Text className="text-dd-gray-500! text-xs">
            {loc.contact_name}
            {loc.contact_phone && <span className="ml-1 font-mono">· {loc.contact_phone}</span>}
          </Text>
        </div>
      )}
    </Card>
  );
}

export default function MapPage() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<LocationType | 'all'>('all');
  const [floodFilter, setFloodFilter] = useState<'all' | 'flooded' | 'clear'>('all');
  const [editTarget, setEditTarget] = useState<Location | null>(null);
  const [addDrawerOpen, setAddDrawerOpen] = useState(false);
  const [editForm] = Form.useForm<UpdateStatusBody>();
  const [addForm] = Form.useForm<CreateLocationBody>();

  const { data, isLoading, isError, refetch, dataUpdatedAt } = useQuery<Location[]>({
    queryKey: ['locations'],
    queryFn: () => api.get<Location[]>('/locations').then(r => r.data),
    refetchInterval: 60_000,
    staleTime: 30_000,
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateStatusBody }) =>
      api.patch(`/locations/${id}/status`, body).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['locations'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      setEditTarget(null);
      editForm.resetFields();
    },
  });

  const createMutation = useMutation({
    mutationFn: (body: CreateLocationBody) =>
      api.post<Location>('/locations', body).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['locations'] });
      setAddDrawerOpen(false);
      addForm.resetFields();
    },
  });

  const openEdit = (loc: Location) => {
    setEditTarget(loc);
    editForm.setFieldsValue({
      is_flooded: loc.is_flooded,
      is_active: loc.is_active,
      current_occupancy: loc.current_occupancy,
    });
  };

  const locations = useMemo(() => {
    if (!data) return [];
    return data.filter(loc => {
      const matchesType = typeFilter === 'all' || loc.type === typeFilter;
      const matchesFlood =
        floodFilter === 'all' ||
        (floodFilter === 'flooded' && loc.is_flooded) ||
        (floodFilter === 'clear' && !loc.is_flooded);
      const term = search.toLowerCase();
      const matchesSearch =
        !term ||
        loc.name.toLowerCase().includes(term) ||
        loc.node_code.toLowerCase().includes(term);
      return matchesType && matchesFlood && matchesSearch;
    });
  }, [data, search, typeFilter, floodFilter]);

  const floodedCount = data?.filter(l => l.is_flooded).length ?? 0;
  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            Operations Map
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated ? `Updated ${lastUpdated} · auto-refreshes every 60s` : 'Loading…'}
          </Text>
        </div>
        <div className="flex gap-2">
          <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
            Refresh
          </Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setAddDrawerOpen(true)}>
            Add Location
          </Button>
        </div>
      </div>

      {floodedCount > 0 && (
        <Alert
          icon={<WarningOutlined />}
          message={`${floodedCount} location${floodedCount > 1 ? 's' : ''} currently flooded`}
          description="Click the edit icon on any card to update flood status and occupancy."
          type="warning"
          showIcon
          className="mb-4!"
        />
      )}

      {isError && (
        <Alert message="Failed to load locations." type="error" showIcon className="mb-4" />
      )}

      <div className="flex items-center gap-3 mb-4 flex-wrap">
        {(['camp', 'hospital', 'warehouse', 'checkpoint', 'staging'] as LocationType[]).map(t => (
          <Tooltip key={t} title={`Filter by ${t}`}>
            <Tag
              color={typeFilter === t ? TYPE_COLORS[t] : 'default'}
              icon={TYPE_ICONS[t]}
              className="cursor-pointer capitalize"
              onClick={() => setTypeFilter(prev => (prev === t ? 'all' : t))}
            >
              {t} ({data?.filter(l => l.type === t).length ?? 0})
            </Tag>
          </Tooltip>
        ))}
      </div>

      <div className="flex items-center gap-3 mb-5 flex-wrap">
        <Input
          prefix={<SearchOutlined className="text-dd-gray-400" />}
          placeholder="Search location or code…"
          value={search}
          onChange={e => setSearch(e.target.value)}
          allowClear
          className="max-w-xs"
        />
        <Select
          value={floodFilter}
          onChange={v => setFloodFilter(v)}
          style={{ width: 150 }}
          options={[
            { value: 'all', label: 'All conditions' },
            { value: 'flooded', label: '🌊 Flooded' },
            { value: 'clear', label: '✅ Clear' },
          ]}
        />
        {locations.length > 0 && (
          <Text className="text-dd-gray-500! text-sm ml-auto">
            {locations.length} location{locations.length !== 1 ? 's' : ''}
          </Text>
        )}
      </div>

      {isLoading ? (
        <Row gutter={[16, 16]}>
          {Array.from({ length: 6 }).map((_, i) => (
            <Col key={i} xs={24} sm={12} lg={8} xl={6}>
              <Card>
                <Skeleton active paragraph={{ rows: 3 }} />
              </Card>
            </Col>
          ))}
        </Row>
      ) : locations.length === 0 ? (
        <div className="py-16 text-center">
          <CheckCircleOutlined className="text-4xl text-dd-gray-300 mb-3 block" />
          <Text className="text-dd-gray-500!">No locations match your filter</Text>
        </div>
      ) : (
        <Row gutter={[16, 16]}>
          {locations.map(loc => (
            <Col key={loc.id} xs={24} sm={12} lg={8} xl={6}>
              <LocationCard loc={loc} onEdit={openEdit} />
            </Col>
          ))}
        </Row>
      )}

      {/* ── Edit Status Modal ──────────────────────────────────── */}
      <Modal
        title={`Update: ${editTarget?.name ?? ''}`}
        open={!!editTarget}
        onCancel={() => {
          setEditTarget(null);
          editForm.resetFields();
        }}
        onOk={() => editForm.submit()}
        okText="Save Changes"
        confirmLoading={updateStatusMutation.isPending}
        destroyOnClose
      >
        <Form
          form={editForm}
          layout="vertical"
          onFinish={values => {
            if (!editTarget) return;
            updateStatusMutation.mutate({ id: editTarget.id, body: values });
          }}
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="is_flooded" label="Flooded" valuePropName="checked">
                <Switch checkedChildren="Flooded" unCheckedChildren="Clear" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="is_active" label="Active" valuePropName="checked">
                <Switch checkedChildren="Active" unCheckedChildren="Inactive" />
              </Form.Item>
            </Col>
          </Row>
          {editTarget && editTarget.max_capacity > 0 && (
            <Form.Item
              name="current_occupancy"
              label={`Current Occupancy (max: ${editTarget.max_capacity})`}
            >
              <InputNumber min={0} max={editTarget.max_capacity} className="w-full!" />
            </Form.Item>
          )}
        </Form>
        {updateStatusMutation.isError && (
          <Alert message="Update failed." type="error" showIcon className="mt-2" />
        )}
      </Modal>

      {/* ── Add Location Drawer ────────────────────────────────── */}
      <Drawer
        title="Add New Location"
        placement="right"
        width={440}
        open={addDrawerOpen}
        onClose={() => {
          setAddDrawerOpen(false);
          addForm.resetFields();
        }}
        footer={
          <div className="flex justify-end gap-2">
            <Button
              onClick={() => {
                setAddDrawerOpen(false);
                addForm.resetFields();
              }}
            >
              Cancel
            </Button>
            <Button
              type="primary"
              loading={createMutation.isPending}
              onClick={() => addForm.submit()}
            >
              Create Location
            </Button>
          </div>
        }
      >
        <Form form={addForm} layout="vertical" onFinish={v => createMutation.mutate(v)}>
          <Row gutter={12}>
            <Col span={10}>
              <Form.Item name="node_code" label="Node Code" rules={[{ required: true }]}>
                <Input placeholder="N7" style={{ textTransform: 'uppercase' }} />
              </Form.Item>
            </Col>
            <Col span={14}>
              <Form.Item name="type" label="Type" rules={[{ required: true }]}>
                <Select
                  options={[
                    { value: 'central_command', label: 'Central Command' },
                    { value: 'supply_drop', label: 'Supply Drop' },
                    { value: 'relief_camp', label: 'Relief Camp' },
                    { value: 'waypoint', label: 'Waypoint' },
                    { value: 'hospital', label: 'Hospital' },
                    { value: 'drone_base', label: 'Drone Base' },
                  ]}
                />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="name" label="Name" rules={[{ required: true }]}>
            <Input placeholder="Sunamganj Sadar Camp" />
          </Form.Item>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item name="latitude" label="Latitude" rules={[{ required: true }]}>
                <InputNumber
                  min={-90}
                  max={90}
                  step={0.0001}
                  className="w-full!"
                  placeholder="25.0658"
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="longitude" label="Longitude" rules={[{ required: true }]}>
                <InputNumber
                  min={-180}
                  max={180}
                  step={0.0001}
                  className="w-full!"
                  placeholder="91.4073"
                />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="capacity" label="Capacity">
            <InputNumber min={0} className="w-full!" placeholder="Max occupancy (optional)" />
          </Form.Item>
          <Form.Item name="notes" label="Notes">
            <Input.TextArea rows={2} placeholder="Optional notes" />
          </Form.Item>
          {createMutation.isError && (
            <Alert message="Failed to create location." type="error" showIcon />
          )}
        </Form>
      </Drawer>
    </div>
  );
}
