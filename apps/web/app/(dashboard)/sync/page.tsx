'use client';

import {
  CheckCircleOutlined,
  ClockCircleOutlined,
  ReloadOutlined,
  SyncOutlined,
} from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import {
  Alert,
  Badge,
  Button,
  Card,
  Col,
  Form,
  Modal,
  Row,
  Select,
  Skeleton,
  Statistic,
  Table,
  Tag,
  Typography,
} from 'antd';
import { useState } from 'react';

import { api } from '@/lib/api';
import type { SyncConflict, SyncNode } from '@/types';

const { Title, Text } = Typography;

export default function SyncPage() {
  const queryClient = useQueryClient();
  const [resolveTarget, setResolveTarget] = useState<SyncConflict | null>(null);
  const [resolveForm] = Form.useForm<{ resolution: 'node_a' | 'node_b' | 'merge' }>();

  const {
    data: conflicts,
    isLoading: conflictsLoading,
    isError,
    refetch,
    dataUpdatedAt,
  } = useQuery<SyncConflict[]>({
    queryKey: ['sync-conflicts'],
    queryFn: () => api.get<SyncConflict[]>('/sync/conflicts').then(r => r.data),
    refetchInterval: 15_000,
    staleTime: 10_000,
  });

  const { data: nodes, isLoading: nodesLoading } = useQuery<SyncNode[]>({
    queryKey: ['sync-nodes'],
    queryFn: () => api.get<SyncNode[]>('/sync/nodes').then(r => r.data),
    refetchInterval: 15_000,
    staleTime: 10_000,
  });

  const resolveMutation = useMutation({
    mutationFn: ({ id, resolution }: { id: number; resolution: string }) =>
      api.post(`/sync/conflicts/${id}/resolve`, { resolution }).then(r => r.data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sync-conflicts'] });
      setResolveTarget(null);
      resolveForm.resetFields();
    },
  });

  const lastUpdated = dataUpdatedAt ? new Date(dataUpdatedAt).toLocaleTimeString() : null;
  const pending = conflicts?.filter(c => c.status === 'pending').length ?? 0;
  const resolved = conflicts?.filter(c => c.status === 'resolved').length ?? 0;
  const onlineNodes = nodes?.filter(n => n.is_online).length ?? 0;

  const conflictColumns = [
    {
      title: 'Table',
      dataIndex: 'table_name',
      key: 'table_name',
      render: (t: string) => <Tag className="font-mono">{t}</Tag>,
    },
    {
      title: 'Record',
      dataIndex: 'record_id',
      key: 'record_id',
      render: (id: string) => <span className="font-mono text-xs text-dd-gray-700">{id}</span>,
    },
    {
      title: 'Nodes in Conflict',
      key: 'nodes',
      render: (_: unknown, c: SyncConflict) => (
        <div className="text-xs text-dd-gray-600 font-mono">
          <span className="font-medium">{c.node_a_id}</span>
          <span className="text-dd-gray-400 mx-1">vs</span>
          <span className="font-medium">{c.node_b_id}</span>
        </div>
      ),
    },
    {
      title: 'Values',
      key: 'values',
      render: (_: unknown, c: SyncConflict) => (
        <div className="text-xs space-y-1">
          <div>
            <span className="font-semibold text-blue-600">A:</span>{' '}
            <span className="font-mono text-dd-gray-600 truncate max-w-xs inline-block">
              {JSON.stringify(c.node_a_value).slice(0, 60)}…
            </span>
          </div>
          <div>
            <span className="font-semibold text-orange-600">B:</span>{' '}
            <span className="font-mono text-dd-gray-600 truncate max-w-xs inline-block">
              {JSON.stringify(c.node_b_value).slice(0, 60)}…
            </span>
          </div>
        </div>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (s: string, c: SyncConflict) =>
        s === 'resolved' ? (
          <div>
            <Tag color="green" icon={<CheckCircleOutlined />}>
              Resolved
            </Tag>
            {c.resolution && <div className="text-xs text-dd-gray-500 mt-1">{c.resolution}</div>}
          </div>
        ) : (
          <Tag color="orange" icon={<ClockCircleOutlined />}>
            Pending
          </Tag>
        ),
    },
    {
      title: 'Detected',
      dataIndex: 'created_at',
      key: 'created_at',
      render: (t: string) => (
        <span className="tabular-nums text-xs text-dd-gray-600">
          {new Date(t).toLocaleString()}
        </span>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: unknown, c: SyncConflict) =>
        c.status === 'pending' ? (
          <Button size="small" type="primary" onClick={() => setResolveTarget(c)}>
            Resolve
          </Button>
        ) : null,
    },
  ];

  const nodeColumns = [
    {
      title: 'Device ID',
      dataIndex: 'device_id',
      key: 'device_id',
      render: (id: string) => <span className="font-mono text-sm">{id}</span>,
    },
    {
      title: 'Status',
      dataIndex: 'is_online',
      key: 'is_online',
      render: (online: boolean) => (
        <div className="flex items-center gap-2">
          <Badge status={online ? 'processing' : 'default'} />
          <Tag color={online ? 'green' : 'default'}>{online ? 'Online' : 'Offline'}</Tag>
        </div>
      ),
    },
    {
      title: 'Last Seen',
      dataIndex: 'last_seen_at',
      key: 'last_seen_at',
      render: (t: string) => (
        <span className="tabular-nums text-xs text-dd-gray-600">
          {new Date(t).toLocaleString()}
        </span>
      ),
    },
    {
      title: 'Vector Clock',
      dataIndex: 'vector_clock',
      key: 'vector_clock',
      render: (vc: Record<string, number>) => (
        <span className="font-mono text-xs text-dd-gray-500">
          {JSON.stringify(vc).slice(0, 50)}
          {JSON.stringify(vc).length > 50 ? '…' : ''}
        </span>
      ),
    },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <Title level={4} className="mb-0!">
            <SyncOutlined className="mr-2 text-dd-primary-500" />
            CRDT Sync & Conflicts
          </Title>
          <Text className="text-dd-gray-500! text-sm">
            {lastUpdated
              ? `Updated ${lastUpdated} · distributed ledger convergence status`
              : 'Loading…'}
          </Text>
        </div>
        <Button icon={<ReloadOutlined />} onClick={() => refetch()} loading={conflictsLoading}>
          Refresh
        </Button>
      </div>

      {pending > 0 && (
        <Alert
          message={`${pending} unresolved conflict${pending > 1 ? 's' : ''} detected`}
          description="Concurrent writes from disconnected nodes have diverged. Resolve them to converge the distributed ledger."
          type="warning"
          showIcon
          className="mb-4"
        />
      )}

      {isError && (
        <Alert message="Failed to load sync data." type="error" showIcon className="mb-4" />
      )}

      {/* Stats */}
      <Row gutter={[16, 16]} className="mb-6">
        {[
          { label: 'Pending Conflicts', value: pending, color: '#f79009' },
          { label: 'Resolved', value: resolved, color: '#17b26a' },
          { label: 'Nodes Online', value: onlineNodes, color: '#2563eb' },
          { label: 'Total Nodes', value: nodes?.length ?? 0, color: '#374151' },
        ].map(({ label, value, color }) => (
          <Col key={label} xs={12} sm={6}>
            <Card size="small">
              {conflictsLoading || nodesLoading ? (
                <Skeleton.Input active size="small" />
              ) : (
                <Statistic
                  title={label}
                  value={value}
                  styles={{ content: { color, fontSize: 22 } }}
                />
              )}
            </Card>
          </Col>
        ))}
      </Row>

      {/* Conflicts table */}
      <Title level={5} className="mb-3!">
        Conflict Log
      </Title>
      <Table
        dataSource={conflicts ?? []}
        columns={conflictColumns}
        rowKey="id"
        loading={conflictsLoading}
        size="small"
        pagination={{ pageSize: 10 }}
        scroll={{ x: 800 }}
        rowClassName={(c: SyncConflict) => (c.status === 'pending' ? 'bg-orange-50!' : '')}
        className="mb-6"
      />

      {/* Nodes table */}
      <Title level={5} className="mb-3!">
        Registered Nodes
      </Title>
      <Table
        dataSource={nodes ?? []}
        columns={nodeColumns}
        rowKey="id"
        loading={nodesLoading}
        size="small"
        pagination={false}
        scroll={{ x: 600 }}
      />

      {/* ── Resolve Modal ──────────────────────────────────────── */}
      <Modal
        title="Resolve Conflict"
        open={!!resolveTarget}
        onCancel={() => {
          setResolveTarget(null);
          resolveForm.resetFields();
        }}
        onOk={() => resolveForm.submit()}
        okText="Resolve"
        confirmLoading={resolveMutation.isPending}
        destroyOnClose
        width={560}
      >
        {resolveTarget && (
          <>
            <div className="mb-4 p-3 bg-dd-gray-50 rounded-lg text-xs font-mono space-y-2">
              <div>
                <span className="font-semibold text-blue-600">
                  Node A ({resolveTarget.node_a_id}):
                </span>
                <pre className="text-dd-gray-700 mt-1 whitespace-pre-wrap break-all">
                  {JSON.stringify(resolveTarget.node_a_value, null, 2)}
                </pre>
              </div>
              <div className="border-t border-dd-gray-200 pt-2">
                <span className="font-semibold text-orange-600">
                  Node B ({resolveTarget.node_b_id}):
                </span>
                <pre className="text-dd-gray-700 mt-1 whitespace-pre-wrap break-all">
                  {JSON.stringify(resolveTarget.node_b_value, null, 2)}
                </pre>
              </div>
            </div>
            <Form
              form={resolveForm}
              layout="vertical"
              onFinish={values => {
                resolveMutation.mutate({ id: resolveTarget.id, resolution: values.resolution });
              }}
            >
              <Form.Item name="resolution" label="Resolution Strategy" rules={[{ required: true }]}>
                <Select
                  options={[
                    { value: 'node_a', label: `Accept Node A (${resolveTarget.node_a_id})` },
                    { value: 'node_b', label: `Accept Node B (${resolveTarget.node_b_id})` },
                    { value: 'merge', label: 'Merge — last-write-wins by vector clock' },
                  ]}
                />
              </Form.Item>
            </Form>
          </>
        )}
        {resolveMutation.isError && (
          <Alert message="Failed to resolve conflict." type="error" showIcon className="mt-2" />
        )}
      </Modal>
    </div>
  );
}
