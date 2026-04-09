'use client'

import { useEffect, useState } from 'react'
import { getRoleLabel, getRoleColor, type AdminRole } from '@/lib/admin'
import { Check, Eye, EyeOff } from 'lucide-react'

export default function ProfilePage() {
  const [admin, setAdmin] = useState<{ id: string; email: string; full_name: string; role: string } | null>(null)
  const [currentPwd, setCurrentPwd] = useState('')
  const [newPwd, setNewPwd] = useState('')
  const [confirmPwd, setConfirmPwd] = useState('')
  const [showPwd, setShowPwd] = useState(false)
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    const session = localStorage.getItem('admin_session')
    if (session) setAdmin(JSON.parse(session))
  }, [])

  async function handleChangePassword(e: React.FormEvent) {
    e.preventDefault()
    setError('')

    if (newPwd.length < 6) {
      setError('Le mot de passe doit faire au moins 6 caractères')
      return
    }
    if (newPwd !== confirmPwd) {
      setError('Les mots de passe ne correspondent pas')
      return
    }

    setLoading(true)

    // Vérifier l'ancien mot de passe
    const authRes = await fetch('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: admin?.email, password: currentPwd }),
    })

    if (!authRes.ok) {
      setError('Mot de passe actuel incorrect')
      setLoading(false)
      return
    }

    // Changer le mot de passe
    const res = await fetch('/api/change-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ admin_id: admin?.id, new_password: newPwd }),
    })

    if (res.ok) {
      setSuccess(true)
      setCurrentPwd('')
      setNewPwd('')
      setConfirmPwd('')
      setTimeout(() => setSuccess(false), 3000)
    } else {
      setError('Erreur lors du changement')
    }

    setLoading(false)
  }

  if (!admin) return null

  return (
    <div className="max-w-lg">
      <h1 className="text-2xl font-bold mb-8">Mon profil</h1>

      {/* Infos */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6 mb-6">
        <div className="flex items-center gap-4 mb-6">
          <div
            className="w-16 h-16 rounded-full flex items-center justify-center text-white text-xl font-bold"
            style={{ backgroundColor: '#00A8E8' }}
          >
            {admin.full_name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2)}
          </div>
          <div>
            <h2 className="text-lg font-bold">{admin.full_name}</h2>
            <p className="text-sm text-gray-500">{admin.email}</p>
            <span className={`inline-block mt-1 text-xs px-2 py-0.5 rounded-lg font-medium ${getRoleColor(admin.role as AdminRole)}`}>
              {getRoleLabel(admin.role as AdminRole)}
            </span>
          </div>
        </div>
      </div>

      {/* Changer mot de passe */}
      <div className="bg-white rounded-2xl border border-gray-200 p-6">
        <h3 className="font-semibold mb-4">Changer le mot de passe</h3>

        {success && (
          <div className="flex items-center gap-2 bg-green-50 text-green-700 px-4 py-3 rounded-xl mb-4 text-sm">
            <Check size={16} />
            Mot de passe modifié avec succès
          </div>
        )}

        <form onSubmit={handleChangePassword} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Mot de passe actuel</label>
            <div className="relative">
              <input
                type={showPwd ? 'text' : 'password'}
                value={currentPwd}
                onChange={(e) => setCurrentPwd(e.target.value)}
                className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00A8E8] pr-10"
                required
              />
              <button
                type="button"
                onClick={() => setShowPwd(!showPwd)}
                className="absolute right-3 top-1/2 -translate-y-1/2 cursor-pointer"
              >
                {showPwd ? <EyeOff size={16} className="text-gray-400" /> : <Eye size={16} className="text-gray-400" />}
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Nouveau mot de passe</label>
            <input
              type="password"
              value={newPwd}
              onChange={(e) => setNewPwd(e.target.value)}
              className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00A8E8]"
              placeholder="Minimum 6 caractères"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Confirmer le nouveau mot de passe</label>
            <input
              type="password"
              value={confirmPwd}
              onChange={(e) => setConfirmPwd(e.target.value)}
              className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00A8E8]"
              required
            />
          </div>

          {error && <p className="text-red-500 text-sm">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2.5 text-white rounded-xl text-sm font-medium hover:opacity-90 disabled:opacity-50 transition cursor-pointer"
            style={{ backgroundColor: '#00A8E8' }}
          >
            {loading ? 'Modification...' : 'Modifier le mot de passe'}
          </button>
        </form>
      </div>
    </div>
  )
}
