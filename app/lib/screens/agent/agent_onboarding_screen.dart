import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/agent_service.dart';

class AgentOnboardingScreen extends StatefulWidget {
  const AgentOnboardingScreen({super.key});

  @override
  State<AgentOnboardingScreen> createState() => _AgentOnboardingScreenState();
}

class _AgentOnboardingScreenState extends State<AgentOnboardingScreen> {
  final _agentService = AgentService();
  final _bioController = TextEditingController();
  final _presentationController = TextEditingController();
  int _step = 0;
  bool _isLoading = false;
  int _experienceYears = 0;

  // Compétences sélectionnées
  final Set<String> _selectedCompetences = {};
  final List<String> _selectedZones = [];
  final _zoneController = TextEditingController();

  static const _competences = [
    {'value': 'courses', 'label': 'Courses', 'icon': Icons.shopping_cart_outlined},
    {'value': 'medicaments', 'label': 'Médicaments', 'icon': Icons.local_pharmacy_outlined},
    {'value': 'colis', 'label': 'Colis & Livraison', 'icon': Icons.local_shipping_outlined},
    {'value': 'accompagnement', 'label': 'Accompagnement', 'icon': Icons.people_outline},
    {'value': 'assistance', 'label': 'Aide à domicile', 'icon': Icons.home_repair_service_outlined},
    {'value': 'autre', 'label': 'Autre', 'icon': Icons.miscellaneous_services_outlined},
  ];

  Future<void> _submit() async {
    if (_selectedCompetences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins une compétence')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _agentService.saveAgentProfile(
        bio: _bioController.text.trim(),
        competences: _selectedCompetences.toList(),
        presentation: _presentationController.text.trim(),
        experienceYears: _experienceYears,
        zones: _selectedZones,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil agent soumis ! En attente de validation.'),
            backgroundColor: AppColors.success,
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

  void _addZone() {
    final zone = _zoneController.text.trim();
    if (zone.isNotEmpty && !_selectedZones.contains(zone)) {
      setState(() {
        _selectedZones.add(zone);
        _zoneController.clear();
      });
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _presentationController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devenir prestataire'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: AppColors.divider,
            color: AppColors.primary,
            minHeight: 3,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStep(),
            ),
          ),

          // Bottom buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text('Retour'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _step < 2
                              ? () => setState(() => _step++)
                              : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_step < 2 ? 'Suivant' : 'Soumettre'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildCompetencesStep();
      case 1:
        return _buildProfileStep();
      case 2:
        return _buildZonesStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCompetencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos compétences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Quels services pouvez-vous proposer ?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        ...(_competences).map((c) {
          final value = c['value'] as String;
          final selected = _selectedCompetences.contains(value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedCompetences.remove(value);
                  } else {
                    _selectedCompetences.add(value);
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.divider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(c['icon'] as IconData, color: selected ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c['label'] as String,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre profil',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Présentez-vous aux futurs clients',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _bioController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Bio courte',
            hintText: 'Ex : Agent de courses fiable et rapide',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _presentationController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Présentation',
            hintText: 'Décrivez votre expérience, vos motivations...',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Années d\'expérience',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _experienceYears > 0
                  ? () => setState(() => _experienceYears--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: AppColors.primary,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_experienceYears an${_experienceYears > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _experienceYears++),
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZonesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zones d\'intervention',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Dans quels quartiers pouvez-vous intervenir ?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _zoneController,
                decoration: const InputDecoration(
                  hintText: 'Ex : Akanda, Owendo, Centre-ville...',
                ),
                onSubmitted: (_) => _addZone(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addZone,
              icon: const Icon(Icons.add_circle),
              color: AppColors.primary,
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _selectedZones.map((zone) {
            return Chip(
              label: Text(zone),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _selectedZones.remove(zone)),
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
              side: BorderSide.none,
            );
          }).toList(),
        ),
        if (_selectedZones.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.location_on_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  const Text('Ajoutez vos zones d\'intervention', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),

        const SizedBox(height: 32),

        // Récap
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Récapitulatif', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Compétences : ${_selectedCompetences.length} sélectionnée(s)', style: const TextStyle(fontSize: 13)),
              if (_bioController.text.isNotEmpty)
                Text('Bio : ${_bioController.text}', style: const TextStyle(fontSize: 13)),
              Text('Expérience : $_experienceYears an(s)', style: const TextStyle(fontSize: 13)),
              Text('Zones : ${_selectedZones.length} zone(s)', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
