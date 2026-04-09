'use client'

import { useEffect, useState, useMemo } from 'react'
import { getSupabase } from '@/lib/supabase'
import { formatDate, formatRole } from '@/lib/format'
import { Filter, X, ShoppingCart, Briefcase, Ban, Eye } from 'lucide-react'
import Link from 'next/link'
import SearchBar from '@/components/SearchBar'
import Pagination from '@/components/Pagination'
import ExportCSV from '@/components/ExportCSV'
import ConfirmPassword from '@/components/ConfirmPassword'

type User = {
  id: string; firebase_uid: string; first_name: string; last_name: string
  phone: string; email: string | null; role: string; city: string
  is_verified: boolean; is_active: boolean
  is_client_suspended: boolean; is_agent_suspended: boolean
  suspension_reason: string | null; created_at: string
}

const PER_PAGE = 15

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [suspendTarget, setSuspendTarget] = useState<{ user: User; type: 'client' | 'agent' | 'all' } | null>(null)
  const [suspendReason, setSuspendReason] = useState('')
  const [confirmAction, setConfirmAction] = useState<(() => void) | null>(null)
  const [currentAdmin, setCurrentAdmin] = useState<{ id: string } | null>(null)

  useEffect(() => {
    loadUsers()
    const session = localStorage.getItem('admin_session')
    if (session) setCurrentAdmin(JSON.parse(session))
  }, [])

  async function loadUsers() {
    const { data } = await getSupabase().from('profiles').select('*').order('created_at', { ascending: false })
    setUsers((data as User[]) || [])
    setLoading(false)
  }

  const filtered = useMemo(() => {
    let result = users
    if (filter === 'suspended') result = result.filter(u => u.is_client_suspended || u.is_agent_suspended || !u.is_active)
    else if (filter !== 'all') result = result.filter(u => u.role === filter)
    if (search) {
      const q = search.toLowerCase()
      result = result.filter(u =>
        u.first_name?.toLowerCase().includes(q) || u.last_name?.toLowerCase().includes(q) ||
        u.phone?.includes(q) || u.email?.toLowerCase().includes(q) || u.city?.toLowerCase().includes(q)
      )
    }
    return result
  }, [users, filter, search])

  const totalPages = Math.ceil(filtered.length / PER_PAGE)
  const paginated = filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE)

  useEffect(() => { setPage(1) }, [search, filter])

  function requestSuspend(user: User, type: 'client' | 'agent' | 'all') {
    setSuspendTarget({ user, type })
  }

  async function executeSuspend() {
    if (!suspendTarget || !currentAdmin) return
    const updates: Record<string, unknown> = {
      suspension_reason: suspendReason || null, suspended_by: currentAdmin.id, suspended_at: new Date().toISOString(),
    }
    if (suspendTarget.type === 'client' || suspendTarget.type === 'all') updates.is_client_suspended = true
    if (suspendTarget.type === 'agent' || suspendTarget.type === 'all') updates.is_agent_suspended = true
    if (suspendTarget.type === 'all') updates.is_active = false
    await getSupabase().from('profiles').update(updates).eq('id', suspendTarget.user.id)
    await getSupabase().from('admin_logs').insert({ admin_id: currentAdmin.id, action: `suspend_${suspendTarget.type}`, target_type: 'profile', target_id: suspendTarget.user.id, details: { reason: suspendReason } })
    setSuspendTarget(null); setSuspendReason(''); loadUsers()
  }

  async function unsuspend(user: User, type: 'client' | 'agent' | 'all') {
    const updates: Record<string, unknown> = { suspension_reason: null, suspended_by: null, suspended_at: null }
    if (type === 'client' || type === 'all') updates.is_client_suspended = false
    if (type === 'agent' || type === 'all') updates.is_agent_suspended = false
    if (type === 'all') updates.is_active = true
    await getSupabase().from('profiles').update(updates).eq('id', user.id)
    if (currentAdmin) await getSupabase().from('admin_logs').insert({ admin_id: currentAdmin.id, action: `unsuspend_${type}`, target_type: 'profile', target_id: user.id })
    loadUsers()
  }

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  return (
    <div>
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold">Utilisateurs</h1>
          <p className="text-sm text-gray-500 mt-1">{users.length} inscrits</p>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <SearchBar value={search} onChange={setSearch} placeholder="Nom, téléphone, email..." />
          <ExportCSV data={filtered.map(u => ({ nom: `${u.first_name} ${u.last_name}`, phone: u.phone, email: u.email || '', role: formatRole(u.role), ville: u.city, actif: u.is_active ? 'Oui' : 'Non', inscrit: u.created_at }))}
            filename="utilisateurs" headers={['Nom', 'Téléphone', 'Email', 'Rôle', 'Ville', 'Actif', 'Inscrit']} keys={['nom', 'phone', 'email', 'role', 'ville', 'actif', 'inscrit']} />
        </div>
      </div>

      <div className="flex items-center gap-2 flex-wrap mb-6">
        <Filter size={16} className="text-gray-400" />
        <select value={filter} onChange={e => setFilter(e.target.value)} className="text-sm border border-gray-200 rounded-xl px-3 py-2">
          <option value="all">Tous ({users.length})</option>
          <option value="client">Clients ({users.filter(u => u.role === 'client').length})</option>
          <option value="prestataire">Prestataires ({users.filter(u => u.role === 'prestataire').length})</option>
          <option value="suspended">Suspendus ({users.filter(u => u.is_client_suspended || u.is_agent_suspended || !u.is_active).length})</option>
        </select>
        <span className="text-xs text-gray-400">{filtered.length} résultat(s)</span>
      </div>

      {/* Confirm password for critical action */}
      {confirmAction && (
        <ConfirmPassword title="Action critique" message="Confirmez avec votre mot de passe"
          onConfirm={() => { confirmAction(); setConfirmAction(null) }} onCancel={() => setConfirmAction(null)} />
      )}

      {/* Suspend modal */}
      {suspendTarget && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md mx-4">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-bold text-red-600">
                Suspendre {suspendTarget.type === 'client' ? 'côté client' : suspendTarget.type === 'agent' ? 'côté agent' : 'tout le compte'}
              </h2>
              <button onClick={() => setSuspendTarget(null)} className="cursor-pointer"><X size={20} className="text-gray-400" /></button>
            </div>
            <p className="text-sm text-gray-600 mb-4"><strong>{suspendTarget.user.first_name} {suspendTarget.user.last_name}</strong> ({suspendTarget.user.phone})</p>
            <textarea value={suspendReason} onChange={e => setSuspendReason(e.target.value)} rows={3} placeholder="Raison..."
              className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-red-300 mb-4" />
            <div className="flex gap-3">
              <button onClick={() => setSuspendTarget(null)} className="flex-1 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 cursor-pointer">Annuler</button>
              <button onClick={() => setConfirmAction(() => executeSuspend)} className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-medium hover:bg-red-600 cursor-pointer">Suspendre</button>
            </div>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-2xl border border-gray-200 overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="text-left py-3 px-4 font-medium text-gray-500">Utilisateur</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500 hidden sm:table-cell">Téléphone</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500 hidden md:table-cell">Rôle</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Client</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Agent</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500 hidden lg:table-cell">Compte</th>
              <th className="text-right py-3 px-4 font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody>
            {paginated.map(user => (
              <tr key={user.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="py-3 px-4">
                  <div className="font-medium">{user.first_name || user.last_name ? `${user.first_name} ${user.last_name}` : 'Incomplet'}</div>
                  <div className="text-xs text-gray-400 sm:hidden">{user.phone}</div>
                </td>
                <td className="py-3 px-4 text-gray-600 hidden sm:table-cell">{user.phone}</td>
                <td className="py-3 px-4 hidden md:table-cell"><span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-lg">{formatRole(user.role)}</span></td>
                <td className="py-3 px-4">{user.is_client_suspended
                  ? <button onClick={() => unsuspend(user, 'client')} className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg font-medium cursor-pointer hover:bg-red-100">Suspendu</button>
                  : <span className="text-xs bg-green-50 text-green-600 px-2 py-1 rounded-lg">OK</span>}</td>
                <td className="py-3 px-4">{user.is_agent_suspended
                  ? <button onClick={() => unsuspend(user, 'agent')} className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg font-medium cursor-pointer hover:bg-red-100">Suspendu</button>
                  : <span className="text-xs bg-green-50 text-green-600 px-2 py-1 rounded-lg">OK</span>}</td>
                <td className="py-3 px-4 hidden lg:table-cell">{!user.is_active
                  ? <button onClick={() => unsuspend(user, 'all')} className="text-xs bg-red-50 text-red-600 px-2 py-1 rounded-lg font-medium cursor-pointer hover:bg-red-100">Bloqué</button>
                  : <span className="text-xs bg-green-50 text-green-600 px-2 py-1 rounded-lg">Actif</span>}</td>
                <td className="py-3 px-4 text-right">
                  <div className="flex items-center justify-end gap-1">
                    <Link href={`/dashboard/users/${user.id}`} className="p-1.5 hover:bg-gray-100 rounded-lg transition"><Eye size={14} className="text-gray-400" /></Link>
                    <button onClick={() => requestSuspend(user, 'client')} className="p-1.5 hover:bg-yellow-50 rounded-lg cursor-pointer" title="Suspendre client"><ShoppingCart size={14} className="text-yellow-500" /></button>
                    <button onClick={() => requestSuspend(user, 'agent')} className="p-1.5 hover:bg-orange-50 rounded-lg cursor-pointer" title="Suspendre agent"><Briefcase size={14} className="text-orange-500" /></button>
                    <button onClick={() => requestSuspend(user, 'all')} className="p-1.5 hover:bg-red-50 rounded-lg cursor-pointer" title="Bloquer tout"><Ban size={14} className="text-red-500" /></button>
                  </div>
                </td>
              </tr>
            ))}
            {paginated.length === 0 && <tr><td colSpan={7} className="py-12 text-center text-gray-400">Aucun utilisateur</td></tr>}
          </tbody>
        </table>
      </div>

      <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
    </div>
  )
}
