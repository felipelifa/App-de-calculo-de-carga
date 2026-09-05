const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const rootDir = path.join(__dirname, '..');
const outDir = path.join(rootDir, 'out');
const flutterWebSrc = path.join(rootDir, 'public/treino');
const apkSrc = path.join(rootDir, 'public/download/apk.apk');

function copyDir(src, dest) {
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
}

try {
  // Clean out directory
  console.log('Cleaning out/ directory...');
  if (fs.existsSync(outDir)) {
    fs.rmSync(outDir, { recursive: true, force: true });
  }

  // Build Next.js
  console.log('Building Next.js...');
  execSync('npx next build', { stdio: 'inherit', cwd: rootDir });

  // Copy Flutter web build
  console.log('Copying Flutter web build to out/treino/...');
  if (fs.existsSync(flutterWebSrc)) {
    copyDir(flutterWebSrc, path.join(outDir, 'treino'));
    console.log('Flutter web copied successfully');
  } else {
    console.log('Warning: public/treino not found');
  }

  // Copy APK
  console.log('Copying APK to out/download/...');
  if (fs.existsSync(apkSrc)) {
    fs.mkdirSync(path.join(outDir, 'download'), { recursive: true });
    fs.copyFileSync(apkSrc, path.join(outDir, 'download', 'apk.apk'));
    console.log('APK copied successfully');
  } else {
    console.log('Warning: public/download/apk.apk not found');
  }

  console.log('Build completed successfully!');
} catch (error) {
  console.error('Build failed:', error.message);
  process.exit(1);
}
