import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Remplacer par vos vraies clés Supabase
  static const String supabaseUrl = 'https://yetjlxvmnzmqdbjcrdew.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlldGpseHZtbnptcWRiamNyZGV3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NTc2MDMsImV4cCI6MjA5MTIzMzYwM30.gL2Fin4havOPgZ39celz_vQJ5gwHULgRcR4bEBOSeuE';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
