'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { formatPrice } from '@/lib/format'
import { Users, ClipboardList, Package, TrendingUp } from 'lucide-react'

export default function DashboardPage() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalPrestataires: 0,
    totalMissions: 0,
    pendingMissions: 0,
    activeMissions: 0,
    completedMissions: 0,
    totalRevenue: 0,
    totalServices: 0,
  })

  useEffect(() => {
    loadStats()
  }, [])

  async function loadStats() {
    const [users, prestataires, missions, services] = await Promise.all([
      supabase.from('profiles').select('id', { count: 'exact', head: true }),
      supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'prestataire'),
      supabase.from('missions').select('*'),
      supabase.from('services').select('id', { count: 'exact', head: true }),
    ])

    const missionData = missions.data || []
    const pending = missionData.filter(m => m.status === 'pending').length
    const active = missionData.filter(m => m.status === 'in_progress' || m.status === 'accepted').length
    const completed = missionData.filter(m => m.status === 'completed').length
    const revenue = missionData
      .filter(m => m.status === 'completed')
      .reduce((sum, m) => sum + (m.total_price || 0), 0)

    setStats({
      totalUsers: users.count || 0,
      totalPrestataires: prestataires.count || 0,
      totalMissions: missionData.length,
      pendingMissions: pending,
      activeMissions: active,
      completedMissions: completed,
      totalRevenue: revenue,
      totalServices: services.count || 0,
    })
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-8">Tableau de bord</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          icon={<Users className="text-[var(--primary)]" />}
          label="Utilisateurs"
          value={stats.totalUsers}
          sub={`dont ${stats.totalPrestataires} prestataires`}
        />
        <StatCard
          icon={<ClipboardList className="text-yellow-500" />}
          label="Missions"
          value={stats.totalMissions}
          sub={`${stats.pendingMissions} en attente`}
        />
        <StatCard
          icon={<Package className="text-green-500" />}
          label="Terminées"
          value={stats.completedMissions}
          sub={`${stats.activeMissions} en cours`}
        />
        <StatCard
          icon={<TrendingUp className="text-[var(--accent)]" />}
          label="Revenus"
          value={formatPrice(stats.totalRevenue)}
          sub={`${stats.totalServices} services actifs`}
        />
      </div>
    </div>
  )
}

function StatCard({ icon, label, value, sub }: {
  icon: React.ReactNode
  label: string
  value: string | number
  sub: string
}) {
  return (
    <div className="bg-white rounded-2xl p-6 border border-gray-200">
      <div className="flex items-center gap-3 mb-3">
        {icon}
        <span className="text-sm text-gray-500">{label}</span>
      </div>
      <p className="text-2xl font-bold">{value}</p>
      <p className="text-xs text-gray-400 mt-1">{sub}</p>
    </div>
  )
}
