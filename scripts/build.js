const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, '..', 'public/treino');
const destDir = path.join(__dirname, '..', 'out/treino');

console.log('Building Next.js...');
execSync('npx next build', { stdio: 'inherit' });

console.log('Copying Flutter web files...');
if (fs.existsSync(srcDir)) {
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
  copyDir(srcDir, destDir);
  console.log('Done!');
} else {
  console.log('Warning: public/treino not found');
}