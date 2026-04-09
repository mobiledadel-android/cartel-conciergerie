import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'auth_service.dart';
import '../config/supabase_config.dart';

class NotificationService {
  // TODO: Remplacer par votre OneSignal App ID
  static const String _oneSignalAppId = 'VOTRE_ONESIGNAL_APP_ID';

  static Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
  }

  /// Associer le Firebase UID à OneSignal pour cibler l'utilisateur
  static Future<void> setExternalUserId() async {
    final authService = AuthService();
    final uid = authService.uid;
    if (uid != null) {
      OneSignal.login(uid);
    }
  }

  /// Se déconnecter de OneSignal
  static Future<void> removeExternalUserId() async {
    OneSignal.logout();
  }

  /// Envoyer une notification via Supabase (stockée en BDD)
  static Future<void> sendLocalNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Stocker dans la table notifications de Supabase
    final profile = await SupabaseConfig.client
        .from('profiles')
        .select('id')
        .eq('firebase_uid', userId)
        .maybeSingle();

    if (profile != null) {
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': profile['id'],
        'title': title,
        'body': body,
        'data': data,
      });
    }
  }
}
