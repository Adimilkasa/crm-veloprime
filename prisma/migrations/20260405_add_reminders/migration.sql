CREATE TABLE "Reminder" (
  "id" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "note" TEXT,
  "remindAt" TIMESTAMP(3) NOT NULL,
  "isCompleted" BOOLEAN NOT NULL DEFAULT false,
  "completedAt" TIMESTAMP(3),
  "leadId" TEXT,
  "leadNameSnapshot" TEXT,
  "ownerUserId" TEXT,
  "ownerNameSnapshot" TEXT,
  "createdByUserId" TEXT,
  "createdByNameSnapshot" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "Reminder_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Reminder_ownerUserId_remindAt_idx" ON "Reminder"("ownerUserId", "remindAt");
CREATE INDEX "Reminder_leadId_remindAt_idx" ON "Reminder"("leadId", "remindAt");
CREATE INDEX "Reminder_isCompleted_remindAt_idx" ON "Reminder"("isCompleted", "remindAt");

ALTER TABLE "Reminder"
ADD CONSTRAINT "Reminder_leadId_fkey"
FOREIGN KEY ("leadId") REFERENCES "Lead"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Reminder"
ADD CONSTRAINT "Reminder_ownerUserId_fkey"
FOREIGN KEY ("ownerUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "Reminder"
ADD CONSTRAINT "Reminder_createdByUserId_fkey"
FOREIGN KEY ("createdByUserId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;