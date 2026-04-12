'use client';

import {
  AlertOutlined,
  BankOutlined,
  CheckCircleOutlined,
  EnvironmentOutlined,
  HomeOutlined,
  MedicineBoxOutlined,
  ReloadOutlined,
  SearchOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import {
  Alert,
  Button,
  Card,
  Col,
  Input,
  Progress,
  Row,
  Select,
  Skeleton,
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

function LocationCard({ loc }: { loc: Location }) {
  const occupancyPct =
    loc.max_capacity > 0 ? Math.round((loc.current_occupancy / loc.max_capacity) * 100) : 0;

  const occupancyColor =
    occupancyPct >= 90 ? '#f04438' : occupancyPct >= 70 ? '#f79009' : '#17b26a';

  return (
    <Card
      size="small"
      className={`h-full transition-shadow hover:shadow-dd-md! ${loc.is_flooded ? 'border-dd-red-300!' : ''}`}
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
        </div>
      </div>

      {/* Coordinates */}
      <div className="flex items-center gap-1 mb-3">
        <EnvironmentOutlined className="text-dd-gray-400 text-xs" />
        <Text className="text-dd-gray-500! font-mono text-xs">
          {parseFloat(loc.lat).toFixed(4)}, {parseFloat(loc.lng).toFixed(4)}
        </Text>
      </div>

      {/* Occupancy */}
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

      {/* Contact */}
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
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<LocationType | 'all'>('all');
  const [floodFilter, setFloodFilter] = useState<'all' | 'flooded' | 'clear'>('all');

  const { data, isLoading, isError, refetch, dataUpdatedAt } = useQuery<Location[]>({
    queryKey: ['locations'],
    queryFn: () => api.get<Location[]>('/locations').then(r => r.data),
    refetchInterval: 60_000,
    staleTime: 30_000,
  });

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
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            Operations Map
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated ? `Updated ${lastUpdated} · auto-refreshes every 60s` : 'Loading…'}
          </Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
          Refresh
        </Button>
      </div>

      {/* Flood alert */}
      {floodedCount > 0 && (
        <Alert
          icon={<WarningOutlined />}
          message={`${floodedCount} location${floodedCount > 1 ? 's' : ''} currently flooded`}
          description="Flooded locations may have restricted access — plan alternative routes."
          type="warning"
          showIcon
          className="mb-4!"
        />
      )}

      {isError && (
        <Alert message="Failed to load locations." type="error" showIcon className="mb-4" />
      )}

      {/* Legend + summary */}
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

      {/* Filters */}
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

      {/* Location grid */}
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
              <LocationCard loc={loc} />
            </Col>
          ))}
        </Row>
      )}
    </div>
  );
}
