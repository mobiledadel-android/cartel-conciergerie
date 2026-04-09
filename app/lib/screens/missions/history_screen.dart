import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/mission_service.dart';
import '../../services/auth_service.dart';
import 'mission_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _missionService = MissionService();
  final _authService = AuthService();
  late TabController _tabController;
  List<Map<String, dynamic>> _allMissions = [];
  bool _isLoading = true;
  String _role = 'client';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final profile = await _authService.getProfile();
    _role = profile?['role'] ?? 'client';

    List<Map<String, dynamic>> missions;
    if (_role == 'prestataire') {
      missions = await _missionService.getPrestataireMissions();
    } else {
      missions = await _missionService.getClientMissions();
    }

    if (mounted) {
      setState(() {
        _allMissions = missions;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getByStatus(List<String> statuses) {
    return _allMissions.where((m) => statuses.contains(m['status'])).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _getByStatus(['pending', 'accepted', 'in_progress']);
    final completed = _getByStatus(['completed']);
    final cancelled = _getByStatus(['cancelled']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'En cours (${active.length})'),
            Tab(text: 'Terminées (${completed.length})'),
            Tab(text: 'Annulées (${cancelled.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _MissionList(missions: active, onRefresh: _load),
                _MissionList(missions: completed, onRefresh: _load),
                _MissionList(missions: cancelled, onRefresh: _load),
              ],
            ),
    );
  }
}

class _MissionList extends StatelessWidget {
  final List<Map<String, dynamic>> missions;
  final VoidCallback onRefresh;

  const _MissionList({required this.missions, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('Aucune mission',
                style: TextStyle(color: AppColors.textSecondary)),
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
          final status = mission['status'] as String;

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MissionDetailScreen(missionId: mission['id']),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(service?['category'] ?? ''),
                      color: _getStatusColor(status),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service?['name'] ?? 'Mission',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mission['description'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(mission['created_at']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConstants.formatPrice(
                            mission['total_price'] ?? service?['base_price']),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.primary,
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

  String _formatDate(String? date) {
    if (date == null) return '';
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'accepted': return AppColors.primary;
      case 'in_progress': return AppColors.primary;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'accepted': return 'Acceptée';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'courses': return Icons.shopping_cart_outlined;
      case 'medicaments': return Icons.local_pharmacy_outlined;
      case 'colis': return Icons.local_shipping_outlined;
      case 'accompagnement': return Icons.people_outline;
      case 'assistance': return Icons.home_repair_service_outlined;
      default: return Icons.miscellaneous_services_outlined;
    }
  }
}
