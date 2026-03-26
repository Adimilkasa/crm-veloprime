'use client'

import Link from 'next/link'
import { useEffect, useRef, useState, useTransition } from 'react'
import { useRouter } from 'next/navigation'
import { ArrowLeft, CalendarClock, FilePlus2, FileText, GripVertical, Phone, Plus, Search, UserRound, X } from 'lucide-react'

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

type LeadOfferSummary = {
  id: string
  number: string
  title: string
  status: 'DRAFT' | 'SENT' | 'APPROVED' | 'REJECTED' | 'EXPIRED'
  updatedAt: string
  versionCount: number
  pdfHref: string
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
    borderColor: `${stage.color}66`,
    background: `linear-gradient(180deg, ${stage.color}28 0%, ${stage.color}10 100%)`,
  }
}

function getStageHeaderSurface(stage: LeadStage) {
  return {
    borderColor: `${stage.color}55`,
    background: `linear-gradient(135deg, ${stage.color}32 0%, rgba(255,255,255,0.96) 78%)`,
  }
}

function getStageBadgeSurface(stage: LeadStage) {
  return {
    borderColor: `${stage.color}66`,
    backgroundColor: `${stage.color}22`,
    color: '#2c2417',
  }
}

function getLeadCardSurface(stage: LeadStage, hasOwner: boolean) {
  return {
    borderColor: hasOwner ? `${stage.color}3f` : `${stage.color}66`,
    background: hasOwner
      ? `linear-gradient(180deg, rgba(255,255,255,0.98) 0%, ${stage.color}0f 100%)`
      : `linear-gradient(180deg, ${stage.color}1e 0%, rgba(255,250,240,0.98) 100%)`,
    boxShadow: hasOwner
      ? '0 12px 26px rgba(31,31,31,0.05)'
      : '0 14px 28px rgba(31,31,31,0.06)',
  }
}

