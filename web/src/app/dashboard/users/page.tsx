'use client'

import { useEffect, useState } from 'react'
import { getSupabase } from '@/lib/supabase'
import { formatDate, formatRole } from '@/lib/format'
import { Filter, X, UserX, ShoppingCart, Briefcase, Ban } from 'lucide-react'

type User = {
  id: string
  firebase_uid: string
  first_name: string
  last_name: string
  phone: string
  email: string | null
  role: string
  city: string
  is_verified: boolean
  is_active: boolean
  is_client_suspended: boolean
  is_agent_suspended: boolean
  suspension_reason: string | null
  created_at: string
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')
  const [suspendTarget, setSuspendTarget] = useState<{ user: User; type: 'client' | 'agent' | 'all' } | null>(null)
  const [suspendReason, setSuspendReason] = useState('')
  const [currentAdmin, setCurrentAdmin] = useState<{ id: string } | null>(null)

  useEffect(() => {
    loadUsers()
    loadCurrentAdmin()
  }, [])

  async function loadCurrentAdmin() {
    const res = await fetch('/api/auth')
    const data = await res.json()
    if (data.admin) setCurrentAdmin(data.admin)
  }

  async function loadUsers() {
    const { data } = await getSupabase()
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
    setUsers((data as User[]) || [])
    setLoading(false)
  }

  async function suspendUser() {
    if (!suspendTarget || !currentAdmin) return

    const updates: Record<string, unknown> = {
      suspension_reason: suspendReason || null,
      suspended_by: currentAdmin.id,
      suspended_at: new Date().toISOString(),
    }

    if (suspendTarget.type === 'client' || suspendTarget.type === 'all') {
      updates.is_client_suspended = true
    }
    if (suspendTarget.type === 'agent' || suspendTarget.type === 'all') {
      updates.is_agent_suspended = true
    }
    if (suspendTarget.type === 'all') {
      updates.is_active = false
    }

    await getSupabase()
      .from('profiles')
      .update(updates)
      .eq('id', suspendTarget.user.id)

    // Log
    await getSupabase().from('admin_logs').insert({
      admin_id: currentAdmin.id,
      action: `suspend_${suspendTarget.type}`,
      target_type: 'profile',
      target_id: suspendTarget.user.id,
      details: { reason: suspendReason, type: suspendTarget.type },
    })

    setSuspendTarget(null)
    setSuspendReason('')
    loadUsers()
  }

  async function unsuspend(user: User, type: 'client' | 'agent' | 'all') {
    const updates: Record<string, unknown> = {
      suspension_reason: null,
      suspended_by: null,
      suspended_at: null,
    }

    if (type === 'client' || type === 'all') {
      updates.is_client_suspended = false
    }
    if (type === 'agent' || type === 'all') {
      updates.is_agent_suspended = false
    }
    if (type === 'all') {
      updates.is_active = true
    }

    await getSupabase()
      .from('profiles')
      .update(updates)
      .eq('id', user.id)

    if (currentAdmin) {
      await getSupabase().from('admin_logs').insert({
        admin_id: currentAdmin.id,
        action: `unsuspend_${type}`,
        target_type: 'profile',
        target_id: user.id,
      })
    }

    loadUsers()
  }

  const filtered = filter === 'all'
    ? users
    : filter === 'suspended'
      ? users.filter(u => u.is_client_suspended || u.is_agent_suspended || !u.is_active)
      : users.filter(u => u.role === filter)

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">Utilisateurs</h1>
          <p className="text-sm text-gray-500 mt-1">{users.length} utilisateurs inscrits</p>
        </div>
        <div className="flex items-center gap-2">
          <Filter size={16} className="text-gray-400" />
          <select
            value={filter}
            onChange={e => setFilter(e.target.value)}
            className="text-sm border border-gray-200 rounded-xl px-3 py-2 focus:outline-none"
          >
            <option value="all">Tous ({users.length})</option>
            <option value="client">Clients ({users.filter(u => u.role === 'client').length})</option>
            <option value="prestataire">Prestataires ({users.filter(u => u.role === 'prestataire').length})</option>
            <option value="suspended">Suspendus ({users.filter(u => u.is_client_suspended || u.is_agent_suspended || !u.is_active).length})</option>
          </select>
        </div>
      </div>

      {/* Modal suspension */}
      {suspendTarget && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-red-600">
                Suspendre {suspendTarget.type === 'client' ? 'le côté client' : suspendTarget.type === 'agent' ? 'le côté agent' : 'tout le compte'}
              </h2>
              <button onClick={() => setSuspendTarget(null)} className="cursor-pointer">
                <X size={20} className="text-gray-400" />
              </button>
            </div>

            <p className="text-sm text-gray-600 mb-4">
              Utilisateur : <strong>{suspendTarget.user.first_name} {suspendTarget.user.last_name}</strong> ({suspendTarget.user.phone})
            </p>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Raison de la suspension</label>
              <textarea
                value={suspendReason}
                onChange={e => setSuspendReason(e.target.value)}
                rows={3}
                className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-red-300"
                placeholder="Raison de la suspension..."
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => setSuspendTarget(null)}
                className="flex-1 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 transition cursor-pointer"
              >
                Annuler
              </button>
              <button
                onClick={suspendUser}
                className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-medium hover:bg-red-600 transition cursor-pointer"
              >
                Suspendre
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="text-left py-3 px-4 font-medium text-gray-500">Utilisateur</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Téléphone</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Rôle</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Client</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Agent</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Compte</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Inscrit le</th>
              <th className="text-right py-3 px-4 font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(user => (
              <tr key={user.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="py-3 px-4">
                  <div className="font-medium">
                    {user.first_name || user.last_name
                      ? `${user.first_name} ${user.last_name}`
                      : 'Profil incomplet'}
                  </div>
                  {user.email && <div className="text-xs text-gray-400">{user.email}</div>}
                </td>
                <td className="py-3 px-4 text-gray-600">{user.phone}</td>
                <td className="py-3 px-4">
                  <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-lg">
                    {formatRole(user.role)}
                  </span>
                </td>
                <td className="py-3 px-4">
                  {user.is_client_suspended ? (
                    <button
                      onClick={() => unsuspend(user, 'client')}
                      className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg font-medium cursor-pointer hover:bg-red-100"
                    >
                      Suspendu
                    </button>
                  ) : (
                    <span className="text-xs bg-green-50 text-green-600 px-2 py-1 rounded-lg">OK</span>
                  )}
                </td>
                <td className="py-3 px-4">
                  {user.is_agent_suspended ? (
                    <button
                      onClick={() => unsuspend(user, 'agent')}
                      className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg font-medium cursor-pointer hover:bg-red-100"
                    >
                      Suspendu
                    </button>
                  ) : (
                    <span className="text-xs bg-green-50 text-green-600 px-2 py-1 rounded-lg">OK</span>
                  )}
                </td>
                <td className="py-3 px-4">
                  {!user.is_active ? (
                    <button
                      onClick={() => unsuspend(user, 'all')}
                      className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg font-medium cursor-pointer hover:bg-red-100"
                    >
                      Bloqué
                    </button>
                  ) : (
                    <span className="text-xs bg-green-50 text-green-600 px-2 py-1 rounded-lg">Actif</span>
                  )}
                </td>
                <td className="py-3 px-4 text-gray-400 text-xs">{formatDate(user.created_at)}</td>
                <td className="py-3 px-4 text-right">
                  <div className="flex items-center justify-end gap-1">
                    <button
                      onClick={() => setSuspendTarget({ user, type: 'client' })}
                      className="p-1.5 hover:bg-yellow-50 rounded-lg transition cursor-pointer"
                      title="Suspendre côté client"
                    >
                      <ShoppingCart size={14} className="text-yellow-500" />
                    </button>
                    <button
                      onClick={() => setSuspendTarget({ user, type: 'agent' })}
                      className="p-1.5 hover:bg-orange-50 rounded-lg transition cursor-pointer"
                      title="Suspendre côté agent"
                    >
                      <Briefcase size={14} className="text-orange-500" />
                    </button>
                    <button
                      onClick={() => setSuspendTarget({ user, type: 'all' })}
                      className="p-1.5 hover:bg-red-50 rounded-lg transition cursor-pointer"
                      title="Bloquer tout le compte"
                    >
                      <Ban size={14} className="text-red-500" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Légende */}
      <div className="mt-4 flex gap-6 text-xs text-gray-400">
        <span className="flex items-center gap-1"><ShoppingCart size={12} /> Suspendre client</span>
        <span className="flex items-center gap-1"><Briefcase size={12} /> Suspendre agent</span>
        <span className="flex items-center gap-1"><Ban size={12} /> Bloquer tout</span>
        <span>Cliquer sur &quot;Suspendu&quot;/&quot;Bloqué&quot; pour réactiver</span>
      </div>
    </div>
  )
}
