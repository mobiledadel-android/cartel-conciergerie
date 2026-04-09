import '../config/supabase_config.dart';
import 'auth_service.dart';

class ReviewService {
  final _supabase = SupabaseConfig.client;
  final _authService = AuthService();

  /// Laisser un avis après une mission
  Future<void> createReview({
    required String missionId,
    required String reviewedId,
    required int rating,
    String? comment,
  }) async {
    final profile = await _authService.getProfile();
    if (profile == null) throw Exception('Profil introuvable');

    await _supabase.from('reviews').insert({
      'mission_id': missionId,
      'reviewer_id': profile['id'],
      'reviewed_id': reviewedId,
      'rating': rating,
      'comment': comment,
    });
  }

  /// Vérifier si un avis a déjà été laissé pour une mission
  Future<bool> hasReviewed(String missionId) async {
    final profile = await _authService.getProfile();
    if (profile == null) return true;

    final data = await _supabase
        .from('reviews')
        .select('id')
        .eq('mission_id', missionId)
        .eq('reviewer_id', profile['id'])
        .maybeSingle();

    return data != null;
  }

  /// Récupérer les avis d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserReviews(String userId) async {
    final data = await _supabase
        .from('reviews')
        .select('*, reviewer:reviewer_id(first_name, last_name), mission:mission_id(services(name))')
        .eq('reviewed_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}
