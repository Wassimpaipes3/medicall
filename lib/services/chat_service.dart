import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final Map<String, List<ChatMessage>> _conversations = {};
  final Map<String, int> _unreadCounts = {};
  final Map<String, StreamSubscription> _messageSubscriptions = {};

  Map<String, List<ChatMessage>> get conversations => _conversations;
  Map<String, int> get unreadCounts => _unreadCounts;

  int getTotalUnreadCount() {
    return _unreadCounts.values.fold(0, (total, unread) => total + unread);
  }

  String get currentUserId => _auth.currentUser?.uid ?? 'anonymous';

  Future<void> sendMessage(String conversationId, String content, MessageType type) async {
    try {
      // 1. Verify user is authenticated
      if (currentUserId == 'anonymous' || currentUserId.isEmpty) {
        debugPrint('❌ Cannot send message: User not authenticated');
        debugPrint('   Current user ID: $currentUserId');
        debugPrint('   Firebase Auth user: ${_auth.currentUser?.uid}');
        return;
      }

      final chatId = _getChatId(conversationId);
      debugPrint('📤 Sending message to chat: $chatId');
      debugPrint('   From: $currentUserId');
      debugPrint('   To: $conversationId');
      
      // 2. Ensure chat document exists first with correct participants
      await _ensureChatExists(conversationId);
      
      final chatRef = _firestore.collection('chats').doc(chatId);
      
      // 3. Create message in Firestore
      debugPrint('   Adding message to Firestore...');
      debugPrint('   Path: /chats/$chatId/messages/');
      debugPrint('   Data: {senderId: $currentUserId, text: $content, ...}');
      
      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': content,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
        'type': type.toString().split('.').last,
      });

      debugPrint('   ✅ Message document created: ${messageRef.id}');

      // 4. Update chat document with last message
      debugPrint('   Updating chat document...');
      await chatRef.update({
        'lastMessage': content,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
      });

      debugPrint('✅ Message sent successfully (ID: ${messageRef.id})');
      debugPrint('   🔥 Check Firestore: /chats/$chatId');

      // 5. Add to local cache immediately for UI responsiveness
      final message = ChatMessage(
        id: messageRef.id,
        content: content,
        senderId: currentUserId,
        senderName: 'You',
        timestamp: DateTime.now(),
        type: type,
        isFromCurrentUser: true,
      );

      _conversations.putIfAbsent(conversationId, () => []);
      _conversations[conversationId]!.add(message);
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      debugPrint('   Current user: $currentUserId');
      debugPrint('   Conversation ID: $conversationId');
      debugPrint('   Auth status: ${_auth.currentUser != null ? "Authenticated" : "Not authenticated"}');
    }
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

  Future<void> markConversationAsRead(String conversationId) async {
    try {
      debugPrint('🔵 Starting markConversationAsRead for: $conversationId');
      debugPrint('   Current user: $currentUserId');
      
      if (currentUserId.isEmpty || currentUserId == 'anonymous') {
        debugPrint('❌ Cannot mark as read: User not authenticated');
        return;
      }

      final chatId = _getChatId(conversationId);
      debugPrint('   Chat ID: $chatId');
      
      // First check if the chat document exists
      final chatDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        debugPrint('⚠️ Chat document does not exist yet, nothing to mark as read');
        return;
      }

      debugPrint('✅ Chat document exists');
      
      // Verify user is a participant
      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
      debugPrint('   Participants: $participants');
      
      if (!participants.contains(currentUserId)) {
        debugPrint('❌ User is not a participant in this chat');
        debugPrint('   User $currentUserId not in $participants');
        return;
      }
      
      debugPrint('✅ User is a participant');
      
      // Mark all messages as seen in Firestore
      // Only update messages sent by the other user (not our own messages)
      debugPrint('   Querying unread messages from $conversationId...');
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('seen', isEqualTo: false)
          .where('senderId', isEqualTo: conversationId)
          .get();

      debugPrint('   Found ${messagesSnapshot.docs.length} unread messages');

      if (messagesSnapshot.docs.isEmpty) {
        debugPrint('✅ No unread messages to mark as read');
        _unreadCounts[conversationId] = 0;
        notifyListeners();
        return;
      }

      debugPrint('📝 Attempting to mark ${messagesSnapshot.docs.length} messages as read...');

      // Use batch to update multiple messages at once
      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        debugPrint('   Adding to batch: ${doc.id}');
        batch.update(doc.reference, {'seen': true});
      }
      
      try {
        debugPrint('   Committing batch update...');
        await batch.commit();
        debugPrint('✅ Successfully marked ${messagesSnapshot.docs.length} messages as read');
        _unreadCounts[conversationId] = 0;
        notifyListeners();
      } catch (batchError) {
        // If batch fails, try updating one by one (slower but more reliable)
        debugPrint('⚠️ Batch update failed: $batchError');
        debugPrint('   Trying individual updates...');
        int successCount = 0;
        for (var doc in messagesSnapshot.docs) {
          try {
            debugPrint('   Updating message ${doc.id}...');
            await doc.reference.update({'seen': true});
            successCount++;
            debugPrint('   ✅ Success');
          } catch (individualError) {
            debugPrint('   ❌ Failed to update message ${doc.id}: $individualError');
          }
        }
        if (successCount > 0) {
          debugPrint('✅ Successfully marked $successCount/${messagesSnapshot.docs.length} messages as read');
          _unreadCounts[conversationId] = 0;
          notifyListeners();
        } else {
          debugPrint('❌ Failed to mark any messages as read');
        }
      }
    } catch (e) {
      debugPrint('❌ Error marking conversation as read: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      // Don't throw the error, just log it so the app continues working
    }
  }

  void initializeConversation(String providerId) {
    debugPrint('🚀 Initializing conversation with: $providerId');
    debugPrint('   Current user: $currentUserId');
    
    // Check if user is authenticated
    if (currentUserId == 'anonymous' || currentUserId.isEmpty) {
      debugPrint('❌ Cannot initialize conversation: User not authenticated');
      return;
    }
    
    _conversations.putIfAbsent(providerId, () => []);
    
    // Listen to real-time messages
    _listenToMessages(providerId);
  }

  List<ChatMessage> getConversationMessages(String conversationId) {
    return _conversations[conversationId] ?? [];
  }

  Future<void> sendLocationMessage(String conversationId, double latitude, double longitude, String address) async {
    try {
      // Ensure chat exists with correct participants
      await _ensureChatExists(conversationId);
      
      final chatId = _getChatId(conversationId);
      
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': address,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
        'type': 'location',
        'metadata': {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      });

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '📍 Location shared',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
      });
    } catch (e) {
      debugPrint('Error sending location: $e');
    }
  }

  Future<void> sendImageMessage(String conversationId, String imagePath) async {
    try {
      // Ensure chat exists with correct participants
      await _ensureChatExists(conversationId);
      
      final chatId = _getChatId(conversationId);
      
      // TODO: Upload image to Firebase Storage and get URL
      // For now, just send the local path
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'text': 'Photo shared',
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
        'type': 'image',
        'imageUrl': imagePath,
      });

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '📷 Photo',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
      });
    } catch (e) {
      debugPrint('Error sending image: $e');
    }
  }

  Future<void> sendSystemMessage(String conversationId, String content) async {
    try {
      // Ensure chat exists with correct participants
      await _ensureChatExists(conversationId);
      
      final chatId = _getChatId(conversationId);
      
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'text': content,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': true,
        'type': 'system',
      });
    } catch (e) {
      debugPrint('Error sending system message: $e');
    }
  }

  // Helper method to generate consistent chat IDs
  String _getChatId(String otherUserId) {
    final ids = [currentUserId, otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Helper method to ensure chat document exists with correct participants
  // This ALWAYS creates or updates the chat with the correct participants array
  Future<void> _ensureChatExists(String conversationId) async {
    if (currentUserId.isEmpty || currentUserId == 'anonymous') {
      debugPrint('❌ Cannot ensure chat exists: User not authenticated');
      return;
    }

    final chatId = _getChatId(conversationId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    
    try {
      final chatDoc = await chatRef.get();
      
      if (!chatDoc.exists) {
        // Chat doesn't exist - create it with participants
        debugPrint('📝 Creating new chat document with participants: [$currentUserId, $conversationId]');
        await chatRef.set({
          'participants': [currentUserId, conversationId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastTimestamp': FieldValue.serverTimestamp(),
          'lastSenderId': '',
        });
        debugPrint('✅ Chat document created successfully');
      } else {
        // Chat exists - verify participants array is correct
        final data = chatDoc.data();
        final existingParticipants = List<String>.from(data?['participants'] ?? []);
        
        // Check if both users are in participants
        final shouldHaveParticipants = [currentUserId, conversationId];
        final needsUpdate = !existingParticipants.contains(currentUserId) || 
                           !existingParticipants.contains(conversationId) ||
                           existingParticipants.length != 2;
        
        if (needsUpdate) {
          debugPrint('⚠️ Chat exists but participants are incorrect');
          debugPrint('   Current: $existingParticipants');
          debugPrint('   Expected: $shouldHaveParticipants');
          debugPrint('   Fixing participants array...');
          
          await chatRef.update({
            'participants': shouldHaveParticipants,
          });
          debugPrint('✅ Participants array fixed');
        } else {
          debugPrint('✅ Chat exists with correct participants: $existingParticipants');
        }
      }
    } catch (e) {
      debugPrint('❌ Error ensuring chat exists: $e');
      rethrow;
    }
  }

  // Listen to real-time messages from Firestore
  void _listenToMessages(String conversationId) {
    // 1. Check if user is authenticated
    if (currentUserId == 'anonymous' || currentUserId.isEmpty) {
      debugPrint('❌ Cannot listen to messages: User not authenticated');
      return;
    }

    final chatId = _getChatId(conversationId);
    debugPrint('🔔 Setting up message listener for chat: $chatId');
    
    // Cancel existing subscription if any
    _messageSubscriptions[conversationId]?.cancel();
    
    // 2. First check if chat exists and user is a participant
    _firestore
        .collection('chats')
        .doc(chatId)
        .get()
        .then((chatDoc) {
      if (!chatDoc.exists) {
        debugPrint('⚠️ Chat document does not exist yet, will listen after first message');
        // Initialize empty conversation
        _conversations[conversationId] = [];
        _unreadCounts[conversationId] = 0;
        notifyListeners();
        return;
      }

      final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
      if (!participants.contains(currentUserId)) {
        debugPrint('❌ User is not a participant in chat $chatId');
        return;
      }

      debugPrint('✅ User is participant, starting message listener...');

      // 3. Set up the message listener
      _messageSubscriptions[conversationId] = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .listen((snapshot) {
        final messages = <ChatMessage>[];
        int unreadCount = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final senderId = data['senderId'] as String;
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final typeString = data['type'] as String? ?? 'text';
          final seen = data['seen'] as bool? ?? false;

          // Count unread messages from other user
          if (!seen && senderId != currentUserId) {
            unreadCount++;
          }

          messages.add(ChatMessage(
            id: doc.id,
            content: data['text'] as String? ?? '',
            senderId: senderId,
            senderName: senderId == currentUserId ? 'You' : _getProviderName(conversationId),
            timestamp: timestamp,
            type: _parseMessageType(typeString),
            isFromCurrentUser: senderId == currentUserId,
            imageUrl: data['imageUrl'] as String?,
            metadata: data['metadata'] as Map<String, dynamic>?,
          ));
        }

        _conversations[conversationId] = messages;
        _unreadCounts[conversationId] = unreadCount;
        notifyListeners();
      }, onError: (error) {
        debugPrint('❌ Error listening to messages for chat $chatId: $error');
        // If permission error, stop trying to listen
        if (error.toString().contains('permission-denied')) {
          debugPrint('⚠️ Permission denied - stopping message listener');
          _messageSubscriptions[conversationId]?.cancel();
        }
      });
    }).catchError((error) {
      debugPrint('❌ Error checking chat document: $error');
    });
  }

  MessageType _parseMessageType(String typeString) {
    switch (typeString) {
      case 'image':
        return MessageType.image;
      case 'location':
        return MessageType.location;
      case 'file':
        return MessageType.file;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  // Clean up subscriptions
  void disposeConversation(String conversationId) {
    _messageSubscriptions[conversationId]?.cancel();
    _messageSubscriptions.remove(conversationId);
  }

  @override
  void dispose() {
    for (var subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
    super.dispose();
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
