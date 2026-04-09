import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/mission_service.dart';
import '../missions/mission_detail_screen.dart';

class AgentMissionsScreen extends StatefulWidget {
  const AgentMissionsScreen({super.key});

  @override
  State<AgentMissionsScreen> createState() => _AgentMissionsScreenState();
}

class _AgentMissionsScreenState extends State<AgentMissionsScreen>
    with SingleTickerProviderStateMixin {
  final _missionService = MissionService();
  late TabController _tabController;
  List<Map<String, dynamic>> _available = [];
  List<Map<String, dynamic>> _myMissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final available = await _missionService.getAvailableMissions();
    final mine = await _missionService.getPrestataireMissions();
    if (mounted) {
      setState(() {
        _available = available;
        _myMissions = mine;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Missions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _load();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Disponibles (${_available.length})'),
              Tab(text: 'Mes missions (${_myMissions.length})'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _MissionList(
                        missions: _available,
                        emptyMessage: 'Aucune mission disponible',
                        emptyIcon: Icons.search_off,
                        onRefresh: _load,
                        showAcceptHint: true,
                      ),
                      _MissionList(
                        missions: _myMissions,
                        emptyMessage: 'Vous n\'avez pas encore de missions',
                        emptyIcon: Icons.assignment_outlined,
                        onRefresh: _load,
                        showAcceptHint: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MissionList extends StatelessWidget {
  final List<Map<String, dynamic>> missions;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback onRefresh;
  final bool showAcceptHint;

  const _MissionList({
    required this.missions,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
    required this.showAcceptHint,
  });

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: missions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final mission = missions[index];
          final service = mission['services'] as Map<String, dynamic>?;
          final client = mission['client'] as Map<String, dynamic>?;
          final status = mission['status'] as String;

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MissionDetailScreen(missionId: mission['id']),
                ),
              ).then((_) => onRefresh());
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(service?['category'] ?? '').withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(service?['category'] ?? ''),
                          color: _getCategoryColor(service?['category'] ?? ''),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service?['name'] ?? 'Mission',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            if (client != null)
                              Text(
                                'Client : ${client['first_name']} ${client['last_name']}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppConstants.formatPrice(mission['total_price'] ?? service?['base_price']),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                          ),
                          _StatusChip(status: status),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mission['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mission['address_delivery'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      if (showAcceptHint && status == 'pending')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Accepter →',
                            style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'courses': return Icons.shopping_cart_outlined;
      case 'medicaments': return Icons.local_pharmacy_outlined;
      case 'colis': return Icons.local_shipping_outlined;
      case 'accompagnement': return Icons.people_outline;
      case 'assistance': return Icons.home_repair_service_outlined;
      default: return Icons.miscellaneous_services_outlined;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'courses': return AppColors.primary;
      case 'medicaments': return AppColors.accent;
      case 'colis': return AppColors.warning;
      case 'accompagnement': return AppColors.success;
      case 'assistance': return const Color(0xFF8B5CF6);
      default: return AppColors.textSecondary;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _get();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(config.$2, style: TextStyle(fontSize: 10, color: config.$1, fontWeight: FontWeight.w600)),
    );
  }

  (Color, String) _get() {
    switch (status) {
      case 'pending': return (AppColors.warning, 'En attente');
      case 'accepted': return (AppColors.primary, 'Acceptée');
      case 'in_progress': return (AppColors.primary, 'En cours');
      case 'completed': return (AppColors.success, 'Terminée');
      case 'cancelled': return (AppColors.error, 'Annulée');
      default: return (AppColors.textSecondary, status);
    }
  }
}
