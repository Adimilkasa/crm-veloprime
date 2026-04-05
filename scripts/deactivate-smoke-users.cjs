async function main() {
  const { PrismaClient } = await import('@prisma/client')
  const prisma = new PrismaClient()

  try {
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
  } finally {
    await prisma.$disconnect()
  }
}

main()
  .catch((error) => {
    console.error(error)
    process.exitCode = 1
  })