import 'dart:io';
import '../config/supabase_config.dart';
import 'auth_service.dart';

class AgentService {
  final _supabase = SupabaseConfig.client;
  final _authService = AuthService();

  /// Récupérer le profil prestataire
  Future<Map<String, dynamic>?> getAgentProfile() async {
    final profile = await _authService.getProfile();
    if (profile == null) return null;

    return await _supabase
        .from('prestataire_profiles')
        .select()
        .eq('id', profile['id'])
        .maybeSingle();
  }

  /// Créer ou mettre à jour le profil prestataire
  Future<void> saveAgentProfile({
    required String bio,
    required List<String> competences,
    String? presentation,
    int? experienceYears,
    List<String>? zones,
  }) async {
    final profile = await _authService.getProfile();
    if (profile == null) throw Exception('Profil introuvable');

    final existing = await getAgentProfile();

    final data = {
      'bio': bio,
      'competences': competences,
      'presentation': presentation,
      'experience_years': experienceYears ?? 0,
      'zones': zones ?? [],
      'onboarding_status': 'pending_review',
    };

    if (existing == null) {
      await _supabase.from('prestataire_profiles').insert({
        'id': profile['id'],
        ...data,
      });
    } else {
      await _supabase
          .from('prestataire_profiles')
          .update(data)
          .eq('id', profile['id']);
    }

    // Activer le flag prestataire
    await _supabase
        .from('profiles')
        .update({'is_prestataire_enabled': true})
        .eq('id', profile['id']);
  }

  /// Upload un document
  Future<String> uploadDocument({
    required String filePath,
    required String type,
    required String label,
  }) async {
    final profile = await _authService.getProfile();
    if (profile == null) throw Exception('Profil introuvable');

    final fileName = '${profile['id']}/${type}_${DateTime.now().millisecondsSinceEpoch}';

    final file = File(filePath);
    await _supabase.storage
        .from('agent-documents')
        .upload(fileName, file);

    final fileUrl = _supabase.storage
        .from('agent-documents')
        .getPublicUrl(fileName);

    await _supabase.from('agent_documents').insert({
      'profile_id': profile['id'],
      'type': type,
      'label': label,
      'file_url': fileUrl,
    });

    return fileUrl;
  }

  /// Récupérer les documents soumis
  Future<List<Map<String, dynamic>>> getDocuments() async {
    final profile = await _authService.getProfile();
    if (profile == null) return [];

    final data = await _supabase
        .from('agent_documents')
        .select()
        .eq('profile_id', profile['id'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Récupérer les gains
  Future<Map<String, dynamic>> getEarnings() async {
    final profile = await _authService.getProfile();
    if (profile == null) return {'total': 0, 'pending': 0, 'available': 0, 'paid': 0, 'history': []};

    final data = await _supabase
        .from('agent_earnings')
        .select('*, mission:mission_id(services(name), created_at)')
        .eq('agent_id', profile['id'])
        .order('created_at', ascending: false);

    final list = List<Map<String, dynamic>>.from(data);

    double total = 0, pending = 0, available = 0, paid = 0;
    for (final e in list) {
      final amount = (e['amount'] as num?)?.toDouble() ?? 0;
      total += amount;
      switch (e['status']) {
        case 'pending':
          pending += amount;
          break;
        case 'available':
          available += amount;
          break;
        case 'paid':
          paid += amount;
          break;
      }
    }

    return {
      'total': total,
      'pending': pending,
      'available': available,
      'paid': paid,
      'history': list,
    };
  }

  /// Stats de performance
  Future<Map<String, dynamic>> getStats() async {
    final profile = await _authService.getProfile();
    if (profile == null) return {};

    final agentProfile = await getAgentProfile();
    final earnings = await getEarnings();

    final missionsData = await _supabase
        .from('missions')
        .select('status')
        .eq('prestataire_id', profile['id']);

    final missions = List<Map<String, dynamic>>.from(missionsData);
    final completed = missions.where((m) => m['status'] == 'completed').length;
    final inProgress = missions.where((m) => m['status'] == 'in_progress' || m['status'] == 'accepted').length;

    return {
      'rating': agentProfile?['rating_avg'] ?? 0,
      'total_missions': missions.length,
      'completed': completed,
      'in_progress': inProgress,
      'total_earnings': earnings['total'],
      'pending_earnings': earnings['pending'],
      'available_earnings': earnings['available'],
    };
  }
}
