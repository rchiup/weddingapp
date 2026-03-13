import 'package:flutter/foundation.dart';

import '../models/chat_model.dart';
import '../services/chat_service.dart';

/// Provider para gestión de estado de chat
/// 
/// Maneja la lista de conversaciones, mensajes en tiempo real,
/// y estado de lectura de mensajes.
class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  List<ChatModel> _conversations = [];
  Map<String, List<MessageModel>> _messages = {};
  bool _isLoading = false;

  List<ChatModel> get conversations => _conversations;
  bool get isLoading => _isLoading;

  /// Obtiene la lista de mensajes de una conversación
  List<MessageModel> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  /// Carga las conversaciones del usuario
  Future<void> loadConversations(String userId) async {
    _setLoading(true);
    
    try {
      // TODO: Cargar conversaciones desde ChatService
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
    }
  }

  /// Carga los mensajes de una conversación
  Future<void> loadMessages(String chatId) async {
    try {
      // TODO: Cargar mensajes desde ChatService
      // TODO: Escuchar nuevos mensajes en tiempo real
      notifyListeners();
    } catch (e) {
      // TODO: Manejar error
    }
  }

  /// Envía un mensaje
  Future<void> sendMessage(String chatId, String text) async {
    try {
      // TODO: Enviar mensaje con ChatService
      notifyListeners();
    } catch (e) {
      // TODO: Manejar error
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
