class Message {
  final String id;
  final String senderId; // UUID
  final String receiverId; // UUID
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? mediaUrl;
  final String? mediaType; // 'image', 'audio', null

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.deliveredAt,
    this.readAt,
    this.mediaUrl,
    this.mediaType,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      senderId: json['remitente_id']?.toString() ?? '',
      receiverId: json['destinatario_id']?.toString() ?? '',
      content: json['contenido'] ?? '',
      sentAt: () {
        final dateStr = json['created_at']?.toString();
        if (dateStr == null) return DateTime.now();
        // Supabase puede devolver formatos con o sin T, con o sin zona horaria
        // Si no tiene indicador de zona, asumimos UTC que es como guarda Postgres
        if (!dateStr.contains('Z') && !dateStr.contains('+') && !dateStr.contains('-')) {
          return DateTime.parse('${dateStr.replaceFirst(' ', 'T')}Z').toLocal();
        }
        return DateTime.parse(dateStr).toLocal();
      }(),
      isRead: json['leido'] == 1 || json['leido'] == true,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at']) 
          : null,
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at']) 
          : null,
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
    );
  }

  /// Get message status: 'sent', 'delivered', or 'read'
  String get status {
    if (readAt != null) return 'read';
    if (deliveredAt != null) return 'delivered';
    return 'sent';
  }
}
