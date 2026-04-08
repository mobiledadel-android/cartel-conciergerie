import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/mission_service.dart';
import '../../services/auth_service.dart';
import '../chat/chat_screen.dart';

class MissionDetailScreen extends StatefulWidget {
  final String missionId;

  const MissionDetailScreen({super.key, required this.missionId});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final _missionService = MissionService();
  final _authService = AuthService();
  Map<String, dynamic>? _mission;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mission = await _missionService.getMission(widget.missionId);
    final profile = await _authService.getProfile();
    if (mounted) {
      setState(() {
        _mission = mission;
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  bool get _isClient => _profile?['id'] == _mission?['client_id'];
  bool get _isPrestataire => _profile?['id'] == _mission?['prestataire_id'];

  Future<void> _updateStatus(String action) async {
    setState(() => _isLoading = true);
    try {
      switch (action) {
        case 'accept':
          await _missionService.acceptMission(widget.missionId);
          break;
        case 'start':
          await _missionService.startMission(widget.missionId);
          break;
        case 'complete':
          await _missionService.completeMission(widget.missionId);
          break;
        case 'cancel':
          await _missionService.cancelMission(widget.missionId);
          break;
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final mission = _mission!;
    final service = mission['services'] as Map<String, dynamic>?;
    final status = mission['status'] as String;
    final client = mission['client'] as Map<String, dynamic>?;
    final prestataire = mission['prestataire'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(service?['name'] ?? 'Mission'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (mission['prestataire_id'] != null)
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(missionId: widget.missionId),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut
            _StatusBanner(status: status),
            const SizedBox(height: 20),

            // Détails
            _DetailCard(
              title: 'Demande',
              children: [
                _DetailRow(
                  icon: Icons.description_outlined,
                  label: 'Description',
                  value: mission['description'] ?? '',
                ),
                if (mission['address_pickup'] != null)
                  _DetailRow(
                    icon: Icons.store_outlined,
                    label: 'Retrait',
                    value: mission['address_pickup'],
                  ),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Livraison',
                  value: mission['address_delivery'] ?? '',
                ),
                if (mission['notes'] != null)
                  _DetailRow(
                    icon: Icons.note_outlined,
                    label: 'Notes',
                    value: mission['notes'],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Prix
            _DetailCard(
              title: 'Paiement',
              children: [
                _DetailRow(
                  icon: Icons.payment_outlined,
                  label: 'Prix',
                  value: AppConstants.formatPrice(mission['total_price'] ?? service?['base_price']),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Client ou Prestataire info
            if (_isClient && prestataire != null)
              _DetailCard(
                title: 'Votre prestataire',
                children: [
                  _DetailRow(
                    icon: Icons.person_outlined,
                    label: 'Nom',
                    value: '${prestataire['first_name']} ${prestataire['last_name']}',
                  ),
                ],
              ),

            if (_isPrestataire && client != null)
              _DetailCard(
                title: 'Client',
                children: [
                  _DetailRow(
                    icon: Icons.person_outlined,
                    label: 'Nom',
                    value: '${client['first_name']} ${client['last_name']}',
                  ),
                ],
              ),

            if (status == 'pending' && prestataire == null && !_isClient)
              _DetailCard(
                title: 'Client',
                children: [
                  _DetailRow(
                    icon: Icons.person_outlined,
                    label: 'Nom',
                    value: '${client?['first_name']} ${client?['last_name']}',
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Actions selon le rôle et le statut
            ..._buildActions(status),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(String status) {
    final actions = <Widget>[];

    // Prestataire : accepter une mission pending
    if (!_isClient && !_isPrestataire && status == 'pending') {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => _updateStatus('accept'),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Accepter la mission'),
        ),
      );
    }

    // Prestataire : démarrer une mission acceptée
    if (_isPrestataire && status == 'accepted') {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => _updateStatus('start'),
          icon: const Icon(Icons.play_arrow_outlined),
          label: const Text('Démarrer la mission'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
          ),
        ),
      );
    }

    // Prestataire : terminer une mission en cours
    if (_isPrestataire && status == 'in_progress') {
      actions.add(
        ElevatedButton.icon(
          onPressed: () => _updateStatus('complete'),
          icon: const Icon(Icons.check_outlined),
          label: const Text('Mission terminée'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
          ),
        ),
      );
    }

    // Client : annuler si pending ou accepted
    if (_isClient && (status == 'pending' || status == 'accepted')) {
      if (actions.isNotEmpty) actions.add(const SizedBox(height: 12));
      actions.add(
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Annuler la mission ?'),
                content: const Text('Cette action est irréversible.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Non'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Oui, annuler',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
            if (confirm == true) _updateStatus('cancel');
          },
          icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
          label: const Text('Annuler la mission',
              style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
          ),
        ),
      );
    }

    return actions;
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color),
          const SizedBox(width: 10),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return _StatusConfig('En attente d\'un prestataire', Icons.hourglass_empty, AppColors.warning);
      case 'accepted':
        return _StatusConfig('Prestataire assigné', Icons.person_pin, AppColors.primary);
      case 'in_progress':
        return _StatusConfig('Mission en cours', Icons.directions_run, AppColors.primary);
      case 'completed':
        return _StatusConfig('Mission terminée', Icons.check_circle, AppColors.success);
      case 'cancelled':
        return _StatusConfig('Mission annulée', Icons.cancel, AppColors.error);
      default:
        return _StatusConfig(status, Icons.info, AppColors.textSecondary);
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;
  _StatusConfig(this.label, this.icon, this.color);
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
