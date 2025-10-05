# 💬 Chat System Documentation

## ✅ Complete Firebase Firestore Chat Implementation

A production-ready chat system built with Flutter and Firebase Firestore, featuring real-time messaging, read receipts, and chat management.

---

## 📋 Table of Contents

1. [Firestore Schema](#firestore-schema)
2. [Features](#features)
3. [Core Functions](#core-functions)
4. [Models](#models)
5. [Usage Examples](#usage-examples)
6. [UI Screens](#ui-screens)
7. [Testing](#testing)
8. [Firestore Security Rules](#firestore-security-rules)

---

## 🗄️ Firestore Schema

### Collection: `chats`

```typescript
{
  participants: string[],        // [patientId, providerId]
  lastMessage: string,           // Last text sent in this chat
  lastTimestamp: Timestamp,      // Last message time
  unreadCount: number,           // Optional: Count of unread messages
  createdAt: Timestamp           // Chat creation time
}
```

### Subcollection: `chats/{chatId}/messages`

```typescript
{
  senderId: string,              // User who sent the message
  text: string,                  // Message content
  timestamp: Timestamp,          // When message was sent
  seen: boolean                  // Whether recipient has seen it
}
```

---

## ✨ Features

### Core Features
✅ Real-time messaging with StreamBuilder  
✅ Read receipts (single check / double check)  
✅ Message ordering by timestamp  
✅ Chat list ordered by last message time  
✅ Mark messages as seen automatically  
✅ Get or create chat between two users  
✅ Unread message count  
✅ Date separators in conversations  
✅ Auto-scroll to latest message  

### UI Features
✅ Material 3 design  
✅ WhatsApp-style message bubbles  
✅ Empty states  
✅ Error handling  
✅ Loading states  
✅ Time formatting (HH:mm)  
✅ Date formatting (Today, Yesterday, MMM dd, yyyy)  

---

## 🔧 Core Functions

### 1. **sendMessage()**

Send a message in a chat and update the parent chat document.

```dart
Future<String> ChatService.sendMessage({
  required String chatId,
  required String senderId,
  required String text,
});
```

**What it does:**
1. Validates input parameters
2. Creates message document in `chats/{chatId}/messages`
3. Updates parent chat with `lastMessage` and `lastTimestamp`
4. Returns the message ID

**Example:**
```dart
try {
  final messageId = await ChatService.sendMessage(
    chatId: 'chat_123',
    senderId: 'user_456',
    text: 'Hello, how can I help you?',
  );
  print('Message sent: $messageId');
} catch (e) {
  print('Error: $e');
}
```

**Error Handling:**
- Throws `ArgumentError` if parameters are empty
- Throws `Exception` on Firebase errors

---

### 2. **listenForMessages()**

Listen to messages in real-time, ordered by timestamp (oldest first).

```dart
Stream<List<ChatMessage>> ChatService.listenForMessages(String chatId);
```

**What it does:**
1. Returns a Stream of message lists
2. Orders messages by timestamp (ascending)
3. Automatically updates when new messages arrive
4. Handles parsing errors gracefully

**Example:**
```dart
StreamBuilder<List<ChatMessage>>(
  stream: ChatService.listenForMessages('chat_123'),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    final messages = snapshot.data ?? [];
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Text(message.text);
      },
    );
  },
)
```

---

### 3. **markMessageAsSeen()**

Mark a single message as seen by the recipient.

```dart
Future<void> ChatService.markMessageAsSeen({
  required String chatId,
  required String messageId,
});
```

**Example:**
```dart
await ChatService.markMessageAsSeen(
  chatId: 'chat_123',
  messageId: 'msg_456',
);
```

---

### 4. **markAllMessagesAsSeen()**

Mark all unread messages in a chat as seen (excluding messages sent by current user).

```dart
Future<void> ChatService.markAllMessagesAsSeen({
  required String chatId,
  required String currentUserId,
});
```

**What it does:**
1. Queries all unseen messages NOT sent by current user
2. Batch updates them to `seen: true`
3. Uses Firestore batch for performance

**Example:**
```dart
// Call when user opens a chat
@override
void initState() {
  super.initState();
  ChatService.markAllMessagesAsSeen(
    chatId: widget.chatId,
    currentUserId: FirebaseAuth.instance.currentUser!.uid,
  );
}
```

---

### 5. **listenToUserChats()**

Listen to all chats for a user, ordered by last message timestamp (most recent first).

```dart
Stream<List<Chat>> ChatService.listenToUserChats(String userId);
```

**Example:**
```dart
StreamBuilder<List<Chat>>(
  stream: ChatService.listenToUserChats('user_123'),
  builder: (context, snapshot) {
    final chats = snapshot.data ?? [];
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ListTile(
          title: Text(chat.lastMessage),
          subtitle: Text(timeago.format(chat.lastTimestamp)),
        );
      },
    );
  },
)
```

---

### 6. **getOrCreateChat()**

Get existing chat between two users, or create a new one if it doesn't exist.

```dart
Future<String> ChatService.getOrCreateChat({
  required String patientId,
  required String providerId,
});
```

**What it does:**
1. Checks if chat already exists with both participants
2. Returns existing chat ID if found
3. Creates new chat if none exists
4. Returns the chat ID

**Example:**
```dart
final chatId = await ChatService.getOrCreateChat(
  patientId: 'patient_123',
  providerId: 'provider_456',
);

// Navigate to chat screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatConversationScreen(
      chatId: chatId,
      otherUserId: 'provider_456',
      otherUserName: 'Dr. Smith',
    ),
  ),
);
```

---

## 📦 Models

### ChatMessage Model

```dart
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool seen;

  // Factory constructor
  factory ChatMessage.fromFirestore(DocumentSnapshot doc);

  // Convert to Map
  Map<String, dynamic> toMap();

  // Check if current user sent it
  bool isSentByMe(String currentUserId);
}
```

**Helper Methods:**
- `isSentByMe(userId)` - Returns true if message was sent by specified user
- `copyWith()` - Create a copy with updated fields
- `toString()` - Debug-friendly string representation

---

### Chat Model

```dart
class Chat {
  final String id;
  final List<String> participants;  // [patientId, providerId]
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;

  // Factory constructor
  factory Chat.fromFirestore(DocumentSnapshot doc);

  // Convert to Map
  Map<String, dynamic> toMap();

  // Get other participant ID
  String getOtherParticipantId(String currentUserId);

  // Check if user is participant
  bool hasParticipant(String userId);
}
```

**Helper Methods:**
- `getOtherParticipantId(userId)` - Returns the ID of the other participant
- `hasParticipant(userId)` - Checks if user is in the chat
- `copyWith()` - Create a copy with updated fields

---

## 📱 UI Screens

### 1. ChatListScreen

Displays all chats for the current user.

**Features:**
- Real-time chat list updates
- Ordered by last message time (most recent first)
- Shows last message preview
- Shows time ago (e.g., "2m ago", "1h ago")
- Unread message badges
- Empty state when no chats
- User avatar from Firestore

**Navigation:**
```dart
Navigator.pushNamed(context, '/chat-list');
```

---

### 2. ChatConversationScreen

Full conversation view with message history.

**Features:**
- Real-time message stream
- WhatsApp-style message bubbles
- Date separators (Today, Yesterday, etc.)
- Read receipts (✓ = sent, ✓✓ = seen)
- Auto-scroll to latest message
- Send button with loading state
- Empty state when no messages
- Message timestamps (HH:mm format)

**Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatConversationScreen(
      chatId: 'chat_123',
      otherUserId: 'user_456',
      otherUserName: 'Dr. Smith',
    ),
  ),
);
```

---

## 💡 Usage Examples

### Example 1: Start a Chat with a Provider

```dart
// In your provider profile or booking screen
ElevatedButton(
  onPressed: () async {
    try {
      // Get or create chat
      final chatId = await ChatService.getOrCreateChat(
        patientId: currentUser.uid,
        providerId: provider.id,
      );

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(
            chatId: chatId,
            otherUserId: provider.id,
            otherUserName: provider.name,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  child: const Text('Message Provider'),
)
```

---

### Example 2: Display Unread Message Count

```dart
FutureBuilder<int>(
  future: ChatService.getUnreadMessageCount(
    chatId: chatId,
    currentUserId: currentUser.uid,
  ),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;
    
    if (unreadCount > 0) {
      return Badge(
        label: Text('$unreadCount'),
        child: Icon(Icons.chat),
      );
    }
    
    return Icon(Icons.chat);
  },
)
```

---

### Example 3: Send Message with Error Handling

```dart
Future<void> _sendMessage(String text) async {
  if (text.trim().isEmpty) return;

  setState(() => _isSending = true);

  try {
    await ChatService.sendMessage(
      chatId: chatId,
      senderId: currentUser.uid,
      text: text.trim(),
    );

    _messageController.clear();
    _scrollToBottom();
  } on ArgumentError catch (e) {
    _showError('Invalid input: $e');
  } on Exception catch (e) {
    _showError('Failed to send: $e');
  } finally {
    setState(() => _isSending = false);
  }
}
```

---

### Example 4: Listen to Messages with State Management

```dart
class ChatScreenState extends State<ChatScreen> {
  late Stream<List<ChatMessage>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = ChatService.listenForMessages(widget.chatId);
    _markMessagesAsSeen();
  }

  Future<void> _markMessagesAsSeen() async {
    await ChatService.markAllMessagesAsSeen(
      chatId: widget.chatId,
      currentUserId: currentUser.uid,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        // Handle loading, error, and data states
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }

        final messages = snapshot.data ?? [];
        return MessagesList(messages: messages);
      },
    );
  }
}
```

---

## 🧪 Testing

### Unit Tests

The package includes comprehensive unit tests using `fake_cloud_firestore`.

**Run tests:**
```bash
flutter test test/chat_service_test.dart
```

**Test Coverage:**
- ✅ sendMessage() creates message and updates chat
- ✅ sendMessage() throws error for empty text
- ✅ listenForMessages() returns stream of messages
- ✅ markMessageAsSeen() updates seen field
- ✅ listenToUserChats() orders by lastTimestamp
- ✅ getOrCreateChat() returns existing chat
- ✅ getOrCreateChat() creates new chat
- ✅ markAllMessagesAsSeen() only marks recipient messages
- ✅ deleteChat() removes chat and messages
- ✅ getUnreadMessageCount() returns correct count

---

## 🔒 Firestore Security Rules

Add these rules to your `firestore.rules` file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Chat collection rules
    match /chats/{chatId} {
      // Allow read if user is a participant
      allow read: if request.auth != null &&
                     request.auth.uid in resource.data.participants;
      
      // Allow create if user is one of the participants
      allow create: if request.auth != null &&
                       request.auth.uid in request.resource.data.participants;
      
      // Allow update if user is a participant
      allow update: if request.auth != null &&
                       request.auth.uid in resource.data.participants;
      
      // Allow delete if user is a participant
      allow delete: if request.auth != null &&
                       request.auth.uid in resource.data.participants;
      
      // Messages subcollection rules
      match /messages/{messageId} {
        // Allow read if user is a participant of the parent chat
        allow read: if request.auth != null &&
                       request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        
        // Allow create if user is a participant and is the sender
        allow create: if request.auth != null &&
                         request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants &&
                         request.auth.uid == request.resource.data.senderId;
        
        // Allow update if user is a participant (for marking as seen)
        allow update: if request.auth != null &&
                         request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        
        // Allow delete if user is the sender
        allow delete: if request.auth != null &&
                         request.auth.uid == resource.data.senderId;
      }
    }
  }
}
```

---

## 📊 Performance Considerations

### Indexing

Create these composite indexes in Firebase Console:

1. **chats collection:**
   - Field: `participants` (Array)
   - Field: `lastTimestamp` (Descending)

2. **messages subcollection:**
   - Field: `seen` (Ascending)
   - Field: `senderId` (Ascending)
   - Field: `timestamp` (Ascending)

### Pagination

For large chat histories, implement pagination:

```dart
Stream<List<ChatMessage>> listenForMessages(
  String chatId, {
  int limit = 50,
  DocumentSnapshot? startAfter,
}) {
  var query = _firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(limit);

  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }

  return query.snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => ChatMessage.fromFirestore(doc))
        .toList();
  });
}
```

---

## 🎨 Customization

### Colors

Update colors in the UI screens:

```dart
// Primary colors
static const primaryColor = Color(0xFF1976D2);  // Blue
static const backgroundColor = Color(0xFFF5F5F5);  // Light gray
static const surfaceColor = Color(0xFFFFFFFF);  // White

// Message bubbles
static const myMessageColor = Color(0xFF1976D2);  // Blue for sent
static const otherMessageColor = Color(0xFFFFFFFF);  // White for received
```

### Message Bubble Style

Customize bubble design in `_MessageBubble` widget:

```dart
decoration: BoxDecoration(
  color: isMine ? myMessageColor : otherMessageColor,
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(isMine ? 16 : 4),
    bottomRight: Radius.circular(isMine ? 4 : 16),
  ),
)
```

---

## ✅ Summary

**Files Created:**
1. `lib/data/models/chat_message.dart` - Message model
2. `lib/data/models/chat.dart` - Chat model
3. `lib/data/services/chat_service.dart` - Core service (450+ lines)
4. `lib/screens/chat/chat_list_screen.dart` - Chat list UI
5. `lib/screens/chat/chat_conversation_screen.dart` - Conversation UI
6. `test/chat_service_test.dart` - Comprehensive tests

**Key Features:**
✅ Real-time messaging with StreamBuilder  
✅ Read receipts (✓ sent, ✓✓ seen)  
✅ Automatic message ordering  
✅ Mark messages as seen  
✅ Chat creation and retrieval  
✅ Material 3 UI design  
✅ Error handling throughout  
✅ Unit tests included  
✅ Firestore security rules provided  

The chat system is **production-ready** and fully tested! 🚀
