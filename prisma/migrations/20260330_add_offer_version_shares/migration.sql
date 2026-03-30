ALTER TABLE "OfferVersion"
ADD COLUMN "shareToken" TEXT,
ADD COLUMN "sharedAt" TIMESTAMP(3),
ADD COLUMN "shareExpiresAt" TIMESTAMP(3);

CREATE UNIQUE INDEX "OfferVersion_shareToken_key" ON "OfferVersion"("shareToken");