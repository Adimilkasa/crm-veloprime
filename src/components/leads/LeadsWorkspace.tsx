'use client'

import { useState } from 'react'
import { Plus, X } from 'lucide-react'

import { LeadsKanbanBoard } from '@/components/leads/LeadsKanbanBoard'

type LeadStage = {
  id: string
  name: string
  color: string
  order: number
  kind: 'OPEN' | 'WON' | 'LOST'
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

type SalesUser = {
  id: string
  fullName: string
}

function Overlay({ title, onClose, children }: { title: string; onClose: () => void; children: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 bg-[rgba(32,28,19,0.22)] p-4 backdrop-blur-sm lg:p-8">
      <div className="mx-auto flex h-full w-full max-w-2xl flex-col overflow-hidden rounded-[28px] border border-[#e9e1d3] bg-[#fcfbf8] shadow-[0_30px_80px_rgba(31,31,31,0.14)]">
        <div className="flex items-center justify-between gap-4 border-b border-[#eee6d9] px-5 py-4">
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Leady</div>
            <h2 className="mt-1 text-xl font-semibold text-[#1f1f1f]">{title}</h2>
          </div>
          <button type="button" onClick={onClose} className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-[#ebe3d6] bg-white text-[#5f5a4f] transition hover:border-[rgba(201,161,59,0.24)] hover:text-[#8f6b18]">
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
  stages,
  salesUsers,
  canAssign,
  canManageStages,
  firstStageId,
  stats,
  createLeadAction,
  createLeadStageAction,
  moveLeadStageAction,
  assignLeadSalespersonAction,
  addLeadInformationAction,
  addLeadCommentAction,
}: {
  leads: ManagedLead[]
  stages: LeadStage[]
  salesUsers: SalesUser[]
  canAssign: boolean
  canManageStages: boolean
  firstStageId: string
  stats: { visible: number; active: number; won: number; stageCount: number }
  createLeadAction: (formData: FormData) => Promise<void>
  createLeadStageAction: (formData: FormData) => Promise<void>
  moveLeadStageAction: (formData: FormData) => Promise<void>
  assignLeadSalespersonAction: (formData: FormData) => Promise<void>
  addLeadInformationAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  addLeadCommentAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
}) {
  const [isLeadModalOpen, setLeadModalOpen] = useState(false)
  const [isStageModalOpen, setStageModalOpen] = useState(false)

  return (
    <main className="grid gap-6">
      <section className="overflow-hidden rounded-[32px] border border-[#e8e2d3] bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f1_52%,#f7f3e8_100%)] px-5 py-5 shadow-[0_24px_70px_rgba(31,31,31,0.06)] lg:px-6 lg:py-6">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div className="min-w-0">
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Pipeline leadów</div>
            <h2 className="mt-2 text-2xl font-semibold text-[#1f1f1f]">Pipeline leadów</h2>
            <div className="mt-3 flex flex-wrap gap-2 text-xs uppercase tracking-[0.16em] text-[#7a7262]">
              <span className="rounded-full border border-[#e7dfd0] bg-white px-3 py-1">Leady: {stats.visible}</span>
              <span className="rounded-full border border-[#e7dfd0] bg-white px-3 py-1">Otwarte: {stats.active}</span>
              <span className="rounded-full border border-[#e7dfd0] bg-white px-3 py-1">Wygrane: {stats.won}</span>
            </div>
          </div>

          <div className="flex flex-wrap gap-3">
            <button type="button" onClick={() => setLeadModalOpen(true)} className="inline-flex h-11 items-center justify-center gap-2 rounded-[14px] bg-[#c9a13b] px-4 text-sm font-semibold text-white shadow-[0_16px_32px_rgba(201,161,59,0.24)] transition hover:bg-[#b8932f]">
              <Plus className="h-4 w-4" />
              <span>Nowy lead</span>
            </button>
          </div>
        </div>
      </section>

      <LeadsKanbanBoard
        leads={leads}
        stages={stages}
        salesUsers={salesUsers}
        canAssign={canAssign}
        canManageStages={canManageStages}
        moveLeadStageAction={moveLeadStageAction}
        createLeadStageAction={createLeadStageAction}
        assignLeadSalespersonAction={assignLeadSalespersonAction}
        addLeadInformationAction={addLeadInformationAction}
        addLeadCommentAction={addLeadCommentAction}
      />

      {isLeadModalOpen ? (
        <Overlay title="Dodaj nowy lead" onClose={() => setLeadModalOpen(false)}>
          <form action={createLeadAction} className="grid gap-4">
            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Źródło</span>
                <input name="source" defaultValue="Manual" className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Landing page" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Model</span>
                <input name="interestedModel" className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="BYD Seal 6 DM-i" />
              </label>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-[#1f1f1f]">Imię i nazwisko</span>
              <input name="fullName" className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Jan Kowalski" />
            </label>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Email</span>
                <input name="email" className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="jan@example.com" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Telefon</span>
                <input name="phone" className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="+48 500 000 000" />
              </label>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Region</span>
                <input name="region" className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Warszawa" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Etap startowy</span>
                <select name="stageId" defaultValue={firstStageId} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
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
                <span className="text-sm font-medium text-[#1f1f1f]">Przypisz handlowca</span>
                <select name="salespersonId" className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                  <option value="">Bez przypisania</option>
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
              <textarea name="message" rows={4} className="mt-2 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 py-3 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Kontekst rozmowy, forma finansowania, planowany follow-up..." />
            </label>

            <button type="submit" className="inline-flex h-11 items-center justify-center rounded-[14px] bg-[#c9a13b] px-4 text-sm font-semibold text-white transition hover:bg-[#b8932f]">
              Dodaj lead
            </button>
          </form>
        </Overlay>
      ) : null}

    </main>
  )
}