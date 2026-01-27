class Message {
  final int id;
  final String senderId; // UUID
  final String receiverId; // UUID
  final String content;
  final DateTime sentAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      senderId: json['remitente_id']?.toString() ?? '',
      receiverId: json['destinatario_id']?.toString() ?? '',
      content: json['riff_text'] ?? '',
      sentAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['leido'] == 1 || json['leido'] == true,
    );
  }
}
