'use client'

import { useEffect, useState, useCallback } from 'react'
import { getSupabase } from '@/lib/supabase'
import { formatPrice } from '@/lib/format'
import { Users, ClipboardList, Package, TrendingUp, RefreshCw } from 'lucide-react'

export default function DashboardPage() {
  const [stats, setStats] = useState({
    totalUsers: 0, totalPrestataires: 0, totalMissions: 0,
    pendingMissions: 0, activeMissions: 0, completedMissions: 0,
    totalRevenue: 0, totalServices: 0,
  })
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date())

  const loadStats = useCallback(async () => {
    const [users, prestataires, missions, services] = await Promise.all([
      getSupabase().from('profiles').select('id', { count: 'exact', head: true }),
      getSupabase().from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'prestataire'),
      getSupabase().from('missions').select('*'),
      getSupabase().from('services').select('id', { count: 'exact', head: true }),
    ])

    const missionData = missions.data || []
    setStats({
      totalUsers: users.count || 0,
      totalPrestataires: prestataires.count || 0,
      totalMissions: missionData.length,
      pendingMissions: missionData.filter(m => m.status === 'pending').length,
      activeMissions: missionData.filter(m => m.status === 'in_progress' || m.status === 'accepted').length,
      completedMissions: missionData.filter(m => m.status === 'completed').length,
      totalRevenue: missionData.filter(m => m.status === 'completed').reduce((s, m) => s + (m.total_price || 0), 0),
      totalServices: services.count || 0,
    })
    setLastUpdate(new Date())
  }, [])

  useEffect(() => { loadStats() }, [loadStats])

  // Realtime updates
  useEffect(() => {
    const channel = getSupabase()
      .channel('dashboard-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'missions' }, () => loadStats())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'profiles' }, () => loadStats())
      .subscribe()

    return () => { getSupabase().removeChannel(channel) }
  }, [loadStats])

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-bold">Tableau de bord</h1>
        <div className="flex items-center gap-3">
          <span className="text-xs text-gray-400">
            Mis à jour à {lastUpdate.toLocaleTimeString('fr-FR')}
          </span>
          <button onClick={loadStats} className="p-2 hover:bg-gray-100 rounded-lg transition cursor-pointer" title="Rafraîchir">
            <RefreshCw size={16} className="text-gray-400" />
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6 mb-8">
        <StatCard icon={<Users className="text-[#00A8E8]" />} label="Utilisateurs" value={stats.totalUsers} sub={`dont ${stats.totalPrestataires} prestataires`} />
        <StatCard icon={<ClipboardList className="text-yellow-500" />} label="Missions" value={stats.totalMissions} sub={`${stats.pendingMissions} en attente`} />
        <StatCard icon={<Package className="text-green-500" />} label="Terminées" value={stats.completedMissions} sub={`${stats.activeMissions} en cours`} />
        <StatCard icon={<TrendingUp className="text-[#E91E63]" />} label="Revenus" value={formatPrice(stats.totalRevenue)} sub={`${stats.totalServices} services actifs`} />
      </div>
    </div>
  )
}

function StatCard({ icon, label, value, sub }: { icon: React.ReactNode; label: string; value: string | number; sub: string }) {
  return (
    <div className="bg-white rounded-2xl p-5 md:p-6 border border-gray-200">
      <div className="flex items-center gap-3 mb-3">{icon}<span className="text-sm text-gray-500">{label}</span></div>
      <p className="text-xl md:text-2xl font-bold">{value}</p>
      <p className="text-xs text-gray-400 mt-1">{sub}</p>
    </div>
  )
}
