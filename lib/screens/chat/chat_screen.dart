import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../controllers/navigation_controller.dart';
import 'ai_chat_screen.dart';
import 'patient_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
    _loadChatsFromFirestore();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _loadChatsFromFirestore() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = currentUser.uid;

      // Always include AI Assistant at the top
      final aiAssistant = {
        'id': 'ai-assistant',
        'name': 'AI Health Assistant',
        'specialty': '24/7 Health Support',
        'lastMessage': 'Hello! I\'m here to help with your health questions.',
        'time': 'Online',
        'unreadCount': 0,
        'isOnline': true,
        'avatar': 'ai-assistant',
        'isAI': true,
        'timestamp': DateTime.now(),
      };

      // Get all chats where current user is a participant
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastTimestamp', descending: true)
          .get();

      List<Map<String, dynamic>> loadedChats = [aiAssistant];

      for (var chatDoc in chatsQuery.docs) {
        final chatData = chatDoc.data();
        final participants = List<String>.from(chatData['participants'] ?? []);
        
        // Get the other participant (the doctor/provider)
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        // Try to get provider info from professionals collection
        DocumentSnapshot? providerDoc;
        try {
          providerDoc = await _firestore
              .collection('professionals')
              .doc(otherUserId)
              .get();
        } catch (e) {
          // If not found, try patients collection (for testing)
          try {
            providerDoc = await _firestore
                .collection('patients')
                .doc(otherUserId)
                .get();
          } catch (e) {
            continue;
          }
        }

        if (!providerDoc.exists) continue;

        final providerData = providerDoc.data() as Map<String, dynamic>?;
        if (providerData == null) continue;

        // Get unread message count
        final messagesQuery = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('senderId', isEqualTo: otherUserId)
            .where('seen', isEqualTo: false)
            .get();

        final unreadCount = messagesQuery.docs.length;

        // Format timestamp
        final lastTimestamp = (chatData['lastTimestamp'] as Timestamp?)?.toDate();
        String timeString = 'No messages';
        if (lastTimestamp != null) {
          final now = DateTime.now();
          final difference = now.difference(lastTimestamp);

          if (difference.inMinutes < 1) {
            timeString = 'Just now';
          } else if (difference.inHours < 1) {
            timeString = '${difference.inMinutes}m ago';
          } else if (difference.inDays < 1) {
            timeString = '${lastTimestamp.hour}:${lastTimestamp.minute.toString().padLeft(2, '0')}';
          } else if (difference.inDays < 2) {
            timeString = 'Yesterday';
          } else if (difference.inDays < 7) {
            timeString = '${difference.inDays}d ago';
          } else {
            timeString = '${lastTimestamp.day}/${lastTimestamp.month}/${lastTimestamp.year}';
          }
        }

        loadedChats.add({
          'id': otherUserId,
          'name': providerData['name'] ?? providerData['fullName'] ?? 'Provider',
          'specialty': providerData['specialty'] ?? providerData['role'] ?? 'Healthcare Provider',
          'lastMessage': chatData['lastMessage'] ?? 'No messages yet',
          'time': timeString,
          'unreadCount': unreadCount,
          'isOnline': providerData['isOnline'] ?? false,
          'avatar': providerData['profileImage'] ?? providerData['avatar'] ?? 'assets/images/doctor1.png',
          'isAI': false,
          'timestamp': lastTimestamp ?? DateTime.now(),
          'rating': providerData['rating']?.toString() ?? '4.5',
          'experience': providerData['experience']?.toString() ?? '5+',
        });
      }

      setState(() {
        _chatList = loadedChats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chats: $e');
      // Fallback to AI Assistant only
      setState(() {
        _chatList = [
          {
            'id': 'ai-assistant',
            'name': 'AI Health Assistant',
            'specialty': '24/7 Health Support',
            'lastMessage': 'Hello! I\'m here to help with your health questions.',
            'time': 'Online',
            'unreadCount': 0,
            'isOnline': true,
            'avatar': 'ai-assistant',
            'isAI': true,
            'timestamp': DateTime.now(),
          }
        ];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openChat(Map<String, dynamic> chat) async {
    // Store chat context for navigation consistency
    HapticFeedback.lightImpact();
    
    if (chat['isAI'] == true) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              const AIChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      );
    } else {
      // Navigate to chat and reload list when returning to see updated last message
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              PatientChatScreen(
                doctorInfo: {
                  'id': chat['id']?.toString() ?? 'unknown',
                  'name': chat['name']?.toString() ?? 'Provider',
                  'specialty': chat['specialty']?.toString() ?? 'General Physician',
                  'isOnline': chat['isOnline'] ?? true,
                  'rating': chat['rating']?.toString() ?? '4.5',
                  'experience': chat['experience']?.toString() ?? '5+',
                },
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      );
      
      // Reload chats to update last message and unread count
      _loadChatsFromFirestore();
    }
  }

  void _showNewChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        'Start New Chat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: _firestore.collection('professionals').get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No healthcare providers available',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              ),
                              title: Text(
                                data['name'] ?? data['fullName'] ?? 'Provider',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    data['specialty'] ?? 'Healthcare Provider',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (data['rating'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          data['rating'].toString(),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Icon(
                                Icons.chat_bubble_outline,
                                color: AppTheme.primaryColor,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _openChat({
                                  'id': doc.id,
                                  'name': data['name'] ?? data['fullName'] ?? 'Provider',
                                  'specialty': data['specialty'] ?? 'Healthcare Provider',
                                  'isOnline': data['isOnline'] ?? false,
                                  'rating': data['rating']?.toString() ?? '4.5',
                                  'experience': data['experience']?.toString() ?? '5+',
                                  'isAI': false,
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 114, // Increased from 88 to 114 for much lower positioning from top
        titleSpacing: 12, // Increased spacing for better positioning
        leading: IconButton(
          iconSize: 24,
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textPrimaryColor,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            // Reset navigation to home state
            NavigationController().setCurrentIndex(0);
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            height: 1.2,
          ),
        ),
        actions: [
          IconButton(
            iconSize: 26,
            icon: Icon(
              Icons.search_rounded,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildChatList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showNewChatDialog();
        },
        child: const Icon(
          Icons.add_comment_rounded,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your conversations...',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_chatList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _loadChatsFromFirestore,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _chatList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          
          final chat = _chatList[index - 1];
          return _buildChatCard(chat, index - 1);
        },
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _chatList.fold<int>(
      0, (sum, chat) => sum + (chat['unreadCount'] as int),
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unreadCount > 0 
                      ? '$unreadCount new messages'
                      : 'Stay connected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Chat with your healthcare providers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _openChat(chat);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: chat['isAI'] == true 
                            ? AppTheme.primaryColor.withOpacity(0.1) 
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: chat['isAI'] == true 
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withOpacity(0.2),
                          width: 2,
                        ),
                        gradient: chat['isAI'] == true ? LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                      ),
                      child: chat['isAI'] == true 
                          ? Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.white,
                              size: 28,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/images/avatar.png',
                                fit: BoxFit.cover,
                                width: 44,
                                height: 44,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 28,
                                  );
                                },
                              ),
                            ),
                    ),
                    if (chat['isOnline'])
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Chat details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          Text(
                            chat['time'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondaryColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        chat['specialty'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat['lastMessage'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat['unreadCount'] > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, 
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat['unreadCount'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your\nhealthcare providers',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
