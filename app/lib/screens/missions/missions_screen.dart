import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/mission_service.dart';
import '../../services/auth_service.dart';
import 'mission_detail_screen.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  final _missionService = MissionService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _missions = [];
  bool _isLoading = true;
  String _currentRole = 'client';

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getProfile();
      _currentRole = profile?['role'] ?? 'client';

      List<Map<String, dynamic>> missions;
      if (_currentRole == 'prestataire') {
        // Prestataire : ses missions + les missions disponibles
        final own = await _missionService.getPrestataireMissions();
        final available = await _missionService.getAvailableMissions();
        missions = [...own, ...available];
      } else {
        missions = await _missionService.getClientMissions();
      }

      if (mounted) {
        setState(() {
          _missions = missions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadMissions,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentRole == 'prestataire'
                    ? 'Missions'
                    : 'Mes demandes',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _missions.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 64,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _currentRole == 'prestataire'
                                            ? 'Aucune mission disponible'
                                            : 'Aucune demande',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: _missions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return _MissionCard(
                                mission: _missions[index],
                                isPrestataire: _currentRole == 'prestataire',
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MissionDetailScreen(
                                        missionId: _missions[index]['id'],
                                      ),
                                    ),
                                  );
                                  _loadMissions();
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Map<String, dynamic> mission;
  final bool isPrestataire;
  final VoidCallback onTap;

  const _MissionCard({
    required this.mission,
    required this.isPrestataire,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = mission['services'] as Map<String, dynamic>?;
    final status = mission['status'] as String;
    final statusConfig = _getStatusConfig(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(service?['category'] ?? ''),
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service?['name'] ?? 'Service',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusConfig.label,
                    style: TextStyle(
                      color: statusConfig.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mission['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mission['address_delivery'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  AppConstants.formatPrice(service?['base_price']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return _StatusConfig('En attente', AppColors.warning);
      case 'accepted':
        return _StatusConfig('Acceptée', AppColors.primary);
      case 'in_progress':
        return _StatusConfig('En cours', AppColors.primary);
      case 'completed':
        return _StatusConfig('Terminée', AppColors.success);
      case 'cancelled':
        return _StatusConfig('Annulée', AppColors.error);
      default:
        return _StatusConfig(status, AppColors.textSecondary);
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  _StatusConfig(this.label, this.color);
}
