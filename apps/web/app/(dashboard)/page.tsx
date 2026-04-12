'use client';

import {
  AlertOutlined,
  CarOutlined,
  CheckCircleOutlined,
  ClockCircleOutlined,
  DeploymentUnitOutlined,
  EnvironmentOutlined,
  ExclamationCircleOutlined,
  ReloadOutlined,
  RocketOutlined,
  WarningOutlined,
  WifiOutlined,
} from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import {
  Alert,
  Badge,
  Button,
  Card,
  Col,
  Progress,
  Row,
  Skeleton,
  Statistic,
  Tag,
  Typography,
} from 'antd';

import { api } from '@/lib/api';
import type { DashboardStats } from '@/types';

const { Title, Text } = Typography;

function StatCard({
  title,
  value,
  suffix,
  icon,
  color,
  loading,
}: {
  title: string;
  value: number;
  suffix?: string;
  icon: React.ReactNode;
  color: string;
  loading: boolean;
}) {
  return (
    <Card className="h-full">
      <div className="flex items-start justify-between">
        <div className="flex-1 min-w-0">
          <Text className="!text-dd-gray-500 text-sm block mb-1">{title}</Text>
          {loading ? (
            <Skeleton.Input active size="large" className="!w-20" />
          ) : (
            <Statistic
              value={value}
              suffix={suffix}
              styles={{ content: { color, fontSize: 28 } }}
            />
          )}
        </div>
        <div
          className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ml-3"
          style={{ backgroundColor: `${color}18` }}
        >
          <span style={{ color, fontSize: 18 }}>{icon}</span>
        </div>
      </div>
    </Card>
  );
}

