const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()

async function main() {
  const result = await prisma.user.updateMany({
    where: {
      email: {
        startsWith: 'smoke.sales.',
      },
    },
    data: {
      isActive: false,
    },
  })

  console.log(`SMOKE_USERS_DEACTIVATED=${result.count}`)
}

main()
  .catch((error) => {
    console.error(error)
    process.exitCode = 1
  })
  .finally(async () => {
    await prisma.$disconnect()
  })