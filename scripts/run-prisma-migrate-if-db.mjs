import { spawnSync } from 'node:child_process'

const advisoryLockTimeoutPattern = /Timed out trying to acquire a postgres advisory lock|pg_advisory_lock|Error:\s*P1002/i
const databaseUnavailablePattern = /Error:\s*P1001|Can't reach database server|Can’t reach database server|ECONNREFUSED|ENOTFOUND|getaddrinfo|server has closed the connection/i

function sleep(milliseconds) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds)
}

function runPrismaMigrateDeploy() {
  return spawnSync(npxCommand, ['prisma', 'migrate', 'deploy'], {
    stdio: 'pipe',
    env: process.env,
    encoding: 'utf8',
  })
}

function writeCommandOutput(result) {
  if (result.stdout) {
    process.stdout.write(result.stdout)
  }

  if (result.stderr) {
    process.stderr.write(result.stderr)
  }
}

if (!process.env.DATABASE_URL?.trim()) {
  console.log('Skipping prisma migrate deploy because DATABASE_URL is not set.')
  process.exit(0)
}

const npxCommand = process.platform === 'win32' ? 'npx.cmd' : 'npx'

const maxAttempts = Number(process.env.PRISMA_MIGRATE_DEPLOY_RETRIES ?? '4')
let result = null

for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
  result = runPrismaMigrateDeploy()
  writeCommandOutput(result)

  if (result.status === 0) {
    process.exit(0)
  }

  const combinedOutput = `${result.stdout ?? ''}\n${result.stderr ?? ''}`
  const isAdvisoryLockTimeout = advisoryLockTimeoutPattern.test(combinedOutput)
  const isDatabaseUnavailable = databaseUnavailablePattern.test(combinedOutput)

  if (isDatabaseUnavailable) {
    console.warn('Skipping prisma migrate deploy because the configured database is currently unavailable.')
    process.exit(0)
  }

  if (!isAdvisoryLockTimeout || attempt === maxAttempts) {
    process.exit(result.status ?? 1)
  }

  const delayMilliseconds = attempt * 15000
  console.warn(
    `Prisma migrate deploy hit an advisory lock timeout. Retrying in ${Math.round(delayMilliseconds / 1000)}s ` +
      `(attempt ${attempt} of ${maxAttempts}).`,
  )
  sleep(delayMilliseconds)
}

if (result?.status !== 0) {
  process.exit(result?.status ?? 1)
}