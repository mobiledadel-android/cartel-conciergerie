import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/agent_service.dart';
import '../auth/login_screen.dart';
import '../missions/history_screen.dart';
import '../agent/agent_onboarding_screen.dart';
import '../agent/agent_earnings_screen.dart';
import '../agent/agent_stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _agentService = AgentService();
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _agentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getProfile();
    Map<String, dynamic>? agentProfile;
    if (profile?['role'] == 'prestataire' || profile?['is_prestataire_enabled'] == true) {
      agentProfile = await _agentService.getAgentProfile();
    }
    if (mounted) {
      setState(() {
        _profile = profile;
        _agentProfile = agentProfile;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRole() async {
    if (_profile == null) return;

    final currentRole = _profile!['role'] as String;
    final isPrestataire = currentRole == 'prestataire';

    // Si veut devenir prestataire et pas encore de profil agent
    if (!isPrestataire && _agentProfile == null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AgentOnboardingScreen()),
      );
      if (result == true) {
        await _authService.switchRole('prestataire');
        await _loadProfile();
      }
      return;
    }

    // Si veut devenir prestataire et profil agent existe
    if (!isPrestataire) {
      await _authService.switchRole('prestataire');
    } else {
      await _authService.switchRole('client');
    }
    await _loadProfile();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _profile!['role'] == 'prestataire'
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
              backgroundColor: isPrestataire ? AppColors.accent : AppColors.primary,
              child: Text(
                initials,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_profile?['first_name'] ?? ''} ${_profile?['last_name'] ?? ''}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_profile?['phone'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
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
                  fontWeight: FontWeight.w600, fontSize: 13,
                ),
              ),
            ),

            // Onboarding status
            if (_agentProfile != null && _agentProfile!['onboarding_status'] == 'pending_review')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '⏳ Profil agent en attente de validation',
                  style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),

            const SizedBox(height: 24),

            // Switch rôle
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
                  isPrestataire ? 'Passer en mode client' : 'Devenir prestataire',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  isPrestataire ? 'Demander des services' : 'Accepter des missions',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Switch(
                  value: isPrestataire,
                  activeThumbColor: AppColors.accent,
                  onChanged: (_) => _toggleRole(),
                ),
                onTap: _toggleRole,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),

            // Section agent (si prestataire)
            if (isPrestataire) ...[
              _SectionTitle(title: 'Espace prestataire'),
              const SizedBox(height: 8),
              _ProfileTile(
                icon: Icons.monetization_on_outlined,
                title: 'Mes gains',
                subtitle: 'Revenus et commissions',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentEarningsScreen())),
              ),
              _ProfileTile(
                icon: Icons.bar_chart_outlined,
                title: 'Mes statistiques',
                subtitle: 'Performance et notes',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentStatsScreen())),
              ),
              _ProfileTile(
                icon: Icons.edit_note_outlined,
                title: 'Modifier mon profil agent',
                subtitle: 'Compétences, bio, zones',
                onTap: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentOnboardingScreen()));
                  if (result == true) _loadProfile();
                },
              ),
              const SizedBox(height: 20),
            ],

            // Section général
            _SectionTitle(title: 'Général'),
            const SizedBox(height: 8),
            _ProfileTile(
              icon: Icons.history,
              title: 'Historique',
              subtitle: 'Toutes vos missions',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
            ),
            _ProfileTile(
              icon: Icons.help_outline,
              title: 'Aide & Support',
              subtitle: 'FAQ, contact',
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textPrimary),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: Icon(Icons.chevron_right, color: color ?? AppColors.textSecondary),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
