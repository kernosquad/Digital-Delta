'use client';
import { Form } from 'antd';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

import { clientApi } from '@/utils/axios/clientApi';

export default function useAuth() {
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  const handleLogin = async (values: { email: string; password: string }) => {
    setLoading(true);
    try {
      await clientApi.post('/auth/login', values);
      router.push('/dashboard');
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (values: { fullName: string; email: string; password: string }) => {
    setLoading(true);
    try {
      await clientApi.post('/auth/register', values);
      router.push('/');
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    setLoading(true);
    try {
      await clientApi.post('/auth/logout');
      router.push('/login');
    } finally {
      setLoading(false);
    }
  };

  return { form, loading, handleLogin, handleRegister, handleLogout };
}
