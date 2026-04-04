'use client'

import { useState } from 'react'
import { Plus, X } from 'lucide-react'

import { LeadsKanbanBoard } from '@/components/leads/LeadsKanbanBoard'

type LeadStage = {
  id: string
  name: string
  color: string
  order: number
  kind: 'OPEN' | 'WON' | 'LOST' | 'HOLD'
}

type ManagedLead = {
  id: string
  source: string
  fullName: string
  email: string | null
  phone: string | null
  interestedModel: string | null
  region: string | null
  stageId: string
  message: string | null
  managerName: string | null
  salespersonId: string | null
  salespersonName: string | null
  nextActionAt: string | null
  details: Array<{
    id: string
    kind: 'INFO' | 'COMMENT'
    label: string
    value: string
    authorName: string | null
    createdAt: string
  }>
  createdAt: string
  updatedAt: string
}

type LeadOfferSummary = {
  id: string
  number: string
  title: string
  status: 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED'
  updatedAt: string
  versionCount: number
}

type SalesUser = {
  id: string
  fullName: string
}

function Overlay({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 bg-[rgba(17,17,17,0.12)] p-4 backdrop-blur-md lg:p-8">
      <div className="crm-overlay mx-auto flex h-full w-full max-w-2xl flex-col overflow-hidden rounded-[28px]">
        <div className="flex items-center justify-between gap-4 border-b border-[rgba(17,17,17,0.05)] px-5 py-4">
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Leady</div>
            <h2 className="mt-1 text-xl font-semibold text-[#1f1f1f]">{title}</h2>
          </div>
          <button type="button" onClick={onClose} className="crm-button-icon inline-flex h-10 w-10 items-center justify-center rounded-2xl text-[#5f5a4f] hover:text-[#8f6b18]">
            <X className="h-4 w-4" />
          </button>
        </div>
        <div className="overflow-y-auto px-5 py-5">{children}</div>
      </div>
    </div>
  )
}

export function LeadsWorkspace({
  leads,
  leadOffersByLeadId,
  stages,
  salesUsers,
  canAssign,
  firstStageId,
  preferredOwnerId,
  stats,
  createLeadAction,
  moveLeadStageAction,
  addLeadInformationAction,
  addLeadCommentAction,
}: {
  leads: ManagedLead[]
  leadOffersByLeadId: Record<string, LeadOfferSummary[]>
  stages: LeadStage[]
  salesUsers: SalesUser[]
  canAssign: boolean
  firstStageId: string
  preferredOwnerId: string
  stats: { visible: number; active: number; won: number; hold: number; stageCount: number }
  createLeadAction: (formData: FormData) => Promise<void>
  moveLeadStageAction: (formData: FormData) => Promise<void>
  addLeadInformationAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  addLeadCommentAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
}) {
  const [isLeadModalOpen, setLeadModalOpen] = useState(false)

  return (
    <main className="grid gap-6">
      <section className="crm-card-strong overflow-hidden rounded-[26px] px-4 py-4 lg:px-5 lg:py-4">
        <div className="flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
          <div className="min-w-0">
            <div className="text-[11px] font-bold uppercase tracking-[0.18em] text-[#8c6715]">Pipeline leadów</div>
            <div className="mt-1 flex flex-col gap-2 xl:flex-row xl:items-center xl:gap-3">
              <h2 className="text-[20px] font-semibold text-[#1f1f1f]">Pipeline leadów</h2>
              <div className="flex flex-wrap gap-2 text-[11px] uppercase tracking-[0.16em] text-[#7a7262]">
                <span className="crm-pill px-3 py-1">Leady: {stats.visible}</span>
                <span className="crm-pill px-3 py-1">Otwarte: {stats.active}</span>
                <span className="crm-pill px-3 py-1">Wygrane: {stats.won}</span>
                <span className="crm-pill px-3 py-1">Wstrzymane: {stats.hold}</span>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap gap-3">
            <button type="button" onClick={() => setLeadModalOpen(true)} className="crm-button-primary inline-flex h-11 items-center justify-center gap-2 rounded-[16px] px-4 text-sm font-semibold">
              <Plus className="h-4 w-4" />
              <span>Nowy lead</span>
            </button>
          </div>
        </div>
      </section>

      <LeadsKanbanBoard
        leads={leads}
        leadOffersByLeadId={leadOffersByLeadId}
        stages={stages}
        moveLeadStageAction={moveLeadStageAction}
        addLeadInformationAction={addLeadInformationAction}
        addLeadCommentAction={addLeadCommentAction}
      />

      {isLeadModalOpen ? (
        <Overlay title="Dodaj nowy lead" onClose={() => setLeadModalOpen(false)}>
          <form action={createLeadAction} className="grid gap-4">
            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Źródło</span>
                <input name="source" defaultValue="Manual" className="crm-input mt-2 w-full px-4 text-sm" placeholder="Landing page" />
              </label>
              <div className="block rounded-[18px] border border-[rgba(17,17,17,0.05)] bg-[rgba(255,255,255,0.72)] px-4 py-3">
                <div className="text-sm font-medium text-[#1f1f1f]">Model</div>
                <p className="mt-2 text-sm leading-6 text-[#6b6b6b]">
                  Model wybieramy dopiero na etapie przygotowania oferty, zgodnie z workflow aplikacji.
                </p>
              </div>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-[#1f1f1f]">Imię i nazwisko</span>
              <input name="fullName" className="crm-input mt-2 w-full px-4 text-sm" placeholder="Jan Kowalski" />
            </label>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Email</span>
                <input name="email" className="crm-input mt-2 w-full px-4 text-sm" placeholder="jan@example.com" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Telefon</span>
                <input name="phone" className="crm-input mt-2 w-full px-4 text-sm" placeholder="+48 500 000 000" />
              </label>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Region</span>
                <input name="region" className="crm-input mt-2 w-full px-4 text-sm" placeholder="Warszawa" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Etap startowy</span>
                <select name="stageId" defaultValue={firstStageId} className="crm-input mt-2 w-full px-4 text-sm">
                  {stages.map((stage) => (
                    <option key={stage.id} value={stage.id}>
                      {stage.name}
                    </option>
                  ))}
                </select>
              </label>
            </div>

            {canAssign ? (
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Opiekun</span>
                <select name="salespersonId" className="crm-input mt-2 w-full px-4 text-sm" defaultValue={preferredOwnerId}>
                  {salesUsers.map((user) => (
                    <option key={user.id} value={user.id}>
                      {user.fullName}
                    </option>
                  ))}
                </select>
              </label>
            ) : null}

            <label className="block">
              <span className="text-sm font-medium text-[#1f1f1f]">Notatka</span>
              <textarea name="message" rows={4} className="crm-input mt-2 w-full px-4 py-3 text-sm" placeholder="Kontekst rozmowy, forma finansowania, planowany follow-up..." />
            </label>

            <button type="submit" className="crm-button-primary inline-flex h-11 items-center justify-center rounded-[16px] px-4 text-sm font-semibold">
              Dodaj lead
            </button>
          </form>
        </Overlay>
      ) : null}

    </main>
  )
}