class Message {
  final int id;
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
      id: json['id'] ?? 0,
      senderId: json['remitente_id']?.toString() ?? '',
      receiverId: json['destinatario_id']?.toString() ?? '',
      content: json['riff_text'] ?? '',
      sentAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
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
