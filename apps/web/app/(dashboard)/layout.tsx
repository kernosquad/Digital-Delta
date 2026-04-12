'use client';

import {
  AuditOutlined,
  BarChartOutlined,
  CarOutlined,
  DashboardOutlined,
  LogoutOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  RadarChartOutlined,
  RobotOutlined,
  RocketOutlined,
  SafetyOutlined,
  TeamOutlined,
  ThunderboltOutlined,
  WarningOutlined,
} from '@ant-design/icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Avatar, Button, Dropdown, Layout, Menu, Spin, Tag, Typography } from 'antd';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';

import { api } from '@/lib/api';
import type { User } from '@/types';

const { Sider, Header, Content } = Layout;
const { Text } = Typography;

const ROLE_LABELS: Record<string, string> = {
  sync_admin: 'Admin',
  camp_commander: 'Commander',
  supply_manager: 'Supply Mgr',
  drone_operator: 'Drone Op',
};

const ROLE_COLORS: Record<string, string> = {
  sync_admin: 'red',
  camp_commander: 'blue',
  supply_manager: 'green',
  drone_operator: 'purple',
};

const NAV_ITEMS = [
  { key: '/', icon: <DashboardOutlined />, label: 'Overview' },
  { key: '/missions', icon: <RocketOutlined />, label: 'Mission Control' },
  { key: '/map', icon: <RadarChartOutlined />, label: 'Operations Map' },
  { key: '/supply', icon: <BarChartOutlined />, label: 'Supply Inventory' },
  { key: '/fleet', icon: <CarOutlined />, label: 'Fleet & Drones' },
  { key: '/triage', icon: <WarningOutlined />, label: 'Triage Queue' },
  { key: '/ml', icon: <RobotOutlined />, label: 'ML Predictions' },
  { key: '/users', icon: <TeamOutlined />, label: 'User Management' },
  { key: '/audit', icon: <AuditOutlined />, label: 'Audit Log' },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const queryClient = useQueryClient();
  const [collapsed, setCollapsed] = useState(false);

  // Fetch current session user
  const {
    data: user,
    isLoading,
    isError,
  } = useQuery<User>({
    queryKey: ['me'],
    queryFn: () => api.get<User>('/web/auth/me').then(r => r.data),
    retry: false,
    staleTime: 5 * 60 * 1000,
  });

  // Redirect to login if not authenticated
  useEffect(() => {
    if (isError) router.replace('/login');
  }, [isError, router]);

  const logoutMutation = useMutation({
    mutationFn: () => api.post('/web/auth/logout').then(r => r.data),
    onSuccess: () => {
      queryClient.clear();
      router.replace('/login');
    },
  });

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-dd-gray-50">
        <Spin size="large" />
      </div>
    );
  }

  if (!user) return null;

  const userMenuItems = [
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Sign out',
      danger: true,
      onClick: () => logoutMutation.mutate(),
    },
  ];

  return (
    <Layout className="min-h-screen">
      {/* ── Sidebar ─────────────────────────────────────────── */}
      <Sider collapsible collapsed={collapsed} trigger={null} width={220}>
        {/* Logo */}
        <div className="flex items-center gap-2 px-4 h-14 border-b border-white/10 overflow-hidden">
          <div className="shrink-0 w-8 h-8 rounded-lg bg-dd-primary-500 flex items-center justify-center">
            <ThunderboltOutlined className="text-white text-sm" />
          </div>
          {!collapsed && (
            <div className="min-w-0">
              <div className="text-white font-semibold text-sm leading-tight truncate">
                Digital Delta
              </div>
              <div className="text-dd-primary-300 text-xs leading-tight">Command Center</div>
            </div>
          )}
        </div>

        {/* Navigation */}
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[pathname ?? '/']}
          items={NAV_ITEMS}
          onClick={({ key }) => router.push(key)}
          style={{ background: 'transparent', borderInlineEnd: 'none' }}
          className="mt-1!"
        />

        {/* System status pill at bottom */}
        {!collapsed && (
          <div className="absolute bottom-14 left-0 right-0 px-3!">
            <div className="flex items-center gap-2 px-3! py-2! rounded-lg bg-white/5 border border-white/10">
              <span className="w-2 h-2 rounded-full bg-dd-success-400 animate-pulse shrink-0" />
              <Text className="text-dd-gray-400! text-xs truncate">System online</Text>
            </div>
          </div>
        )}
      </Sider>

      <Layout>
        {/* ── Header ──────────────────────────────────────────── */}
        <Header className="flex items-center justify-between border-b border-dd-gray-200 px-4!">
          {/* Collapse toggle */}
          <Button
            type="text"
            icon={collapsed ? <MenuUnfoldOutlined /> : <MenuFoldOutlined />}
            onClick={() => setCollapsed(!collapsed)}
          />

          {/* Right side: role badge + user avatar */}
          <div className="flex items-center gap-3">
            <Tag color={ROLE_COLORS[user.role] ?? 'default'}>
              <SafetyOutlined className="mr-1" />
              {ROLE_LABELS[user.role] ?? user.role}
            </Tag>

            <Dropdown menu={{ items: userMenuItems }} placement="bottomRight" trigger={['click']}>
              <button className="flex items-center gap-2 cursor-pointer bg-transparent border-none p-1 rounded-lg hover:bg-dd-gray-100 transition-colors">
                <Avatar
                  size={32}
                  style={{ backgroundColor: 'var(--color-dd-primary-600)' }}
                  className="font-semibold! text-sm"
                >
                  {user.name.charAt(0).toUpperCase()}
                </Avatar>
                <div className="text-left hidden sm:block">
                  <div className="text-dd-gray-900 text-sm font-medium leading-tight">
                    {user.name}
                  </div>
                  <div className="text-dd-gray-500 text-xs leading-tight">{user.email}</div>
                </div>
              </button>
            </Dropdown>
          </div>
        </Header>

        {/* ── Content ─────────────────────────────────────────── */}
        <Content className="bg-dd-gray-50 overflow-auto">
          <div className="p-6">{children}</div>
        </Content>
      </Layout>
    </Layout>
  );
}
