'use client'

import { useEffect, useState } from 'react'
import { getSupabase } from '@/lib/supabase'
import { formatDate, formatRole } from '@/lib/format'
import { Filter, Shield, ShieldOff } from 'lucide-react'

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
  created_at: string
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')

  useEffect(() => { loadUsers() }, [])

  async function loadUsers() {
    const { data } = await getSupabase()
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
    setUsers((data as User[]) || [])
    setLoading(false)
  }

  async function toggleVerified(user: User) {
    await getSupabase()
      .from('profiles')
      .update({ is_verified: !user.is_verified })
      .eq('id', user.id)
    loadUsers()
  }

  async function toggleActive(user: User) {
    await getSupabase()
      .from('profiles')
      .update({ is_active: !user.is_active })
      .eq('id', user.id)
    loadUsers()
  }

  async function changeRole(userId: string, role: string) {
    await getSupabase()
      .from('profiles')
      .update({ role })
      .eq('id', userId)
    loadUsers()
  }

  const filtered = filter === 'all'
    ? users
    : users.filter(u => u.role === filter)

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-bold">Utilisateurs</h1>
        <div className="flex items-center gap-2">
          <Filter size={16} className="text-gray-400" />
          <select
            value={filter}
            onChange={e => setFilter(e.target.value)}
            className="text-sm border border-gray-200 rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
          >
            <option value="all">Tous ({users.length})</option>
            <option value="client">Clients ({users.filter(u => u.role === 'client').length})</option>
            <option value="prestataire">Prestataires ({users.filter(u => u.role === 'prestataire').length})</option>
            <option value="admin">Admins ({users.filter(u => u.role === 'admin').length})</option>
          </select>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="text-left py-3 px-4 font-medium text-gray-500">Utilisateur</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Téléphone</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Ville</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Rôle</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Vérifié</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Statut</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Inscrit le</th>
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
                  {user.email && (
                    <div className="text-xs text-gray-400">{user.email}</div>
                  )}
                </td>
                <td className="py-3 px-4 text-gray-600">{user.phone}</td>
                <td className="py-3 px-4 text-gray-600">{user.city || '—'}</td>
                <td className="py-3 px-4">
                  <select
                    value={user.role}
                    onChange={e => changeRole(user.id, e.target.value)}
                    className="text-xs border border-gray-200 rounded-lg px-2 py-1 focus:outline-none"
                  >
                    <option value="client">Client</option>
                    <option value="prestataire">Prestataire</option>
                    <option value="admin">Admin</option>
                  </select>
                </td>
                <td className="py-3 px-4">
                  <button
                    onClick={() => toggleVerified(user)}
                    className="cursor-pointer"
                    title={user.is_verified ? 'Retirer la vérification' : 'Vérifier'}
                  >
                    {user.is_verified ? (
                      <Shield size={16} className="text-green-500" />
                    ) : (
                      <ShieldOff size={16} className="text-gray-300" />
                    )}
                  </button>
                </td>
                <td className="py-3 px-4">
                  <button
                    onClick={() => toggleActive(user)}
                    className={`text-xs px-2 py-1 rounded-lg font-medium cursor-pointer ${
                      user.is_active
                        ? 'bg-green-50 text-green-600'
                        : 'bg-red-50 text-red-600'
                    }`}
                  >
                    {user.is_active ? 'Actif' : 'Bloqué'}
                  </button>
                </td>
                <td className="py-3 px-4 text-gray-400 text-xs">
                  {formatDate(user.created_at)}
                </td>
              </tr>
            ))}
            {filtered.length === 0 && (
              <tr>
                <td colSpan={7} className="py-12 text-center text-gray-400">
                  Aucun utilisateur
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
