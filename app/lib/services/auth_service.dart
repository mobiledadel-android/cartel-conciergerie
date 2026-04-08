import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  // Singleton pour garder le _verificationId entre les écrans
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;

  fb.User? get currentUser => _firebaseAuth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get uid => currentUser?.uid;
  String? get phoneNumber => currentUser?.phoneNumber;

  // Mode test : désactive la vérification APNs/reCAPTCHA
  // TODO: Passer à false en production
  static const bool _isTestMode = true;

  // Stocke le verificationId entre sendOtp et verifyOtp
  String? _verificationId;

  /// Envoyer un OTP par SMS via Firebase (gratuit)
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function()? onAutoVerified,
  }) async {
    final formattedPhone = _formatGabonPhone(phoneNumber);

    // Désactive la vérification APNs/reCAPTCHA en mode test
    // Nécessite des numéros de test dans Firebase Console
    if (_isTestMode) {
      _firebaseAuth.setSettings(appVerificationDisabledForTesting: true);
    }

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fb.PhoneAuthCredential credential) async {
        // Auto-vérification sur Android (lecture auto du SMS)
        await _signInWithCredential(credential);
        onAutoVerified?.call();
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        onError(e.message ?? 'Erreur de vérification');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Vérifier le code OTP saisi par l'utilisateur
  Future<void> verifyOtp(String otpCode) async {
    if (_verificationId == null) {
      throw Exception('Aucune vérification en cours');
    }

    final credential = fb.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otpCode,
    );

    await _signInWithCredential(credential);
  }

  /// Connexion Firebase + sync avec Supabase
  Future<void> _signInWithCredential(fb.PhoneAuthCredential credential) async {
    final result = await _firebaseAuth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) throw Exception('Échec de connexion');

    // Synchroniser avec Supabase : créer ou mettre à jour le profil
    await _syncWithSupabase(user);
  }

  /// Créer/mettre à jour le profil dans Supabase avec le Firebase UID
  Future<void> _syncWithSupabase(fb.User user) async {
    final phone = user.phoneNumber ?? '';

    // Vérifier si le profil existe déjà
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('firebase_uid', user.uid)
        .maybeSingle();

    if (existing == null) {
      // Nouveau utilisateur → créer le profil
      await _supabase.from('profiles').insert({
        'firebase_uid': user.uid,
        'first_name': '',
        'last_name': '',
        'phone': phone,
        'role': 'client',
      });
    }
  }

  /// Compléter le profil après la première connexion
  Future<void> completeProfile({
    required String firstName,
    required String lastName,
    String? email,
  }) async {
    await _supabase.from('profiles').update({
      'first_name': firstName,
      'last_name': lastName,
      if (email != null && email.isNotEmpty) 'email': email,
    }).eq('firebase_uid', uid!);
  }

  /// Vérifier si le profil est complété
  Future<bool> isProfileComplete() async {
    if (!isLoggedIn) return false;
    final data = await _supabase
        .from('profiles')
        .select('first_name, last_name')
        .eq('firebase_uid', uid!)
        .single();
    return data['first_name']?.toString().isNotEmpty == true &&
        data['last_name']?.toString().isNotEmpty == true;
  }

  /// Récupérer le profil Supabase
  Future<Map<String, dynamic>?> getProfile() async {
    if (!isLoggedIn) return null;
    return await _supabase
        .from('profiles')
        .select()
        .eq('firebase_uid', uid!)
        .maybeSingle();
  }

  /// Changer le rôle actif (client ↔ prestataire)
  Future<void> switchRole(String role) async {
    await _supabase
        .from('profiles')
        .update({'role': role})
        .eq('firebase_uid', uid!);
  }

  /// Déconnexion des deux services
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Formater le numéro au format gabonais +241
  String _formatGabonPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+241')) return phone;
    if (phone.startsWith('241')) return '+$phone';
    if (phone.startsWith('0')) return '+241${phone.substring(1)}';
    return '+241$phone';
  }
}
