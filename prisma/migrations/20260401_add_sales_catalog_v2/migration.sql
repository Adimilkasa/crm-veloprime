-- CreateEnum
CREATE TYPE "SalesModelStatus" AS ENUM ('ACTIVE', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "PowertrainType" AS ENUM ('ELECTRIC', 'HYBRID', 'ICE');

-- CreateEnum
CREATE TYPE "DriveType" AS ENUM ('FWD', 'RWD', 'AWD');

-- CreateEnum
CREATE TYPE "SalesPricingStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "AssetCategory" AS ENUM ('PRIMARY', 'EXTERIOR', 'INTERIOR', 'DETAILS', 'PREMIUM', 'SPEC_PDF', 'LOGO', 'OTHER');

-- CreateTable
CREATE TABLE "SalesBrand" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesBrand_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SalesModel" (
    "id" TEXT NOT NULL,
    "brandId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "marketingName" TEXT,
    "status" "SalesModelStatus" NOT NULL DEFAULT 'ACTIVE',
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesModel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SalesVersion" (
    "id" TEXT NOT NULL,
    "modelId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "year" INTEGER,
    "powertrainType" "PowertrainType" NOT NULL,
    "driveType" "DriveType",
    "systemPowerHp" INTEGER,
    "batteryCapacityKwh" DECIMAL(8,2),
    "combustionEnginePowerHp" INTEGER,
    "engineDisplacementCc" INTEGER,
    "rangeKm" INTEGER,
    "notes" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SalesVersionPricing" (
    "id" TEXT NOT NULL,
    "versionId" TEXT NOT NULL,
    "listPriceNet" DECIMAL(12,2) NOT NULL,
    "listPriceGross" DECIMAL(12,2) NOT NULL,
    "basePriceNet" DECIMAL(12,2) NOT NULL,
    "basePriceGross" DECIMAL(12,2) NOT NULL,
    "vatRate" DECIMAL(5,2) NOT NULL DEFAULT 23.00,
    "marginPoolNet" DECIMAL(12,2) NOT NULL,
    "marginPoolGross" DECIMAL(12,2) NOT NULL,
    "pricingStatus" "SalesPricingStatus" NOT NULL DEFAULT 'DRAFT',
    "effectiveFrom" TIMESTAMP(3),
    "effectiveTo" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesVersionPricing_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SalesModelColor" (
    "id" TEXT NOT NULL,
    "modelId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "finishType" TEXT,
    "isBaseColor" BOOLEAN NOT NULL DEFAULT false,
    "hasSurcharge" BOOLEAN NOT NULL DEFAULT false,
    "surchargeNet" DECIMAL(12,2),
    "surchargeGross" DECIMAL(12,2),
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesModelColor_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SalesModelAssetBundle" (
    "id" TEXT NOT NULL,
    "modelId" TEXT NOT NULL,
    "assetsVersionTag" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesModelAssetBundle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SalesAssetFile" (
    "id" TEXT NOT NULL,
    "bundleId" TEXT NOT NULL,
    "category" "AssetCategory" NOT NULL,
    "powertrainType" "PowertrainType",
    "fileName" TEXT NOT NULL,
    "filePath" TEXT NOT NULL,
    "mimeType" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesAssetFile_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SalesBrand_code_key" ON "SalesBrand"("code");

-- CreateIndex
CREATE INDEX "SalesBrand_sortOrder_idx" ON "SalesBrand"("sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "SalesModel_brandId_code_key" ON "SalesModel"("brandId", "code");

-- CreateIndex
CREATE INDEX "SalesModel_brandId_sortOrder_idx" ON "SalesModel"("brandId", "sortOrder");

-- CreateIndex
CREATE INDEX "SalesModel_status_idx" ON "SalesModel"("status");

-- CreateIndex
CREATE UNIQUE INDEX "SalesVersion_modelId_code_key" ON "SalesVersion"("modelId", "code");

-- CreateIndex
CREATE INDEX "SalesVersion_modelId_sortOrder_idx" ON "SalesVersion"("modelId", "sortOrder");

-- CreateIndex
CREATE INDEX "SalesVersion_powertrainType_idx" ON "SalesVersion"("powertrainType");

-- CreateIndex
CREATE INDEX "SalesVersionPricing_versionId_pricingStatus_idx" ON "SalesVersionPricing"("versionId", "pricingStatus");

-- CreateIndex
CREATE INDEX "SalesVersionPricing_effectiveFrom_effectiveTo_idx" ON "SalesVersionPricing"("effectiveFrom", "effectiveTo");

-- CreateIndex
CREATE UNIQUE INDEX "SalesModelColor_modelId_code_key" ON "SalesModelColor"("modelId", "code");

-- CreateIndex
CREATE INDEX "SalesModelColor_modelId_sortOrder_idx" ON "SalesModelColor"("modelId", "sortOrder");

-- CreateIndex
CREATE UNIQUE INDEX "SalesModelAssetBundle_modelId_key" ON "SalesModelAssetBundle"("modelId");

-- CreateIndex
CREATE INDEX "SalesAssetFile_bundleId_category_sortOrder_idx" ON "SalesAssetFile"("bundleId", "category", "sortOrder");

-- CreateIndex
CREATE INDEX "SalesAssetFile_bundleId_powertrainType_idx" ON "SalesAssetFile"("bundleId", "powertrainType");

-- AddForeignKey
ALTER TABLE "SalesModel" ADD CONSTRAINT "SalesModel_brandId_fkey" FOREIGN KEY ("brandId") REFERENCES "SalesBrand"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesVersion" ADD CONSTRAINT "SalesVersion_modelId_fkey" FOREIGN KEY ("modelId") REFERENCES "SalesModel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesVersionPricing" ADD CONSTRAINT "SalesVersionPricing_versionId_fkey" FOREIGN KEY ("versionId") REFERENCES "SalesVersion"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesModelColor" ADD CONSTRAINT "SalesModelColor_modelId_fkey" FOREIGN KEY ("modelId") REFERENCES "SalesModel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesModelAssetBundle" ADD CONSTRAINT "SalesModelAssetBundle_modelId_fkey" FOREIGN KEY ("modelId") REFERENCES "SalesModel"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesAssetFile" ADD CONSTRAINT "SalesAssetFile_bundleId_fkey" FOREIGN KEY ("bundleId") REFERENCES "SalesModelAssetBundle"("id") ON DELETE CASCADE ON UPDATE CASCADE;