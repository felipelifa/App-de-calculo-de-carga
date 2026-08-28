const { existsSync, readdirSync, statSync } = require('fs');
const { join } = require('path');
const { spawn, spawnSync } = require('child_process');

const migrationsPath = join(__dirname, 'prisma', 'migrations');
const hasMigrations = existsSync(migrationsPath)
  && readdirSync(migrationsPath).some((entry) => statSync(join(migrationsPath, entry)).isDirectory());

if (!hasMigrations) {
  console.error(
    'Production startup aborted: prisma/migrations is missing or empty. '
      + 'Create and commit a reviewed Prisma migration before deploying.',
  );
  process.exit(1);
}

const migrate = spawnSync(
  process.execPath,
  [require.resolve('prisma/build/index.js'), 'migrate', 'deploy'],
  { stdio: 'inherit' },
);

if (migrate.status !== 0) {
  process.exit(migrate.status || 1);
}

const server = spawn(process.execPath, [join(__dirname, 'dist', 'src', 'main.js')], {
  stdio: 'inherit',
});

server.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exit(code || 0);
  }
});
