'use client'

import { useEffect, useMemo, useState } from 'react'
import { usePathname, useRouter, useSearchParams } from 'next/navigation'
import { BriefcaseBusiness, RefreshCw, Save, Users } from 'lucide-react'

import type { UserRoleKey } from '@/lib/rbac'

type CommissionValueType = 'AMOUNT' | 'PERCENT'

type CommissionRule = {
  id: string
  userId: string
  userName: string
  userRole: 'DIRECTOR' | 'MANAGER'
  catalogKey: string
  brand: string
  model: string
  version: string
  year: string | null
  valueType: CommissionValueType
  value: number | null
}

function formatDate(value: string | null) {
  if (!value) {
    return 'Brak synchronizacji'
  }

  return new Intl.DateTimeFormat('pl-PL', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

export function CommissionsWorkspace({
  role,
  roleLabel,
  targetUserId,
  editable,
  users,
  rules,
  summary,
  updatedAt,
  updatedBy,
  saveCommissionRulesAction,
  syncCommissionRulesAction,
}: {
  role: UserRoleKey
  roleLabel: string
  targetUserId: string | null
  editable: boolean
  users: Array<{ id: string; fullName: string; role: 'DIRECTOR' | 'MANAGER' }>
  rules: CommissionRule[]
  summary: { total: number; configured: number; missing: number; archived: number }
  updatedAt: string | null
  updatedBy: string | null
  saveCommissionRulesAction: (formData: FormData) => Promise<{ ok: boolean; error?: string }>
  syncCommissionRulesAction: () => Promise<{ ok: boolean; error?: string }>
}) {
  const router = useRouter()
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null)
  const [draftRules, setDraftRules] = useState(rules)

  useEffect(() => {
    setDraftRules(rules)
  }, [rules])

  const groupedRules = useMemo(() => {
    return draftRules.reduce<Record<string, CommissionRule[]>>((groups, rule) => {
      const key = `${rule.brand}`
      groups[key] = groups[key] ? [...groups[key], rule] : [rule]
      return groups
    }, {})
  }, [draftRules])

  function updateRuleValue(ruleId: string, field: 'valueType' | 'value', nextValue: string) {
    setDraftRules((current) => current.map((rule) => {
      if (rule.id !== ruleId) {
        return rule
      }

      if (field === 'valueType') {
        return { ...rule, valueType: nextValue as CommissionValueType }
      }

      const trimmed = nextValue.trim()
      return { ...rule, value: trimmed ? Number(trimmed) : null }
    }))
  }

  async function handleSave() {
    if (!targetUserId) {
      return
    }

    setFeedback(null)
    const formData = new FormData()
    formData.set('targetUserId', targetUserId)
    formData.set('rulesJson', JSON.stringify(draftRules.map((rule) => ({
      id: rule.id,
      valueType: rule.valueType,
      value: rule.value,
    }))))

    const result = await saveCommissionRulesAction(formData)

    if (!result.ok) {
      setFeedback({ type: 'error', message: result.error || 'Nie udało się zapisać prowizji.' })
      return
    }

    setFeedback({ type: 'success', message: 'Lista prowizji została zapisana. Istniejące wpisy zostały zachowane, a nowe modele wymagają tylko uzupełnienia braków.' })
    router.refresh()
  }

  async function handleSync() {
    setFeedback(null)

    const result = await syncCommissionRulesAction()

    if (!result.ok) {
      setFeedback({ type: 'error', message: result.error || 'Nie udało się zsynchronizować listy prowizji.' })
      return
    }

    setFeedback({ type: 'success', message: 'Lista prowizji została zsynchronizowana jawnie. Widok nie uruchamia już synchronizacji przy samym otwarciu.' })
    router.refresh()
  }

  function handleUserChange(nextUserId: string) {
    const params = new URLSearchParams(searchParams.toString())
    params.set('userId', nextUserId)
    router.push(`${pathname}?${params.toString()}`)
  }

  return (
    <main className="grid gap-6">
      <section className="overflow-hidden rounded-[32px] border border-[#e8e2d3] bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f1_52%,#f7f3e8_100%)] px-5 py-5 shadow-[0_24px_70px_rgba(31,31,31,0.06)] lg:px-6 lg:py-6">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between">
          <div className="min-w-0">
            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">Prowizje struktury</div>
            <div className="mt-2 flex flex-col gap-2 xl:flex-row xl:items-center xl:gap-4">
              <h2 className="text-2xl font-semibold text-[#1f1f1f]">Prowizje dyrektora i menedżera per model</h2>
              <span className="inline-flex w-fit rounded-full border border-[#e7dfd0] bg-white px-3 py-1 text-xs uppercase tracking-[0.16em] text-[#6b6b6b] shadow-[0_10px_24px_rgba(31,31,31,0.03)]">
                Rola: {roleLabel}
              </span>
            </div>
            <p className="mt-3 max-w-4xl text-sm leading-7 text-[#6b6b6b]">
              Po zmianie polityki cenowej CRM synchronizuje listę modeli z prowizjami. Dotychczasowe wpisy zostają zachowane,
              a nowe pozycje pojawiają się jako brakujące do uzupełnienia bez przepisywania całej listy od początku.
            </p>
          </div>

          <div className="flex flex-wrap gap-2 text-xs uppercase tracking-[0.16em] text-[#7a7262]">
            <span className="rounded-full border border-[#e7dfd0] bg-white px-3 py-1">Łącznie: {summary.total}</span>
            <span className="rounded-full border border-[#d9ece4] bg-[#f4fbf8] px-3 py-1 text-[#3f7d64]">Uzupełnione: {summary.configured}</span>
            <span className="rounded-full border border-[#efe0ba] bg-[#fffaf0] px-3 py-1 text-[#9d7b27]">Brakujące: {summary.missing}</span>
          </div>
        </div>
      </section>

      <section className="grid gap-4 xl:grid-cols-[320px_minmax(0,1fr)]">
        <div className="grid gap-4">
          <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
            <div className="flex items-center gap-3">
              <Users className="h-5 w-5 text-[#9d7b27]" />
              <div>
                <div className="text-sm font-semibold text-[#1f1f1f]">Zakres konfiguracji</div>
                <div className="text-sm text-[#6b6b6b]">Administrator może podejrzeć każdą listę. Dyrektor i manager edytują własną.</div>
              </div>
            </div>

            {role === 'ADMIN' ? (
              <label className="mt-4 block">
                <span className="text-sm font-medium text-[#1f1f1f]">Użytkownik</span>
                <select
                  value={targetUserId ?? ''}
                  onChange={(event) => handleUserChange(event.target.value)}
                  className="mt-2 h-12 w-full rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)]"
                >
                  {users.map((user) => (
                    <option key={user.id} value={user.id}>
                      {user.fullName} ({user.role === 'DIRECTOR' ? 'Dyrektor' : 'Manager'})
                    </option>
                  ))}
                </select>
              </label>
            ) : (
              <div className="mt-4 rounded-[24px] border border-[#e8e1d4] bg-[#fcfbf8] p-4 text-sm text-[#555555]">
                {users.find((user) => user.id === targetUserId)?.fullName ?? 'Brak użytkownika'}
              </div>
            )}

            <div className="mt-4 rounded-[24px] border border-[#e8e1d4] bg-[#fcfbf8] p-4 text-sm leading-7 text-[#555555]">
              Ostatnia synchronizacja listy: {formatDate(updatedAt)}
              <br />
              Ostatni zapis: {updatedBy ?? 'brak autora'}
            </div>

            {feedback ? (
              <div className={[
                'mt-4 rounded-[18px] px-4 py-3 text-sm shadow-[0_12px_30px_rgba(31,31,31,0.03)]',
                feedback.type === 'success'
                  ? 'border border-[#d9ece4] bg-[#f4fbf8] text-[#3f7d64]'
                  : 'border border-[#f1d4d2] bg-[#fff5f4] text-[#a64b45]',
              ].join(' ')}>
                {feedback.message}
              </div>
            ) : null}

            <button
              type="button"
              onClick={handleSync}
              className="mt-4 inline-flex h-11 w-full items-center justify-center gap-2 rounded-[14px] border border-[#e0d4b2] bg-white px-4 text-sm font-semibold text-[#8d6d1f] transition hover:bg-[#fdf9ef]"
            >
              <RefreshCw className="h-4 w-4" />
              <span>Synchronizuj listę modeli</span>
            </button>

            <button
              type="button"
              onClick={handleSave}
              disabled={!editable || !targetUserId}
              className="mt-4 inline-flex h-11 w-full items-center justify-center gap-2 rounded-[14px] bg-[#c9a13b] px-4 text-sm font-semibold text-white transition hover:bg-[#b8932f] disabled:cursor-not-allowed disabled:opacity-50"
            >
              <Save className="h-4 w-4" />
              <span>Zapisz listę prowizji</span>
            </button>
          </section>

          <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
            <div className="flex items-center gap-3">
              <BriefcaseBusiness className="h-5 w-5 text-[#9d7b27]" />
              <div>
                <div className="text-sm font-semibold text-[#1f1f1f]">Zasada działania</div>
                <div className="text-sm text-[#6b6b6b]">Uzupełniasz tylko brakujące pozycje po zmianie katalogu.</div>
              </div>
            </div>
            <div className="mt-4 grid gap-2 text-sm text-[#555555]">
              <div>1. Aktualizacja polityki cenowej nie usuwa starych prowizji.</div>
              <div>2. Nowy model lub wersja dodaje tylko nową pozycję do listy.</div>
              <div>3. Wartość można ustawić kwotowo albo procentowo dla każdej pozycji osobno.</div>
            </div>
          </section>
        </div>

        <section className="rounded-[28px] border border-[#e8e1d4] bg-white p-4 shadow-[0_18px_42px_rgba(31,31,31,0.05)] lg:p-5">
          <div className="overflow-hidden rounded-[24px] border border-[#e8e1d4]">
            <div className="hidden grid-cols-[0.85fr_1fr_1fr_0.65fr_0.7fr_0.7fr] gap-4 border-b border-[#e8e1d4] bg-[#f7f3ea] px-5 py-4 text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27] lg:grid">
              <span>Marka</span>
              <span>Model</span>
              <span>Wersja</span>
              <span>Rocznik</span>
              <span>Typ</span>
              <span>Wartość</span>
            </div>

            <div className="grid">
              {draftRules.length > 0 ? Object.entries(groupedRules).map(([brand, brandRules]) => (
                <div key={brand} className="border-b border-[#ece5d7] last:border-b-0">
                  <div className="border-b border-[#e8e1d4] bg-[#fcfbf8] px-5 py-3 text-xs font-semibold uppercase tracking-[0.18em] text-[#9d7b27]">
                    {brand}
                  </div>
                  {brandRules.map((rule) => (
                    <div key={rule.id} className="grid gap-4 border-b border-[#ece5d7] px-5 py-4 last:border-b-0 lg:grid-cols-[0.85fr_1fr_1fr_0.65fr_0.7fr_0.7fr] lg:items-center">
                      <div className="text-sm font-semibold text-[#1f1f1f]">{rule.brand}</div>
                      <div className="text-sm text-[#555555]">{rule.model}</div>
                      <div className="text-sm text-[#555555]">{rule.version}</div>
                      <div className="text-sm text-[#555555]">{rule.year ?? '—'}</div>
                      <select
                        value={rule.valueType}
                        onChange={(event) => updateRuleValue(rule.id, 'valueType', event.target.value)}
                        disabled={!editable}
                        className="h-11 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)] disabled:opacity-60"
                      >
                        <option value="AMOUNT">Kwota</option>
                        <option value="PERCENT">Procent</option>
                      </select>
                      <input
                        type="number"
                        step="0.01"
                        value={rule.value ?? ''}
                        onChange={(event) => updateRuleValue(rule.id, 'value', event.target.value)}
                        disabled={!editable}
                        placeholder={rule.valueType === 'PERCENT' ? 'np. 10' : 'np. 3000'}
                        className="h-11 rounded-2xl border border-[#e8e1d4] bg-[#fffdf9] px-4 text-sm text-[#1f1f1f] outline-none transition focus:border-[rgba(201,161,59,0.45)] disabled:opacity-60"
                      />
                    </div>
                  ))}
                </div>
              )) : (
                <div className="px-4 py-16 text-center text-sm text-[#8a826f]">
                  Brak pozycji prowizyjnych. Najpierw zapisz politykę cenową i dodaj dyrektorów lub managerów.
                </div>
              )}
            </div>
          </div>
        </section>
      </section>
    </main>
  )
}