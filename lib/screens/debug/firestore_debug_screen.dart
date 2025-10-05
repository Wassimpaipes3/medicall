import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debugging screen to check Firestore data
/// Add this to your app temporarily to debug chat issues
class FirestoreDebugScreen extends StatefulWidget {
  const FirestoreDebugScreen({super.key});

  @override
  State<FirestoreDebugScreen> createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String _results = 'Tap buttons to check Firestore data...';
  bool _loading = false;

  Future<void> _checkCurrentUser() async {
    setState(() {
      _loading = true;
      _results = 'Checking current user...';
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _results = '❌ No user logged in!';
        _loading = false;
      });
      return;
    }

    setState(() {
      _results = '''
✅ Current User:
   UID: ${user.uid}
   Email: ${user.email ?? 'N/A'}
   Display Name: ${user.displayName ?? 'N/A'}
''';
      _loading = false;
    });
  }

  Future<void> _checkAllChats() async {
    setState(() {
      _loading = true;
      _results = 'Loading all chats...';
    });

    try {
      final chats = await _firestore.collection('chats').get();
      
      if (chats.docs.isEmpty) {
        setState(() {
          _results = '''
⚠️ No chats found in Firestore!
   
This could mean:
- No messages have been sent yet
- Messages failed to write
- Wrong Firestore project
''';
          _loading = false;
        });
        return;
      }

      String result = '✅ Found ${chats.docs.length} chats:\n\n';
      
      for (var doc in chats.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final lastMessage = data['lastMessage'] ?? 'N/A';
        
        result += '''
📝 Chat ID: ${doc.id}
   Participants: ${participants.join(', ')}
   Last Message: $lastMessage
   
''';
      }

      setState(() {
        _results = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _results = '❌ Error loading chats: $e';
        _loading = false;
      });
    }
  }

  Future<void> _checkMyChats() async {
    setState(() {
      _loading = true;
      _results = 'Loading my chats...';
    });

    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _results = '❌ No user logged in!';
        _loading = false;
      });
      return;
    }

    try {
      final chats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();
      
      if (chats.docs.isEmpty) {
        setState(() {
          _results = '''
⚠️ No chats found for user: ${user.uid}
   
This could mean:
- You haven't sent/received any messages
- Participants array not set correctly
- Wrong user logged in
''';
          _loading = false;
        });
        return;
      }

      String result = '✅ Found ${chats.docs.length} chats for you:\n\n';
      
      for (var doc in chats.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final lastMessage = data['lastMessage'] ?? 'N/A';
        
        // Get other participant(s)
        final otherParticipants = participants.where((id) => id != user.uid).toList();
        
        result += '''
📝 Chat ID: ${doc.id}
   With: ${otherParticipants.join(', ')}
   Last Message: $lastMessage
   Participants: ${participants.join(', ')}
   
''';

        // Check messages
        final messages = await doc.reference.collection('messages').get();
        result += '   📨 Messages: ${messages.docs.length}\n';
        
        if (messages.docs.isNotEmpty) {
          result += '   Recent messages:\n';
          for (var msg in messages.docs.take(3)) {
            final msgData = msg.data();
            result += '      - ${msgData['text']?.toString().substring(0, 30) ?? 'N/A'}...\n';
          }
        }
        
        result += '\n';
      }

      setState(() {
        _results = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _results = '❌ Error loading chats: $e';
        _loading = false;
      });
    }
  }

  Future<void> _checkSpecificChat() async {
    setState(() {
      _loading = true;
      _results = 'Checking specific chat...';
    });

    // Use the chat ID from your logs
    const chatId = '7ftk4BqD7McN3Bjm3LFFtiJ6xkV2_Mk5GRsJy3dTHi75Vid7bp7Q3VLg2';
    
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!doc.exists) {
        setState(() {
          _results = '''
❌ Chat document does NOT exist!
   
Chat ID: $chatId

This means:
- Message write failed
- Permission denied
- Document was deleted
''';
          _loading = false;
        });
        return;
      }

      final data = doc.data()!;
      final participants = List<String>.from(data['participants'] ?? []);
      
      String result = '''
✅ Chat document EXISTS!
   
Chat ID: $chatId

Data:
   Participants: ${participants.join('\n                 ')}
   Last Message: ${data['lastMessage']}
   Last Sender: ${data['lastSenderId']}
   Created: ${data['createdAt']}
   
''';

      // Check messages
      final messages = await doc.reference.collection('messages').get();
      result += '\n📨 Messages in chat: ${messages.docs.length}\n\n';
      
      if (messages.docs.isEmpty) {
        result += '⚠️ No messages in subcollection!\n';
      } else {
        result += 'Messages:\n';
        for (var msg in messages.docs) {
          final msgData = msg.data();
          result += '''
   
   Message ID: ${msg.id}
   Sender: ${msgData['senderId']}
   Text: ${msgData['text']}
   Seen: ${msgData['seen']}
   Type: ${msgData['type']}
''';
        }
      }

      setState(() {
        _results = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _results = '❌ Error checking chat: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Debug'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _checkCurrentUser,
                  icon: const Icon(Icons.person),
                  label: const Text('Check Current User'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _checkAllChats,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Check All Chats'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _checkMyChats,
                  icon: const Icon(Icons.chat),
                  label: const Text('Check My Chats'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _checkSpecificChat,
                  icon: const Icon(Icons.search),
                  label: const Text('Check Specific Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SelectableText(
                      _results,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
