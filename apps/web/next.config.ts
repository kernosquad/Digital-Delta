import type { NextConfig } from 'next';

const API_BASE = process.env.API_BASE_URL ?? 'http://localhost:3333';

const nextConfig: NextConfig = {
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${API_BASE}/api/:path*`,
      },
    ];
  },
};

export default nextConfig;
