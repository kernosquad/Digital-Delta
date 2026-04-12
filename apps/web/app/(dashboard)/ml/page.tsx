'use client';

import {
  AlertOutlined,
  CheckCircleOutlined,
  FireOutlined,
  ReloadOutlined,
  RobotOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import { Alert, Button, Card, Col, Progress, Row, Skeleton, Tag, Timeline, Typography } from 'antd';
import { useMemo } from 'react';

import { api } from '@/lib/api';
import type { Mission, PriorityClass } from '@/types';

const { Title, Text } = Typography;

const PRIORITY_COLORS: Record<PriorityClass, string> = {
  p0_critical: '#f04438',
  p1_high: '#f79009',
  p2_standard: '#2563eb',
  p3_low: '#98a2b3',
};

const SLA_HOURS: Record<PriorityClass, number> = {
  p0_critical: 2,
  p1_high: 6,
  p2_standard: 24,
  p3_low: 72,
};

interface RiskAssessment {
  mission: Mission;
  slaRiskPct: number;
  riskLevel: 'critical' | 'high' | 'medium' | 'low';
  minsRemaining: number;
  recommendation: string;
}

function assessRisk(mission: Mission): RiskAssessment {
  const now = Date.now();
  const deadline = new Date(mission.sla_deadline).getTime();
  const slaHours = SLA_HOURS[mission.priority_class] ?? 24;
  const totalMs = slaHours * 60 * 60 * 1000;
  const msRemaining = deadline - now;
  const minsRemaining = Math.round(msRemaining / 60_000);
  const elapsedPct = Math.max(0, Math.min(100, ((totalMs - msRemaining) / totalMs) * 100));

  let riskLevel: RiskAssessment['riskLevel'];
  let recommendation: string;

  if (mission.sla_breached || msRemaining < 0) {
    riskLevel = 'critical';
    recommendation = 'SLA breached — escalate immediately and trigger triage preemption.';
  } else if (elapsedPct >= 80) {
    riskLevel = 'critical';
    recommendation =
      'High breach risk — reassign to idle vehicle or preempt lower-priority mission.';
  } else if (elapsedPct >= 60) {
    riskLevel = 'high';
    recommendation = 'Approaching SLA threshold — verify vehicle is on route, check for blockages.';
  } else if (elapsedPct >= 40) {
    riskLevel = 'medium';
    recommendation = 'Monitor closely — dispatch updates to field team.';
  } else {
    riskLevel = 'low';
    recommendation = 'On track — no action required.';
  }

  return { mission, slaRiskPct: Math.round(elapsedPct), riskLevel, minsRemaining, recommendation };
}

function RiskBadge({ level }: { level: RiskAssessment['riskLevel'] }) {
  const cfg = {
    critical: { color: 'red', icon: <FireOutlined />, label: 'Critical Risk' },
    high: { color: 'orange', icon: <WarningOutlined />, label: 'High Risk' },
    medium: { color: 'blue', icon: <AlertOutlined />, label: 'Medium Risk' },
    low: { color: 'green', icon: <CheckCircleOutlined />, label: 'Low Risk' },
  }[level];
  return (
    <Tag color={cfg.color} icon={cfg.icon}>
      {cfg.label}
    </Tag>
  );
}

export default function MlPage() {
  const {
    data: activeMissions,
    isLoading,
    isError,
    refetch,
    dataUpdatedAt,
  } = useQuery<Mission[]>({
    queryKey: ['missions-all-active'],
    queryFn: () =>
      api.get<Mission[]>('/missions', { params: { status: 'active' } }).then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const { data: plannedMissions } = useQuery<Mission[]>({
    queryKey: ['missions-planned'],
    queryFn: () =>
      api.get<Mission[]>('/missions', { params: { status: 'planned' } }).then(r => r.data),
    refetchInterval: 30_000,
    staleTime: 15_000,
  });

  const risks = useMemo(() => {
    const all = [...(activeMissions ?? []), ...(plannedMissions ?? [])];
    return all.map(assessRisk).sort((a, b) => b.slaRiskPct - a.slaRiskPct);
  }, [activeMissions, plannedMissions]);

  const criticalCount = risks.filter(r => r.riskLevel === 'critical').length;
  const highCount = risks.filter(r => r.riskLevel === 'high').length;

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const timelineItems = risks.slice(0, 8).map(r => ({
    key: r.mission.id,
    color:
      r.riskLevel === 'critical'
        ? 'red'
        : r.riskLevel === 'high'
          ? 'orange'
          : r.riskLevel === 'medium'
            ? 'blue'
            : 'green',
    children: (
      <div>
        <div className="flex items-center gap-2 flex-wrap mb-1">
          <span className="font-mono font-medium text-sm">{r.mission.mission_code}</span>
          <RiskBadge level={r.riskLevel} />
          <Tag color={PRIORITY_COLORS[r.mission.priority_class] as string} className="text-xs">
            {r.mission.priority_class.replace(/_/g, ' ').toUpperCase()}
          </Tag>
        </div>
        <div className="text-xs text-dd-gray-600 mb-1">{r.recommendation}</div>
        <div className="text-xs text-dd-gray-400">
          {r.minsRemaining > 0
            ? `${r.minsRemaining >= 60 ? `${Math.floor(r.minsRemaining / 60)}h ${r.minsRemaining % 60}m` : `${r.minsRemaining}m`} remaining`
            : `Overdue by ${Math.abs(r.minsRemaining)}m`}
          {' · '}
          {r.mission.origin_name} → {r.mission.destination_name}
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
            <RobotOutlined className="mr-2 text-dd-primary-500" />
            ML Risk Predictions
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated
              ? `SLA breach risk analysis · updated ${lastUpdated}`
              : 'Analyzing mission risk profiles…'}
          </Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
          Refresh
        </Button>
      </div>

      {(criticalCount > 0 || highCount > 0) && (
        <Alert
          icon={<FireOutlined />}
          message={`${criticalCount} critical + ${highCount} high-risk missions detected`}
          description="Immediate attention required to prevent SLA breaches."
          type="error"
          showIcon
          className="mb-4"
        />
      )}

      {isError && (
        <Alert message="Failed to load mission data." type="error" showIcon className="mb-4" />
      )}

      <Row gutter={[16, 16]}>
        {/* Risk summary */}
        <Col xs={24} lg={8}>
          <Card title="Risk Distribution" className="h-full">
            {isLoading ? (
              <Skeleton active paragraph={{ rows: 5 }} />
            ) : (
              <div className="space-y-4">
                {(
                  [
                    { level: 'critical', label: 'Critical Risk', color: '#f04438' },
                    { level: 'high', label: 'High Risk', color: '#f79009' },
                    { level: 'medium', label: 'Medium Risk', color: '#2563eb' },
                    { level: 'low', label: 'Low Risk', color: '#17b26a' },
                  ] as const
                ).map(({ level, label, color }) => {
                  const count = risks.filter(r => r.riskLevel === level).length;
                  const pct = risks.length > 0 ? Math.round((count / risks.length) * 100) : 0;
                  return (
                    <div key={level}>
                      <div className="flex justify-between mb-1">
                        <Text className="text-sm text-dd-gray-700!">{label}</Text>
                        <Text className="text-sm font-semibold!" style={{ color }}>
                          {count}
                        </Text>
                      </div>
                      <Progress percent={pct} strokeColor={color} showInfo={false} size="small" />
                    </div>
                  );
                })}

                <div className="pt-3 border-t border-dd-gray-100">
                  <Text className="text-dd-gray-500! text-xs">
                    {risks.length} missions analysed · rule-based heuristic model (SLA elapsed % +
                    priority weight)
                  </Text>
                </div>
              </div>
            )}
          </Card>
        </Col>

        {/* Top risks */}
        <Col xs={24} lg={16}>
          <Card
            title={
              <span>
                <WarningOutlined className="mr-2 text-dd-warning-500" />
                Mission Risk Queue
              </span>
            }
            className="h-full"
          >
            {isLoading ? (
              <Skeleton active paragraph={{ rows: 6 }} />
            ) : risks.length === 0 ? (
              <div className="py-8 text-center">
                <CheckCircleOutlined className="text-3xl text-dd-success-500 mb-2 block" />
                <Text className="text-dd-gray-500!">No active or planned missions</Text>
              </div>
            ) : (
              <div className="max-h-[480px] overflow-y-auto pr-1">
                <Timeline items={timelineItems} />
                {risks.length > 8 && (
                  <Text className="text-dd-gray-400! text-xs block text-center mt-2">
                    +{risks.length - 8} more missions at lower risk
                  </Text>
                )}
              </div>
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
}
