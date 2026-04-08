import '../config/supabase_config.dart';
import 'auth_service.dart';

class MissionService {
  final _supabase = SupabaseConfig.client;
  final _authService = AuthService();

  /// Récupérer la liste des services actifs
  Future<List<Map<String, dynamic>>> getServices() async {
    final data = await _supabase
        .from('services')
        .select()
        .eq('is_active', true)
        .order('category');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Créer une nouvelle mission (côté client)
  Future<Map<String, dynamic>> createMission({
    required String serviceId,
    required String description,
    required String addressDelivery,
    String? addressPickup,
    String? notes,
    int? totalPrice,
    String missionType = 'ponctuel',
    String? recurrenceFrequency,
    String? recurrenceEndDate,
    String? scheduledAt,
  }) async {
    final profile = await _authService.getProfile();
    if (profile == null) throw Exception('Profil introuvable');

    final data = await _supabase.from('missions').insert({
      'client_id': profile['id'],
      'service_id': serviceId,
      'description': description,
      'address_delivery': addressDelivery,
      'address_pickup': addressPickup,
      'notes': notes,
      'status': 'pending',
      'mission_type': missionType,
      if (totalPrice != null) 'total_price': totalPrice,
      if (recurrenceFrequency != null) 'recurrence_frequency': recurrenceFrequency,
      if (recurrenceEndDate != null) 'recurrence_end_date': recurrenceEndDate,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
    }).select().single();

    return data;
  }

  /// Missions du client connecté
  Future<List<Map<String, dynamic>>> getClientMissions() async {
    final profile = await _authService.getProfile();
    if (profile == null) return [];

    final data = await _supabase
        .from('missions')
        .select('*, services(*), prestataire:prestataire_id(first_name, last_name, phone)')
        .eq('client_id', profile['id'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Missions disponibles pour les prestataires (status = pending, pas encore assignées)
  Future<List<Map<String, dynamic>>> getAvailableMissions() async {
    final data = await _supabase
        .from('missions')
        .select('*, services(*), client:client_id(first_name, last_name)')
        .eq('status', 'pending')
        .isFilter('prestataire_id', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Missions du prestataire connecté
  Future<List<Map<String, dynamic>>> getPrestataireMissions() async {
    final profile = await _authService.getProfile();
    if (profile == null) return [];

    final data = await _supabase
        .from('missions')
        .select('*, services(*), client:client_id(first_name, last_name, phone)')
        .eq('prestataire_id', profile['id'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Accepter une mission (côté prestataire)
  Future<void> acceptMission(String missionId) async {
    final profile = await _authService.getProfile();
    if (profile == null) throw Exception('Profil introuvable');

    await _supabase.from('missions').update({
      'prestataire_id': profile['id'],
      'status': 'accepted',
      'accepted_at': DateTime.now().toIso8601String(),
    }).eq('id', missionId);
  }

  /// Démarrer une mission
  Future<void> startMission(String missionId) async {
    await _supabase.from('missions').update({
      'status': 'in_progress',
    }).eq('id', missionId);
  }

  /// Terminer une mission
  Future<void> completeMission(String missionId) async {
    await _supabase.from('missions').update({
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', missionId);
  }

  /// Annuler une mission
  Future<void> cancelMission(String missionId) async {
    await _supabase.from('missions').update({
      'status': 'cancelled',
      'cancelled_at': DateTime.now().toIso8601String(),
    }).eq('id', missionId);
  }

  /// Récupérer une mission par ID
  Future<Map<String, dynamic>> getMission(String missionId) async {
    return await _supabase
        .from('missions')
        .select('*, services(*), client:client_id(*), prestataire:prestataire_id(*)')
        .eq('id', missionId)
        .single();
  }
}
