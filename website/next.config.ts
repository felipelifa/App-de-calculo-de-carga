import type { NextConfig } from 'next';
import * as fs from 'fs';
import * as path from 'path';

const copyDir = (src: string, dest: string) => {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
};

const nextConfig: NextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
  basePath: '',
  trailingSlash: false,
};

copyDir(path.join(__dirname, 'public/treino'), path.join(__dirname, 'out/treino'));

export default nextConfig;
