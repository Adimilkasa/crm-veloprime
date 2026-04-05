CREATE TABLE "CustomerWorkflowStageConfig" (
    "id" TEXT NOT NULL,
    "stageKey" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "color" TEXT NOT NULL,
    "sortOrder" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CustomerWorkflowStageConfig_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "CustomerWorkflowStageConfig_stageKey_key" ON "CustomerWorkflowStageConfig"("stageKey");
CREATE INDEX "CustomerWorkflowStageConfig_sortOrder_idx" ON "CustomerWorkflowStageConfig"("sortOrder");