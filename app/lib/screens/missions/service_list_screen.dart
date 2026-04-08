import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/mission_service.dart';
import 'create_mission_screen.dart';

class ServiceListScreen extends StatefulWidget {
  final String category;

  const ServiceListScreen({super.key, required this.category});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _missionService = MissionService();
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final all = await _missionService.getServices();
    final filtered =
        all.where((s) => s['category'] == widget.category).toList();
    if (mounted) {
      setState(() {
        _services = filtered;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryLabel =
        AppConstants.categoryLabels[widget.category] ?? widget.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? Center(
                  child: Text(
                    'Aucun service disponible',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _services.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    final isMonthly = (service['name'] as String?)
                            ?.toLowerCase()
                            .contains('mensuel') ??
                        false;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateMissionScreen(service: service),
                          ),
                        );
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
                                color: _getCategoryColor(widget.category)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(widget.category),
                                color: _getCategoryColor(widget.category),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          service['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (isMonthly)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Mensuel',
                                            style: TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service['description'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isMonthly
                                        ? '${AppConstants.formatPrice(service['base_price'])}/mois'
                                        : AppConstants.formatPrice(
                                            service['base_price']),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color:
                                          _getCategoryColor(widget.category),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    );
                  },
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
      case 'assistance':
        return Icons.home_repair_service_outlined;
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'courses':
        return AppColors.primary;
      case 'medicaments':
        return AppColors.accent;
      case 'colis':
        return AppColors.warning;
      case 'accompagnement':
        return AppColors.success;
      case 'assistance':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.textSecondary;
    }
  }
}
