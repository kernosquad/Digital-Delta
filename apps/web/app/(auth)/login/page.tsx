'use client';

import { Button, Form, Input, Typography } from 'antd';
import Link from 'next/link';

import useAuth from '../useAuth';

const { Title, Text } = Typography;

export default function LoginPage() {
  const { form, loading, handleLogin } = useAuth();

  return (
    <div className="w-full min-h-screen flex items-center justify-center px-4 py-8">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-lg p-8 sm:p-10 border border-app-gray-200">
        {/* Title */}
        <div className="text-center mb-8">
          <Title level={3} className="!mb-2">
            Welcome back
          </Title>
          <Text type="secondary">Sign in to your account</Text>
        </div>

        {/* Form */}
        <Form form={form} layout="vertical" name="login" onFinish={handleLogin}>
          <Form.Item
            label="Email address"
            name="email"
            rules={[
              { required: true, message: 'Please enter your email' },
              { type: 'email', message: 'Please enter a valid email' },
            ]}
          >
            <Input placeholder="you@example.com" />
          </Form.Item>

          <Form.Item
            label="Password"
            name="password"
            rules={[{ required: true, message: 'Please enter your password' }]}
          >
            <Input.Password placeholder="At least 6 characters" />
          </Form.Item>

          <div className="flex justify-between items-center text-sm mb-4">
            <Text type="secondary">Don&apos;t have an account?</Text>
            <Link href="/register" className="text-primary-500 hover:underline font-medium">
              Create one
            </Link>
          </div>

          <Form.Item style={{ marginBottom: 0 }}>
            <Button type="primary" htmlType="submit" block loading={loading}>
              Sign In
            </Button>
          </Form.Item>
        </Form>

        <div className="text-center mt-6">
          <Link href="/forgot-password" className="text-sm text-primary-500 hover:underline">
            Forgot your password?
          </Link>
        </div>
      </div>
    </div>
  );
}