function getLeadMetaSurface(stage: LeadStage) {
  return {
    borderColor: `${stage.color}2f`,
    background: `linear-gradient(180deg, rgba(255,255,255,0.88) 0%, ${stage.color}0d 100%)`,
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

function getOfferStatusLabel(status: LeadOfferSummary['status']) {
  switch (status) {
    case 'APPROVED':
      return 'Zaakceptowana'
    case 'SENT':
      return 'Wysłana'
    case 'REJECTED':
      return 'Odrzucona'
    case 'EXPIRED':
      return 'Wygasła'
    default:
      return 'Szkic'
  }
}

function getOfferStatusClassName(status: LeadOfferSummary['status']) {
  switch (status) {
    case 'APPROVED':
      return 'border-[#d9ece4] bg-[#f4fbf8] text-[#3f7d64]'
    case 'SENT':
      return 'border-[#dbe7f6] bg-[#f8fbff] text-[#4a90e2]'
    case 'REJECTED':
      return 'border-[#f1d4d2] bg-[#fff5f4] text-[#a64b45]'
    case 'EXPIRED':
      return 'border-[#e8e1d4] bg-[#fcfbf8] text-[#7a7262]'
    default:
      return 'border-[#efe0ba] bg-[#fffaf0] text-[#9d7b27]'
  }
}

function LeadDetailsScreen({
  selectedLead,
  leadOffers,
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
  leadOffers: LeadOfferSummary[]
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
    <div className="flex h-full w-full flex-col overflow-hidden bg-[radial-gradient(circle_at_top,rgba(201,161,59,0.10),transparent_30%),linear-gradient(180deg,#fcfbf8,#f6f3ec)]" onClick={(event) => event.stopPropagation()}>
      <div className="flex items-start justify-between gap-4 border-b border-[#ebe4d8] px-4 py-4 sm:px-6 sm:py-5">
        <div className="flex items-start gap-3">
          <button type="button" onClick={onClose} className="inline-flex h-11 w-11 items-center justify-center rounded-2xl border border-[#e6dece] bg-white text-[#5f5a4f] transition hover:border-[rgba(201,161,59,0.24)] hover:text-[#8f6b18]">
            <ArrowLeft className="h-4 w-4" />
          </button>
          <div>
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Szczegóły leada</div>
            <h3 className="mt-2 text-[28px] font-semibold text-[#1f1f1f]">{selectedLead.fullName}</h3>
            <div className="mt-2 flex flex-wrap gap-2 text-[11px] uppercase tracking-[0.16em] text-[#7a7262]">
              <span className="rounded-full border border-[#e7dfd0] bg-white px-3 py-1">{selectedLead.source}</span>
              {selectedLead.interestedModel ? (
                <span className="rounded-full border border-[#e7dfd0] bg-white px-3 py-1">{selectedLead.interestedModel}</span>
              ) : null}
              {selectedLead.region ? (
                <span className="rounded-full border border-[#e7dfd0] bg-white px-3 py-1">{selectedLead.region}</span>
              ) : null}
            </div>
          </div>
        </div>
        <button type="button" onClick={onClose} className="inline-flex h-11 w-11 items-center justify-center rounded-2xl border border-[#e6dece] bg-white text-[#5f5a4f] transition hover:border-[rgba(201,161,59,0.24)] hover:text-[#8f6b18]">
          <X className="h-4 w-4" />
        </button>
      </div>

      <div className="grid flex-1 gap-4 overflow-y-auto px-4 py-4 sm:px-6 sm:py-5 xl:grid-cols-[0.72fr_1.28fr]">
          <div className="grid gap-3 content-start">
            <div className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
              <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Kontakt</div>
              <div className="mt-3 grid gap-2.5 text-sm text-[#444444]">
                <div className="flex items-center gap-2"><Phone className="h-4 w-4 text-[#9d7b27]" />{selectedLead.phone ?? 'Brak telefonu'}</div>
                <div className="flex items-center gap-2"><UserRound className="h-4 w-4 text-[#9d7b27]" />{selectedLead.email ?? 'Brak emaila'}</div>
              </div>
            </div>

            <div className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
              <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Obsługa</div>
              <div className="mt-3 grid gap-2.5 text-sm text-[#444444]">
                <div>Manager: {selectedLead.managerName ?? 'Nie przypisano'}</div>
                <div>Handlowiec: {selectedLead.salespersonName ?? 'Nie przypisano'}</div>
                <div className="flex items-center gap-2"><CalendarClock className="h-4 w-4 text-[#9d7b27]" />{formatDate(selectedLead.nextActionAt)}</div>
                <div>Aktualizacja: {formatDate(selectedLead.updatedAt)}</div>
              </div>
            </div>

            {selectedLead.message ? (
              <div className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
                <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Notatka startowa</div>
                <p className="mt-3 text-sm leading-7 text-[#666666]">{selectedLead.message}</p>
              </div>
            ) : null}

            <form action={moveLeadStageAction} className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
              <input type="hidden" name="leadId" value={selectedLead.id} />
              <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Etap pipeline</div>
              <div className="mt-3 flex flex-col gap-3">
                <select name="stageId" defaultValue={selectedLead.stageId} className="h-11 min-w-0 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                  {stages.map((stage) => (
                    <option key={stage.id} value={stage.id}>
                      {stage.name}
                    </option>
                  ))}
                </select>
                <button disabled={isPending} type="submit" className="inline-flex h-11 items-center justify-center rounded-[14px] border border-[#e5dfd1] bg-white px-4 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f] disabled:cursor-not-allowed disabled:opacity-60">
                  Zmień etap
                </button>
              </div>
            </form>

            {canAssign ? (
              <form action={assignLeadSalespersonAction} className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
                <input type="hidden" name="leadId" value={selectedLead.id} />
                <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Przypisanie handlowca</div>
                <div className="mt-3 flex flex-col gap-3">
                  <select name="salespersonId" defaultValue={selectedLead.salespersonId ?? ''} className="h-11 min-w-0 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                    <option value="">Bez handlowca</option>
                    {salesUsers.map((user) => (
                      <option key={user.id} value={user.id}>
                        {user.fullName}
                      </option>
                    ))}
                  </select>
                  <button type="submit" className="inline-flex h-11 items-center justify-center rounded-[14px] border border-[#e5dfd1] bg-white px-4 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
                    Zapisz opiekuna
                  </button>
                </div>
              </form>
            ) : null}

            <div className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
              <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Oferty klienta</div>
              {leadOffers.length > 0 ? (
                <>
                  <div className="mt-2 text-sm leading-6 text-[#666666]">Dla tego leada są już przypisane oferty. Możesz wejść od razu do dokumentu PDF albo utworzyć kolejną wersję oferty.</div>
                  <div className="mt-3 grid gap-3">
                    {leadOffers.map((offer) => (
                      <article key={offer.id} className="rounded-[18px] border border-[#e8e1d4] bg-[#fcfbf8] p-3.5">
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <div className="text-sm font-semibold text-[#1f1f1f]">{offer.title}</div>
                            <div className="mt-1 text-xs uppercase tracking-[0.14em] text-[#8a826f]">{offer.number} • aktualizacja {formatDate(offer.updatedAt)}</div>
                          </div>
                          <span className={[
                            'inline-flex rounded-full border px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.16em]',
                            getOfferStatusClassName(offer.status),
                          ].join(' ')}>
                            {getOfferStatusLabel(offer.status)}
                          </span>
                        </div>
                        <div className="mt-3 flex items-center justify-between gap-3">
                          <div className="text-xs uppercase tracking-[0.14em] text-[#8a826f]">Wersje: {offer.versionCount}</div>
                          <Link href={offer.pdfHref} className="inline-flex h-10 items-center justify-center gap-2 rounded-[14px] border border-[#e5dfd1] bg-white px-3 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
                            <FileText className="h-4 w-4" />
                            <span>PDF</span>
                          </Link>
                        </div>
                      </article>
                    ))}
                  </div>
                </>
              ) : (
                <div className="mt-2 text-sm leading-6 text-[#666666]">Ten lead nie ma jeszcze przypisanej oferty. Jeśli chcesz, możesz od razu przejść do generatora i utworzyć pierwszy dokument PDF dla tego klienta.</div>
              )}
              <Link href={`/offers?leadId=${selectedLead.id}`} className="mt-3 inline-flex h-11 items-center justify-center gap-2 rounded-[14px] bg-[#c9a13b] px-4 text-sm font-semibold text-white transition hover:bg-[#b8932f]">
                <FilePlus2 className="h-4 w-4" />
                <span>{leadOffers.length > 0 ? 'Nowa oferta dla tego klienta' : 'Stwórz nową ofertę'}</span>
              </Link>
            </div>
          </div>

          <div className="grid gap-3 content-start">
            <div className="grid gap-3 xl:grid-cols-2">
              <form ref={informationFormRef} action={handleAddInformation} className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
                <input type="hidden" name="leadId" value={selectedLead.id} />
                <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Dodaj informację</div>
                <div className="mt-3 grid gap-3">
                  <input name="label" className="h-11 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Np. Data wydania samochodu" />
                  <textarea name="value" rows={3} className="w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 py-3 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Wpisz własną wartość, datę, ustalenie albo dowolną informację." />
                  <button type="submit" className="inline-flex h-11 items-center justify-center rounded-[14px] border border-[#e5dfd1] bg-white px-4 text-sm font-medium text-[#4d4d4d] transition hover:border-[rgba(201,161,59,0.26)] hover:text-[#1f1f1f]">
                    Dodaj informację
                  </button>
                </div>
              </form>

              <form ref={commentFormRef} action={handleAddComment} className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
                <input type="hidden" name="leadId" value={selectedLead.id} />
                <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Dodaj komentarz</div>
                <div className="mt-3 grid gap-3">
                  <textarea name="value" rows={5} className="w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 py-3 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Komentarz z rozmowy, ustalenie, przypomnienie, follow-up..." />
                  <button type="submit" className="inline-flex h-11 items-center justify-center rounded-[14px] bg-[#c9a13b] px-4 text-sm font-medium text-white transition hover:bg-[#b8932f]">
                    Dodaj komentarz
                  </button>
                </div>
              </form>
            </div>

            {feedback ? (
              <div className={[
                'rounded-[18px] px-4 py-3 text-sm shadow-[0_12px_30px_rgba(31,31,31,0.03)]',
                feedback.type === 'success'
                  ? 'border border-[#d9ece4] bg-[#f4fbf8] text-[#3f7d64]'
                  : 'border border-[#f1d4d2] bg-[#fff5f4] text-[#a64b45]',
              ].join(' ')}>
                {feedback.message}
              </div>
            ) : null}

            <div className="rounded-[22px] border border-[#ebe4d7] bg-white p-4 shadow-[0_14px_32px_rgba(31,31,31,0.04)]">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Informacje i historia</div>
                  <div className="mt-1 text-sm text-[#6b6b6b]">Podział na informacje i komentarze z widocznym autorem każdego wpisu.</div>
                </div>
                <div className="rounded-full border border-[#e7dfd0] bg-[#fcfbf8] px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#7a7262]">
                  {detailEntries.length} wpisów
                </div>
              </div>

              <div className="mt-4 grid gap-4">
                {detailEntries.length > 0 ? (
                  <>
                    <div className="grid gap-2.5">
                      <div className="flex items-center justify-between gap-3">
                        <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#4a90e2]">Informacje</div>
                        <div className="text-[11px] uppercase tracking-[0.16em] text-[#8a826f]">{informationEntries.length} wpisów</div>
                      </div>
                      {informationEntries.length > 0 ? informationEntries.map((detail) => (
                        <article key={detail.id} className="rounded-[16px] border border-[#dbe7f6] bg-[#f8fbff] p-3.5">
                          <div className="flex items-center justify-between gap-3">
                            <div className="flex items-center gap-2">
                              <span className="inline-flex rounded-full border border-[#d6e4f5] bg-white px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-[#4a90e2]">
                                Informacja
                              </span>
                              <span className="text-sm font-semibold text-[#1f1f1f]">{detail.label}</span>
                            </div>
                            <span className="text-xs uppercase tracking-[0.14em] text-[#8a826f]">{formatDate(detail.createdAt)}</span>
                          </div>
                          <div className="mt-2 text-[11px] uppercase tracking-[0.14em] text-[#8a826f]">Autor: {detail.authorName ?? 'System'}</div>
                          <p className="mt-3 text-sm leading-6 text-[#555555]">{detail.value}</p>
                        </article>
                      )) : (
                        <div className="rounded-[18px] border border-dashed border-[#d6e4f5] bg-[#fafcff] px-4 py-6 text-center text-sm text-[#8a826f]">
                          Brak własnych informacji dla tego leada.
                        </div>
                      )}
                    </div>

                    <div className="grid gap-2.5">
                      <div className="flex items-center justify-between gap-3">
                        <div className="text-xs font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">Komentarze</div>
                        <div className="text-[11px] uppercase tracking-[0.16em] text-[#8a826f]">{commentEntries.length} wpisów</div>
                      </div>
                      {commentEntries.length > 0 ? commentEntries.map((detail) => (
                        <article key={detail.id} className="rounded-[16px] border border-[#eee2c0] bg-[#fffaf0] p-3.5">
                          <div className="flex items-center justify-between gap-3">
                            <div className="flex items-center gap-2">
                              <span className="inline-flex rounded-full border border-[#efe0ba] bg-white px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.16em] text-[#9d7b27]">
                                Komentarz
                              </span>
                              <span className="text-sm font-semibold text-[#1f1f1f]">{detail.label}</span>
                            </div>
                            <span className="text-xs uppercase tracking-[0.14em] text-[#8a826f]">{formatDate(detail.createdAt)}</span>
                          </div>
                          <div className="mt-2 text-[11px] uppercase tracking-[0.14em] text-[#8a826f]">Autor: {detail.authorName ?? 'System'}</div>
                          <p className="mt-3 text-sm leading-6 text-[#555555]">{detail.value}</p>
                        </article>
                      )) : (
                        <div className="rounded-[18px] border border-dashed border-[#efe0ba] bg-[#fffdf8] px-4 py-6 text-center text-sm text-[#8a826f]">
                          Brak komentarzy dla tego leada.
                        </div>
                      )}
                    </div>
                  </>
                ) : (
                  <div className="rounded-[18px] border border-dashed border-[#e8dfd0] bg-[#fcfbf8] px-4 py-10 text-center text-sm text-[#8a826f]">
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
  leadOffersByLeadId,
  stages,
  salesUsers,
  canAssign,
  canManageStages,
  moveLeadStageAction,
  createLeadStageAction,
  assignLeadSalespersonAction,
  addLeadInformationAction,
  addLeadCommentAction,
}: {
  leads: ManagedLead[]
  leadOffersByLeadId: Record<string, LeadOfferSummary[]>
  stages: LeadStage[]
  salesUsers: SalesUser[]
  canAssign: boolean
  canManageStages: boolean
  moveLeadStageAction: (formData: FormData) => Promise<void>
  createLeadStageAction: (formData: FormData) => Promise<void>
  assignLeadSalespersonAction: (formData: FormData) => Promise<void>
  addLeadInformationAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  addLeadCommentAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
}) {
  const [selectedLeadId, setSelectedLeadId] = useState<string | null>(null)
  const [draggedLeadId, setDraggedLeadId] = useState<string | null>(null)
  const [hoveredStageId, setHoveredStageId] = useState<string | null>(null)
  const [stageInsertAfter, setStageInsertAfter] = useState<LeadStage | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
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

    return matchesQuery
  })

  const selectedLead = filteredLeads.find((lead) => lead.id === selectedLeadId) ?? leads.find((lead) => lead.id === selectedLeadId) ?? null
  const selectedLeadOffers = selectedLead ? leadOffersByLeadId[selectedLead.id] ?? [] : []

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
      'flex h-full flex-col rounded-[24px] border p-2.5 shadow-[0_18px_42px_rgba(31,31,31,0.05)] transition duration-150',
      isHovered
        ? 'scale-[1.01] border-[rgba(201,161,59,0.28)] shadow-[0_24px_56px_rgba(31,31,31,0.08)] ring-2 ring-[rgba(201,161,59,0.12)]'
        : 'border-[#e8e1d4]',
      !hasLeads ? 'justify-start' : '',
    ].join(' ')
  }

  function getDropZoneClassNames(stageId: string) {
    const isHovered = hoveredStageId === stageId

    return [
      'rounded-[18px] border border-dashed px-4 py-10 text-center text-xs transition duration-150',
      isHovered
        ? 'border-[rgba(201,161,59,0.45)] bg-[rgba(201,161,59,0.10)] text-[#8f6b18]'
        : 'border-[#e7dfd0] bg-[#fcfbf8] text-[#8a826f]',
    ].join(' ')
  }

  function getCardStateClassName(lead: ManagedLead) {
    const hasOwner = Boolean(lead.salespersonId)
    return hasOwner
      ? 'border-[#e7dfd0] bg-white text-[#5f5a4f]'
      : 'border-[#efe3c2] bg-[#fffaf0] text-[#8f6b18]'
  }

  return (
    <section className="grid gap-4">
      {selectedLead ? (
        <div className="fixed inset-0 z-40 bg-[rgba(36,30,20,0.16)] backdrop-blur-md">
          <LeadDetailsScreen
            selectedLead={selectedLead}
            leadOffers={selectedLeadOffers}
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

      {stageInsertAfter ? (
        <div className="fixed inset-0 z-40 bg-[rgba(36,30,20,0.16)] p-4 backdrop-blur-md sm:p-6" onClick={() => setStageInsertAfter(null)}>
          <div className="mx-auto w-full max-w-xl rounded-[28px] border border-[#e9e1d3] bg-[#fcfbf8] shadow-[0_30px_80px_rgba(31,31,31,0.14)]" onClick={(event) => event.stopPropagation()}>
            <div className="flex items-center justify-between gap-4 border-b border-[#eee6d9] px-5 py-4">
              <div>
                <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Pipeline leadów</div>
                <h3 className="mt-1 text-xl font-semibold text-[#1f1f1f]">Dodaj etap po: {stageInsertAfter.name}</h3>
              </div>
              <button type="button" onClick={() => setStageInsertAfter(null)} className="inline-flex h-10 w-10 items-center justify-center rounded-2xl border border-[#ebe3d6] bg-white text-[#5f5a4f] transition hover:border-[rgba(201,161,59,0.24)] hover:text-[#8f6b18]">
                <X className="h-4 w-4" />
              </button>
            </div>

            <form action={createLeadStageAction} className="grid gap-4 px-5 py-5">
              <input type="hidden" name="afterStageId" value={stageInsertAfter.id} />
              <label className="block">
                <span className="text-sm font-medium text-[#1f1f1f]">Nazwa etapu</span>
                <input name="name" className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="Np. Finansowanie ustalone" />
              </label>
              <div className="grid gap-4 md:grid-cols-2">
                <label className="block">
                  <span className="text-sm font-medium text-[#1f1f1f]">Kolor znacznika</span>
                  <input name="color" defaultValue={stageInsertAfter.color} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]" placeholder="#5aa9e6" />
                </label>
                <label className="block">
                  <span className="text-sm font-medium text-[#1f1f1f]">Typ etapu</span>
                  <select name="kind" defaultValue={stageInsertAfter.kind} className="mt-2 h-11 w-full rounded-2xl border border-[#e8e1d4] bg-white px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]">
                    <option value="OPEN">Otwarte</option>
                    <option value="WON">Wygrane</option>
                    <option value="LOST">Utracone</option>
                  </select>
                </label>
              </div>
              <button type="submit" className="inline-flex h-11 items-center justify-center rounded-[14px] bg-[#c9a13b] px-4 text-sm font-semibold text-white transition hover:bg-[#b8932f]">
                Dodaj etap w tym miejscu
              </button>
            </form>
          </div>
        </div>
      ) : null}

      <div className="flex flex-col gap-3 px-1">
        <div className="flex items-center justify-between gap-4">
          <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Kanban leadów</div>
          <div className="text-xs uppercase tracking-[0.16em] text-[#8a826f]">Przeciągnij kartę albo kliknij szczegóły</div>
        </div>

        <div className="grid gap-3 rounded-[24px] border border-[#e8e1d4] bg-white p-3 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:grid-cols-[minmax(0,1fr)_auto] lg:items-center">
          <label className="flex h-12 items-center gap-3 rounded-2xl border border-[#e8e1d4] bg-[#fcfbf8] px-4 text-sm text-[#5f5a4f]">
            <Search className="h-4 w-4 text-[#9d7b27]" />
            <input
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
              className="h-full w-full bg-transparent text-sm text-[#1f1f1f] outline-none placeholder:text-[#8a826f]"
              placeholder="Szukaj po kliencie, modelu, telefonie, emailu, regionie..."
            />
          </label>

          <div className="flex flex-wrap gap-2 text-[11px] uppercase tracking-[0.16em] text-[#7a7262] lg:justify-end">
            <span className="rounded-full border border-[#e7dfd0] bg-[#fcfbf8] px-3 py-1">Widoczne: {filteredLeads.length}</span>
          </div>
        </div>
      </div>

      <div className="relative max-w-full overflow-hidden rounded-[28px]">
        <div className="kanban-scroll-fade-strong overflow-x-auto overscroll-x-contain px-6 pb-2">
          <div className="grid min-w-max grid-flow-col gap-2.5">
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
                  className={`${getColumnClassNames(stage.id, stageLeads.length > 0)} w-[248px] sm:w-[274px] xl:w-[292px]`}
                  style={stageStyle}
                >
                  <div className="rounded-[18px] border px-3 py-3" style={getStageHeaderSurface(stage)}>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <div className="text-sm font-semibold text-[#1f1f1f]">{stage.name}</div>
                        <div className="mt-1 text-[11px] uppercase tracking-[0.16em] text-[#6f6553]">{stageLeads.length} leadów</div>
                      </div>
                      <div className="flex items-center gap-2">
                        {canManageStages ? (
                          <button
                            type="button"
                            onClick={() => setStageInsertAfter(stage)}
                            className="inline-flex h-9 w-9 items-center justify-center rounded-2xl border border-[#e7dfd0] bg-white text-[#8f6b18] transition hover:border-[rgba(201,161,59,0.34)] hover:bg-[#fff8ea]"
                            aria-label={`Dodaj etap po ${stage.name}`}
                          >
                            <Plus className="h-4 w-4" />
                          </button>
                        ) : null}
                        <span className="inline-flex rounded-full border px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.16em]" style={getStageBadgeSurface(stage)}>
                          {stage.kind === 'OPEN' ? 'Otwarte' : stage.kind === 'WON' ? 'Wygrane' : 'Utracone'}
                        </span>
                      </div>
                    </div>
                    <div className="mt-3 text-2xl font-semibold text-[#1f1f1f]">{stageLeads.length}</div>
                  </div>

                  <div className="mt-3 grid min-h-[420px] gap-2 content-start">
                    {stageLeads.map((lead) => (
                      (() => {
                        const newestDetail = getNewestDetail(lead)
                        const leadOffers = leadOffersByLeadId[lead.id] ?? []
                        const hasOwner = Boolean(lead.salespersonId)

                        return (
                          <button
                            key={lead.id}
                            type="button"
                            draggable
                            onDragStart={() => setDraggedLeadId(lead.id)}
                            onDragEnd={() => setDraggedLeadId(null)}
                            onClick={() => setSelectedLeadId(lead.id)}
                            className={[
                              'rounded-[18px] border px-3 py-2.5 text-left transition duration-150 hover:border-[rgba(201,161,59,0.28)] hover:shadow-[0_14px_28px_rgba(31,31,31,0.06)]',
                              draggedLeadId === lead.id ? 'scale-[0.98] rotate-[0.6deg] border-[rgba(201,161,59,0.35)] opacity-60 shadow-[0_16px_30px_rgba(31,31,31,0.10)]' : '',
                            ].join(' ')}
                            style={getLeadCardSurface(stage, hasOwner)}
                          >
                            <div className="flex items-start justify-between gap-2">
                              <div className="min-w-0 flex-1">
                                <div className="truncate text-[13px] font-semibold text-[#1f1f1f]">{lead.fullName}</div>
                                <div className="mt-1 flex flex-wrap items-center gap-1.5">
                                  <span className="inline-flex rounded-full border px-2 py-0.5 text-[9px] uppercase tracking-[0.16em] text-[#6a604d]" style={getLeadMetaSurface(stage)}>
                                    {lead.source}
                                  </span>
                                  {lead.region ? (
                                    <span className="inline-flex rounded-full border px-2 py-0.5 text-[9px] uppercase tracking-[0.16em] text-[#6a604d]" style={getLeadMetaSurface(stage)}>
                                      {lead.region}
                                    </span>
                                  ) : null}
                                </div>
                              </div>
                              <GripVertical className="mt-0.5 h-3.5 w-3.5 shrink-0 text-[#b09a63]" />
                            </div>

                            <div className="mt-2.5 grid gap-1">
                              <div className="truncate text-[12px] font-medium text-[#444444]">{lead.interestedModel ?? 'Model nieokreślony'}</div>
                              <div className="truncate text-[11px] text-[#6b6b6b]">{lead.phone ?? lead.email ?? 'Brak danych kontaktowych'}</div>
                            </div>

                            <div className="mt-2.5 flex flex-wrap gap-1.5">
                              <span className={[
                                'inline-flex rounded-full border px-2 py-1 text-[10px] uppercase tracking-[0.14em]',
                                getCardStateClassName(lead),
                              ].join(' ')}>
                                Opiekun: <span className="ml-1">{lead.salespersonName ?? 'Brak'}</span>
                              </span>
                              {leadOffers.length > 0 ? (
                                <span className="inline-flex rounded-full border px-2 py-1 text-[10px] uppercase tracking-[0.14em] text-[#355f99]" style={{ borderColor: `${stage.color}42`, backgroundColor: `${stage.color}18` }}>
                                  Oferty: <span className="ml-1">{leadOffers.length}</span>
                                </span>
                              ) : null}
                              {newestDetail?.authorName ? (
                                <span className="inline-flex rounded-full border px-2 py-1 text-[10px] uppercase tracking-[0.14em] text-[#5f5a4f]" style={getLeadMetaSurface(stage)}>
                                  Autor: <span className="ml-1">{newestDetail.authorName}</span>
                                </span>
                              ) : null}
                            </div>

                            <div className="mt-2.5 grid gap-1 rounded-2xl border px-2.5 py-2 text-[10px] uppercase tracking-[0.14em] text-[#5c564b]" style={getLeadMetaSurface(stage)}>
                              <div className="flex items-center justify-between gap-2">
                                <span>Następna akcja</span>
                                <span className="text-right text-[#5f5a4f]">
                                  <span className="sm:hidden">{formatShortDate(lead.nextActionAt)}</span>
                                  <span className="hidden sm:inline">{formatShortDate(lead.nextActionAt)}</span>
                                </span>
                              </div>
                              <div className="flex items-center justify-between gap-2">
                                <span>Aktywność</span>
                                <span className="text-right text-[#5f5a4f]">{formatShortDate(newestDetail?.createdAt ?? lead.updatedAt)}</span>
                              </div>
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
      </div>

    </section>
  )
}
