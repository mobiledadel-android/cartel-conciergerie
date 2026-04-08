'use client'

import { useEffect, useState } from 'react'
import { getSupabase } from '@/lib/supabase'
import { formatDate } from '@/lib/format'

type Log = {
  id: string
  action: string
  target_type: string | null
  target_id: string | null
  details: Record<string, unknown> | null
  created_at: string
  admin: { full_name: string; email: string } | null
}

const ACTION_LABELS: Record<string, string> = {
  create_admin: 'Création admin',
  deactivate_admin: 'Désactivation admin',
  activate_admin: 'Activation admin',
  suspend_client: 'Suspension client',
  suspend_agent: 'Suspension agent',
  suspend_all: 'Blocage compte',
  unsuspend_client: 'Réactivation client',
  unsuspend_agent: 'Réactivation agent',
  unsuspend_all: 'Déblocage compte',
}

export default function LogsPage() {
  const [logs, setLogs] = useState<Log[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => { loadLogs() }, [])

  async function loadLogs() {
    const { data } = await getSupabase()
      .from('admin_logs')
      .select('*, admin:admin_id(full_name, email)')
      .order('created_at', { ascending: false })
      .limit(100)
    setLogs((data as Log[]) || [])
    setLoading(false)
  }

  if (loading) return <div className="text-center py-20 text-gray-400">Chargement...</div>

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold">Journal d&apos;activité</h1>
        <p className="text-sm text-gray-500 mt-1">Historique des actions administratives</p>
      </div>

      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 bg-gray-50">
              <th className="text-left py-3 px-4 font-medium text-gray-500">Date</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Admin</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Action</th>
              <th className="text-left py-3 px-4 font-medium text-gray-500">Détails</th>
            </tr>
          </thead>
          <tbody>
            {logs.map(log => (
              <tr key={log.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="py-3 px-4 text-gray-400 text-xs whitespace-nowrap">
                  {formatDate(log.created_at)}
                </td>
                <td className="py-3 px-4">
                  <div className="font-medium text-sm">{log.admin?.full_name || '—'}</div>
                  <div className="text-xs text-gray-400">{log.admin?.email}</div>
                </td>
                <td className="py-3 px-4">
                  <span className="text-xs bg-gray-100 text-gray-700 px-2 py-1 rounded-lg font-medium">
                    {ACTION_LABELS[log.action] || log.action}
                  </span>
                </td>
                <td className="py-3 px-4 text-xs text-gray-500">
                  {log.details ? (
                    <pre className="whitespace-pre-wrap">{JSON.stringify(log.details, null, 2)}</pre>
                  ) : '—'}
                </td>
              </tr>
            ))}
            {logs.length === 0 && (
              <tr>
                <td colSpan={4} className="py-12 text-center text-gray-400">
                  Aucune activité
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
