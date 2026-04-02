import { rmSync } from 'node:fs'
import { join } from 'node:path'

const targets = [
  join(process.cwd(), '.next', 'build'),
  join(process.cwd(), '.next', 'cache'),
  join(process.cwd(), '.next', 'types'),
  join(process.cwd(), '.next', 'diagnostics'),
  join(process.cwd(), '.next', 'dev', 'types'),
]

try {
  for (const target of targets) {
    rmSync(target, { recursive: true, force: true })
  }

  console.log('Removed Next.js build and generated type artifacts.')
} catch (error) {
  console.error('Failed to remove Next.js build artifacts.')
  console.error(error)
  process.exit(1)
}