import { redirect } from 'next/navigation'

import {
  addLeadCommentAction,
  addLeadInformationAction,
  assignLeadSalespersonAction,
  createLeadAction,
  createLeadStageAction,
  moveLeadStageAction,
} from '@/app/(app)/leads/actions'
import { LeadsWorkspace } from '@/components/leads/LeadsWorkspace'
import { getSession } from '@/lib/auth'
import { listManagedLeads, listManagedLeadStages } from '@/lib/lead-management'
import { listManagedUsers } from '@/lib/user-management'

export default async function LeadsPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; success?: string }>
}) {
  const session = await getSession()

  if (!session) {
    redirect('/login')
  }

  const [leads, stages, users, { error, success }] = await Promise.all([
    listManagedLeads(session),
    listManagedLeadStages(),
    listManagedUsers(),
    searchParams,
  ])

  const activeSalesUsers = users.filter((user) => user.isActive && user.role === 'SALES')
  const canAssign = session.role === 'ADMIN' || session.role === 'DIRECTOR' || session.role === 'MANAGER'
  const canManageStages = canAssign
  const activePipeline = leads.filter((lead) => {
    const stage = stages.find((entry) => entry.id === lead.stageId)
    return stage?.kind === 'OPEN'
  }).length
  const wonLeads = leads.filter((lead) => {
    const stage = stages.find((entry) => entry.id === lead.stageId)
    return stage?.kind === 'WON'
  }).length
  const firstStageId = stages.find((stage) => stage.kind === 'OPEN')?.id ?? stages[0]?.id ?? ''

  return (
    <>
      {error ? (
        <div className="rounded-[18px] border border-[#f1d4d2] bg-[#fff5f4] px-4 py-3 text-sm text-[#a64b45] shadow-[0_12px_30px_rgba(31,31,31,0.03)]">{error}</div>
      ) : null}
      {success ? (
        <div className="rounded-[18px] border border-[#d9ece4] bg-[#f4fbf8] px-4 py-3 text-sm text-[#3f7d64] shadow-[0_12px_30px_rgba(31,31,31,0.03)]">
          {success === 'created'
            ? 'Lead został dodany do pipeline.'
            : success === 'assigned'
              ? 'Przypisanie handlowca zostało zapisane.'
              : success === 'stage-created'
                ? 'Nowy etap pipeline został dodany.'
                : 'Lead został przesunięty do nowego etapu.'}
        </div>
      ) : null}

      <LeadsWorkspace
        leads={leads}
        stages={stages}
        salesUsers={activeSalesUsers}
        canAssign={canAssign}
        canManageStages={canManageStages}
        firstStageId={firstStageId}
        stats={{
          visible: leads.length,
          active: activePipeline,
          won: wonLeads,
          stageCount: stages.length,
        }}
        createLeadAction={createLeadAction}
        createLeadStageAction={createLeadStageAction}
        moveLeadStageAction={moveLeadStageAction}
        assignLeadSalespersonAction={assignLeadSalespersonAction}
        addLeadInformationAction={addLeadInformationAction}
        addLeadCommentAction={addLeadCommentAction}
      />
    </>
  )
}