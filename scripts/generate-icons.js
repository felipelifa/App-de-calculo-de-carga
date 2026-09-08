const sharp = require('sharp');
const toIco = require('to-ico');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const SVG_PATH = path.join(ROOT, 'app', 'icon.svg');
const svgBuffer = fs.readFileSync(SVG_PATH);

const ICONS = [
  // Next.js / Web favicons
  { name: 'favicon-16.png', size: 16, dest: 'public' },
  { name: 'favicon-32.png', size: 32, dest: 'public' },
  { name: 'apple-touch-icon.png', size: 180, dest: 'public' },
  { name: 'icon-192.png', size: 192, dest: 'public' },
  { name: 'icon-512.png', size: 512, dest: 'public' },

  // Flutter treino web
  { name: 'favicon.png', size: 32, dest: 'public/treino' },
  { name: 'Icon-192.png', size: 192, dest: 'public/treino/icons' },
  { name: 'Icon-512.png', size: 512, dest: 'public/treino/icons' },
  { name: 'Icon-maskable-192.png', size: 192, dest: 'public/treino/icons', pad: true },
  { name: 'Icon-maskable-512.png', size: 512, dest: 'public/treino/icons', pad: true },

  // Flutter source web
  { name: 'favicon.png', size: 32, dest: 'app_flutter/web' },
  { name: 'Icon-192.png', size: 192, dest: 'app_flutter/web/icons' },
  { name: 'Icon-512.png', size: 512, dest: 'app_flutter/web/icons' },
  { name: 'Icon-maskable-192.png', size: 192, dest: 'app_flutter/web/icons', pad: true },
  { name: 'Icon-maskable-512.png', size: 512, dest: 'app_flutter/web/icons', pad: true },

  // Flutter master icon
  { name: 'icon_1024.png', size: 1024, dest: 'app_flutter/assets' },
];

async function generatePng(icon) {
  const destDir = path.join(ROOT, icon.dest);
  if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
  }

  let pipeline = sharp(svgBuffer).resize(icon.size, icon.size, {
    fit: 'contain',
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  });

  if (icon.pad) {
    const pad = Math.round(icon.size * 0.1);
    pipeline = pipeline.extend({
      top: pad,
      bottom: pad,
      left: pad,
      right: pad,
      background: { r: 204, g: 255, b: 0, alpha: 1 },
    }).resize(icon.size, icon.size);
  }

  const outPath = path.join(destDir, icon.name);
  await pipeline.png().toFile(outPath);
  console.log(`✓ ${outPath}`);
}

async function generateFaviconIco() {
  const sizes = [16, 32, 48];
  const buffers = await Promise.all(
    sizes.map((s) =>
      sharp(svgBuffer)
        .resize(s, s, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
        .png()
        .toBuffer()
    )
  );

  const icoBuffer = await toIco(buffers);

  // Write to both app/ and public/
  fs.writeFileSync(path.join(ROOT, 'app', 'favicon.ico'), icoBuffer);
  console.log(`✓ app/favicon.ico`);
  fs.writeFileSync(path.join(ROOT, 'public', 'favicon.ico'), icoBuffer);
  console.log(`✓ public/favicon.ico`);
}

async function main() {
  console.log('Generating icons from app/icon.svg...\n');

  for (const icon of ICONS) {
    await generatePng(icon);
  }

  console.log('\nGenerating favicon.ico...');
  await generateFaviconIco();

  console.log('\nDone! All icons generated.');
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
