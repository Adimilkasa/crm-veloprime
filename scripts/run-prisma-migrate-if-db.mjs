import { spawnSync } from 'node:child_process'

if (!process.env.DATABASE_URL?.trim()) {
  console.log('Skipping prisma migrate deploy because DATABASE_URL is not set.')
  process.exit(0)
}

const npxCommand = process.platform === 'win32' ? 'npx.cmd' : 'npx'
const result = spawnSync(npxCommand, ['prisma', 'migrate', 'deploy'], {
  stdio: 'inherit',
  env: process.env,
})

if (result.status !== 0) {
  process.exit(result.status ?? 1)
}