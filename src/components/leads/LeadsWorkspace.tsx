'use client'

import { useState } from 'react'
import { Plus, Workflow, X } from 'lucide-react'

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
    <div className="fixed inset-0 z-50 bg-[rgba(3,6,10,0.68)] p-4 backdrop-blur-sm lg:p-8">
      <div className="mx-auto flex h-full w-full max-w-2xl flex-col overflow-hidden rounded-[28px] border border-white/8 bg-[#0f151d] shadow-[0_30px_80px_rgba(0,0,0,0.34)]">
        <div className="flex items-center justify-between gap-4 border-b border-white/8 px-5 py-4">
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Leady</div>
            <h2 className="mt-1 text-xl font-semibold text-white">{title}</h2>
          </div>
          <button type="button" onClick={onClose} className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-white/8 bg-white/[0.03] text-[#d5dce5] transition hover:bg-white/[0.08]">
            <X className="h-4 w-4" />
          </button>
        </div>
        <div className="overflow-y-auto px-5 py-5">{children}</div>
      </div>
    </div>
  )
}

export function LeadsWorkspace({
  roleLabel,
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
  roleLabel: string
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
    <main className="grid gap-4">
      <section className="rounded-[28px] border border-white/8 bg-[rgba(18,24,33,0.78)] px-4 py-4 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:px-5">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div className="min-w-0">
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Pipeline leadów</div>
            <div className="mt-2 flex flex-col gap-2 xl:flex-row xl:items-center xl:gap-4">
              <h2 className="text-2xl font-semibold text-white">Operacyjny kanban sprzedaży</h2>
              <span className="inline-flex w-fit rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
                Rola: {roleLabel}
              </span>
            </div>
            <div className="mt-3 flex flex-wrap gap-2 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
              <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Leady: {stats.visible}</span>
              <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Otwarte: {stats.active}</span>
              <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Wygrane: {stats.won}</span>
              <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Etapy: {stats.stageCount}</span>
            </div>
          </div>

          <div className="flex flex-wrap gap-3">
            <button type="button" onClick={() => setLeadModalOpen(true)} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-4 text-sm font-semibold text-[#111827] transition hover:brightness-105">
              <Plus className="h-4 w-4" />
              <span>Nowy lead</span>
            </button>
            {canManageStages ? (
              <button type="button" onClick={() => setStageModalOpen(true)} className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                <Workflow className="h-4 w-4" />
                <span>Nowy etap</span>
              </button>
            ) : null}
          </div>
        </div>
      </section>

      <LeadsKanbanBoard
        leads={leads}
        stages={stages}
        salesUsers={salesUsers}
        canAssign={canAssign}
        moveLeadStageAction={moveLeadStageAction}
        assignLeadSalespersonAction={assignLeadSalespersonAction}
        addLeadInformationAction={addLeadInformationAction}
        addLeadCommentAction={addLeadCommentAction}
      />

      {isLeadModalOpen ? (
        <Overlay title="Dodaj nowy lead" onClose={() => setLeadModalOpen(false)}>
          <form action={createLeadAction} className="grid gap-4">
            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Źródło</span>
                <input name="source" defaultValue="Manual" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Landing page" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Model</span>
                <input name="interestedModel" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="BYD Seal 6 DM-i" />
              </label>
            </div>

            <label className="block">
              <span className="text-sm font-medium text-white">Imię i nazwisko</span>
              <input name="fullName" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Jan Kowalski" />
            </label>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Email</span>
                <input name="email" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="jan@example.com" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Telefon</span>
                <input name="phone" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="+48 500 000 000" />
              </label>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Region</span>
                <input name="region" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Warszawa" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Etap startowy</span>
                <select name="stageId" defaultValue={firstStageId} className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
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
                <span className="text-sm font-medium text-white">Przypisz handlowca</span>
                <select name="salespersonId" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
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
              <span className="text-sm font-medium text-white">Notatka</span>
              <textarea name="message" rows={4} className="mt-2 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 py-3 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Kontekst rozmowy, forma finansowania, planowany follow-up..." />
            </label>

            <button type="submit" className="inline-flex h-11 items-center justify-center rounded-2xl border border-[rgba(216,180,90,0.4)] bg-[linear-gradient(135deg,#d8b45a,#b98b1d)] px-4 text-sm font-semibold text-[#111827] transition hover:brightness-105">
              Dodaj lead
            </button>
          </form>
        </Overlay>
      ) : null}

      {isStageModalOpen ? (
        <Overlay title="Dodaj etap pipeline" onClose={() => setStageModalOpen(false)}>
          <form action={createLeadStageAction} className="grid gap-4">
            <label className="block">
              <span className="text-sm font-medium text-white">Nazwa etapu</span>
              <input name="name" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Np. Finansowanie ustalone" />
            </label>
            <div className="grid gap-4 md:grid-cols-2">
              <label className="block">
                <span className="text-sm font-medium text-white">Kolor znacznika</span>
                <input name="color" defaultValue="#5aa9e6" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="#5aa9e6" />
              </label>
              <label className="block">
                <span className="text-sm font-medium text-white">Typ etapu</span>
                <select name="kind" defaultValue="OPEN" className="mt-2 h-11 w-full rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                  <option value="OPEN">Otwarte</option>
                  <option value="WON">Wygrane</option>
                  <option value="LOST">Utracone</option>
                </select>
              </label>
            </div>
            <button type="submit" className="inline-flex h-11 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
              Dodaj etap
            </button>
          </form>
        </Overlay>
      ) : null}
    </main>
  )
}