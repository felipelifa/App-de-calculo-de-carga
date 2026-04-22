import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  images: {
    unoptimized: true,
  },
  output: 'standalone',
  basePath: '',
  trailingSlash: false,
};

export default nextConfig;
