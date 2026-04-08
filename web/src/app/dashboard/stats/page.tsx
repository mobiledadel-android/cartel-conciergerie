'use client'

import { useEffect, useState } from 'react'
import { getSupabase } from '@/lib/supabase'
import { formatPrice } from '@/lib/format'

type CategoryStat = {
  category: string
  count: number
  revenue: number
}

export default function StatsPage() {
  const [missionsByStatus, setMissionsByStatus] = useState<Record<string, number>>({})
  const [categoryStats, setCategoryStats] = useState<CategoryStat[]>([])
  const [monthlyRevenue, setMonthlyRevenue] = useState<{ month: string; revenue: number }[]>([])
  const [topPrestataires, setTopPrestataires] = useState<{ name: string; missions: number; revenue: number }[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => { loadStats() }, [])

  async function loadStats() {
    const { data: missions } = await getSupabase()
      .from('missions')
      .select('*, services(category)')

    const { data: profiles } = await getSupabase()
      .from('profiles')
      .select('id, first_name, last_name')
      .eq('role', 'prestataire')

    if (!missions) { setLoading(false); return }

    // Missions par statut
    const byStatus: Record<string, number> = {}
    missions.forEach(m => {
      byStatus[m.status] = (byStatus[m.status] || 0) + 1
    })
    setMissionsByStatus(byStatus)

    // Stats par catégorie
    const catMap: Record<string, CategoryStat> = {}
    missions.forEach(m => {
      const cat = m.services?.category || 'autre'
      if (!catMap[cat]) catMap[cat] = { category: cat, count: 0, revenue: 0 }
      catMap[cat].count++
      if (m.status === 'completed') catMap[cat].revenue += m.total_price || 0
    })
    setCategoryStats(Object.values(catMap).sort((a, b) => b.count - a.count))

    // Revenus mensuels
    const monthMap: Record<string, number> = {}
    missions.filter(m => m.status === 'completed').forEach(m => {
      const d = new Date(m.created_at)
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
      monthMap[key] = (monthMap[key] || 0) + (m.total_price || 0)
    })
    setMonthlyRevenue(
      Object.entries(monthMap)
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([month, revenue]) => ({ month, revenue }))
    )

    // Top prestataires
    const prestaMap: Record<string, { name: string; missions: number; revenue: number }> = {}
    missions.filter(m => m.prestataire_id && m.status === 'completed').forEach(m => {
      if (!prestaMap[m.prestataire_id]) {
        const p = profiles?.find(p => p.id === m.prestataire_id)
        prestaMap[m.prestataire_id] = {
          name: p ? `${p.first_name} ${p.last_name}` : 'Inconnu',
          missions: 0,
          revenue: 0,
        }
      }
      prestaMap[m.prestataire_id].missions++
      prestaMap[m.prestataire_id].revenue += m.total_price || 0
    })
    setTopPrestataires(
      Object.values(prestaMap).sort((a, b) => b.missions - a.missions).slice(0, 10)
    )

    setLoading(false)
  }

  const CATEGORY_LABELS: Record<string, string> = {
    courses: 'Courses',
    medicaments: 'Médicaments',
    colis: 'Colis',
    accompagnement: 'Accompagnement',
    assistance: 'Aide à domicile',
    autre: 'Autre',
  }

  const STATUS_LABELS: Record<string, { label: string; color: string }> = {
    pending: { label: 'En attente', color: 'bg-yellow-400' },
    accepted: { label: 'Acceptées', color: 'bg-blue-400' },
    in_progress: { label: 'En cours', color: 'bg-blue-500' },
    completed: { label: 'Terminées', color: 'bg-green-500' },
    cancelled: { label: 'Annulées', color: 'bg-red-400' },
  }

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  const totalMissions = Object.values(missionsByStatus).reduce((a, b) => a + b, 0)

  return (
    <div>
      <h1 className="text-2xl font-bold mb-8">Statistiques</h1>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Missions par statut */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6">
          <h2 className="font-semibold mb-4">Missions par statut</h2>
          <div className="space-y-3">
            {Object.entries(missionsByStatus).map(([status, count]) => {
              const config = STATUS_LABELS[status] || { label: status, color: 'bg-gray-400' }
              const pct = totalMissions > 0 ? (count / totalMissions) * 100 : 0
              return (
                <div key={status}>
                  <div className="flex justify-between text-sm mb-1">
                    <span>{config.label}</span>
                    <span className="text-gray-500">{count} ({pct.toFixed(0)}%)</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full ${config.color}`}
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                </div>
              )
            })}
          </div>
        </div>

        {/* Stats par catégorie */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6">
          <h2 className="font-semibold mb-4">Par catégorie</h2>
          <div className="space-y-3">
            {categoryStats.map(cat => (
              <div key={cat.category} className="flex items-center justify-between py-2 border-b border-gray-50">
                <div>
                  <span className="font-medium text-sm">
                    {CATEGORY_LABELS[cat.category] || cat.category}
                  </span>
                  <span className="text-xs text-gray-400 ml-2">{cat.count} missions</span>
                </div>
                <span className="text-sm font-medium text-green-600">
                  {formatPrice(cat.revenue)}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Revenus mensuels */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6">
          <h2 className="font-semibold mb-4">Revenus mensuels</h2>
          {monthlyRevenue.length === 0 ? (
            <p className="text-gray-400 text-sm">Aucune donnée</p>
          ) : (
            <div className="space-y-3">
              {monthlyRevenue.map(m => (
                <div key={m.month} className="flex items-center justify-between py-2 border-b border-gray-50">
                  <span className="text-sm">{m.month}</span>
                  <span className="text-sm font-bold">{formatPrice(m.revenue)}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Top prestataires */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6">
          <h2 className="font-semibold mb-4">Top prestataires</h2>
          {topPrestataires.length === 0 ? (
            <p className="text-gray-400 text-sm">Aucune donnée</p>
          ) : (
            <div className="space-y-3">
              {topPrestataires.map((p, i) => (
                <div key={i} className="flex items-center justify-between py-2 border-b border-gray-50">
                  <div>
                    <span className="font-medium text-sm">{p.name}</span>
                    <span className="text-xs text-gray-400 ml-2">{p.missions} missions</span>
                  </div>
                  <span className="text-sm font-medium">{formatPrice(p.revenue)}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
