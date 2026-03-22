'use client'

import { useEffect, useRef, useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { ArrowLeft, CalendarClock, GripVertical, Phone, Search, SlidersHorizontal, UserRound, X } from 'lucide-react'

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

function formatDate(value: string | null) {
  if (!value) {
    return 'Brak terminu'
  }

  return new Intl.DateTimeFormat('pl-PL', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function formatShortDate(value: string | null) {
  if (!value) {
    return 'Brak'
  }

  return new Intl.DateTimeFormat('pl-PL', {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(value))
}

function getStageSurface(stage: LeadStage) {
  return {
    borderColor: `${stage.color}44`,
    backgroundColor: `${stage.color}12`,
  }
}

function getNewestDetail(lead: ManagedLead) {
  const details = lead.details ?? []

  if (details.length === 0) {
    return null
  }

  return [...details].sort(
    (left, right) => new Date(right.createdAt).getTime() - new Date(left.createdAt).getTime()
  )[0]
}

function LeadDetailsScreen({
  selectedLead,
  stages,
  salesUsers,
  canAssign,
  isPending,
  moveLeadStageAction,
  assignLeadSalespersonAction,
  addLeadInformationAction,
  addLeadCommentAction,
  onClose,
}: {
  selectedLead: ManagedLead | null
  stages: LeadStage[]
  salesUsers: SalesUser[]
  canAssign: boolean
  isPending: boolean
  moveLeadStageAction: (formData: FormData) => Promise<void>
  assignLeadSalespersonAction: (formData: FormData) => Promise<void>
  addLeadInformationAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  addLeadCommentAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  onClose: () => void
}) {
  const router = useRouter()
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null)
  const informationFormRef = useRef<HTMLFormElement>(null)
  const commentFormRef = useRef<HTMLFormElement>(null)

  if (!selectedLead) {
    return null
  }

  const detailEntries = [...(selectedLead.details ?? [])].sort(
    (left, right) => new Date(right.createdAt).getTime() - new Date(left.createdAt).getTime()
  )
  const informationEntries = detailEntries.filter((detail) => detail.kind === 'INFO')
  const commentEntries = detailEntries.filter((detail) => detail.kind === 'COMMENT')

  async function handleAddInformation(formData: FormData) {
    setFeedback(null)
    const result = await addLeadInformationAction(formData)

    if (!result.ok) {
      setFeedback({ type: 'error', message: result.error || 'Nie udało się dodać informacji.' })
      return
    }

    setFeedback({ type: 'success', message: 'Informacja została dodana.' })
    informationFormRef.current?.reset()
    router.refresh()
  }

  async function handleAddComment(formData: FormData) {
    setFeedback(null)
    const result = await addLeadCommentAction(formData)

    if (!result.ok) {
      setFeedback({ type: 'error', message: result.error || 'Nie udało się dodać komentarza.' })
      return
    }

    setFeedback({ type: 'success', message: 'Komentarz został dodany.' })
    commentFormRef.current?.reset()
    router.refresh()
  }

  return (
    <div className="flex h-full w-full flex-col overflow-hidden bg-[radial-gradient(circle_at_top,rgba(216,180,90,0.08),transparent_32%),linear-gradient(180deg,#131a23,#0a0e13)]" onClick={(event) => event.stopPropagation()}>
      <div className="flex items-start justify-between gap-4 border-b border-white/8 px-4 py-4 sm:px-6 sm:py-5">
        <div className="flex items-start gap-3">
          <button type="button" onClick={onClose} className="inline-flex h-11 w-11 items-center justify-center rounded-2xl border border-white/8 bg-white/[0.03] text-[#d5dce5] transition hover:bg-white/[0.08]">
            <ArrowLeft className="h-4 w-4" />
          </button>
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Szczegóły leada</div>
            <h3 className="mt-2 text-3xl font-semibold text-white">{selectedLead.fullName}</h3>
            <p className="mt-2 text-sm text-[#9ba6b2]">Przegląd kontaktu, własne informacje i historia komentarzy dla obsługi klienta.</p>
          </div>
        </div>
        <button type="button" onClick={onClose} className="inline-flex h-11 w-11 items-center justify-center rounded-2xl border border-white/8 bg-white/[0.03] text-[#d5dce5] transition hover:bg-white/[0.08]">
          <X className="h-4 w-4" />
        </button>
      </div>

      <div className="grid flex-1 gap-5 overflow-y-auto px-4 py-4 sm:px-6 sm:py-6 xl:grid-cols-[0.78fr_1.22fr]">
          <div className="grid gap-4 content-start">
            <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
              <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#f3d998]">Kontakt</div>
              <div className="mt-3 grid gap-3 text-sm text-[#d5dce5]">
                <div className="flex items-center gap-2"><Phone className="h-4 w-4 text-[#8b96a3]" />{selectedLead.phone ?? 'Brak telefonu'}</div>
                <div className="flex items-center gap-2"><UserRound className="h-4 w-4 text-[#8b96a3]" />{selectedLead.email ?? 'Brak emaila'}</div>
                <div>Źródło: {selectedLead.source}</div>
                <div>Model: {selectedLead.interestedModel ?? 'Nie wskazano'}</div>
                <div>Region: {selectedLead.region ?? '—'}</div>
              </div>
            </div>

            <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
              <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#f3d998]">Obsługa</div>
              <div className="mt-3 grid gap-3 text-sm text-[#d5dce5]">
                <div>Manager: {selectedLead.managerName ?? 'Nie przypisano'}</div>
                <div>Handlowiec: {selectedLead.salespersonName ?? 'Nie przypisano'}</div>
                <div className="flex items-center gap-2"><CalendarClock className="h-4 w-4 text-[#8b96a3]" />{formatDate(selectedLead.nextActionAt)}</div>
                <div>Utworzono: {formatDate(selectedLead.createdAt)}</div>
                <div>Aktualizacja: {formatDate(selectedLead.updatedAt)}</div>
              </div>
            </div>

            {selectedLead.message ? (
              <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
                <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#f3d998]">Notatka startowa</div>
                <p className="mt-3 text-sm leading-6 text-[#c2cad4]">{selectedLead.message}</p>
              </div>
            ) : null}

            <form action={moveLeadStageAction} className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
              <input type="hidden" name="leadId" value={selectedLead.id} />
              <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#f3d998]">Etap pipeline</div>
              <div className="mt-3 flex flex-col gap-3">
                <select name="stageId" defaultValue={selectedLead.stageId} className="h-11 min-w-0 rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                  {stages.map((stage) => (
                    <option key={stage.id} value={stage.id}>
                      {stage.name}
                    </option>
                  ))}
                </select>
                <button disabled={isPending} type="submit" className="inline-flex h-11 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08] disabled:cursor-not-allowed disabled:opacity-60">
                  Zmień etap
                </button>
              </div>
            </form>

            {canAssign ? (
              <form action={assignLeadSalespersonAction} className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
                <input type="hidden" name="leadId" value={selectedLead.id} />
                <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#f3d998]">Przypisanie handlowca</div>
                <div className="mt-3 flex flex-col gap-3">
                  <select name="salespersonId" defaultValue={selectedLead.salespersonId ?? ''} className="h-11 min-w-0 rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]">
                    <option value="">Bez handlowca</option>
                    {salesUsers.map((user) => (
                      <option key={user.id} value={user.id}>
                        {user.fullName}
                      </option>
                    ))}
                  </select>
                  <button type="submit" className="inline-flex h-11 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                    Zapisz opiekuna
                  </button>
                </div>
              </form>
            ) : null}
          </div>

          <div className="grid gap-4 content-start">
            <div className="grid gap-4 xl:grid-cols-2">
              <form ref={informationFormRef} action={handleAddInformation} className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
                <input type="hidden" name="leadId" value={selectedLead.id} />
                <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#f3d998]">Dodaj informację</div>
                <div className="mt-3 grid gap-3">
                  <input name="label" className="h-11 rounded-2xl border border-white/10 bg-[#131922] px-4 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Np. Data wydania samochodu" />
                  <textarea name="value" rows={3} className="w-full rounded-2xl border border-white/10 bg-[#131922] px-4 py-3 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Wpisz własną wartość, datę, ustalenie albo dowolną informację." />
                  <button type="submit" className="inline-flex h-11 items-center justify-center rounded-2xl border border-white/10 bg-white/[0.04] px-4 text-sm font-medium text-white transition hover:bg-white/[0.08]">
                    Dodaj informację
                  </button>
                </div>
              </form>

              <form ref={commentFormRef} action={handleAddComment} className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
                <input type="hidden" name="leadId" value={selectedLead.id} />
                <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#f3d998]">Dodaj komentarz</div>
                <div className="mt-3 grid gap-3">
                  <textarea name="value" rows={5} className="w-full rounded-2xl border border-white/10 bg-[#131922] px-4 py-3 text-sm text-white outline-none transition focus:border-[rgba(216,180,90,0.45)]" placeholder="Komentarz z rozmowy, ustalenie, przypomnienie, follow-up..." />
                  <button type="submit" className="inline-flex h-11 items-center justify-center rounded-2xl border border-[rgba(216,180,90,0.35)] bg-[rgba(216,180,90,0.12)] px-4 text-sm font-medium text-[#f3d998] transition hover:bg-[rgba(216,180,90,0.18)]">
                    Dodaj komentarz
                  </button>
                </div>
              </form>
            </div>

            {feedback ? (
              <div className={[
                'rounded-2xl px-4 py-3 text-sm',
                feedback.type === 'success'
                  ? 'border border-emerald-400/20 bg-emerald-500/10 text-emerald-200'
                  : 'border border-red-400/20 bg-red-500/10 text-red-200',
              ].join(' ')}>
                {feedback.message}
              </div>
            ) : null}

            <div className="rounded-[22px] border border-white/8 bg-white/[0.03] p-4">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#f3d998]">Informacje i historia</div>
                  <div className="mt-1 text-sm text-[#9ba6b2]">Podział na informacje i komentarze z widocznym autorem każdego wpisu.</div>
                </div>
                <div className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#aeb7c2]">
                  {detailEntries.length} wpisów
                </div>
              </div>

              <div className="mt-4 grid gap-4">
                {detailEntries.length > 0 ? (
                  <>
                    <div className="grid gap-3">
                      <div className="flex items-center justify-between gap-3">
                        <div className="text-xs font-semibold uppercase tracking-[0.16em] text-sky-100">Informacje</div>
                        <div className="text-[11px] uppercase tracking-[0.16em] text-[#7f8a97]">{informationEntries.length} wpisów</div>
                      </div>
                      {informationEntries.length > 0 ? informationEntries.map((detail) => (
                        <article key={detail.id} className="rounded-[18px] border border-sky-400/10 bg-[#111821] p-4">
                          <div className="flex items-center justify-between gap-3">
                            <div className="flex items-center gap-2">
                              <span className="inline-flex rounded-full border border-sky-400/20 bg-sky-500/10 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-sky-100">
                                Informacja
                              </span>
                              <span className="text-sm font-semibold text-white">{detail.label}</span>
                            </div>
                            <span className="text-xs uppercase tracking-[0.14em] text-[#7f8a97]">{formatDate(detail.createdAt)}</span>
                          </div>
                          <div className="mt-2 text-[11px] uppercase tracking-[0.14em] text-[#8b96a3]">Autor: {detail.authorName ?? 'System'}</div>
                          <p className="mt-3 text-sm leading-6 text-[#d5dce5]">{detail.value}</p>
                        </article>
                      )) : (
                        <div className="rounded-[18px] border border-dashed border-sky-400/10 bg-white/[0.03] px-4 py-6 text-center text-sm text-[#7f8a97]">
                          Brak własnych informacji dla tego leada.
                        </div>
                      )}
                    </div>

                    <div className="grid gap-3">
                      <div className="flex items-center justify-between gap-3">
                        <div className="text-xs font-semibold uppercase tracking-[0.16em] text-amber-100">Komentarze</div>
                        <div className="text-[11px] uppercase tracking-[0.16em] text-[#7f8a97]">{commentEntries.length} wpisów</div>
                      </div>
                      {commentEntries.length > 0 ? commentEntries.map((detail) => (
                        <article key={detail.id} className="rounded-[18px] border border-amber-400/10 bg-[#111821] p-4">
                          <div className="flex items-center justify-between gap-3">
                            <div className="flex items-center gap-2">
                              <span className="inline-flex rounded-full border border-amber-400/20 bg-amber-500/10 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-amber-100">
                                Komentarz
                              </span>
                              <span className="text-sm font-semibold text-white">{detail.label}</span>
                            </div>
                            <span className="text-xs uppercase tracking-[0.14em] text-[#7f8a97]">{formatDate(detail.createdAt)}</span>
                          </div>
                          <div className="mt-2 text-[11px] uppercase tracking-[0.14em] text-[#8b96a3]">Autor: {detail.authorName ?? 'System'}</div>
                          <p className="mt-3 text-sm leading-6 text-[#d5dce5]">{detail.value}</p>
                        </article>
                      )) : (
                        <div className="rounded-[18px] border border-dashed border-amber-400/10 bg-white/[0.03] px-4 py-6 text-center text-sm text-[#7f8a97]">
                          Brak komentarzy dla tego leada.
                        </div>
                      )}
                    </div>
                  </>
                ) : (
                  <div className="rounded-[18px] border border-dashed border-white/10 bg-white/[0.03] px-4 py-10 text-center text-sm text-[#7f8a97]">
                    Nie ma jeszcze wpisów. Dodaj własną informację albo komentarz do tego leada.
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
    </div>
  )
}

export function LeadsKanbanBoard({
  leads,
  stages,
  salesUsers,
  canAssign,
  moveLeadStageAction,
  assignLeadSalespersonAction,
  addLeadInformationAction,
  addLeadCommentAction,
}: {
  leads: ManagedLead[]
  stages: LeadStage[]
  salesUsers: SalesUser[]
  canAssign: boolean
  moveLeadStageAction: (formData: FormData) => Promise<void>
  assignLeadSalespersonAction: (formData: FormData) => Promise<void>
  addLeadInformationAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  addLeadCommentAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
}) {
  const [selectedLeadId, setSelectedLeadId] = useState<string | null>(null)
  const [draggedLeadId, setDraggedLeadId] = useState<string | null>(null)
  const [hoveredStageId, setHoveredStageId] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [stageFilter, setStageFilter] = useState('ALL')
  const [ownerFilter, setOwnerFilter] = useState<'ALL' | 'ASSIGNED' | 'UNASSIGNED'>('ALL')
  const [isPending, startTransition] = useTransition()

  const normalizedQuery = searchQuery.trim().toLowerCase()
  const filteredLeads = leads.filter((lead) => {
    const matchesQuery = !normalizedQuery || [
      lead.fullName,
      lead.email,
      lead.phone,
      lead.interestedModel,
      lead.region,
      lead.source,
      lead.salespersonName,
    ].some((value) => value?.toLowerCase().includes(normalizedQuery))

    const matchesStage = stageFilter === 'ALL' || lead.stageId === stageFilter
    const matchesOwner = ownerFilter === 'ALL'
      ? true
      : ownerFilter === 'ASSIGNED'
        ? Boolean(lead.salespersonId)
        : !lead.salespersonId

    return matchesQuery && matchesStage && matchesOwner
  })

  const selectedLead = filteredLeads.find((lead) => lead.id === selectedLeadId) ?? leads.find((lead) => lead.id === selectedLeadId) ?? null

  useEffect(() => {
    if (!selectedLeadId) {
      return
    }

    function handleEscape(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        setSelectedLeadId(null)
      }
    }

    window.addEventListener('keydown', handleEscape)

    return () => {
      window.removeEventListener('keydown', handleEscape)
    }
  }, [selectedLeadId])

  function handleDrop(leadId: string, stageId: string) {
    if (!leadId) {
      return
    }

    const formData = new FormData()
    formData.set('leadId', leadId)
    formData.set('stageId', stageId)

    startTransition(async () => {
      await moveLeadStageAction(formData)
    })
  }

  function getColumnClassNames(stageId: string, hasLeads: boolean) {
    const isHovered = hoveredStageId === stageId

    return [
      'flex h-full flex-col rounded-[24px] border bg-[rgba(18,24,33,0.82)] p-3 shadow-[0_18px_48px_rgba(0,0,0,0.16)] transition duration-150',
      isHovered
        ? 'scale-[1.01] border-white/20 shadow-[0_24px_56px_rgba(0,0,0,0.24)] ring-2 ring-white/10'
        : 'border-white/8',
      !hasLeads ? 'justify-start' : '',
    ].join(' ')
  }

  function getDropZoneClassNames(stageId: string) {
    const isHovered = hoveredStageId === stageId

    return [
      'rounded-[18px] border border-dashed px-4 py-10 text-center text-xs transition duration-150',
      isHovered
        ? 'border-[rgba(216,180,90,0.45)] bg-[rgba(216,180,90,0.12)] text-[#f3d998]'
        : 'border-white/10 bg-white/[0.03] text-[#768190]',
    ].join(' ')
  }

  return (
    <section className="grid gap-3">
      {selectedLead ? (
        <div className="fixed inset-0 z-40 bg-[rgba(4,7,10,0.88)] backdrop-blur-md">
          <LeadDetailsScreen
            selectedLead={selectedLead}
            stages={stages}
            salesUsers={salesUsers}
            canAssign={canAssign}
            isPending={isPending}
            moveLeadStageAction={moveLeadStageAction}
            assignLeadSalespersonAction={assignLeadSalespersonAction}
            addLeadInformationAction={addLeadInformationAction}
            addLeadCommentAction={addLeadCommentAction}
            onClose={() => setSelectedLeadId(null)}
          />
        </div>
      ) : null}

      <div className="flex flex-col gap-3 px-1">
        <div className="flex items-center justify-between gap-4">
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#f3d998]">Kanban leadów</div>
          <div className="text-xs uppercase tracking-[0.16em] text-[#8b96a3]">Przeciągnij kartę albo kliknij szczegóły</div>
        </div>

        <div className="grid gap-3 rounded-[24px] border border-white/8 bg-[rgba(18,24,33,0.78)] p-3 shadow-[0_18px_48px_rgba(0,0,0,0.16)] lg:grid-cols-[minmax(0,1.3fr)_220px_220px_auto] lg:items-center">
          <label className="flex h-12 items-center gap-3 rounded-2xl border border-white/10 bg-[#111821] px-4 text-sm text-[#d5dce5]">
            <Search className="h-4 w-4 text-[#7f8a97]" />
            <input
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
              className="h-full w-full bg-transparent text-sm text-white outline-none placeholder:text-[#64707d]"
              placeholder="Szukaj po kliencie, modelu, telefonie, emailu, regionie..."
            />
          </label>

          <label className="flex h-12 items-center gap-3 rounded-2xl border border-white/10 bg-[#111821] px-4 text-sm text-[#d5dce5]">
            <SlidersHorizontal className="h-4 w-4 text-[#7f8a97]" />
            <select value={stageFilter} onChange={(event) => setStageFilter(event.target.value)} className="h-full w-full bg-transparent text-sm text-white outline-none">
              <option value="ALL">Wszystkie etapy</option>
              {stages.map((stage) => (
                <option key={stage.id} value={stage.id}>{stage.name}</option>
              ))}
            </select>
          </label>

          <label className="flex h-12 items-center gap-3 rounded-2xl border border-white/10 bg-[#111821] px-4 text-sm text-[#d5dce5]">
            <UserRound className="h-4 w-4 text-[#7f8a97]" />
            <select value={ownerFilter} onChange={(event) => setOwnerFilter(event.target.value as 'ALL' | 'ASSIGNED' | 'UNASSIGNED')} className="h-full w-full bg-transparent text-sm text-white outline-none">
              <option value="ALL">Wszyscy opiekunowie</option>
              <option value="ASSIGNED">Tylko przypisane</option>
              <option value="UNASSIGNED">Bez opiekuna</option>
            </select>
          </label>

          <div className="flex flex-wrap gap-2 text-[11px] uppercase tracking-[0.16em] text-[#aeb7c2] lg:justify-end">
            <span className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1">Widoczne: {filteredLeads.length}</span>
            <button type="button" onClick={() => { setSearchQuery(''); setStageFilter('ALL'); setOwnerFilter('ALL') }} className="rounded-full border border-white/8 bg-white/[0.03] px-3 py-1 transition hover:bg-white/[0.08]">
              Reset filtrów
            </button>
          </div>
        </div>
      </div>

      <div className="overflow-x-auto pb-2">
        <div className="grid min-w-max grid-flow-col gap-3">
          {stages.map((stage) => {
            const stageLeads = filteredLeads.filter((lead) => lead.stageId === stage.id)
            const stageStyle = getStageSurface(stage)

            return (
              <section
                key={stage.id}
                onDragEnter={() => setHoveredStageId(stage.id)}
                onDragOver={(event) => {
                  event.preventDefault()
                  if (hoveredStageId !== stage.id) {
                    setHoveredStageId(stage.id)
                  }
                }}
                onDragLeave={(event) => {
                  const nextTarget = event.relatedTarget

                  if (!nextTarget || !(nextTarget instanceof Node) || !event.currentTarget.contains(nextTarget)) {
                    setHoveredStageId((current) => (current === stage.id ? null : current))
                  }
                }}
                onDrop={() => {
                  if (draggedLeadId) {
                    handleDrop(draggedLeadId, stage.id)
                    setDraggedLeadId(null)
                  }
                  setHoveredStageId(null)
                }}
                className={`${getColumnClassNames(stage.id, stageLeads.length > 0)} w-[282px] sm:w-[320px] xl:w-[340px]`}
                style={stageStyle}
              >
                <div className="border-b border-white/8 pb-3">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="text-sm font-semibold text-white">{stage.name}</div>
                      <div className="mt-1 text-[11px] uppercase tracking-[0.16em] text-[#9ba6b2]">{stageLeads.length} leadów</div>
                    </div>
                    <span className="inline-flex rounded-full border px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-white" style={{ borderColor: `${stage.color}66`, backgroundColor: `${stage.color}22` }}>
                      {stage.kind === 'OPEN' ? 'Otwarte' : stage.kind === 'WON' ? 'Wygrane' : 'Utracone'}
                    </span>
                  </div>
                  <div className="mt-3 text-2xl font-semibold text-white">{stageLeads.length}</div>
                </div>

                <div className="mt-3 grid min-h-[420px] gap-2.5 content-start">
                  {stageLeads.map((lead) => (
                    (() => {
                      const newestDetail = getNewestDetail(lead)

                      return (
                        <button
                          key={lead.id}
                          type="button"
                          draggable
                          onDragStart={() => setDraggedLeadId(lead.id)}
                          onDragEnd={() => setDraggedLeadId(null)}
                          onClick={() => setSelectedLeadId(lead.id)}
                          className={[
                            'rounded-[18px] border border-white/8 bg-[#10161d] px-3 py-3 text-left transition duration-150 hover:border-white/16 hover:bg-[#121b24] sm:px-3 sm:py-3',
                            draggedLeadId === lead.id ? 'scale-[0.98] rotate-[0.6deg] border-[rgba(216,180,90,0.35)] opacity-60 shadow-[0_12px_30px_rgba(0,0,0,0.24)]' : '',
                          ].join(' ')}
                        >
                          <div className="flex items-start justify-between gap-2">
                            <div className="min-w-0 flex-1">
                              <div className="truncate text-[13px] font-semibold text-white">{lead.fullName}</div>
                              <div className="mt-1 text-[10px] uppercase tracking-[0.16em] text-[#8b96a3]">{lead.source}</div>
                            </div>
                            <GripVertical className="mt-0.5 h-3.5 w-3.5 shrink-0 text-[#64707d]" />
                          </div>

                          <div className="mt-2.5 grid gap-1 text-[12px] text-[#c2cad4]">
                            <div className="truncate">{lead.interestedModel ?? 'Model nieokreślony'}</div>
                            <div className="truncate sm:hidden">{lead.phone ?? lead.email ?? 'Brak kontaktu'}</div>
                            <div className="hidden truncate sm:block">{lead.email ?? lead.phone ?? 'Brak danych kontaktowych'}</div>
                          </div>

                          <div className="mt-2.5 flex flex-wrap gap-1.5 sm:gap-2">
                            <span className="inline-flex rounded-full border border-white/8 bg-white/[0.03] px-2 py-1 text-[10px] uppercase tracking-[0.14em] text-[#d5dce5]">
                              Opiekun: <span className="ml-1 hidden sm:inline">{lead.salespersonName ?? 'Brak'}</span><span className="ml-1 sm:hidden">{lead.salespersonName ? 'Tak' : 'Nie'}</span>
                            </span>
                            <span className="inline-flex rounded-full border border-white/8 bg-white/[0.03] px-2 py-1 text-[10px] uppercase tracking-[0.14em] text-[#d5dce5]">
                              Region: <span className="ml-1">{lead.region ?? '—'}</span>
                            </span>
                            <span className="hidden sm:inline-flex rounded-full border border-white/8 bg-white/[0.03] px-2 py-1 text-[10px] uppercase tracking-[0.14em] text-[#d5dce5]">
                              Autor: <span className="ml-1">{newestDetail?.authorName ?? 'Brak wpisu'}</span>
                            </span>
                          </div>

                          <div className="mt-2.5 grid gap-1.5 rounded-2xl border border-white/8 bg-white/[0.03] px-2.5 py-2 text-[10px] uppercase tracking-[0.14em] text-[#d5dce5]">
                            <div>Następna akcja: <span className="sm:hidden">{formatShortDate(lead.nextActionAt)}</span><span className="hidden sm:inline">{formatDate(lead.nextActionAt)}</span></div>
                            <div className="sm:hidden">Aktywność: {formatShortDate(newestDetail?.createdAt ?? lead.updatedAt)}</div>
                            <div className="hidden sm:block">Utworzono: {formatDate(lead.createdAt)}</div>
                            <div className="hidden sm:block">Ostatnia aktywność: {formatDate(newestDetail?.createdAt ?? lead.updatedAt)}</div>
                          </div>
                        </button>
                      )
                    })()
                  ))}

                  <div className={getDropZoneClassNames(stage.id)}>
                    {hoveredStageId === stage.id
                      ? 'Upuść leada, aby przenieść go do tego etapu.'
                      : stageLeads.length === 0
                        ? 'Upuść pierwszy lead tutaj.'
                        : 'Miejsce na kolejnego leada.'}
                  </div>
                </div>
              </section>
            )
          })}
        </div>
      </div>

    </section>
  )
}
