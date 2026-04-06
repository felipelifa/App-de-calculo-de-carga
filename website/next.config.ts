/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  images: {
    remotePatterns: [],
  },
  async rewrites() {
    return [
      {
        source: '/app/:path*',
        destination: 'https://<VERCEL-URL>/:path*', // Replace with actual Flutter web URL after deploy
      },
    ];
  },
};

export default nextConfig;
