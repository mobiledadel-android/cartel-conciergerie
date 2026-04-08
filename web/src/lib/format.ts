export function formatPrice(price: number | null | undefined): string {
  if (price == null) return '—'
  if (price === 0) return 'Sur devis'
  return new Intl.NumberFormat('fr-FR').format(price) + ' FCFA'
}

export function formatDate(date: string | null | undefined): string {
  if (!date) return '—'
  return new Date(date).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function formatStatus(status: string): { label: string; color: string } {
  switch (status) {
    case 'pending':
      return { label: 'En attente', color: 'bg-yellow-100 text-yellow-800' }
    case 'accepted':
      return { label: 'Acceptée', color: 'bg-blue-100 text-blue-800' }
    case 'in_progress':
      return { label: 'En cours', color: 'bg-blue-100 text-blue-800' }
    case 'completed':
      return { label: 'Terminée', color: 'bg-green-100 text-green-800' }
    case 'cancelled':
      return { label: 'Annulée', color: 'bg-red-100 text-red-800' }
    default:
      return { label: status, color: 'bg-gray-100 text-gray-800' }
  }
}

export function formatMissionType(type: string): string {
  switch (type) {
    case 'ponctuel': return 'Ponctuel'
    case 'programme': return 'Programmé'
    case 'recurrent': return 'Récurrent'
    default: return type
  }
}

export function formatRole(role: string): string {
  switch (role) {
    case 'client': return 'Client'
    case 'prestataire': return 'Prestataire'
    case 'admin': return 'Admin'
    default: return role
  }
}
