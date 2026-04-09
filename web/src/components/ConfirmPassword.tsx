'use client'

import { useState } from 'react'
import { X } from 'lucide-react'

export default function ConfirmPassword({
  title,
  message,
  onConfirm,
  onCancel,
}: {
  title: string
  message: string
  onConfirm: () => void
  onCancel: () => void
}) {
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleConfirm() {
    setLoading(true)
    setError('')

    const admin = JSON.parse(localStorage.getItem('admin_session') || '{}')

    const res = await fetch('/api/auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: admin.email, password }),
    })

    if (res.ok) {
      onConfirm()
    } else {
      setError('Mot de passe incorrect')
    }
    setLoading(false)
  }

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-[60]">
      <div className="bg-white rounded-2xl p-6 w-full max-w-sm">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-bold text-red-600">{title}</h2>
          <button onClick={onCancel} className="cursor-pointer">
            <X size={20} className="text-gray-400" />
          </button>
        </div>

        <p className="text-sm text-gray-600 mb-4">{message}</p>

        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Votre mot de passe pour confirmer
          </label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-red-300"
            placeholder="Mot de passe"
            onKeyDown={(e) => e.key === 'Enter' && handleConfirm()}
          />
          {error && <p className="text-red-500 text-xs mt-1">{error}</p>}
        </div>

        <div className="flex gap-3">
          <button
            onClick={onCancel}
            className="flex-1 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 transition cursor-pointer"
          >
            Annuler
          </button>
          <button
            onClick={handleConfirm}
            disabled={!password || loading}
            className="flex-1 py-2.5 bg-red-500 text-white rounded-xl text-sm font-medium hover:bg-red-600 disabled:opacity-50 transition cursor-pointer"
          >
            {loading ? 'Vérification...' : 'Confirmer'}
          </button>
        </div>
      </div>
    </div>
  )
}
