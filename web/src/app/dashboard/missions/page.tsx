'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { formatPrice, formatDate, formatStatus, formatMissionType } from '@/lib/format'
import { Eye, Filter } from 'lucide-react'

type Mission = {
  id: string
  status: string
  mission_type: string
  description: string
  address_delivery: string
  total_price: number
  recurrence_frequency: string | null
  created_at: string
  scheduled_at: string | null
  services: { name: string; category: string } | null
  client: { first_name: string; last_name: string; phone: string } | null
  prestataire: { first_name: string; last_name: string; phone: string } | null
}

export default function MissionsPage() {
  const [missions, setMissions] = useState<Mission[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')
  const [selected, setSelected] = useState<Mission | null>(null)

  useEffect(() => { loadMissions() }, [])

  async function loadMissions() {
    const { data } = await supabase
      .from('missions')
      .select('*, services(name, category), client:client_id(first_name, last_name, phone), prestataire:prestataire_id(first_name, last_name, phone)')
      .order('created_at', { ascending: false })
    setMissions((data as Mission[]) || [])
    setLoading(false)
  }

  const filtered = filter === 'all'
    ? missions
    : missions.filter(m => m.status === filter)

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-bold">Missions</h1>
        <div className="flex items-center gap-2">
          <Filter size={16} className="text-gray-400" />
          <select
            value={filter}
            onChange={e => setFilter(e.target.value)}
            className="text-sm border border-gray-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
          >
            <option value="all">Toutes ({missions.length})</option>
            <option value="pending">En attente ({missions.filter(m => m.status === 'pending').length})</option>
            <option value="accepted">Acceptées ({missions.filter(m => m.status === 'accepted').length})</option>
            <option value="in_progress">En cours ({missions.filter(m => m.status === 'in_progress').length})</option>
            <option value="completed">Terminées ({missions.filter(m => m.status === 'completed').length})</option>
            <option value="cancelled">Annulées ({missions.filter(m => m.status === 'cancelled').length})</option>
          </select>
        </div>
      </div>

      {/* Modal détail */}
      {selected && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-lg max-h-[90vh] overflow-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-bold">{selected.services?.name || 'Mission'}</h2>
              <button onClick={() => setSelected(null)} className="text-gray-400 hover:text-gray-600 cursor-pointer">
                &times;
              </button>
            </div>

            <div className="space-y-4 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">Statut</span>
                <span className={`px-2 py-1 rounded-lg text-xs font-medium ${formatStatus(selected.status).color}`}>
                  {formatStatus(selected.status).label}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Type</span>
                <span>{formatMissionType(selected.mission_type || 'ponctuel')}</span>
              </div>
              {selected.recurrence_frequency && (
                <div className="flex justify-between">
                  <span className="text-gray-500">Récurrence</span>
                  <span className="capitalize">{selected.recurrence_frequency}</span>
                </div>
              )}
              <div className="flex justify-between">
                <span className="text-gray-500">Prix</span>
                <span className="font-medium">{formatPrice(selected.total_price)}</span>
              </div>
              <hr />
              <div>
                <span className="text-gray-500 block mb-1">Description</span>
                <p>{selected.description}</p>
              </div>
              <div>
                <span className="text-gray-500 block mb-1">Adresse</span>
                <p>{selected.address_delivery}</p>
              </div>
              <hr />
              <div className="flex justify-between">
                <span className="text-gray-500">Client</span>
                <span>{selected.client?.first_name} {selected.client?.last_name} ({selected.client?.phone})</span>
              </div>
              {selected.prestataire && (
                <div className="flex justify-between">
                  <span className="text-gray-500">Prestataire</span>
                  <span>{selected.prestataire.first_name} {selected.prestataire.last_name} ({selected.prestataire.phone})</span>
                </div>
              )}
              <div className="flex justify-between">
                <span className="text-gray-500">Créée le</span>
                <span>{formatDate(selected.created_at)}</span>
              </div>
              {selected.scheduled_at && (
                <div className="flex justify-between">
                  <span className="text-gray-500">Programmée le</span>
                  <span>{formatDate(selected.scheduled_at)}</span>
                </div>
              )}
            </div>

            <button
              onClick={() => setSelected(null)}
              className="w-full mt-6 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 transition cursor-pointer"
            >
              Fermer
            </button>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="text-left py-3 px-4 font-medium text-gray-500">Service</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Client</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Prestataire</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Type</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Prix</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Statut</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Date</th>
              <th className="text-right py-3 px-4 font-medium text-gray-500"></th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(mission => {
              const status = formatStatus(mission.status)
              return (
                <tr key={mission.id} className="border-b border-gray-100 hover:bg-gray-50">
                  <td className="py-3 px-4 font-medium">{mission.services?.name || '—'}</td>
                  <td className="py-3 px-4">
                    {mission.client ? `${mission.client.first_name} ${mission.client.last_name}` : '—'}
                  </td>
                  <td className="py-3 px-4">
                    {mission.prestataire ? `${mission.prestataire.first_name} ${mission.prestataire.last_name}` : '—'}
                  </td>
                  <td className="py-3 px-4">
                    <span className="text-xs">{formatMissionType(mission.mission_type || 'ponctuel')}</span>
                  </td>
                  <td className="py-3 px-4">{formatPrice(mission.total_price)}</td>
                  <td className="py-3 px-4">
                    <span className={`px-2 py-1 rounded-lg text-xs font-medium ${status.color}`}>
                      {status.label}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-gray-400 text-xs">{formatDate(mission.created_at)}</td>
                  <td className="py-3 px-4 text-right">
                    <button
                      onClick={() => setSelected(mission)}
                      className="p-1.5 hover:bg-gray-100 rounded-lg transition cursor-pointer"
                    >
                      <Eye size={14} className="text-gray-400" />
                    </button>
                  </td>
                </tr>
              )
            })}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={8} className="py-12 text-center text-gray-400">
                  Aucune mission
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
