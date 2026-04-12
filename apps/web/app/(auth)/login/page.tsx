'use client';

import {
  AlertOutlined,
  EnvironmentOutlined,
  LockOutlined,
  MailOutlined,
  ThunderboltOutlined,
} from '@ant-design/icons';
import { useMutation } from '@tanstack/react-query';
import { Alert, Button, Form, Input, Typography } from 'antd';
import { useRouter } from 'next/navigation';

import { api } from '@/lib/api';
import type { User } from '@/types';

const { Title, Text } = Typography;

interface LoginPayload {
  email: string;
  password: string;
}

const CONTEXT_ITEMS = [
  { icon: <EnvironmentOutlined />, text: 'Sylhet Division flood response — 5.2M displaced' },
  { icon: <AlertOutlined />, text: 'Offline-first · works without internet' },
  { icon: <ThunderboltOutlined />, text: 'Real-time mesh coordination across field nodes' },
];

export default function LoginPage() {
  const router = useRouter();

  const { mutate, isPending, error } = useMutation({
    mutationFn: (payload: LoginPayload) =>
      api.post<{ user: User }>('/web/auth/login', payload).then(r => r.data),
    onSuccess: () => router.replace('/'),
  });

  return (
    <div className="min-h-screen flex flex-col lg:flex-row">
      {/* ── Left: Branding panel ─────────────────────────────────── */}
      <div
        className="relative flex flex-col justify-between p-10! lg:w-120 lg:min-h-screen"
        style={{
          background: 'linear-gradient(160deg, #052e16 0%, #14532d 50%, #166534 100%)',
        }}
      >
        {/* Subtle grid overlay */}
        <div
          className="absolute inset-0 opacity-5"
          style={{
            backgroundImage:
              'linear-gradient(rgba(255,255,255,.3) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,.3) 1px,transparent 1px)',
            backgroundSize: '32px 32px',
          }}
        />

        <div className="relative z-10">
          {/* Logo */}
          <div className="flex items-center gap-3 mb-14">
            <div className="w-10 h-10 rounded-xl bg-dd-primary-500 flex items-center justify-center shadow-lg">
              <ThunderboltOutlined className="text-white text-lg" />
            </div>
            <div>
              <div className="text-white font-bold text-lg leading-tight">Digital Delta</div>
              <div className="text-dd-primary-300 text-xs leading-tight">Command Center</div>
            </div>
          </div>

          {/* Headline */}
          <Title
            level={2}
            className="text-white! font-bold! leading-tight! mb-3!"
            style={{ fontSize: 32 }}
          >
            Resilient logistics
            <br />
            <span className="text-dd-primary-300">under any condition.</span>
          </Title>
          <Text className="text-dd-primary-200! text-sm leading-relaxed block mb-10 max-w-xs">
            Coordinate critical relief supply delivery across a decentralised network of volunteers,
            boats, drones, and field hospitals — even when the internet goes dark.
          </Text>

          {/* Context list */}
          <div className="space-y-3">
            {CONTEXT_ITEMS.map(item => (
              <div key={item.text} className="flex items-center gap-3">
                <div className="w-7 h-7 rounded-lg bg-white/10 flex items-center justify-center shrink-0 text-dd-primary-300 text-sm">
                  {item.icon}
                </div>
                <Text className="text-dd-primary-100! text-sm">{item.text}</Text>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom note */}
        <div className="relative z-10 mt-10">
          <div className="flex items-center gap-2 px-3 py-2 rounded-lg bg-white/5 border border-white/10 w-fit">
            <span className="w-2 h-2 rounded-full bg-dd-success-400 animate-pulse shrink-0" />
            <Text className="text-dd-gray-400! text-xs">
              HackFusion 2026 — IEEE CS LU SB Chapter
            </Text>
          </div>
        </div>
      </div>

      {/* ── Right: Form panel ────────────────────────────────────── */}
      <div className="flex-1 flex items-center justify-center bg-dd-gray-50 p-6 lg:p-16">
        <div className="w-full max-w-sm">
          <div className="mb-8">
            <Title level={3} className="mb-1! text-dd-gray-900! font-bold!">
              Welcome back
            </Title>
            <Text className="text-dd-gray-500! text-sm">Sign in to the command dashboard</Text>
          </div>

          {error && (
            <Alert
              message={(error as Error).message}
              type="error"
              showIcon
              className="mb-5! rounded-lg"
              closable
            />
          )}

          <div className="bg-white rounded-2xl p-8 shadow-sm border border-dd-gray-200">
            <Form
              layout="vertical"
              onFinish={(values: LoginPayload) => mutate(values)}
              requiredMark={false}
              size="large"
            >
              <Form.Item
                name="email"
                label={<span className="text-sm font-medium text-dd-gray-700">Email address</span>}
                rules={[
                  { required: true, message: 'Please enter your email' },
                  { type: 'email', message: 'Enter a valid email address' },
                ]}
                className="mb-4!"
              >
                <Input
                  prefix={<MailOutlined className="text-dd-gray-400 mr-1" />}
                  placeholder="commander@example.com"
                  autoComplete="email"
                />
              </Form.Item>

              <Form.Item
                name="password"
                label={<span className="text-sm font-medium text-dd-gray-700">Password</span>}
                rules={[{ required: true, message: 'Please enter your password' }]}
                className="mb-6!"
              >
                <Input.Password
                  prefix={<LockOutlined className="text-dd-gray-400 mr-1" />}
                  placeholder="••••••••"
                  autoComplete="current-password"
                />
              </Form.Item>

              <Button
                type="primary"
                htmlType="submit"
                size="large"
                block
                loading={isPending}
                className="h-11! font-semibold!"
              >
                Sign in to Command Center
              </Button>
            </Form>
          </div>

          <div className="mt-6 flex items-center gap-2 p-3 rounded-xl bg-dd-warning-50 border border-dd-warning-200">
            <AlertOutlined className="text-dd-warning-600 shrink-0" />
            <Text className="text-dd-warning-700! text-xs">
              Field volunteers use the{' '}
              <span className="font-semibold">Digital Delta mobile app</span>, not this dashboard.
            </Text>
          </div>
        </div>
      </div>
    </div>
  );
}
