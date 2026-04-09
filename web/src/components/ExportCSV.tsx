'use client'

import { Download } from 'lucide-react'

export default function ExportCSV({
  data,
  filename,
  headers,
  keys,
}: {
  data: Record<string, unknown>[]
  filename: string
  headers: string[]
  keys: string[]
}) {
  function exportCSV() {
    const csvRows = [headers.join(',')]

    data.forEach((row) => {
      const values = keys.map((key) => {
        const val = key.split('.').reduce((obj: unknown, k) => {
          if (obj && typeof obj === 'object') return (obj as Record<string, unknown>)[k]
          return ''
        }, row)
        const str = String(val ?? '').replace(/"/g, '""')
        return `"${str}"`
      })
      csvRows.push(values.join(','))
    })

    const blob = new Blob(['\ufeff' + csvRows.join('\n')], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = `${filename}_${new Date().toISOString().split('T')[0]}.csv`
    link.click()
    URL.revokeObjectURL(url)
  }

  return (
    <button
      onClick={exportCSV}
      className="flex items-center gap-2 px-3 py-2 text-sm border border-gray-200 rounded-xl text-gray-600 hover:bg-gray-50 transition cursor-pointer"
    >
      <Download size={14} />
      Export CSV
    </button>
  )
}
