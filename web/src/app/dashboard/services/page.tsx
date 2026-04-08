'use client'

import { useEffect, useState } from 'react'
import { supabase } from '@/lib/supabase'
import { formatPrice } from '@/lib/format'
import { Plus, Pencil, Trash2, X, Check } from 'lucide-react'

type Service = {
  id: string
  name: string
  category: string
  description: string
  base_price: number
  is_active: boolean
  allowed_types: string[]
  allow_recurrence: boolean
}

const CATEGORIES = [
  { value: 'courses', label: 'Courses' },
  { value: 'medicaments', label: 'Médicaments' },
  { value: 'colis', label: 'Colis' },
  { value: 'accompagnement', label: 'Accompagnement' },
  { value: 'assistance', label: 'Aide à domicile' },
  { value: 'autre', label: 'Autre' },
]

const MISSION_TYPES = [
  { value: 'ponctuel', label: 'Ponctuel' },
  { value: 'programme', label: 'Programmé' },
  { value: 'recurrent', label: 'Récurrent' },
]

const emptyService: Omit<Service, 'id'> = {
  name: '',
  category: 'courses',
  description: '',
  base_price: 0,
  is_active: true,
  allowed_types: ['ponctuel'],
  allow_recurrence: false,
}

export default function ServicesPage() {
  const [services, setServices] = useState<Service[]>([])
  const [editing, setEditing] = useState<Partial<Service> | null>(null)
  const [isNew, setIsNew] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => { loadServices() }, [])

  async function loadServices() {
    const { data } = await supabase
      .from('services')
      .select('*')
      .order('category')
      .order('name')
    setServices(data || [])
    setLoading(false)
  }

  async function saveService() {
    if (!editing?.name) return

    const payload = {
      name: editing.name,
      category: editing.category,
      description: editing.description,
      base_price: editing.base_price,
      is_active: editing.is_active,
      allowed_types: editing.allowed_types,
      allow_recurrence: editing.allow_recurrence,
    }

    if (isNew) {
      await supabase.from('services').insert(payload)
    } else {
      await supabase.from('services').update(payload).eq('id', editing.id)
    }

    setEditing(null)
    setIsNew(false)
    loadServices()
  }

  async function deleteService(id: string) {
    if (!confirm('Supprimer ce service ?')) return
    await supabase.from('services').delete().eq('id', id)
    loadServices()
  }

  function toggleType(type: string) {
    if (!editing) return
    const types = editing.allowed_types || []
    const newTypes = types.includes(type)
      ? types.filter(t => t !== type)
      : [...types, type]
    setEditing({ ...editing, allowed_types: newTypes })
  }

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-bold">Services</h1>
        <button
          onClick={() => { setEditing({ ...emptyService }); setIsNew(true) }}
          className="flex items-center gap-2 bg-[var(--primary)] text-white px-4 py-2 rounded-xl text-sm font-medium hover:opacity-90 transition cursor-pointer"
        >
          <Plus size={16} /> Ajouter
        </button>
      </div>

      {/* Modal édition */}
      {editing && (
        <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-6 w-full max-w-lg max-h-[90vh] overflow-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-bold">
                {isNew ? 'Nouveau service' : 'Modifier le service'}
              </h2>
              <button onClick={() => { setEditing(null); setIsNew(false) }} className="cursor-pointer">
                <X size={20} className="text-gray-400" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nom</label>
                <input
                  type="text"
                  value={editing.name || ''}
                  onChange={e => setEditing({ ...editing, name: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Catégorie</label>
                <select
                  value={editing.category || 'courses'}
                  onChange={e => setEditing({ ...editing, category: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
                >
                  {CATEGORIES.map(c => (
                    <option key={c.value} value={c.value}>{c.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <textarea
                  value={editing.description || ''}
                  onChange={e => setEditing({ ...editing, description: e.target.value })}
                  rows={2}
                  className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Prix de base (FCFA)</label>
                <input
                  type="number"
                  value={editing.base_price || 0}
                  onChange={e => setEditing({ ...editing, base_price: Number(e.target.value) })}
                  className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[var(--primary)]"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Types de demande autorisés</label>
                <div className="flex gap-2">
                  {MISSION_TYPES.map(t => {
                    const selected = editing.allowed_types?.includes(t.value)
                    return (
                      <button
                        key={t.value}
                        onClick={() => toggleType(t.value)}
                        className={`px-3 py-1.5 rounded-lg text-sm font-medium transition cursor-pointer ${
                          selected
                            ? 'bg-[var(--primary)] text-white'
                            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                        }`}
                      >
                        {t.label}
                      </button>
                    )
                  })}
                </div>
              </div>

              <div className="flex items-center gap-3">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={editing.allow_recurrence || false}
                    onChange={e => setEditing({ ...editing, allow_recurrence: e.target.checked })}
                    className="w-4 h-4 rounded"
                  />
                  <span className="text-sm text-gray-700">Autoriser la récurrence</span>
                </label>
              </div>

              <div className="flex items-center gap-3">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={editing.is_active !== false}
                    onChange={e => setEditing({ ...editing, is_active: e.target.checked })}
                    className="w-4 h-4 rounded"
                  />
                  <span className="text-sm text-gray-700">Service actif</span>
                </label>
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  onClick={() => { setEditing(null); setIsNew(false) }}
                  className="flex-1 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 transition cursor-pointer"
                >
                  Annuler
                </button>
                <button
                  onClick={saveService}
                  className="flex-1 py-2.5 bg-[var(--primary)] text-white rounded-xl text-sm font-medium hover:opacity-90 transition cursor-pointer"
                >
                  Enregistrer
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Liste des services */}
      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="text-left py-3 px-4 font-medium text-gray-500">Service</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Catégorie</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Prix</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Types</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Statut</th>
              <th className="text-right py-3 px-4 font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody>
            {services.map(service => (
              <tr key={service.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="py-3 px-4">
                  <div className="font-medium">{service.name}</div>
                  <div className="text-xs text-gray-400 mt-0.5">{service.description}</div>
                </td>
                <td className="py-3 px-4">
                  <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded-lg">
                    {CATEGORIES.find(c => c.value === service.category)?.label || service.category}
                  </span>
                </td>
                <td className="py-3 px-4 font-medium">{formatPrice(service.base_price)}</td>
                <td className="py-3 px-4">
                  <div className="flex gap-1 flex-wrap">
                    {(service.allowed_types || []).map(t => (
                      <span key={t} className="text-xs bg-blue-50 text-blue-600 px-2 py-0.5 rounded">
                        {MISSION_TYPES.find(mt => mt.value === t)?.label || t}
                      </span>
                    ))}
                    {service.allow_recurrence && (
                      <span className="text-xs bg-purple-50 text-purple-600 px-2 py-0.5 rounded">
                        Récurrent
                      </span>
                    )}
                  </div>
                </td>
                <td className="py-3 px-4">
                  {service.is_active ? (
                    <span className="flex items-center gap-1 text-green-600 text-xs">
                      <Check size={14} /> Actif
                    </span>
                  ) : (
                    <span className="text-gray-400 text-xs">Inactif</span>
                  )}
                </td>
                <td className="py-3 px-4 text-right">
                  <div className="flex items-center justify-end gap-2">
                    <button
                      onClick={() => { setEditing(service); setIsNew(false) }}
                      className="p-1.5 hover:bg-gray-100 rounded-lg transition cursor-pointer"
                    >
                      <Pencil size={14} className="text-gray-400" />
                    </button>
                    <button
                      onClick={() => deleteService(service.id)}
                      className="p-1.5 hover:bg-red-50 rounded-lg transition cursor-pointer"
                    >
                      <Trash2 size={14} className="text-red-400" />
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
