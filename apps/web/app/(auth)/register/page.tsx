'use client';

import { Button, Form, Input, Typography } from 'antd';
import Link from 'next/link';

import useAuth from '../useAuth';

const { Title, Text } = Typography;

export default function RegisterPage() {
  const { form, loading, handleRegister } = useAuth();

  return (
    <div className="w-full min-h-screen flex items-center justify-center px-4 py-8">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-lg p-8 sm:p-10 border border-app-gray-200">
        {/* Title */}
        <div className="text-center mb-8">
          <Title level={3} className="!mb-2">
            Create your account
          </Title>
          <Text type="secondary">Get started today</Text>
        </div>

        {/* Form */}
        <Form form={form} layout="vertical" name="register" onFinish={handleRegister}>
          <Form.Item
            label="Full Name"
            name="fullName"
            rules={[{ required: true, message: 'Please enter your name' }]}
          >
            <Input placeholder="Enter your name" />
          </Form.Item>

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
            rules={[{ required: true, message: 'Please enter a password' }]}
          >
            <Input.Password placeholder="At least 6 characters" />
          </Form.Item>

          <Form.Item
            label="Confirm Password"
            name="confirmPassword"
            dependencies={['password']}
            rules={[
              { required: true, message: 'Please confirm your password' },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  if (!value || getFieldValue('password') === value) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error('Passwords do not match'));
                },
              }),
            ]}
          >
            <Input.Password placeholder="Re-enter your password" />
          </Form.Item>

          <Form.Item style={{ marginBottom: 0 }}>
            <Button type="primary" htmlType="submit" block loading={loading}>
              Create Account
            </Button>
          </Form.Item>
        </Form>

        <div className="text-center mt-6">
          <Text className="text-sm" type="secondary">
            Already have an account?{' '}
            <Link href="/login" className="text-primary-500 hover:underline font-medium">
              Sign in
            </Link>
          </Text>
        </div>
      </div>
    </div>
  );
}
