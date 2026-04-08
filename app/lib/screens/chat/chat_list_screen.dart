import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _authService = AuthService();
  final _supabase = SupabaseConfig.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _authService.getProfile();
      if (profile == null) return;

      final profileId = profile['id'];

      // Récupérer les missions où l'utilisateur est impliqué et qui ont un prestataire
      final missions = await _supabase
          .from('missions')
          .select(
              '*, services(name), client:client_id(first_name, last_name), prestataire:prestataire_id(first_name, last_name)')
          .or('client_id.eq.$profileId,prestataire_id.eq.$profileId')
          .not('prestataire_id', 'is', null)
          .order('updated_at', ascending: false);

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(missions);
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
        onRefresh: _loadConversations,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _conversations.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 64,
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Aucune conversation',
                                        style: TextStyle(
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
                            itemCount: _conversations.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final conv = _conversations[index];
                              final service =
                                  conv['services'] as Map<String, dynamic>?;
                              final client =
                                  conv['client'] as Map<String, dynamic>?;
                              final prestataire =
                                  conv['prestataire'] as Map<String, dynamic>?;

                              // Afficher l'autre personne
                              final isClient = conv['client_id'] ==
                                  _conversations.first['client_id'];
                              final otherPerson =
                                  isClient ? prestataire : client;
                              final otherName = otherPerson != null
                                  ? '${otherPerson['first_name']} ${otherPerson['last_name']}'
                                  : 'Inconnu';

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    otherName.isNotEmpty
                                        ? otherName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  otherName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  service?['name'] ?? 'Mission',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreen(missionId: conv['id']),
                                    ),
                                  );
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
