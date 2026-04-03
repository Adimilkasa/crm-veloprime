-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "public"."UserRole" AS ENUM ('ADMIN', 'DIRECTOR', 'MANAGER', 'SALES');

-- CreateEnum
CREATE TYPE "public"."LeadStatus" AS ENUM ('NEW', 'CONTACTED', 'QUALIFIED', 'OFFER_PREPARED', 'NEGOTIATION', 'WON', 'LOST');

-- CreateEnum
CREATE TYPE "public"."VehicleStatus" AS ENUM ('AVAILABLE', 'RESERVED', 'SOLD', 'HIDDEN');

-- CreateEnum
CREATE TYPE "public"."OfferStatus" AS ENUM ('DRAFT', 'SENT', 'APPROVED', 'REJECTED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "public"."CustomerType" AS ENUM ('PRIVATE', 'BUSINESS');

-- CreateEnum
CREATE TYPE "public"."CommissionValueType" AS ENUM ('AMOUNT', 'PERCENT');

-- CreateEnum
CREATE TYPE "public"."FinancingInputMode" AS ENUM ('AMOUNT', 'PERCENT');

-- CreateEnum
CREATE TYPE "public"."OfferColorKind" AS ENUM ('BASE', 'EXTRA_PAID');

-- CreateTable
CREATE TABLE "public"."User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT,
    "fullName" TEXT NOT NULL,
    "role" "public"."UserRole" NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "phone" TEXT,
    "region" TEXT,
    "teamName" TEXT,
    "reportsToUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Customer" (
    "id" TEXT NOT NULL,
    "fullName" TEXT NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "companyName" TEXT,
    "taxId" TEXT,
    "city" TEXT,
    "notes" TEXT,
    "ownerId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Lead" (
    "id" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "firstName" TEXT,
    "lastName" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "message" TEXT,
    "status" "public"."LeadStatus" NOT NULL DEFAULT 'NEW',
    "interestedModel" TEXT,
    "interestedVehicle" TEXT,
    "region" TEXT,
    "managerId" TEXT,
    "salespersonId" TEXT,
    "customerId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Lead_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Vehicle" (
    "id" TEXT NOT NULL,
    "stockNumber" TEXT NOT NULL,
    "vin" TEXT,
    "brand" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "version" TEXT,
    "year" INTEGER,
    "bodyType" TEXT,
    "powertrain" TEXT,
    "color" TEXT,
    "mileageKm" INTEGER,
    "status" "public"."VehicleStatus" NOT NULL DEFAULT 'AVAILABLE',
    "availableFrom" TIMESTAMP(3),
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."VehiclePrice" (
    "id" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "listPriceGross" DECIMAL(12,2),
    "listPriceNet" DECIMAL(12,2),
    "targetPriceGross" DECIMAL(12,2),
    "targetPriceNet" DECIMAL(12,2),
    "minPriceGross" DECIMAL(12,2),
    "minPriceNet" DECIMAL(12,2),
    "cashPriceGross" DECIMAL(12,2),
    "leaseMonthlyFrom" DECIMAL(12,2),
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VehiclePrice_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."BrandSetting" (
    "id" TEXT NOT NULL,
    "brand" TEXT NOT NULL,
    "defaultCurrency" TEXT NOT NULL DEFAULT 'PLN',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BrandSetting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."FinancingSetting" (
    "id" TEXT NOT NULL,
    "brandSettingId" TEXT NOT NULL,
    "leaseTotalFactor" DECIMAL(6,4) NOT NULL DEFAULT 1.20,
    "disclaimerTemplate" TEXT,
    "allowedTermsJson" JSONB,
    "buyoutLimitsJson" JSONB,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "FinancingSetting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SalesCatalogItem" (
    "id" TEXT NOT NULL,
    "brand" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "version" TEXT NOT NULL,
    "year" TEXT,
    "powertrain" TEXT,
    "powerHp" TEXT,
    "baseColorName" TEXT,
    "listPriceGross" DECIMAL(12,2),
    "listPriceNet" DECIMAL(12,2),
    "basePriceGross" DECIMAL(12,2),
    "basePriceNet" DECIMAL(12,2),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "brandSettingId" TEXT,
    "colorPaletteId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesCatalogItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SalesModelColorPalette" (
    "id" TEXT NOT NULL,
    "brand" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "baseColorName" TEXT NOT NULL,
    "optionalColorSurchargeGross" DECIMAL(12,2),
    "optionalColorSurchargeNet" DECIMAL(12,2),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "brandSettingId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesModelColorPalette_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SalesModelColorOption" (
    "id" TEXT NOT NULL,
    "paletteId" TEXT NOT NULL,
    "colorName" TEXT NOT NULL,
    "isBase" BOOLEAN NOT NULL DEFAULT false,
    "surchargeGross" DECIMAL(12,2),
    "surchargeNet" DECIMAL(12,2),
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesModelColorOption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SalesCommissionRule" (
    "id" TEXT NOT NULL,
    "ownerUserId" TEXT NOT NULL,
    "catalogItemId" TEXT NOT NULL,
    "valueType" "public"."CommissionValueType" NOT NULL,
    "value" DECIMAL(12,4),
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalesCommissionRule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Offer" (
    "id" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "status" "public"."OfferStatus" NOT NULL DEFAULT 'DRAFT',
    "title" TEXT NOT NULL,
    "customerId" TEXT NOT NULL,
    "vehicleId" TEXT,
    "salesCatalogItemId" TEXT,
    "ownerId" TEXT NOT NULL,
    "customerType" "public"."CustomerType" NOT NULL DEFAULT 'PRIVATE',
    "selectedColorKind" "public"."OfferColorKind" NOT NULL DEFAULT 'BASE',
    "selectedColorName" TEXT,
    "colorSurchargeGross" DECIMAL(12,2),
    "colorSurchargeNet" DECIMAL(12,2),
    "discountAmount" DECIMAL(12,2),
    "discountPercent" DECIMAL(7,4),
    "validUntil" TIMESTAMP(3),
    "totalGross" DECIMAL(12,2),
    "totalNet" DECIMAL(12,2),
    "financingVariant" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Offer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."OfferSnapshot" (
    "id" TEXT NOT NULL,
    "offerId" TEXT NOT NULL,
    "salesCatalogItemId" TEXT,
    "customerType" "public"."CustomerType" NOT NULL,
    "selectedColorKind" "public"."OfferColorKind" NOT NULL,
    "selectedColorName" TEXT,
    "listPriceGross" DECIMAL(12,2),
    "listPriceNet" DECIMAL(12,2),
    "basePriceGross" DECIMAL(12,2),
    "basePriceNet" DECIMAL(12,2),
    "colorSurchargeGross" DECIMAL(12,2),
    "colorSurchargeNet" DECIMAL(12,2),
    "marginPoolGross" DECIMAL(12,2),
    "marginPoolNet" DECIMAL(12,2),
    "directorShareAmount" DECIMAL(12,2),
    "managerShareAmount" DECIMAL(12,2),
    "salespersonCommission" DECIMAL(12,2),
    "availableDiscountAmount" DECIMAL(12,2),
    "discountAmount" DECIMAL(12,2),
    "discountPercent" DECIMAL(7,4),
    "finalPriceGross" DECIMAL(12,2),
    "finalPriceNet" DECIMAL(12,2),
    "customerViewJson" JSONB,
    "internalViewJson" JSONB,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OfferSnapshot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."OfferFinancing" (
    "id" TEXT NOT NULL,
    "offerId" TEXT NOT NULL,
    "termMonths" INTEGER NOT NULL,
    "downPaymentInputMode" "public"."FinancingInputMode" NOT NULL,
    "downPaymentInputValue" DECIMAL(12,2) NOT NULL,
    "downPaymentAmount" DECIMAL(12,2),
    "downPaymentPercent" DECIMAL(7,4),
    "buyoutPercent" DECIMAL(7,4),
    "buyoutAmount" DECIMAL(12,2),
    "financedAssetValue" DECIMAL(12,2),
    "leaseTotalFactor" DECIMAL(6,4),
    "totalLeaseCost" DECIMAL(12,2),
    "estimatedInstallment" DECIMAL(12,2),
    "disclaimerText" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "OfferFinancing_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."OfferVersion" (
    "id" TEXT NOT NULL,
    "offerId" TEXT NOT NULL,
    "versionNumber" INTEGER NOT NULL,
    "pdfUrl" TEXT,
    "payloadJson" JSONB,
    "customerSnapshotJson" JSONB,
    "internalSnapshotJson" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OfferVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."ActivityLog" (
    "id" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "description" TEXT,
    "payloadJson" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ActivityLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "public"."User"("email");

-- CreateIndex
CREATE INDEX "User_reportsToUserId_idx" ON "public"."User"("reportsToUserId");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_stockNumber_key" ON "public"."Vehicle"("stockNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_vin_key" ON "public"."Vehicle"("vin");

-- CreateIndex
CREATE UNIQUE INDEX "VehiclePrice_vehicleId_key" ON "public"."VehiclePrice"("vehicleId");

-- CreateIndex
CREATE UNIQUE INDEX "BrandSetting_brand_key" ON "public"."BrandSetting"("brand");

-- CreateIndex
CREATE UNIQUE INDEX "FinancingSetting_brandSettingId_key" ON "public"."FinancingSetting"("brandSettingId");

-- CreateIndex
CREATE INDEX "SalesCatalogItem_brand_model_idx" ON "public"."SalesCatalogItem"("brand", "model");

-- CreateIndex
CREATE INDEX "SalesCatalogItem_isActive_idx" ON "public"."SalesCatalogItem"("isActive");

-- CreateIndex
CREATE UNIQUE INDEX "SalesCatalogItem_brand_model_version_year_key" ON "public"."SalesCatalogItem"("brand", "model", "version", "year");

-- CreateIndex
CREATE INDEX "SalesModelColorPalette_brand_idx" ON "public"."SalesModelColorPalette"("brand");

-- CreateIndex
CREATE UNIQUE INDEX "SalesModelColorPalette_brand_model_key" ON "public"."SalesModelColorPalette"("brand", "model");

-- CreateIndex
CREATE INDEX "SalesModelColorOption_paletteId_isActive_idx" ON "public"."SalesModelColorOption"("paletteId", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "SalesModelColorOption_paletteId_colorName_key" ON "public"."SalesModelColorOption"("paletteId", "colorName");

-- CreateIndex
CREATE INDEX "SalesCommissionRule_ownerUserId_isActive_idx" ON "public"."SalesCommissionRule"("ownerUserId", "isActive");

-- CreateIndex
CREATE UNIQUE INDEX "SalesCommissionRule_ownerUserId_catalogItemId_key" ON "public"."SalesCommissionRule"("ownerUserId", "catalogItemId");

-- CreateIndex
CREATE UNIQUE INDEX "Offer_number_key" ON "public"."Offer"("number");

-- CreateIndex
CREATE INDEX "Offer_salesCatalogItemId_idx" ON "public"."Offer"("salesCatalogItemId");

-- CreateIndex
CREATE UNIQUE INDEX "OfferSnapshot_offerId_key" ON "public"."OfferSnapshot"("offerId");

-- CreateIndex
CREATE INDEX "OfferSnapshot_salesCatalogItemId_idx" ON "public"."OfferSnapshot"("salesCatalogItemId");

-- CreateIndex
CREATE UNIQUE INDEX "OfferFinancing_offerId_key" ON "public"."OfferFinancing"("offerId");

-- CreateIndex
CREATE INDEX "OfferFinancing_termMonths_idx" ON "public"."OfferFinancing"("termMonths");

-- CreateIndex
CREATE UNIQUE INDEX "OfferVersion_offerId_versionNumber_key" ON "public"."OfferVersion"("offerId", "versionNumber");

-- AddForeignKey
ALTER TABLE "public"."User" ADD CONSTRAINT "User_reportsToUserId_fkey" FOREIGN KEY ("reportsToUserId") REFERENCES "public"."User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Customer" ADD CONSTRAINT "Customer_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "public"."User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Lead" ADD CONSTRAINT "Lead_managerId_fkey" FOREIGN KEY ("managerId") REFERENCES "public"."User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Lead" ADD CONSTRAINT "Lead_salespersonId_fkey" FOREIGN KEY ("salespersonId") REFERENCES "public"."User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Lead" ADD CONSTRAINT "Lead_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."VehiclePrice" ADD CONSTRAINT "VehiclePrice_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "public"."Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."FinancingSetting" ADD CONSTRAINT "FinancingSetting_brandSettingId_fkey" FOREIGN KEY ("brandSettingId") REFERENCES "public"."BrandSetting"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."SalesCatalogItem" ADD CONSTRAINT "SalesCatalogItem_brandSettingId_fkey" FOREIGN KEY ("brandSettingId") REFERENCES "public"."BrandSetting"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."SalesCatalogItem" ADD CONSTRAINT "SalesCatalogItem_colorPaletteId_fkey" FOREIGN KEY ("colorPaletteId") REFERENCES "public"."SalesModelColorPalette"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."SalesModelColorPalette" ADD CONSTRAINT "SalesModelColorPalette_brandSettingId_fkey" FOREIGN KEY ("brandSettingId") REFERENCES "public"."BrandSetting"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."SalesModelColorOption" ADD CONSTRAINT "SalesModelColorOption_paletteId_fkey" FOREIGN KEY ("paletteId") REFERENCES "public"."SalesModelColorPalette"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."SalesCommissionRule" ADD CONSTRAINT "SalesCommissionRule_ownerUserId_fkey" FOREIGN KEY ("ownerUserId") REFERENCES "public"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."SalesCommissionRule" ADD CONSTRAINT "SalesCommissionRule_catalogItemId_fkey" FOREIGN KEY ("catalogItemId") REFERENCES "public"."SalesCatalogItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Offer" ADD CONSTRAINT "Offer_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Offer" ADD CONSTRAINT "Offer_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "public"."Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Offer" ADD CONSTRAINT "Offer_salesCatalogItemId_fkey" FOREIGN KEY ("salesCatalogItemId") REFERENCES "public"."SalesCatalogItem"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Offer" ADD CONSTRAINT "Offer_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "public"."User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."OfferSnapshot" ADD CONSTRAINT "OfferSnapshot_offerId_fkey" FOREIGN KEY ("offerId") REFERENCES "public"."Offer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."OfferSnapshot" ADD CONSTRAINT "OfferSnapshot_salesCatalogItemId_fkey" FOREIGN KEY ("salesCatalogItemId") REFERENCES "public"."SalesCatalogItem"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."OfferFinancing" ADD CONSTRAINT "OfferFinancing_offerId_fkey" FOREIGN KEY ("offerId") REFERENCES "public"."Offer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."OfferVersion" ADD CONSTRAINT "OfferVersion_offerId_fkey" FOREIGN KEY ("offerId") REFERENCES "public"."Offer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ActivityLog" ADD CONSTRAINT "ActivityLog_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "public"."User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

