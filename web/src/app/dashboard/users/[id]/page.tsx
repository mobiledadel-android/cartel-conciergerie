'use client'

export const runtime = 'edge'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { getSupabase } from '@/lib/supabase'
import { formatPrice, formatDate, formatStatus, formatRole } from '@/lib/format'
import { ArrowLeft, Phone, Mail, MapPin, Calendar, Star } from 'lucide-react'

type UserProfile = {
  id: string; first_name: string; last_name: string; phone: string; email: string | null
  role: string; city: string; is_verified: boolean; is_active: boolean
  is_client_suspended: boolean; is_agent_suspended: boolean; suspension_reason: string | null
  created_at: string
}

type Mission = {
  id: string; status: string; description: string; total_price: number; created_at: string
  services: { name: string } | null
}

type Review = {
  id: string; rating: number; comment: string | null; created_at: string
  mission: { services: { name: string } | null } | null
}

export default function UserDetailPage() {
  const { id } = useParams()
  const router = useRouter()
  const [user, setUser] = useState<UserProfile | null>(null)
  const [missions, setMissions] = useState<Mission[]>([])
  const [reviews, setReviews] = useState<Review[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!id) return
    loadUser()
  }, [id])

  async function loadUser() {
    const [profileRes, missionsRes, reviewsRes] = await Promise.all([
      getSupabase().from('profiles').select('*').eq('id', id).single(),
      getSupabase().from('missions').select('*, services(name)').or(`client_id.eq.${id},prestataire_id.eq.${id}`).order('created_at', { ascending: false }).limit(20),
      getSupabase().from('reviews').select('*, mission:mission_id(services(name))').eq('reviewed_id', id).order('created_at', { ascending: false }).limit(10),
    ])

    setUser(profileRes.data as UserProfile)
    setMissions((missionsRes.data as Mission[]) || [])
    setReviews((reviewsRes.data as Review[]) || [])
    setLoading(false)
  }

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>
  if (!user) return <div className="text-center py-20 text-gray-400">Utilisateur introuvable</div>

  const avgRating = reviews.length > 0 ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length : 0
  const completedMissions = missions.filter(m => m.status === 'completed').length
  const totalRevenue = missions.filter(m => m.status === 'completed').reduce((sum, m) => sum + (m.total_price || 0), 0)

  return (
    <div>
      <button onClick={() => router.back()} className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700 mb-6 cursor-pointer">
        <ArrowLeft size={16} /> Retour
      </button>

      {/* Header */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-6">
        <div className="flex flex-col sm:flex-row items-start gap-4">
          <div className="w-16 h-16 rounded-full flex items-center justify-center text-white text-xl font-bold shrink-0" style={{ backgroundColor: '#00A8E8' }}>
            {user.first_name?.[0]}{user.last_name?.[0]}
          </div>
          <div className="flex-1">
            <h1 className="text-xl font-bold">{user.first_name} {user.last_name}</h1>
            <div className="flex flex-wrap gap-4 mt-2 text-sm text-gray-500">
              <span className="flex items-center gap-1"><Phone size={14} /> {user.phone}</span>
              {user.email && <span className="flex items-center gap-1"><Mail size={14} /> {user.email}</span>}
              {user.city && <span className="flex items-center gap-1"><MapPin size={14} /> {user.city}</span>}
              <span className="flex items-center gap-1"><Calendar size={14} /> Inscrit le {formatDate(user.created_at)}</span>
            </div>
            <div className="flex flex-wrap gap-2 mt-3">
              <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-lg">{formatRole(user.role)}</span>
              {user.is_client_suspended && <span className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg">Client suspendu</span>}
              {user.is_agent_suspended && <span className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg">Agent suspendu</span>}
              {!user.is_active && <span className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg">Compte bloqué</span>}
              {user.is_verified && <span className="text-xs bg-green-50 text-green-600 px-2 py-1 rounded-lg">Vérifié</span>}
              {user.suspension_reason && <span className="text-xs text-red-500">Raison : {user.suspension_reason}</span>}
            </div>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold">{missions.length}</p>
          <p className="text-xs text-gray-400">Missions totales</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold">{completedMissions}</p>
          <p className="text-xs text-gray-400">Terminées</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold">{formatPrice(totalRevenue)}</p>
          <p className="text-xs text-gray-400">Total</p>
        </div>
        <div className="bg-white rounded-xl border border-gray-200 p-4 text-center">
          <p className="text-2xl font-bold flex items-center justify-center gap-1">
            {avgRating > 0 ? avgRating.toFixed(1) : '—'} <Star size={16} className="text-yellow-400" />
          </p>
          <p className="text-xs text-gray-400">{reviews.length} avis</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Missions */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6">
          <h2 className="font-semibold mb-4">Dernières missions</h2>
          {missions.length === 0 ? <p className="text-sm text-gray-400">Aucune mission</p> : (
            <div className="space-y-3">
              {missions.slice(0, 10).map(m => {
                const status = formatStatus(m.status)
                return (
                  <div key={m.id} className="flex items-center justify-between py-2 border-b border-gray-50">
                    <div>
                      <p className="text-sm font-medium">{m.services?.name || 'Mission'}</p>
                      <p className="text-xs text-gray-400">{formatDate(m.created_at)}</p>
                    </div>
                    <div className="text-right">
                      <span className={`text-xs px-2 py-0.5 rounded-lg ${status.color}`}>{status.label}</span>
                      <p className="text-xs text-gray-500 mt-1">{formatPrice(m.total_price)}</p>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        {/* Avis */}
        <div className="bg-white rounded-2xl border border-gray-200 p-6">
          <h2 className="font-semibold mb-4">Avis reçus</h2>
          {reviews.length === 0 ? <p className="text-sm text-gray-400">Aucun avis</p> : (
            <div className="space-y-3">
              {reviews.map(r => (
                <div key={r.id} className="py-2 border-b border-gray-50">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1">
                      {Array.from({ length: 5 }).map((_, i) => (
                        <Star key={i} size={14} className={i < r.rating ? 'text-yellow-400 fill-yellow-400' : 'text-gray-200'} />
                      ))}
                    </div>
                    <span className="text-xs text-gray-400">{formatDate(r.created_at)}</span>
                  </div>
                  {r.comment && <p className="text-sm text-gray-600 mt-1">{r.comment}</p>}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
