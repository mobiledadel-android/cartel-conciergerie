import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/mission_service.dart';
import '../missions/missions_screen.dart';
import '../missions/service_list_screen.dart';
import '../missions/mission_detail_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    _HomeContent(),
    MissionsScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final _missionService = MissionService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _activeMissions = [];
  String _firstName = '';
  String _role = 'client';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _authService.getProfile();

    final role = profile?['role'] ?? 'client';
    List<Map<String, dynamic>> missions;
    if (role == 'prestataire') {
      final own = await _missionService.getPrestataireMissions();
      final available = await _missionService.getAvailableMissions();
      missions = [...own, ...available];
    } else {
      missions = await _missionService.getClientMissions();
    }

    final active = missions
        .where((m) =>
            m['status'] != 'completed' && m['status'] != 'cancelled')
        .toList();

    if (mounted) {
      setState(() {
        _firstName = profile?['first_name'] ?? '';
        _role = role;
        _activeMissions = active;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour 👋',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _firstName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (_role == 'prestataire')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🛠 Prestataire',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: Badge(
                      smallSize: 8,
                      child:
                          const Icon(Icons.notifications_outlined, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Catégories de services (mode client)
              if (_role == 'client') ...[
                Text(
                  'Nos services',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _CategoryCard(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Courses',
                      subtitle: 'Supermarché, marché',
                      color: AppColors.primary,
                      onTap: () => _openCategory('courses'),
                    ),
                    _CategoryCard(
                      icon: Icons.local_pharmacy_outlined,
                      title: 'Médicaments',
                      subtitle: 'Pharmacie',
                      color: AppColors.accent,
                      onTap: () => _openCategory('medicaments'),
                    ),
                    _CategoryCard(
                      icon: Icons.local_shipping_outlined,
                      title: 'Colis',
                      subtitle: 'Envoi & réception',
                      color: AppColors.warning,
                      onTap: () => _openCategory('colis'),
                    ),
                    _CategoryCard(
                      icon: Icons.people_outline,
                      title: 'Accompagnement',
                      subtitle: 'RDV, personnes âgées',
                      color: AppColors.success,
                      onTap: () => _openCategory('accompagnement'),
                    ),
                    _CategoryCard(
                      icon: Icons.home_repair_service_outlined,
                      title: 'Aide à domicile',
                      subtitle: 'Ménage, garde, cuisine',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => _openCategory('assistance'),
                    ),
                    _CategoryCard(
                      icon: Icons.more_horiz,
                      title: 'Autre',
                      subtitle: 'Service sur mesure',
                      color: AppColors.textSecondary,
                      onTap: () => _openCategory('autre'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],

              // Missions en cours
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _role == 'prestataire'
                        ? 'Missions disponibles'
                        : 'En cours',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_activeMissions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _role == 'prestataire'
                            ? 'Aucune mission disponible'
                            : 'Aucune mission en cours',
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (_role == 'client') ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Choisissez un service ci-dessus !',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                ...List.generate(_activeMissions.length, (index) {
                  final mission = _activeMissions[index];
                  final service =
                      mission['services'] as Map<String, dynamic>?;
                  final status = mission['status'] as String;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MissionDetailScreen(
                              missionId: mission['id'],
                            ),
                          ),
                        ).then((_) => _load());
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getCategoryIcon(
                                    service?['category'] ?? ''),
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service?['name'] ?? 'Mission',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    mission['description'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StatusDot(status: status),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _openCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceListScreen(category: category),
      ),
    ).then((_) => _load());
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'courses':
        return Icons.shopping_cart_outlined;
      case 'medicaments':
        return Icons.local_pharmacy_outlined;
      case 'colis':
        return Icons.local_shipping_outlined;
      case 'accompagnement':
        return Icons.people_outline;
      case 'assistance':
        return Icons.home_repair_service_outlined;
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = AppColors.warning;
        label = 'En attente';
        break;
      case 'accepted':
        color = AppColors.primary;
        label = 'Acceptée';
        break;
      case 'in_progress':
        color = AppColors.primary;
        label = 'En cours';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
