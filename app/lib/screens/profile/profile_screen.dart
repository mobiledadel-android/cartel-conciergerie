import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRole() async {
    if (_profile == null) return;

    final currentRole = _profile!['role'] as String;
    final isPrestataire = currentRole == 'prestataire';

    // Si l'utilisateur veut devenir prestataire pour la première fois
    if (!isPrestataire && _profile!['is_prestataire_enabled'] != true) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Devenir prestataire'),
          content: const Text(
            'Vous pourrez accepter des missions et gagner de l\'argent.\n\n'
            'Vous pourrez revenir en mode client à tout moment.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Activer'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final newRole = isPrestataire ? 'client' : 'prestataire';
    await _authService.switchRole(newRole);
    await _loadProfile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newRole == 'prestataire'
                ? 'Mode prestataire activé'
                : 'Mode client activé',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPrestataire = _profile?['role'] == 'prestataire';
    final initials = _profile != null
        ? '${(_profile!['first_name'] ?? ' ')[0]}${(_profile!['last_name'] ?? ' ')[0]}'
            .toUpperCase()
        : '';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar
            CircleAvatar(
              radius: 45,
              backgroundColor:
                  isPrestataire ? AppColors.accent : AppColors.primary,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_profile?['first_name'] ?? ''} ${_profile?['last_name'] ?? ''}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _profile?['phone'] ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            // Badge rôle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isPrestataire
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPrestataire ? '🛠 Prestataire' : '👤 Client',
                style: TextStyle(
                  color: isPrestataire ? AppColors.accent : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Switch de rôle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: ListTile(
                leading: Icon(
                  isPrestataire ? Icons.person_outline : Icons.handyman,
                  color: AppColors.accent,
                ),
                title: Text(
                  isPrestataire
                      ? 'Passer en mode client'
                      : 'Devenir prestataire',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  isPrestataire
                      ? 'Demander des services'
                      : 'Accepter des missions',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Switch(
                  value: isPrestataire,
                  activeThumbColor: AppColors.accent,
                  onChanged: (_) => _toggleRole(),
                ),
                onTap: _toggleRole,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Options
            _ProfileTile(
              icon: Icons.person_outline,
              title: 'Modifier le profil',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.location_on_outlined,
              title: 'Mes adresses',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.payment_outlined,
              title: 'Paiement',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.history,
              title: 'Historique',
              onTap: () {},
            ),
            _ProfileTile(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // Déconnexion
            _ProfileTile(
              icon: Icons.logout,
              title: 'Déconnexion',
              color: AppColors.error,
              onTap: () async {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(color: color ?? AppColors.textPrimary),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? AppColors.textSecondary,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
