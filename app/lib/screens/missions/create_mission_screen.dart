import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/mission_service.dart';
import '../../services/location_service.dart';
import 'mission_detail_screen.dart';

class CreateMissionScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const CreateMissionScreen({super.key, required this.service});

  @override
  State<CreateMissionScreen> createState() => _CreateMissionScreenState();
}

class _CreateMissionScreenState extends State<CreateMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressDeliveryController = TextEditingController();
  final _addressPickupController = TextEditingController();
  final _notesController = TextEditingController();
  final _missionService = MissionService();
  bool _isLoading = false;

  // Type de demande
  String _missionType = 'ponctuel';
  String? _recurrenceFrequency;
  DateTime? _scheduledDate;
  DateTime? _recurrenceEndDate;

  List<String> get _allowedTypes {
    final types = widget.service['allowed_types'];
    if (types == null) return ['ponctuel'];
    if (types is List) return types.cast<String>();
    return ['ponctuel'];
  }

  int get _basePrice =>
      (widget.service['base_price'] as num?)?.toInt() ?? 0;

  bool get _needsPickup {
    final cat = widget.service['category'] as String? ?? '';
    return cat == 'courses' || cat == 'medicaments' || cat == 'colis';
  }

  int get _transportFee => _needsPickup ? LocationService.fixedTransportFee : 0;

  int get _totalPrice {
    if (_basePrice == 0) return 0;
    return _basePrice + _transportFee;
  }

  Future<void> _createMission() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final mission = await _missionService.createMission(
        serviceId: widget.service['id'],
        description: _descriptionController.text.trim(),
        addressDelivery: _addressDeliveryController.text.trim(),
        addressPickup: _addressPickupController.text.trim().isEmpty
            ? null
            : _addressPickupController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        totalPrice: _totalPrice > 0 ? _totalPrice : null,
        missionType: _missionType,
        recurrenceFrequency: _recurrenceFrequency,
        scheduledAt: _scheduledDate?.toIso8601String(),
        recurrenceEndDate: _recurrenceEndDate?.toIso8601String().split('T').first,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MissionDetailScreen(missionId: mission['id']),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressDeliveryController.dispose();
    _addressPickupController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final category = service['category'] as String;
    final isMonthly =
        (service['name'] as String?)?.toLowerCase().contains('mensuel') ??
            false;

    return Scaffold(
      appBar: AppBar(
        title: Text(service['name'] ?? 'Nouvelle mission'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info service
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            service['description'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppConstants.formatPrice(service['base_price']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        if (isMonthly)
                          const Text(
                            '/mois',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                'Décrivez votre demande',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _getDescriptionHint(category),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),

              // Adresse de retrait (si applicable)
              if (_needsPickup) ...[
                Text(
                  'Adresse de retrait',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressPickupController,
                  decoration: InputDecoration(
                    hintText: _getPickupHint(category),
                    prefixIcon: const Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Adresse de livraison / domicile
              Text(
                _needsPickup ? 'Adresse de livraison' : 'Votre adresse',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressDeliveryController,
                decoration: InputDecoration(
                  hintText: _needsPickup
                      ? 'Où livrer ?'
                      : 'Adresse du domicile ou du lieu',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Adresse requise' : null,
              ),
              const SizedBox(height: 20),

              // Notes
              Text(
                'Notes (optionnel)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Instructions supplémentaires...',
                ),
              ),
              const SizedBox(height: 20),

              // Type de demande
              if (_allowedTypes.length > 1) ...[
                Text(
                  'Type de demande',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _allowedTypes.map((type) {
                    final isSelected = _missionType == type;
                    return ChoiceChip(
                      label: Text(_getTypeLabel(type)),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _missionType = type;
                          if (type == 'ponctuel') {
                            _recurrenceFrequency = null;
                            _scheduledDate = null;
                            _recurrenceEndDate = null;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Date programmée (si type = programme)
              if (_missionType == 'programme') ...[
                Text(
                  'Date et heure',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 90)),
                    );
                    if (date != null && mounted) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (time != null && mounted) {
                        setState(() {
                          _scheduledDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          _scheduledDate != null
                              ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year} à ${_scheduledDate!.hour}h${_scheduledDate!.minute.toString().padLeft(2, '0')}'
                              : 'Choisir une date',
                          style: TextStyle(
                            color: _scheduledDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Récurrence (si type = recurrent)
              if (_missionType == 'recurrent') ...[
                Text(
                  'Fréquence',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _FrequencyChip(
                      label: 'Chaque jour',
                      value: 'quotidien',
                      selected: _recurrenceFrequency == 'quotidien',
                      onSelected: () => setState(
                          () => _recurrenceFrequency = 'quotidien'),
                    ),
                    _FrequencyChip(
                      label: 'Chaque semaine',
                      value: 'hebdomadaire',
                      selected: _recurrenceFrequency == 'hebdomadaire',
                      onSelected: () => setState(
                          () => _recurrenceFrequency = 'hebdomadaire'),
                    ),
                    _FrequencyChip(
                      label: 'Tous les 15 jours',
                      value: 'bimensuel',
                      selected: _recurrenceFrequency == 'bimensuel',
                      onSelected: () => setState(
                          () => _recurrenceFrequency = 'bimensuel'),
                    ),
                    _FrequencyChip(
                      label: 'Chaque mois',
                      value: 'mensuel',
                      selected: _recurrenceFrequency == 'mensuel',
                      onSelected: () => setState(
                          () => _recurrenceFrequency = 'mensuel'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date de fin de récurrence
                Text(
                  'Jusqu\'à quand ?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate:
                          DateTime.now().add(const Duration(days: 7)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && mounted) {
                      setState(() => _recurrenceEndDate = date);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_outlined,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          _recurrenceEndDate != null
                              ? '${_recurrenceEndDate!.day}/${_recurrenceEndDate!.month}/${_recurrenceEndDate!.year}'
                              : 'Choisir une date de fin',
                          style: TextStyle(
                            color: _recurrenceEndDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // Récapitulatif prix
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    _PriceRow(
                      label: 'Service',
                      value: _basePrice > 0
                          ? AppConstants.formatPrice(_basePrice)
                          : 'Sur devis',
                    ),
                    if (_needsPickup) ...[
                      const SizedBox(height: 8),
                      _PriceRow(
                        label: 'Transport',
                        value: AppConstants.formatPrice(_transportFee),
                        isSubtle: true,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _basePrice == 0
                              ? 'Sur devis'
                              : AppConstants.formatPrice(_totalPrice),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bouton confirmer
              ElevatedButton(
                onPressed: _isLoading ? null : _createMission,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmer la demande'),
              ),
            ],
          ),
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
      case 'assistance':
        return Icons.home_repair_service_outlined;
      default:
        return Icons.miscellaneous_services_outlined;
    }
  }

  String _getDescriptionHint(String category) {
    switch (category) {
      case 'courses':
        return 'Ex : 2kg de riz, 1L d\'huile, 6 oeufs...';
      case 'medicaments':
        return 'Ex : Doliprane 1000mg, ordonnance jointe...';
      case 'colis':
        return 'Ex : Colis à récupérer chez DHL, référence...';
      case 'accompagnement':
        return 'Ex : Accompagnement rendez-vous médical à 14h...';
      case 'assistance':
        return 'Ex : Ménage complet appartement 3 pièces...';
      default:
        return 'Décrivez ce dont vous avez besoin...';
    }
  }

  String _getPickupHint(String category) {
    switch (category) {
      case 'courses':
        return 'Nom du supermarché ou marché';
      case 'medicaments':
        return 'Nom de la pharmacie';
      case 'colis':
        return 'Adresse de retrait du colis';
      default:
        return 'Adresse de retrait';
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'ponctuel':
        return 'Ponctuel';
      case 'programme':
        return 'Programmé';
      case 'recurrent':
        return 'Récurrent';
      default:
        return type;
    }
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelected;

  const _FrequencyChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.accent.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.accent : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? AppColors.accent : AppColors.divider,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSubtle;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isSubtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSubtle ? 13 : 14,
            color: isSubtle ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isSubtle ? 13 : 14,
            fontWeight: isSubtle ? FontWeight.normal : FontWeight.w600,
            color: isSubtle ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
