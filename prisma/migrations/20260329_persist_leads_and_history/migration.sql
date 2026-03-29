CREATE TYPE "LeadPipelineStage" AS ENUM (
  'NEW_LEAD',
  'FIRST_CONTACT',
  'FOLLOW_UP',
  'MEETING_SCHEDULED',
  'OFFER_SHARED',
  'WON',
  'LOST',
  'ON_HOLD'
);

CREATE TYPE "LeadDetailEntryKind" AS ENUM ('INFO', 'COMMENT');

ALTER TABLE "User"
ADD COLUMN IF NOT EXISTS "phone" TEXT;

ALTER TABLE "Lead"
ADD COLUMN IF NOT EXISTS "pipelineStage" "LeadPipelineStage" NOT NULL DEFAULT 'NEW_LEAD',
ADD COLUMN IF NOT EXISTS "nextActionAt" TIMESTAMP(3);

CREATE TABLE IF NOT EXISTS "LeadDetailEntry" (
  "id" TEXT NOT NULL,
  "leadId" TEXT NOT NULL,
  "kind" "LeadDetailEntryKind" NOT NULL DEFAULT 'INFO',
  "label" TEXT NOT NULL,
  "value" TEXT NOT NULL,
  "authorUserId" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "LeadDetailEntry_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "Lead_pipelineStage_idx" ON "Lead"("pipelineStage");
CREATE INDEX IF NOT EXISTS "Lead_salespersonId_idx" ON "Lead"("salespersonId");
CREATE INDEX IF NOT EXISTS "Lead_updatedAt_idx" ON "Lead"("updatedAt");
CREATE INDEX IF NOT EXISTS "LeadDetailEntry_leadId_createdAt_idx" ON "LeadDetailEntry"("leadId", "createdAt");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'LeadDetailEntry_leadId_fkey'
  ) THEN
    ALTER TABLE "LeadDetailEntry"
    ADD CONSTRAINT "LeadDetailEntry_leadId_fkey"
    FOREIGN KEY ("leadId") REFERENCES "Lead"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'LeadDetailEntry_authorUserId_fkey'
  ) THEN
    ALTER TABLE "LeadDetailEntry"
    ADD CONSTRAINT "LeadDetailEntry_authorUserId_fkey"
    FOREIGN KEY ("authorUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;