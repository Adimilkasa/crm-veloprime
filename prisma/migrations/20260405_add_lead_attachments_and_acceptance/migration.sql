ALTER TABLE "Lead"
ADD COLUMN "acceptedOfferId" TEXT,
ADD COLUMN "acceptedAt" TIMESTAMP(3);

CREATE TABLE "LeadAttachment" (
  "id" TEXT NOT NULL,
  "leadId" TEXT NOT NULL,
  "fileName" TEXT NOT NULL,
  "fileUrl" TEXT NOT NULL,
  "mimeType" TEXT,
  "sizeBytes" INTEGER NOT NULL,
  "uploadedByUserId" TEXT,
  "uploadedByName" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "LeadAttachment_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "LeadAttachment_leadId_createdAt_idx" ON "LeadAttachment"("leadId", "createdAt");

ALTER TABLE "LeadAttachment"
ADD CONSTRAINT "LeadAttachment_leadId_fkey"
FOREIGN KEY ("leadId") REFERENCES "Lead"("id") ON DELETE CASCADE ON UPDATE CASCADE;