'use client';

import {
  KeyOutlined,
  LockOutlined,
  LogoutOutlined,
  ReloadOutlined,
  UserSwitchOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { useQuery } from '@tanstack/react-query';
import { Alert, Button, Select, Table, Tag, Tooltip, Typography } from 'antd';
import { useState } from 'react';

import { api } from '@/lib/api';

const { Title, Text } = Typography;

type AuthEventType =
  | 'login_success'
  | 'login_fail'
  | 'logout'
  | 'otp_success'
  | 'otp_fail'
  | 'key_provision'
  | 'key_rotation'
  | 'role_change'
  | 'session_expire';

// AdonisJS Lucid models serialize to camelCase
interface AuditLogEntry {
  id: number;
  userId: number | null;
  eventType: AuthEventType;
  deviceId: string | null;
  ipAddress: string | null;
  payload: Record<string, unknown> | null;
  eventHash: string;
  createdAt: string;
  user?: {
    id: number;
    name: string;
    email: string;
    role: string;
  } | null;
}

interface PaginatedResponse<T> {
  data: T[];
  meta: { total: number; perPage: number; currentPage: number; lastPage: number };
}

const EVENT_CONFIG: Record<AuthEventType, { color: string; icon: React.ReactNode; label: string }> =
  {
    login_success: { color: 'green', icon: <LockOutlined />, label: 'Login' },
    login_fail: { color: 'red', icon: <WarningOutlined />, label: 'Login Failed' },
    logout: { color: 'default', icon: <LogoutOutlined />, label: 'Logout' },
    otp_success: { color: 'blue', icon: <KeyOutlined />, label: 'OTP Verified' },
    otp_fail: { color: 'orange', icon: <WarningOutlined />, label: 'OTP Failed' },
    key_provision: { color: 'purple', icon: <KeyOutlined />, label: 'Key Provisioned' },
    key_rotation: { color: 'purple', icon: <KeyOutlined />, label: 'Key Rotated' },
    role_change: { color: 'orange', icon: <UserSwitchOutlined />, label: 'Role Changed' },
    session_expire: { color: 'default', icon: <LockOutlined />, label: 'Session Expired' },
  };

export default function AuditPage() {
  const [page, setPage] = useState(1);
  const [eventFilter, setEventFilter] = useState<AuthEventType | 'all'>('all');

  const { data, isLoading, isError, refetch, dataUpdatedAt } = useQuery<
    PaginatedResponse<AuditLogEntry>
  >({
    queryKey: ['audit-logs', page, eventFilter],
    queryFn: () =>
      api
        .get<PaginatedResponse<AuditLogEntry>>('/web/auth/audit-logs', {
          params: { page, per_page: 50, ...(eventFilter !== 'all' && { event_type: eventFilter }) },
        })
        .then(r => r.data),
    staleTime: 15_000,
  });

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const columns = [
    {
      title: '#',
      dataIndex: 'id',
      key: 'id',
      width: 70,
      render: (id: number) => <span className="tabular-nums text-dd-gray-400 text-xs">{id}</span>,
    },
    {
      title: 'Event',
      dataIndex: 'eventType',
      key: 'eventType',
      render: (type: AuthEventType) => {
        const cfg = EVENT_CONFIG[type] ?? { color: 'default', icon: null, label: type };
        return (
          <Tag color={cfg.color} icon={cfg.icon}>
            {cfg.label}
          </Tag>
        );
      },
    },
    {
      title: 'User',
      key: 'user',
      render: (_: unknown, row: AuditLogEntry) =>
        row.user ? (
          <div>
            <div className="font-medium text-dd-gray-900 text-sm">{row.user.name}</div>
            <div className="text-xs text-dd-gray-500">{row.user.email}</div>
          </div>
        ) : (
          <Text className="text-dd-gray-400!">
            {(row.payload?.email as string) ?? `User #${row.userId ?? '?'}`}
          </Text>
        ),
    },
    {
      title: 'IP',
      dataIndex: 'ipAddress',
      key: 'ip',
      render: (ip: string | null) => (
        <span className="font-mono text-xs text-dd-gray-600">{ip ?? '—'}</span>
      ),
    },
    {
      title: 'Payload',
      key: 'payload',
      render: (_: unknown, row: AuditLogEntry) => {
        if (!row.payload) return <Text className="text-dd-gray-400!">—</Text>;
        const keys = Object.keys(row.payload).filter(k => k !== 'source');
        if (!keys.length) return <Text className="text-dd-gray-400!">—</Text>;
        return (
          <div className="flex flex-wrap gap-1">
            {keys.slice(0, 3).map(k => (
              <Tag key={k} className="text-xs">
                {k}: {String(row.payload![k])}
              </Tag>
            ))}
          </div>
        );
      },
    },
    {
      title: 'Hash',
      dataIndex: 'eventHash',
      key: 'hash',
      render: (hash: string | undefined) => (
        <Tooltip title={hash ?? '—'}>
          <span className="font-mono text-xs text-dd-gray-400 cursor-help">
            {hash ? `${hash.slice(0, 8)}…` : '—'}
          </span>
        </Tooltip>
      ),
    },
    {
      title: 'Time',
      dataIndex: 'createdAt',
      key: 'createdAt',
      render: (t: string) => (
        <span className="tabular-nums text-xs text-dd-gray-600">
          {new Date(t).toLocaleString()}
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
            Audit Log
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated
              ? `Updated ${lastUpdated} · hash-chained authentication events`
              : 'Loading…'}
          </Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
          Refresh
        </Button>
      </div>

      {isError && (
        <Alert
          message="Access restricted. Only admins and commanders can view audit logs."
          type="warning"
          showIcon
          className="mb-4"
        />
      )}

      {/* Event filter */}
      <div className="flex items-center gap-3 mb-4">
        <Select
          value={eventFilter}
          onChange={v => {
            setEventFilter(v);
            setPage(1);
          }}
          style={{ width: 180 }}
          options={[
            { value: 'all', label: 'All events' },
            { value: 'login_success', label: 'Logins' },
            { value: 'login_fail', label: 'Failed logins' },
            { value: 'logout', label: 'Logouts' },
            { value: 'role_change', label: 'Role changes' },
            { value: 'key_provision', label: 'Key provisions' },
            { value: 'otp_success', label: 'OTP events' },
          ]}
        />
        {data?.meta && (
          <Text className="text-dd-gray-500! text-sm ml-auto">
            {data.meta.total.toLocaleString()} total events
          </Text>
        )}
      </div>

      <Table
        dataSource={data?.data ?? []}
        columns={columns}
        rowKey="id"
        loading={isLoading}
        pagination={{
          current: page,
          pageSize: data?.meta.perPage ?? 50,
          total: data?.meta.total ?? 0,
          onChange: p => setPage(p),
          showTotal: t => `${t} events`,
        }}
        size="small"
        scroll={{ x: 800 }}
        className="pagination"
      />
    </div>
  );
}
