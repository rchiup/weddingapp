/// Modelo de chat
/// 
/// Representa una conversación entre dos usuarios.
class ChatModel {
  final String id;
  final String userId1;
  final String userId2;
  final String eventId;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.eventId,
    required this.lastMessageAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  /// Crea un ChatModel desde un documento de Firestore
  factory ChatModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawLastMessageAt = data['lastMessageAt'];
    final lastMessageAt = rawLastMessageAt is DateTime
        ? rawLastMessageAt
        : (rawLastMessageAt is String ? DateTime.tryParse(rawLastMessageAt) : null) ??
            DateTime.now();

    return ChatModel(
      id: id,
      userId1: data['userId1'] ?? '',
      userId2: data['userId2'] ?? '',
      eventId: data['eventId'] ?? '',
      lastMessageAt: lastMessageAt,
      lastMessage: data['lastMessage'],
      unreadCount: data['unreadCount'] ?? 0,
    );
  }
}

/// Modelo de mensaje
/// 
/// Representa un mensaje individual dentro de un chat.
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isRead = false,
  });

  /// Crea un MessageModel desde un documento de Firestore
  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawSentAt = data['sentAt'];
    final sentAt = rawSentAt is DateTime
        ? rawSentAt
        : (rawSentAt is String ? DateTime.tryParse(rawSentAt) : null) ??
            DateTime.now();

    return MessageModel(
      id: id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      sentAt: sentAt,
      isRead: data['isRead'] ?? false,
    );
  }
}
