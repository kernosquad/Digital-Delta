'use client';

import { ReloadOutlined, TeamOutlined } from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Alert, Button, Select, Table, Tag, Typography } from 'antd';
import { useState } from 'react';

import { api } from '@/lib/api';
import type { User, UserRole, UserStatus } from '@/types';

const { Title, Text } = Typography;

const ROLE_OPTIONS: { value: UserRole; label: string }[] = [
  { value: 'field_volunteer', label: 'Field Volunteer' },
  { value: 'supply_manager', label: 'Supply Manager' },
  { value: 'drone_operator', label: 'Drone Operator' },
  { value: 'camp_commander', label: 'Camp Commander' },
  { value: 'sync_admin', label: 'Sync Admin' },
];

const STATUS_OPTIONS: { value: UserStatus; label: string }[] = [
  { value: 'active', label: 'Active' },
  { value: 'inactive', label: 'Inactive' },
  { value: 'suspended', label: 'Suspended' },
];

const STATUS_COLORS: Record<UserStatus, string> = {
  active: 'green',
  inactive: 'default',
  suspended: 'red',
};

const ROLE_COLORS: Record<UserRole, string> = {
  sync_admin: 'red',
  camp_commander: 'blue',
  supply_manager: 'green',
  drone_operator: 'purple',
  field_volunteer: 'default',
};

export default function UsersPage() {
  const queryClient = useQueryClient();
  const [updatingRole, setUpdatingRole] = useState<number | null>(null);
  const [updatingStatus, setUpdatingStatus] = useState<number | null>(null);

  const {
    data: users,
    isLoading,
    isError,
    refetch,
    dataUpdatedAt,
  } = useQuery<User[]>({
    queryKey: ['users'],
    queryFn: () => api.get<User[]>('/users').then(r => r.data),
    staleTime: 15_000,
  });

  const roleMutation = useMutation({
    mutationFn: ({ id, role }: { id: number; role: UserRole }) =>
      api.patch(`/users/${id}/role`, { role }).then(r => r.data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
    onSettled: () => setUpdatingRole(null),
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }: { id: number; status: UserStatus }) =>
      api.patch(`/users/${id}/status`, { status }).then(r => r.data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['users'] }),
    onSettled: () => setUpdatingStatus(null),
  });

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;

  const columns = [
    {
      title: 'User',
      key: 'user',
      render: (_: unknown, u: User) => (
        <div>
          <div className="font-medium text-dd-gray-900">{u.name}</div>
          <div className="text-xs text-dd-gray-500">{u.email}</div>
          {u.phone && <div className="text-xs text-dd-gray-400">{u.phone}</div>}
        </div>
      ),
      sorter: (a: User, b: User) => a.name.localeCompare(b.name),
    },
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      render: (role: UserRole, u: User) => (
        <Select
          value={role}
          loading={updatingRole === u.id}
          disabled={updatingRole === u.id}
          size="small"
          style={{ width: 160 }}
          options={ROLE_OPTIONS.map(o => ({
            value: o.value,
            label: <Tag color={ROLE_COLORS[o.value]}>{o.label}</Tag>,
          }))}
          onChange={val => {
            setUpdatingRole(u.id);
            roleMutation.mutate({ id: u.id, role: val });
          }}
        />
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: UserStatus, u: User) => (
        <Select
          value={status}
          loading={updatingStatus === u.id}
          disabled={updatingStatus === u.id}
          size="small"
          style={{ width: 130 }}
          options={STATUS_OPTIONS.map(o => ({
            value: o.value,
            label: <Tag color={STATUS_COLORS[o.value]}>{o.label}</Tag>,
          }))}
          onChange={val => {
            setUpdatingStatus(u.id);
            statusMutation.mutate({ id: u.id, status: val });
          }}
        />
      ),
    },
    {
      title: 'Last Seen',
      dataIndex: 'last_seen_at',
      key: 'last_seen_at',
      render: (t: string | null) =>
        t ? (
          <span className="tabular-nums text-xs text-dd-gray-600">
            {new Date(t).toLocaleString()}
          </span>
        ) : (
          <Text className="text-dd-gray-400!">Never</Text>
        ),
      sorter: (a: User, b: User) => (a.last_seen_at ?? '').localeCompare(b.last_seen_at ?? ''),
    },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            <TeamOutlined className="mr-2 text-dd-primary-500" />
            User Management
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated
              ? `Updated ${lastUpdated} · role/status changes require sync_admin`
              : 'Loading…'}
          </Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading}>
          Refresh
        </Button>
      </div>

      {isError && (
        <Alert
          message="Access restricted. Only sync_admin can manage users."
          type="warning"
          showIcon
          className="mb-4"
        />
      )}

      <Table
        dataSource={users ?? []}
        columns={columns}
        rowKey="id"
        loading={isLoading}
        pagination={{ pageSize: 25, showSizeChanger: true }}
        size="middle"
      />
    </div>
  );
}
