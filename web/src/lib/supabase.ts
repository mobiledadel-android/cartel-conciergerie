import { createClient, SupabaseClient } from '@supabase/supabase-js'

const FALLBACK_URL = 'https://yetjlxvmnzmqdbjcrdew.supabase.co'
const FALLBACK_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlldGpseHZtbnptcWRiamNyZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTc2MDMsImV4cCI6MjA5MTIzMzYwM30.gL2Fin4havOPgZ39celz_vQJ5gwHULgRcR4bEBOSeuE'

let _supabase: SupabaseClient | null = null

export function getSupabase(): SupabaseClient {
  if (_supabase) return _supabase

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || FALLBACK_URL
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || FALLBACK_KEY

  _supabase = createClient(supabaseUrl, supabaseAnonKey)
  return _supabase
}
