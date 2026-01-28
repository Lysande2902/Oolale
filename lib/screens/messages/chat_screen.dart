import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/message.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String userId; 
  final String userName; 

  const ChatScreen({super.key, required this.userId, required this.userName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupRealtime();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupRealtime() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    _subscription = _supabase
        .from('intercom')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((List<Map<String, dynamic>> data) {
          final threadMessages = data.where((msg) => 
            (msg['remitente_id'] == myId && msg['destinatario_id'] == widget.userId) ||
            (msg['remitente_id'] == widget.userId && msg['destinatario_id'] == myId)
          ).map((m) => Message.fromJson(m)).toList();

          if (mounted) {
            setState(() {
              _messages = threadMessages;
              _isLoading = false;
            });
            _scrollToBottom();
          }
        });
  }

  Future<void> _loadMessages() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      final data = await _supabase
          .from('intercom')
          .select()
          .or('and(remitente_id.eq.$myId,destinatario_id.eq.${widget.userId}),and(remitente_id.eq.${widget.userId},destinatario_id.eq.$myId)')
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = data.map((m) => Message.fromJson(m)).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    _messageController.clear();
    try {
      await _supabase.from('intercom').insert({
        'remitente_id': myId,
        'destinatario_id': widget.userId,
        'riff_text': text, // Mantener nombre de columna por DB pero texto simple en UI
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar mensaje')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ThemeColors.icon(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
              child: Text(widget.userName.substring(0, 1).toUpperCase(), 
                  style: const TextStyle(color: AppConstants.primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Text(
              widget.userName,
              style: GoogleFonts.outfit(color: ThemeColors.primaryText(context), fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 60, color: ThemeColors.disabledText(context)),
          const SizedBox(height: 16),
          Text(
            'Inicia la conversación...',
            style: GoogleFonts.outfit(color: ThemeColors.secondaryText(context), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final myId = _supabase.auth.currentUser?.id;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg.senderId == myId;
        return _MessageBubble(message: msg, isMe: isMe);
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: ThemeColors.divider(context))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.outfit(color: ThemeColors.primaryText(context)),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: GoogleFonts.outfit(color: ThemeColors.hintText(context), fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: AppConstants.primaryColor, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppConstants.primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          border: isMe ? null : Border.all(color: ThemeColors.divider(context)),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: GoogleFonts.outfit(
                color: isMe ? Colors.black : ThemeColors.primaryText(context),
                fontSize: 15,
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.sentAt),
              style: GoogleFonts.outfit(
                color: isMe ? Colors.black.withOpacity(0.5) : ThemeColors.secondaryText(context),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
