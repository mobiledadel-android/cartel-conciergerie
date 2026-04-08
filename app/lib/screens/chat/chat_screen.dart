import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String missionId;

  const ChatScreen({super.key, required this.missionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _authService = AuthService();
  final _supabase = SupabaseConfig.client;

  List<Map<String, dynamic>> _messages = [];
  String? _myProfileId;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final profile = await _authService.getProfile();
    if (profile == null || !mounted) return;

    setState(() => _myProfileId = profile['id']);

    // Charger les messages existants
    final data = await _supabase
        .from('messages')
        .select('*, sender:sender_id(first_name, last_name)')
        .eq('mission_id', widget.missionId)
        .order('created_at');
    if (mounted) {
      setState(() => _messages = List<Map<String, dynamic>>.from(data));
      _scrollToBottom();
    }

    // Écouter les nouveaux messages en temps réel
    _subscription = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('mission_id', widget.missionId)
        .order('created_at')
        .listen((data) async {
      if (!mounted) return;
      // Recharger avec les infos sender
      final enriched = await _supabase
          .from('messages')
          .select('*, sender:sender_id(first_name, last_name)')
          .eq('mission_id', widget.missionId)
          .order('created_at');
      if (mounted) {
        setState(() => _messages = List<Map<String, dynamic>>.from(enriched));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _myProfileId == null) return;

    _messageController.clear();

    await _supabase.from('messages').insert({
      'mission_id': widget.missionId,
      'sender_id': _myProfileId,
      'content': text,
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun message',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender_id'] == _myProfileId;
                      final sender = msg['sender'] as Map<String, dynamic>?;
                      final senderName = sender != null
                          ? '${sender['first_name']}'
                          : '';

                      return _MessageBubble(
                        content: msg['content'] ?? '',
                        senderName: senderName,
                        isMe: isMe,
                        time: msg['created_at'] ?? '',
                      );
                    },
                  ),
          ),

          // Champ de saisie
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Votre message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
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
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final String senderName;
  final bool isMe;
  final String time;

  const _MessageBubble({
    required this.content,
    required this.senderName,
    required this.isMe,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: AppColors.divider),
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
