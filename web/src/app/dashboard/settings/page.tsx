'use client'

import { useEffect, useState } from 'react'
import { getSupabase } from '@/lib/supabase'
import { Check, Settings } from 'lucide-react'

type Setting = {
  key: string
  value: string
  label: string
  description: string | null
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<Setting[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState<string | null>(null)
  const [saved, setSaved] = useState<string | null>(null)
  const [editValues, setEditValues] = useState<Record<string, string>>({})

  useEffect(() => { loadSettings() }, [])

  async function loadSettings() {
    const { data } = await getSupabase()
      .from('platform_settings')
      .select('*')
      .order('key')
    const items = (data as Setting[]) || []
    setSettings(items)
    const values: Record<string, string> = {}
    items.forEach(s => { values[s.key] = s.value })
    setEditValues(values)
    setLoading(false)
  }

  async function saveSetting(key: string) {
    setSaving(key)
    const admin = JSON.parse(localStorage.getItem('admin_session') || '{}')

    await getSupabase()
      .from('platform_settings')
      .update({
        value: editValues[key],
        updated_by: admin.id,
        updated_at: new Date().toISOString(),
      })
      .eq('key', key)

    // Log
    if (admin.id) {
      await getSupabase().from('admin_logs').insert({
        admin_id: admin.id,
        action: 'update_setting',
        target_type: 'setting',
        details: { key, value: editValues[key] },
      })
    }

    setSaving(null)
    setSaved(key)
    setTimeout(() => setSaved(null), 2000)
    loadSettings()
  }

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  return (
    <div className="max-w-2xl">
      <div className="flex items-center gap-3 mb-8">
        <Settings size={24} className="text-gray-400" />
        <div>
          <h1 className="text-2xl font-bold">Paramètres</h1>
          <p className="text-sm text-gray-500">Configuration de la plateforme</p>
        </div>
      </div>

      <div className="space-y-4">
        {settings.map(setting => {
          const isCommission = setting.key === 'commission_rate'
          const isCurrency = setting.key !== 'commission_rate'

          return (
            <div key={setting.key} className="bg-white rounded-2xl border border-gray-200 p-6">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <h3 className="font-semibold">{setting.label}</h3>
                  {setting.description && (
                    <p className="text-sm text-gray-500 mt-1">{setting.description}</p>
                  )}
                </div>
                {saved === setting.key && (
                  <span className="flex items-center gap-1 text-green-600 text-sm">
                    <Check size={14} /> Enregistré
                  </span>
                )}
              </div>

              <div className="flex items-center gap-3">
                <div className="relative flex-1">
                  <input
                    type="number"
                    value={editValues[setting.key] || ''}
                    onChange={e => setEditValues({ ...editValues, [setting.key]: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#00A8E8] text-lg font-semibold pr-16"
                  />
                  <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-400 text-sm">
                    {isCommission ? '%' : 'FCFA'}
                  </span>
                </div>

                <button
                  onClick={() => saveSetting(setting.key)}
                  disabled={saving === setting.key || editValues[setting.key] === setting.value}
                  className="px-5 py-3 text-white rounded-xl text-sm font-medium hover:opacity-90 disabled:opacity-50 transition cursor-pointer"
                  style={{ backgroundColor: '#00A8E8' }}
                >
                  {saving === setting.key ? '...' : 'Enregistrer'}
                </button>
              </div>

              {isCommission && (
                <p className="text-xs text-gray-400 mt-3">
                  Exemple : pour un service à 5 000 FCFA avec {editValues[setting.key] || 15}% de commission →
                  Agent reçoit {Math.round(5000 * (1 - (Number(editValues[setting.key] || 15)) / 100))} FCFA,
                  Plateforme reçoit {Math.round(5000 * (Number(editValues[setting.key] || 15)) / 100)} FCFA
                </p>
              )}

              {isCurrency && (
                <p className="text-xs text-gray-400 mt-3">
                  Valeur actuelle : {new Intl.NumberFormat('fr-FR').format(Number(setting.value))} FCFA
                </p>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
