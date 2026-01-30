import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/message.dart';
import '../../config/constants.dart';
import '../../config/theme_colors.dart';
import '../../services/realtime_service.dart';
import '../../services/media_service.dart';
import '../../widgets/media_message_bubble.dart';
import '../../widgets/image_viewer.dart';
import '../../widgets/audio_player_widget.dart';
import 'package:intl/intl.dart';
import '../reports/report_content_screen.dart';

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
  
  late RealtimeService _realtimeService;
  late MediaService _mediaService;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isConnected = false;
  bool _checkingConnection = true;
  bool _otherUserTyping = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Timer? _typingTimer;
  StreamSubscription? _typingSubscription;

  @override
  void initState() {
    super.initState();
    _realtimeService = RealtimeService(_supabase);
    _mediaService = MediaService(_supabase);
    _checkConnection();
    
    // Listen for typing changes
    _messageController.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTypingChanged() {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    final isTyping = _messageController.text.isNotEmpty;
    final conversationId = _getConversationId(myId, widget.userId);
    
    // Send typing indicator
    _realtimeService.sendTypingIndicator(conversationId, isTyping);
  }

  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> _checkConnection() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) {
      if (mounted) setState(() => _checkingConnection = false);
      return;
    }

    try {
      // Check if user is blocked
      final blockData = await _supabase
          .from('usuarios_bloqueados')
          .select()
          .or('and(usuario_id.eq.$myId,bloqueado_id.eq.${widget.userId}),and(usuario_id.eq.${widget.userId},bloqueado_id.eq.$myId)')
          .eq('activo', true)
          .maybeSingle();

      if (blockData != null) {
        if (mounted) {
          setState(() {
            _isConnected = false;
            _checkingConnection = false;
          });
        }
        return;
      }

      // Check if there's an accepted connection
      final connectionData = await _supabase
          .from('connections')
          .select()
          .or('and(usuario_id.eq.$myId,conectado_id.eq.${widget.userId}),and(usuario_id.eq.${widget.userId},conectado_id.eq.$myId)')
          .eq('estatus', 'accepted')
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isConnected = connectionData != null;
          _checkingConnection = false;
        });

        if (_isConnected) {
          await _loadMessages();
          await _setupRealtime();
          await _markAllAsRead();
        }
      }
    } catch (e) {
      debugPrint('Error checking connection: $e');
      if (mounted) {
        setState(() {
          _isConnected = false;
          _checkingConnection = false;
        });
      }
    }
  }

  Future<void> _setupRealtime() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    // Subscribe to conversation messages
    await _realtimeService.subscribeToConversation(
      myId,
      widget.userId,
      (newMessage) {
        final message = Message.fromJson(newMessage);
        if (mounted) {
          setState(() {
            // Check if message already exists
            final exists = _messages.any((m) => m.id == message.id);
            if (!exists) {
              _messages.add(message);
              _scrollToBottom();
            }
          });

          // Mark as read if from other user
          if (message.senderId == widget.userId) {
            _realtimeService.markMessageAsRead(message.id.toString());
          }
        }
      },
    );

    // Listen for typing indicators
    final conversationId = _getConversationId(myId, widget.userId);
    _typingSubscription = _realtimeService
        .listenTypingIndicators(conversationId)
        .listen((event) {
      if (mounted) {
        setState(() {
          _otherUserTyping = event.isTyping;
        });

        // Auto-hide typing indicator after 3 seconds
        if (event.isTyping) {
          _typingTimer?.cancel();
          _typingTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _otherUserTyping = false;
              });
            }
          });
        }
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
      debugPrint('Error loading messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    await _realtimeService.markAllMessagesAsRead(myId, widget.userId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    _messageController.clear();
    
    try {
      // Insert message
      await _supabase.from('intercom').insert({
        'remitente_id': myId,
        'destinatario_id': widget.userId,
        'riff_text': text,
        'delivered_at': DateTime.now().toIso8601String(),
      });

      // Create notification
      try {
        final myProfile = await _supabase
            .from('profiles')
            .select('nombre_artistico')
            .eq('id', myId)
            .single();

        await _supabase.from('notifications').insert({
          'user_id': widget.userId,
          'tipo': 'new_message',
          'titulo': 'Nuevo mensaje',
          'mensaje': '${myProfile['nombre_artistico']} te envió un mensaje',
          'leido': false,
          'data': {'sender_id': myId, 'conversation_id': widget.userId},
        });
      } catch (notifError) {
        debugPrint('Error creating notification: $notifError');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar mensaje')),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload image
      final imageFile = File(image.path);
      final imageUrl = await _mediaService.uploadImage(imageFile, myId);

      setState(() {
        _uploadProgress = 0.5;
      });

      // Send message with image
      final text = _messageController.text.trim();
      _messageController.clear();

      await _supabase.from('intercom').insert({
        'remitente_id': myId,
        'destinatario_id': widget.userId,
        'riff_text': text,
        'media_url': imageUrl,
        'media_type': 'image',
        'delivered_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      // Create notification
      try {
        final myProfile = await _supabase
            .from('profiles')
            .select('nombre_artistico')
            .eq('id', myId)
            .single();

        await _supabase.from('notifications').insert({
          'user_id': widget.userId,
          'tipo': 'new_message',
          'titulo': 'Nuevo mensaje',
          'mensaje': '${myProfile['nombre_artistico']} te envió una imagen',
          'leido': false,
          'data': {'sender_id': myId, 'conversation_id': widget.userId},
        });
      } catch (notifError) {
        debugPrint('Error creating notification: $notifError');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar imagen: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickAndSendAudio() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) return;

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload audio
      final audioFile = File(result.files.first.path!);
      
      // Validate file size
      if (!_mediaService.validateFileSize(audioFile, 10)) {
        throw Exception('El archivo de audio no debe superar 10MB');
      }

      final audioUrl = await _mediaService.uploadAudio(audioFile, myId);

      setState(() {
        _uploadProgress = 0.5;
      });

      // Send message with audio
      final text = _messageController.text.trim();
      _messageController.clear();

      await _supabase.from('intercom').insert({
        'remitente_id': myId,
        'destinatario_id': widget.userId,
        'riff_text': text,
        'media_url': audioUrl,
        'media_type': 'audio',
        'delivered_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      // Create notification
      try {
        final myProfile = await _supabase
            .from('profiles')
            .select('nombre_artistico')
            .eq('id', myId)
            .single();

        await _supabase.from('notifications').insert({
          'user_id': widget.userId,
          'tipo': 'new_message',
          'titulo': 'Nuevo mensaje',
          'mensaje': '${myProfile['nombre_artistico']} te envió un audio',
          'leido': false,
          'data': {'sender_id': myId, 'conversation_id': widget.userId},
        });
      } catch (notifError) {
        debugPrint('Error creating notification: $notifError');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar audio: ${e.toString()}')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_checkingConnection) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: ThemeColors.icon(context)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.userName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
      );
    }

    if (!_isConnected) {
      return _buildNotConnectedScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          if (_otherUserTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildNotConnectedScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ThemeColors.icon(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.userName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: ThemeColors.iconSecondary(context),
              ),
              const SizedBox(height: 24),
              Text(
                'No puedes enviar mensajes',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.primaryText(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Debes estar conectado con ${widget.userName} para poder enviar mensajes.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: ThemeColors.secondaryText(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text('Volver', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
            child: Text(
              widget.userName.substring(0, 1).toUpperCase(), 
              style: const TextStyle(
                color: AppConstants.primaryColor, 
                fontSize: 14, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.userName,
            style: GoogleFonts.outfit(
              color: ThemeColors.primaryText(context), 
              fontWeight: FontWeight.bold, 
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: ThemeColors.icon(context)),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'report') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportContentScreen(
                    contentType: 'message',
                    contentId: widget.userId,
                    contentTitle: 'Conversación con ${widget.userName}',
                  ),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Text('Reportar conversación', style: GoogleFonts.outfit(color: Colors.orange)),
                ],
              ),
            ),
          ],
        ),
      ],
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

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            '${widget.userName} está escribiendo',
            style: GoogleFonts.outfit(
              color: ThemeColors.secondaryText(context),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                ThemeColors.secondaryText(context),
              ),
            ),
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
        
        // Use media bubble if message has media
        if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) {
          return MediaMessageBubble(
            message: msg,
            isMe: isMe,
            onImageTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewer(
                    imageUrl: msg.mediaUrl!,
                    caption: msg.content,
                  ),
                ),
              );
            },
            onAudioTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AudioPlayerWidget(audioUrl: msg.mediaUrl!),
                ),
              );
            },
          );
        }
        
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
        child: Column(
          children: [
            // Upload progress indicator
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: ThemeColors.divider(context),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subiendo archivo...',
                      style: GoogleFonts.outfit(
                        color: ThemeColors.secondaryText(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Input row
            Row(
              children: [
                // Image button
                IconButton(
                  icon: Icon(Icons.image, color: ThemeColors.icon(context)),
                  onPressed: _isUploading ? null : _pickAndSendImage,
                ),
                
                // Audio button
                IconButton(
                  icon: Icon(Icons.mic, color: ThemeColors.icon(context)),
                  onPressed: _isUploading ? null : _pickAndSendAudio,
                ),
                
                const SizedBox(width: 8),
                
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isUploading,
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
                
                // Send button
                GestureDetector(
                  onTap: _isUploading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isUploading 
                          ? AppConstants.primaryColor.withOpacity(0.5)
                          : AppConstants.primaryColor, 
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.black, size: 20),
                  ),
                ),
              ],
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.sentAt),
                  style: GoogleFonts.outfit(
                    color: isMe ? Colors.black.withOpacity(0.5) : ThemeColors.secondaryText(context),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(context),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (message.status) {
      case 'read':
        return const Icon(
          Icons.done_all,
          size: 14,
          color: AppConstants.primaryColor,
        );
      case 'delivered':
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.black.withOpacity(0.5),
        );
      case 'sent':
      default:
        return Icon(
          Icons.done,
          size: 14,
          color: Colors.black.withOpacity(0.5),
        );
    }
  }
}
