import axios from 'axios';

export const api = axios.create({
  baseURL: '/api',
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

// Unwrap the AdonisJS envelope { status, data, message }
api.interceptors.response.use(
  res => {
    if (res.data && 'data' in res.data) {
      res.data = res.data.data;
    }
    return res;
  },
  error => {
    const errors = error.response?.data?.errors;
    if (errors?.length) {
      error.message = errors[0].message;
    }
    return Promise.reject(error);
  }
);
