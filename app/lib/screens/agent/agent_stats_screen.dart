import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/agent_service.dart';

class AgentStatsScreen extends StatefulWidget {
  const AgentStatsScreen({super.key});

  @override
  State<AgentStatsScreen> createState() => _AgentStatsScreenState();
}

class _AgentStatsScreenState extends State<AgentStatsScreen> {
  final _agentService = AgentService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _agentService.getStats();
    if (mounted) setState(() { _stats = stats; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final rating = (_stats['rating'] as num?)?.toDouble() ?? 0;
    final totalMissions = (_stats['total_missions'] as num?)?.toInt() ?? 0;
    final completed = (_stats['completed'] as num?)?.toInt() ?? 0;
    final inProgress = (_stats['in_progress'] as num?)?.toInt() ?? 0;
    final totalEarnings = (_stats['total_earnings'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes statistiques'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Note moyenne
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: i < rating.round() ? Colors.amber : AppColors.divider,
                        size: 36,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rating > 0 ? '${rating.toStringAsFixed(1)} / 5' : 'Pas encore noté',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalMissions mission(s) au total',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grille stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  icon: Icons.check_circle_outline,
                  label: 'Terminées',
                  value: '$completed',
                  color: AppColors.success,
                ),
                _StatCard(
                  icon: Icons.pending_actions,
                  label: 'En cours',
                  value: '$inProgress',
                  color: AppColors.primary,
                ),
                _StatCard(
                  icon: Icons.monetization_on_outlined,
                  label: 'Total gagné',
                  value: AppConstants.formatPrice(totalEarnings),
                  color: AppColors.accent,
                ),
                _StatCard(
                  icon: Icons.percent,
                  label: 'Taux complétion',
                  value: totalMissions > 0
                      ? '${(completed / totalMissions * 100).toStringAsFixed(0)}%'
                      : '—',
                  color: AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
