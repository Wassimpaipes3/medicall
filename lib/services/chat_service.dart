import 'package:flutter/foundation.dart';
import 'dart:async';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final Map<String, List<ChatMessage>> _conversations = {};
  final Map<String, int> _unreadCounts = {};

  Map<String, List<ChatMessage>> get conversations => _conversations;
  Map<String, int> get unreadCounts => _unreadCounts;

  int getTotalUnreadCount() {
    return _unreadCounts.values.fold(0, (sum, count) => sum + count);
  }

  void sendMessage(String conversationId, String content, MessageType type) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderId: 'current_user',
      senderName: 'You',
      timestamp: DateTime.now(),
      type: type,
      isFromCurrentUser: true,
    );

    _conversations.putIfAbsent(conversationId, () => []);
    _conversations[conversationId]!.add(message);
    
    notifyListeners();

    // Simulate provider response after 2-5 seconds
    _simulateProviderResponse(conversationId);
  }

  void _simulateProviderResponse(String conversationId) {
    final responses = [
      "Thank you for your message. I'll be with you shortly.",
      "I'm currently 5 minutes away from your location.",
      "Please have your ID and insurance card ready.",
      "Is this your first time using our mobile service?",
      "I'll call you once I arrive at your location.",
      "Do you have any allergies I should be aware of?",
    ];

    Timer(Duration(seconds: 2 + (DateTime.now().millisecond % 4)), () {
      final response = responses[DateTime.now().millisecond % responses.length];
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        senderId: conversationId,
        senderName: _getProviderName(conversationId),
        timestamp: DateTime.now(),
        type: MessageType.text,
        isFromCurrentUser: false,
      );

      _conversations[conversationId]!.add(message);
      _unreadCounts[conversationId] = (_unreadCounts[conversationId] ?? 0) + 1;
      notifyListeners();
    });
  }

  String _getProviderName(String providerId) {
    switch (providerId) {
      case 'dr_sarah':
        return 'Dr. Sarah Johnson';
      case 'dr_ahmed':
        return 'Dr. Ahmed Hassan';
      case 'dr_emily':
        return 'Dr. Emily Davis';
      case 'dr_michael':
        return 'Dr. Michael Chen';
      case 'dr_lisa':
        return 'Dr. Lisa Rodriguez';
      case 'dr_james':
        return 'Dr. James Wilson';
      case 'dr_anna':
        return 'Dr. Anna Thompson';
      case 'dr_david':
        return 'Dr. David Brown';
      case 'nurse_jennifer':
        return 'Nurse Jennifer Lee';
      case 'nurse_robert':
        return 'Nurse Robert Garcia';
      default:
        return 'Healthcare Provider';
    }
  }

  void markConversationAsRead(String conversationId) {
    _unreadCounts[conversationId] = 0;
    notifyListeners();
  }

  void initializeConversation(String providerId) {
    _conversations.putIfAbsent(providerId, () => []);
    
    // Add welcome message if conversation is new
    if (_conversations[providerId]!.isEmpty) {
      final welcomeMessage = ChatMessage(
        id: 'welcome_${providerId}',
        content: "Hello! I'm ${_getProviderName(providerId)}. I'll be providing your healthcare service today. Feel free to message me if you have any questions.",
        senderId: providerId,
        senderName: _getProviderName(providerId),
        timestamp: DateTime.now(),
        type: MessageType.text,
        isFromCurrentUser: false,
      );
      
      _conversations[providerId]!.add(welcomeMessage);
      _unreadCounts[providerId] = 1;
      notifyListeners();
    }
  }

  List<ChatMessage> getConversationMessages(String conversationId) {
    return _conversations[conversationId] ?? [];
  }

  void sendLocationMessage(String conversationId, double latitude, double longitude, String address) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: address,
      senderId: 'current_user',
      senderName: 'You',
      timestamp: DateTime.now(),
      type: MessageType.location,
      isFromCurrentUser: true,
      metadata: {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );

    _conversations.putIfAbsent(conversationId, () => []);
    _conversations[conversationId]!.add(message);
    notifyListeners();

    _simulateProviderResponse(conversationId);
  }

  void sendImageMessage(String conversationId, String imagePath) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Photo shared',
      senderId: 'current_user',
      senderName: 'You',
      timestamp: DateTime.now(),
      type: MessageType.image,
      isFromCurrentUser: true,
      imageUrl: imagePath,
    );

    _conversations.putIfAbsent(conversationId, () => []);
    _conversations[conversationId]!.add(message);
    notifyListeners();

    _simulateProviderResponse(conversationId);
  }

  void sendSystemMessage(String conversationId, String content) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      senderId: 'system',
      senderName: 'System',
      timestamp: DateTime.now(),
      type: MessageType.system,
      isFromCurrentUser: false,
    );

    _conversations.putIfAbsent(conversationId, () => []);
    _conversations[conversationId]!.add(message);
    notifyListeners();
  }
}

enum MessageType {
  text,
  image,
  location,
  file,
  system,
}

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final MessageType type;
  final bool isFromCurrentUser;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.type,
    required this.isFromCurrentUser,
    this.imageUrl,
    this.metadata,
  });
}