export default function OverviewPage() {
  const {
    data: stats,
    isLoading,
    isError,
    refetch,
    dataUpdatedAt,
  } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats'],
    queryFn: () => api.get<DashboardStats>('/dashboard').then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  return (
    <div>
      {/* Page header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="!mb-0">
            Operations Overview
          </Title>
          <Text className="!text-dd-gray-500 text-sm">
            {lastUpdated ? `Last updated ${lastUpdated} · auto-refreshes every 30s` : 'Loading…'}
          </Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
          Refresh
        </Button>
      </div>

      {/* SLA breach alert */}
      {!isLoading && !!stats?.missions.sla_breached && (
        <Alert
          icon={<AlertOutlined />}
          message={`${stats.missions.sla_breached} mission${stats.missions.sla_breached > 1 ? 's' : ''} have breached SLA`}
          description="Open the Triage Queue to review and preempt affected deliveries."
          type="error"
          showIcon
          action={
            <Button size="small" danger href="/triage">
              View Triage
            </Button>
          }
          className="mb-6"
        />
      )}

      {/* Critical low stock alert */}
      {!isLoading && !!stats?.inventory.critical_items_low && (
        <Alert
          icon={<ExclamationCircleOutlined />}
          message={`${stats.inventory.critical_items_low} critical P0 supply item${stats.inventory.critical_items_low > 1 ? 's' : ''} below threshold`}
          type="warning"
          showIcon
          action={
            <Button size="small" href="/supply">
              View Supply
            </Button>
          }
          className="mb-6"
        />
      )}

      {isError && (
        <Alert
          message="Failed to load stats. Check API connectivity."
          type="error"
          showIcon
          className="mb-6"
        />
      )}

      {/* ── Stat cards ────────────────────────────────────────── */}
      <Row gutter={[16, 16]} className="mb-6">
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Active Missions"
            value={stats?.missions.active ?? 0}
            icon={<RocketOutlined />}
            color="#2563eb"
            loading={isLoading}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Vehicles In-Mission"
            value={stats?.vehicles.in_mission ?? 0}
            suffix={`/ ${stats?.vehicles.total ?? 0}`}
            icon={<CarOutlined />}
            color="#17b26a"
            loading={isLoading}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="Flooded Locations"
            value={stats?.locations.flooded ?? 0}
            suffix={`/ ${stats?.locations.total ?? 0}`}
            icon={<EnvironmentOutlined />}
            color="#f79009"
            loading={isLoading}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatCard
            title="SLA Breaches"
            value={stats?.missions.sla_breached ?? 0}
            icon={<WarningOutlined />}
            color="#f04438"
            loading={isLoading}
          />
        </Col>
      </Row>

      {/* ── Secondary metrics ─────────────────────────────────── */}
      <Row gutter={[16, 16]}>
        {/* Missions breakdown */}
        <Col xs={24} lg={8}>
          <Card
            title={
              <span>
                <RocketOutlined className="mr-2 text-dd-primary-500" />
                Mission Status
              </span>
            }
            className="h-full"
          >
            {isLoading ? (
              <Skeleton active paragraph={{ rows: 4 }} />
            ) : (
              <div className="space-y-3">
                {[
                  {
                    label: 'Active',
                    value: stats?.missions.active ?? 0,
                    total: stats?.missions.total ?? 1,
                    color: '#2563eb',
                  },
                  {
                    label: 'Completed',
                    value: stats?.missions.completed ?? 0,
                    total: stats?.missions.total ?? 1,
                    color: '#17b26a',
                  },
                  {
                    label: 'Planned',
                    value: stats?.missions.planned ?? 0,
                    total: stats?.missions.total ?? 1,
                    color: '#6366f1',
                  },
                  {
                    label: 'SLA Breached',
                    value: stats?.missions.sla_breached ?? 0,
                    total: stats?.missions.total ?? 1,
                    color: '#f04438',
                  },
                ].map(({ label, value, total, color }) => (
                  <div key={label}>
                    <div className="flex justify-between mb-1">
                      <Text className="text-sm !text-dd-gray-700">{label}</Text>
                      <Text className="text-sm font-semibold">{value}</Text>
                    </div>
                    <Progress
                      percent={total > 0 ? Math.round((value / total) * 100) : 0}
                      strokeColor={color}
                      showInfo={false}
                      size="small"
                    />
                  </div>
                ))}
              </div>
            )}
          </Card>
        </Col>

        {/* Fleet status */}
        <Col xs={24} lg={8}>
          <Card
            title={
              <span>
                <CarOutlined className="mr-2 text-dd-primary-500" />
                Fleet Status
              </span>
            }
            className="h-full"
          >
            {isLoading ? (
              <Skeleton active paragraph={{ rows: 3 }} />
            ) : (
              <div className="space-y-3">
                <div className="flex items-center justify-between py-2 border-b border-dd-gray-100">
                  <div className="flex items-center gap-2">
                    <Badge status="processing" color="blue" />
                    <Text>In Mission</Text>
                  </div>
                  <Tag color="blue">{stats?.vehicles.in_mission ?? 0}</Tag>
                </div>
                <div className="flex items-center justify-between py-2 border-b border-dd-gray-100">
                  <div className="flex items-center gap-2">
                    <Badge status="success" />
                    <Text>Idle</Text>
                  </div>
                  <Tag color="green">{stats?.vehicles.idle ?? 0}</Tag>
                </div>
                <div className="flex items-center justify-between py-2">
                  <div className="flex items-center gap-2">
                    <Badge status="default" />
                    <Text>Offline</Text>
                  </div>
                  <Tag>{stats?.vehicles.offline ?? 0}</Tag>
                </div>
              </div>
            )}
          </Card>
        </Col>

        {/* Mesh + Triage */}
        <Col xs={24} lg={8}>
          <Card
            title={
              <span>
                <WifiOutlined className="mr-2 text-dd-primary-500" />
                Mesh & Triage
              </span>
            }
            className="h-full"
          >
            {isLoading ? (
              <Skeleton active paragraph={{ rows: 4 }} />
            ) : (
              <div className="space-y-4">
                <div>
                  <Text className="!text-dd-gray-500 text-xs uppercase tracking-wide">
                    Mesh Messages
                  </Text>
                  <div className="flex items-center justify-between mt-2">
                    <div className="flex items-center gap-2">
                      <ClockCircleOutlined className="text-dd-warning-500" />
                      <Text className="text-sm">Pending delivery</Text>
                    </div>
                    <Tag color="orange">{stats?.mesh_messages.pending ?? 0}</Tag>
                  </div>
                  <div className="flex items-center justify-between mt-2">
                    <div className="flex items-center gap-2">
                      <CheckCircleOutlined className="text-dd-success-500" />
                      <Text className="text-sm">Last 24h</Text>
                    </div>
                    <Tag color="green">{stats?.mesh_messages.total_24h ?? 0}</Tag>
                  </div>
                </div>

                <div className="border-t border-dd-gray-100 pt-4">
                  <Text className="!text-dd-gray-500 text-xs uppercase tracking-wide">
                    Triage Decisions
                  </Text>
                  <div className="flex items-center justify-between mt-2">
                    <div className="flex items-center gap-2">
                      <DeploymentUnitOutlined className="text-dd-primary-500" />
                      <Text className="text-sm">Last 24h</Text>
                    </div>
                    <Tag color="blue">{stats?.triage_decisions.last_24h ?? 0}</Tag>
                  </div>
                </div>
              </div>
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
}
