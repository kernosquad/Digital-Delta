'use client';

import {
  CheckCircleOutlined,
  ClockCircleOutlined,
  ExclamationCircleOutlined,
  FireOutlined,
  ReloadOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import {
  Alert,
  Badge,
  Button,
  Card,
  Col,
  Row,
  Skeleton,
  Table,
  Tag,
  Timeline,
  Typography,
} from 'antd';

import { api } from '@/lib/api';
import type { Mission, PriorityClass, TriageDecision } from '@/types';

const { Title, Text } = Typography;

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

function SlaTag({ deadline, breached, now }: { deadline: string; breached: boolean; now: number }) {
  const ms = new Date(deadline).getTime() - now;
  const mins = Math.round(ms / 60_000);

  if (breached || ms < 0) {
    return (
      <Tag color="red" icon={<FireOutlined />}>
        SLA Breached
      </Tag>
    );
  }
  if (mins < 30) {
    return (
      <Tag color="red" icon={<WarningOutlined />}>
        {mins}m left
      </Tag>
    );
  }
  if (mins < 120) {
    return (
      <Tag color="orange" icon={<ClockCircleOutlined />}>
        {mins}m left
      </Tag>
    );
  }
  const hrs = Math.floor(mins / 60);
  return (
    <Tag color="green" icon={<CheckCircleOutlined />}>
      {hrs}h left
    </Tag>
  );
}

export default function TriagePage() {
  const [renderNow] = useState<number>(Date.now);

  const {
    data: decisions,
    isLoading: decisionsLoading,
    isError: decisionsError,
    refetch: refetchDecisions,
    dataUpdatedAt,
  } = useQuery<TriageDecision[]>({
    queryKey: ['triage-decisions'],
    queryFn: () => api.get<TriageDecision[]>('/triage/decisions').then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const { data: activeMissions, isLoading: missionsLoading } = useQuery<Mission[]>({
    queryKey: ['missions-active'],
    queryFn: () =>
      api.get<Mission[]>('/missions', { params: { status: 'active' } }).then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const breachedMissions = activeMissions?.filter(m => m.sla_breached) ?? [];
  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const missionColumns = [
    {
      title: 'Mission',
      key: 'mission',
      render: (_: unknown, m: Mission) => (
        <div>
          <div className="font-medium font-mono text-dd-gray-900 text-sm">{m.mission_code}</div>
          <div className="text-xs text-dd-gray-500">
            {m.origin_name} → {m.destination_name}
          </div>
        </div>
      ),
    },
    {
      title: 'Priority',
      dataIndex: 'priority_class',
      key: 'priority',
      render: (p: PriorityClass) => <Tag color={PRIORITY_COLORS[p]}>{PRIORITY_LABELS[p]}</Tag>,
    },
    {
      title: 'Vehicle',
      dataIndex: 'vehicle_name',
      key: 'vehicle',
      render: (name: string, m: Mission) => (
        <span className="text-dd-gray-700 capitalize">
          {name} ({m.vehicle_type})
        </span>
      ),
    },
    {
      title: 'SLA',
      key: 'sla',
      render: (_: unknown, m: Mission) => (
        <SlaTag deadline={m.sla_deadline} breached={m.sla_breached} now={renderNow} />
      ),
    },
    {
      title: 'Deadline',
      dataIndex: 'sla_deadline',
      key: 'deadline',
      render: (d: string) => (
        <span className="tabular-nums text-xs text-dd-gray-600">
          {new Date(d).toLocaleString()}
        </span>
      ),
    },
  ];

  const timelineItems = (decisions ?? []).slice(0, 20).map(d => ({
    key: d.id,
    color: d.triggered_by === 'priority_preemption' ? 'red' : 'blue',
    dot: d.triggered_by === 'priority_preemption' ? <WarningOutlined /> : <CheckCircleOutlined />,
    children: (
      <div className="pb-2">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="font-mono text-sm font-medium text-dd-gray-900">{d.mission_code}</span>
          <Tag
            color={d.triggered_by === 'priority_preemption' ? 'red' : 'blue'}
            className="text-xs"
          >
            {d.triggered_by.replace(/_/g, ' ')}
          </Tag>
          {d.preempted_mission_id && (
            <Text className="text-dd-gray-500! text-xs">
              preempted mission #{d.preempted_mission_id}
            </Text>
          )}
        </div>
        <div className="text-sm text-dd-gray-600 mt-1 max-w-lg">{d.rationale}</div>
        <div className="text-xs text-dd-gray-400 mt-1">
          {new Date(d.created_at).toLocaleString()}
        </div>
      </div>
    ),
  }));

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            Triage Queue
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated ? `Updated ${lastUpdated} · auto-refreshes every 30s` : 'Loading…'}
          </Text>
        </div>
        <Button
          icon={<ReloadOutlined />}
          onClick={() => refetchDecisions()}
          loading={decisionsLoading}
        >
          Refresh
        </Button>
      </div>

      {/* Breach alert */}
      {breachedMissions.length > 0 && (
        <Alert
          icon={<FireOutlined />}
          message={`${breachedMissions.length} active mission${breachedMissions.length > 1 ? 's' : ''} have breached SLA`}
          description={breachedMissions.map(m => m.mission_code).join(', ')}
          type="error"
          showIcon
          className="mb-4!"
        />
      )}

      {decisionsError && (
        <Alert message="Failed to load triage data." type="error" showIcon className="mb-4!" />
      )}

      <Row gutter={[16, 16]}>
        {/* Active missions SLA monitor */}
        <Col xs={24} lg={14}>
          <Card
            title={
              <span className="flex items-center gap-2">
                <ExclamationCircleOutlined className="text-dd-warning-500" />
                Active Missions — SLA Monitor
                {activeMissions && <Badge count={activeMissions.length} color="#2563eb" />}
              </span>
            }
          >
            {missionsLoading ? (
              <Skeleton active paragraph={{ rows: 5 }} />
            ) : activeMissions?.length === 0 ? (
              <div className="py-8 text-center">
                <CheckCircleOutlined className="text-3xl text-dd-success-500 mb-2 block" />
                <Text className="text-dd-gray-500!">No active missions</Text>
              </div>
            ) : (
              <Table
                dataSource={activeMissions}
                columns={missionColumns}
                rowKey="id"
                pagination={false}
                size="small"
                scroll={{ x: 550 }}
                rowClassName={m => (m.sla_breached ? 'bg-dd-red-25!' : '')}
              />
            )}
          </Card>
        </Col>

        {/* Decision log */}
        <Col xs={24} lg={10}>
          <Card
            title={
              <span className="flex items-center gap-2">
                <ClockCircleOutlined className="text-dd-primary-500" />
                Decision Log
              </span>
            }
            style={{ height: '100%' }}
          >
            {decisionsLoading ? (
              <Skeleton active paragraph={{ rows: 6 }} />
            ) : !decisions?.length ? (
              <div className="py-8 text-center">
                <Text className="text-dd-gray-500!">No triage decisions yet</Text>
              </div>
            ) : (
              <div className="max-h-96 overflow-y-auto pr-1">
                <Timeline items={timelineItems} />
              </div>
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
}
