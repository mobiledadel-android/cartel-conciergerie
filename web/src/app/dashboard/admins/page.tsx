'use client'

import { useEffect, useState } from 'react'
import { getSupabase } from '@/lib/supabase'
import { getRoleLabel, getRoleColor, type Admin, type AdminRole } from '@/lib/admin'
import { formatDate } from '@/lib/format'
import { Plus, X, Shield, ShieldOff, Copy, Check, Key } from 'lucide-react'

const ROLES: { value: AdminRole; label: string }[] = [
  { value: 'superviseur', label: 'Superviseur' },
  { value: 'admin', label: 'Admin' },
  { value: 'super_admin', label: 'Super Admin' },
]

export default function AdminsPage() {
  const [admins, setAdmins] = useState<Admin[]>([])
  const [loading, setLoading] = useState(true)
  const [showCreate, setShowCreate] = useState(false)
  const [currentAdmin, setCurrentAdmin] = useState<Admin | null>(null)

  // Formulaire création
  const [newEmail, setNewEmail] = useState('')
  const [newName, setNewName] = useState('')
  const [newRole, setNewRole] = useState<AdminRole>('superviseur')
  const [creating, setCreating] = useState(false)

  // Résultat création
  const [createdPassword, setCreatedPassword] = useState<string | null>(null)
  const [emailSent, setEmailSent] = useState(false)
  const [copied, setCopied] = useState(false)

  // Changement mot de passe
  const [changingPwdFor, setChangingPwdFor] = useState<Admin | null>(null)
  const [newPwd, setNewPwd] = useState('')
  const [pwdChanged, setPwdChanged] = useState(false)

  useEffect(() => {
    loadCurrentAdmin()
    loadAdmins()
  }, [])

  function loadCurrentAdmin() {
    const session = localStorage.getItem('admin_session')
    if (session) setCurrentAdmin(JSON.parse(session))
  }

  async function loadAdmins() {
    const { data } = await getSupabase()
      .from('admins')
      .select('*')
      .order('role')
      .order('full_name')
    setAdmins((data as Admin[]) || [])
    setLoading(false)
  }

  async function createAdmin() {
    if (!newEmail || !newName) return
    setCreating(true)

    const res = await fetch('/api/create-admin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: newEmail,
        full_name: newName,
        role: newRole,
        created_by: currentAdmin?.id,
        dashboard_url: window.location.origin,
      }),
    })

    const data = await res.json()

    if (res.ok) {
      setCreatedPassword(data.password)
      setEmailSent(data.email_sent)

      // Log
      if (currentAdmin) {
        await getSupabase().from('admin_logs').insert({
          admin_id: currentAdmin.id,
          action: 'create_admin',
          target_type: 'admin',
          details: { email: newEmail, role: newRole },
        })
      }

      loadAdmins()
    }

    setCreating(false)
  }

  function closeCreateModal() {
    setShowCreate(false)
    setCreatedPassword(null)
    setEmailSent(false)
    setCopied(false)
    setNewEmail('')
    setNewName('')
    setNewRole('superviseur')
  }

  async function copyPassword() {
    if (createdPassword) {
      await navigator.clipboard.writeText(createdPassword)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  async function toggleActive(admin: Admin) {
    await getSupabase()
      .from('admins')
      .update({ is_active: !admin.is_active })
      .eq('id', admin.id)

    if (currentAdmin) {
      await getSupabase().from('admin_logs').insert({
        admin_id: currentAdmin.id,
        action: admin.is_active ? 'deactivate_admin' : 'activate_admin',
        target_type: 'admin',
        target_id: admin.id,
      })
    }

    loadAdmins()
  }

  async function changePassword() {
    if (!changingPwdFor || !newPwd || newPwd.length < 6) return

    const res = await fetch('/api/change-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        admin_id: changingPwdFor.id,
        new_password: newPwd,
      }),
    })

    if (res.ok) {
      setPwdChanged(true)
      if (currentAdmin) {
        await getSupabase().from('admin_logs').insert({
          admin_id: currentAdmin.id,
          action: 'change_password',
          target_type: 'admin',
          target_id: changingPwdFor.id,
        })
      }
      setTimeout(() => {
        setChangingPwdFor(null)
        setNewPwd('')
        setPwdChanged(false)
      }, 2000)
    }
  }

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">Administrateurs</h1>
          <p className="text-sm text-gray-500 mt-1">Gérer les accès au tableau de bord</p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          className="flex items-center gap-2 text-white px-4 py-2 rounded-xl text-sm font-medium hover:opacity-90 transition cursor-pointer"
          style={{ backgroundColor: '#00A8E8' }}
        >
          <Plus size={16} /> Nouvel admin
        </button>
      </div>

      {/* Hiérarchie */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        {ROLES.slice().reverse().map(r => {
          const count = admins.filter(a => a.role === r.value).length
          return (
            <div key={r.value} className="bg-white rounded-xl border border-gray-200 p-4 text-center">
              <span className={`inline-block text-xs px-3 py-1 rounded-lg font-medium ${getRoleColor(r.value)}`}>
                {r.label}
              </span>
              <p className="text-2xl font-bold mt-2">{count}</p>
              <p className="text-xs text-gray-400 mt-1">
                {r.value === 'super_admin' && 'Accès total'}
                {r.value === 'admin' && 'Gestion complète'}
                {r.value === 'superviseur' && 'Modération'}
              </p>
            </div>
          )
        })}
      </div>

      {/* Modal création */}
      {showCreate && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md">
            {createdPassword ? (
              // Résultat : mot de passe généré
              <div>
                <div className="text-center mb-6">
                  <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-4">
                    <Check size={32} className="text-green-600" />
                  </div>
                  <h2 className="text-lg font-bold">Administrateur créé !</h2>
                  {emailSent ? (
                    <p className="text-sm text-gray-500 mt-2">Un email avec les identifiants a été envoyé à <strong>{newEmail}</strong></p>
                  ) : (
                    <p className="text-sm text-amber-600 mt-2">L&apos;email n&apos;a pas pu être envoyé. Transmettez les identifiants manuellement.</p>
                  )}
                </div>

                <div className="bg-gray-50 rounded-xl p-4 mb-4 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Email</span>
                    <span className="font-medium">{newEmail}</span>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-500">Mot de passe</span>
                    <div className="flex items-center gap-2">
                      <code className="font-bold text-pink-600 bg-white px-2 py-1 rounded border text-sm">{createdPassword}</code>
                      <button onClick={copyPassword} className="cursor-pointer p-1 hover:bg-gray-200 rounded">
                        {copied ? <Check size={14} className="text-green-500" /> : <Copy size={14} className="text-gray-400" />}
                      </button>
                    </div>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-500">Rôle</span>
                    <span>{getRoleLabel(newRole)}</span>
                  </div>
                </div>

                <button
                  onClick={closeCreateModal}
                  className="w-full py-2.5 text-white rounded-xl text-sm font-medium hover:opacity-90 transition cursor-pointer"
                  style={{ backgroundColor: '#00A8E8' }}
                >
                  Fermer
                </button>
              </div>
            ) : (
              // Formulaire
              <div>
                <div className="flex items-center justify-between mb-6">
                  <h2 className="text-lg font-bold">Nouvel administrateur</h2>
                  <button onClick={closeCreateModal} className="cursor-pointer">
                    <X size={20} className="text-gray-400" />
                  </button>
                </div>

                <p className="text-sm text-gray-500 mb-4">
                  Un mot de passe sera généré automatiquement et envoyé par email.
                </p>

                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Nom complet</label>
                    <input
                      type="text"
                      value={newName}
                      onChange={e => setNewName(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00A8E8]"
                      placeholder="Jean Dupont"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                    <input
                      type="email"
                      value={newEmail}
                      onChange={e => setNewEmail(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00A8E8]"
                      placeholder="nom@cartel.ga"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Rôle</label>
                    <select
                      value={newRole}
                      onChange={e => setNewRole(e.target.value as AdminRole)}
                      className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00A8E8]"
                    >
                      {ROLES.map(r => (
                        <option key={r.value} value={r.value}>{r.label}</option>
                      ))}
                    </select>
                  </div>

                  <div className="flex gap-3 pt-2">
                    <button
                      onClick={closeCreateModal}
                      className="flex-1 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 transition cursor-pointer"
                    >
                      Annuler
                    </button>
                    <button
                      onClick={createAdmin}
                      disabled={creating || !newEmail || !newName}
                      className="flex-1 py-2.5 text-white rounded-xl text-sm font-medium hover:opacity-90 disabled:opacity-50 transition cursor-pointer"
                      style={{ backgroundColor: '#00A8E8' }}
                    >
                      {creating ? 'Création...' : 'Créer & Envoyer'}
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Modal changement de mot de passe */}
      {changingPwdFor && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-sm">
            {pwdChanged ? (
              <div className="text-center">
                <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mx-auto mb-4">
                  <Check size={32} className="text-green-600" />
                </div>
                <h2 className="text-lg font-bold">Mot de passe modifié !</h2>
                <p className="text-sm text-gray-500 mt-2">{changingPwdFor.full_name}</p>
              </div>
            ) : (
              <div>
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-lg font-bold">Changer le mot de passe</h2>
                  <button onClick={() => { setChangingPwdFor(null); setNewPwd('') }} className="cursor-pointer">
                    <X size={20} className="text-gray-400" />
                  </button>
                </div>
                <p className="text-sm text-gray-500 mb-4">{changingPwdFor.full_name} ({changingPwdFor.email})</p>
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-1">Nouveau mot de passe</label>
                  <input
                    type="password"
                    value={newPwd}
                    onChange={e => setNewPwd(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00A8E8]"
                    placeholder="Minimum 6 caractères"
                  />
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={() => { setChangingPwdFor(null); setNewPwd('') }}
                    className="flex-1 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 transition cursor-pointer"
                  >
                    Annuler
                  </button>
                  <button
                    onClick={changePassword}
                    disabled={newPwd.length < 6}
                    className="flex-1 py-2.5 text-white rounded-xl text-sm font-medium hover:opacity-90 disabled:opacity-50 transition cursor-pointer"
                    style={{ backgroundColor: '#00A8E8' }}
                  >
                    Modifier
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Liste */}
      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="text-left py-3 px-4 font-medium text-gray-500">Nom</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Email</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Rôle</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Dernière connexion</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Statut</th>
              <th className="text-right py-3 px-4 font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody>
            {admins.map(admin => (
              <tr key={admin.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="py-3 px-4 font-medium">{admin.full_name}</td>
                <td className="py-3 px-4 text-gray-600">{admin.email}</td>
                <td className="py-3 px-4">
                  <span className={`text-xs px-2 py-1 rounded-lg font-medium ${getRoleColor(admin.role as AdminRole)}`}>
                    {getRoleLabel(admin.role as AdminRole)}
                  </span>
                </td>
                <td className="py-3 px-4 text-gray-400 text-xs">
                  {admin.last_login ? formatDate(admin.last_login) : 'Jamais'}
                </td>
                <td className="py-3 px-4">
                  <span className={`text-xs px-2 py-1 rounded-lg font-medium ${
                    admin.is_active ? 'bg-green-50 text-green-600' : 'bg-red-50 text-red-600'
                  }`}>
                    {admin.is_active ? 'Actif' : 'Désactivé'}
                  </span>
                </td>
                <td className="py-3 px-4 text-right">
                  <div className="flex items-center justify-end gap-1">
                    <button
                      onClick={() => setChangingPwdFor(admin)}
                      className="p-1.5 hover:bg-gray-100 rounded-lg transition cursor-pointer"
                      title="Changer le mot de passe"
                    >
                      <Key size={14} className="text-gray-400" />
                    </button>
                    <button
                      onClick={() => toggleActive(admin)}
                      className="p-1.5 hover:bg-gray-100 rounded-lg transition cursor-pointer"
                      title={admin.is_active ? 'Désactiver' : 'Activer'}
                    >
                      {admin.is_active
                        ? <ShieldOff size={14} className="text-red-400" />
                        : <Shield size={14} className="text-green-400" />
                      }
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
