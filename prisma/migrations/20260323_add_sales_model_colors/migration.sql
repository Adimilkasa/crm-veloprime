ALTER TABLE "BrandSetting"
DROP COLUMN "nonBaseColorSurchargeGross",
DROP COLUMN "nonBaseColorSurchargeNet";

ALTER TABLE "SalesCatalogItem"
ADD COLUMN "colorPaletteId" TEXT;

CREATE TABLE "SalesModelColorPalette" (
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

CREATE TABLE "SalesModelColorOption" (
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

CREATE UNIQUE INDEX "SalesModelColorPalette_brand_model_key" ON "SalesModelColorPalette"("brand", "model");
CREATE INDEX "SalesModelColorPalette_brand_idx" ON "SalesModelColorPalette"("brand");
CREATE UNIQUE INDEX "SalesModelColorOption_paletteId_colorName_key" ON "SalesModelColorOption"("paletteId", "colorName");
CREATE INDEX "SalesModelColorOption_paletteId_isActive_idx" ON "SalesModelColorOption"("paletteId", "isActive");
CREATE INDEX "SalesCatalogItem_colorPaletteId_idx" ON "SalesCatalogItem"("colorPaletteId");

ALTER TABLE "SalesCatalogItem"
ADD CONSTRAINT "SalesCatalogItem_colorPaletteId_fkey"
FOREIGN KEY ("colorPaletteId") REFERENCES "SalesModelColorPalette"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "SalesModelColorPalette"
ADD CONSTRAINT "SalesModelColorPalette_brandSettingId_fkey"
FOREIGN KEY ("brandSettingId") REFERENCES "BrandSetting"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "SalesModelColorOption"
ADD CONSTRAINT "SalesModelColorOption_paletteId_fkey"
FOREIGN KEY ("paletteId") REFERENCES "SalesModelColorPalette"("id") ON DELETE CASCADE ON UPDATE CASCADE;