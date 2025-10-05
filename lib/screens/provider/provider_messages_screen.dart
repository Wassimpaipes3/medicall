import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../routes/app_routes.dart';
import '../../services/provider/provider_service.dart';
import '../../widgets/provider/provider_navigation_bar.dart';
import 'comprehensive_provider_chat_screen.dart';

class ProviderMessagesScreen extends StatefulWidget {
  const ProviderMessagesScreen({super.key});

  @override
  State<ProviderMessagesScreen> createState() => _ProviderMessagesScreenState();
}

class _ProviderMessagesScreenState extends State<ProviderMessagesScreen>
    with TickerProviderStateMixin {
  final ProviderService _providerService = ProviderService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  int _selectedIndex = 1; // Chat/Messages tab

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadConversationsFromFirestore();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadConversationsFromFirestore() async {
    try {
      print('🔵 MESSAGES SCREEN: Loading conversations from Firestore...');
      setState(() {
        _isLoading = true;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ MESSAGES SCREEN: No authenticated user!');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final providerId = currentUser.uid;
      print('👤 MESSAGES SCREEN: Provider ID: $providerId');

      // Get all chats where current provider is a participant
      print('🔍 MESSAGES SCREEN: Querying chats collection...');
      print('   Query: participants arrayContains $providerId');
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: providerId)
          .orderBy('lastTimestamp', descending: true)
          .get();

      print('📊 MESSAGES SCREEN: Found ${chatsQuery.docs.length} chat documents');

      List<Map<String, dynamic>> loadedConversations = [];

      for (var chatDoc in chatsQuery.docs) {
        print('\n📄 MESSAGES SCREEN: Processing chat: ${chatDoc.id}');
        final chatData = chatDoc.data();
        final participants = List<String>.from(chatData['participants'] ?? []);
        print('   Participants: $participants');
        
        // Get the other participant (the patient)
        final patientId = participants.firstWhere(
          (id) => id != providerId,
          orElse: () => '',
        );

        print('   Patient ID: $patientId');
        if (patientId.isEmpty) {
          print('   ⚠️ Skipping: No patient ID found');
          continue;
        }

        // Try to get patient info from patients collection
        DocumentSnapshot? patientDoc;
        try {
          print('   🔍 Looking for patient in patients collection...');
          patientDoc = await _firestore
              .collection('patients')
              .doc(patientId)
              .get();
        } catch (e) {
          // If not found, try professionals collection (for testing)
          try {
            print('   🔍 Looking for patient in professionals collection...');
            patientDoc = await _firestore
                .collection('professionals')
                .doc(patientId)
                .get();
          } catch (e) {
            print('   ❌ Error getting patient data: $e');
            continue;
          }
        }

        if (!patientDoc.exists) {
          print('   ⚠️ Patient document does not exist');
          continue;
        }

        final patientData = patientDoc.data() as Map<String, dynamic>?;
        if (patientData == null) {
          print('   ⚠️ Patient data is null');
          continue;
        }

        print('   ✅ Patient found: ${patientData['name'] ?? patientData['fullName']}');

        // Get unread message count
        print('   📬 Counting unread messages...');
        final messagesQuery = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('senderId', isEqualTo: patientId)
            .where('seen', isEqualTo: false)
            .get();

        final unreadCount = messagesQuery.docs.length;
        print('   📊 Unread messages: $unreadCount');

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

        final conversationData = {
          'id': patientId,
          'userId': patientId,  // For ComprehensiveProviderChatScreen
          'patientId': patientId,  // For ComprehensiveProviderChatScreen
          'patientName': patientData['name'] ?? patientData['fullName'] ?? 'Patient',
          'patientAvatar': patientData['profileImage'] ?? patientData['avatar'],
          'lastMessage': chatData['lastMessage'] ?? 'No messages yet',
          'lastMessageTime': timeString,
          'unreadCount': unreadCount,
          'isOnline': patientData['isOnline'] ?? false,
          'serviceType': patientData['lastServiceType'] ?? 'General Care',
          'status': 'active',
          'timestamp': lastTimestamp ?? DateTime.now(),
        };
        
        print('   ✅ Added conversation: ${conversationData['patientName']}');
        loadedConversations.add(conversationData);
      }

      print('\n✅ MESSAGES SCREEN: Loaded ${loadedConversations.length} conversations total');
      
      setState(() {
        _conversations = loadedConversations;
        _isLoading = false;
      });
      
      print('📱 MESSAGES SCREEN: UI updated with ${_conversations.length} conversations');
    } catch (e) {
      print('❌ MESSAGES SCREEN: Error loading conversations: $e');
      print('   Stack trace: ${StackTrace.current}');
      setState(() {
        _conversations = [];
        _isLoading = false;
      });
    }
  }

  // Keep old method as backup (renamed) - Not used anymore
  // ignore: unused_element
  Future<void> _loadConversations_OLD() async {
    try {
      final appointments = await _providerService.getActiveAppointments();
      final conversations = _generateConversations_OLD(appointments);
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // OLD METHODS - Kept as backup (not used anymore)
  // ignore: unused_element
  List<Map<String, dynamic>> _generateConversations_OLD(List<AppointmentRequest> appointments) {
    final conversations = <Map<String, dynamic>>[];
    
    // Add conversations for active appointments
    for (final appointment in appointments) {
      conversations.add({
        'id': appointment.id,
        'patientName': appointment.patientName,
        'patientAvatar': null,
        'lastMessage': _getLastMessage_OLD(appointment),
        'lastMessageTime': _getLastMessageTime_OLD(appointment),
        'unreadCount': _getUnreadCount_OLD(appointment),
        'isOnline': true,
        'serviceType': appointment.serviceType,
        'status': appointment.status.toString().split('.').last,
        'appointment': appointment,
      });
    }
    return conversations;
  }

  String _getLastMessage_OLD(AppointmentRequest appointment) {
    final messages = [
      'Hi, I need your services',
      'When can you arrive?',
      'Thank you for accepting',
      'I\'m at the location mentioned',
      'Please hurry, it\'s urgent',
    ];
    return messages[appointment.id.hashCode % messages.length];
  }

  String _getLastMessageTime_OLD(AppointmentRequest appointment) {
    final times = ['5 min ago', '15 min ago', '30 min ago', '1 hour ago', 'Just now'];
    return times[appointment.id.hashCode % times.length];
  }

  int _getUnreadCount_OLD(AppointmentRequest appointment) {
    return appointment.status == AppointmentRequestStatus.pending ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
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
        ),
        bottomNavigationBar: ProviderNavigationBar(
          selectedIndex: _selectedIndex,
          onTap: (index) {},
          hasNotification: false,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildConversationsList(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          HapticFeedback.lightImpact();
          _handleNavigation(index);
        },
        hasNotification: _conversations.any((c) => c['unreadCount'] > 0),
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _conversations.fold<int>(
      0, 
      (sum, conversation) => sum + (conversation['unreadCount'] as int),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20), // Added extra top padding
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: AppTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '${_conversations.length} conversations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadCount new',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_conversations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadConversationsFromFirestore,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationCard(conversation);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: Colors.grey.shade200, width: 2),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: Colors.grey.shade400,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Messages Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Accept appointments to start\ncommunicating with patients',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final hasUnread = conversation['unreadCount'] > 0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openConversation(conversation),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                hasUnread 
                    ? AppTheme.primaryColor.withOpacity(0.02)
                    : Colors.grey.shade50.withOpacity(0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: hasUnread
                ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1)
                : Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          const Color(0xFF10B981),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        conversation['patientName'].toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (conversation['isOnline'])
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['patientName'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        Text(
                          conversation['lastMessageTime'],
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? AppTheme.primaryColor : Colors.grey.shade500,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['lastMessage'],
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread ? Colors.grey.shade700 : Colors.grey.shade600,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation['unreadCount']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        _buildStatusBadge(conversation['status']),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            conversation['serviceType'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = const Color(0xFFF59E0B);
        text = 'Pending';
        break;
      case 'confirmed':
        color = const Color(0xFF10B981);
        text = 'Confirmed';
        break;
      case 'in_progress':
        color = AppTheme.primaryColor;
        text = 'Active';
        break;
      case 'completed':
        color = Colors.grey.shade500;
        text = 'Completed';
        break;
      default:
        color = Colors.grey.shade500;
        text = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _openConversation(Map<String, dynamic> conversation) async {
    // Navigate to comprehensive chat screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComprehensiveProviderChatScreen(
          conversation: conversation,
        ),
      ),
    );
    
    // Reload conversations to update last message and unread count
    _loadConversationsFromFirestore();
  }

  void _handleNavigation(int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
        break;
      case 1: // Chat/Messages - already here
        // Already in messages, do nothing
        break;
      case 2: // Schedule/Appointments
        Navigator.pushReplacementNamed(context, AppRoutes.providerAppointments);
        break;
      case 3: // Profile
        Navigator.pushReplacementNamed(context, AppRoutes.providerProfile);
        break;
    }
  }
}

class ProviderChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback? onMessageSent;

  const ProviderChatDetailScreen({
    super.key,
    required this.conversation,
    this.onMessageSent,
  });

  @override
  State<ProviderChatDetailScreen> createState() => _ProviderChatDetailScreenState();
}

class _ProviderChatDetailScreenState extends State<ProviderChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _showQuickReplies = false;
  List<Map<String, dynamic>> _messages = [];

  final List<String> _quickReplies = [
    "I'm on my way",
    "I'll be there in 10 minutes",
    "Please wait, running slightly late",
    "Thank you for your patience",
    "Service completed successfully",
    "Please provide feedback",
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // Load mock messages for demonstration
    final messages = [
      {
        'id': '1',
        'text': 'Hi Doctor, I need your services urgently',
        'isFromProvider': false,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
        'type': 'text',
      },
      {
        'id': '2',
        'text': 'Hello! I\'ve received your request. I\'ll be there shortly.',
        'isFromProvider': true,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 25)),
        'type': 'text',
      },
      {
        'id': '3',
        'text': 'Thank you so much! When can I expect you?',
        'isFromProvider': false,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 20)),
        'type': 'text',
      },
      {
        'id': '4',
        'text': 'I\'m currently 10 minutes away. Please have your ID ready.',
        'isFromProvider': true,
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
        'type': 'text',
      },
    ];

    setState(() {
      _messages = messages;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': content,
      'isFromProvider': true,
      'timestamp': DateTime.now(),
      'type': 'text',
    };

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();
    _scrollToBottom();
    widget.onMessageSent?.call();
  }

  void _sendQuickReply(String message) {
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': message,
      'isFromProvider': true,
      'timestamp': DateTime.now(),
      'type': 'text',
    };

    setState(() {
      _messages.add(newMessage);
      _showQuickReplies = false;
    });

    _scrollToBottom();
    widget.onMessageSent?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80, // Increased height for better spacing
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: Padding(
          padding: const EdgeInsets.only(top: 8.0), // Added top padding
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimaryColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0), // Added top padding
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      const Color(0xFF10B981),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  widget.conversation['isOnline'] ? Icons.person : Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.conversation['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      widget.conversation['isOnline'] ? 'Online' : 'Last seen 1h ago',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.conversation['isOnline'] 
                            ? const Color(0xFF10B981) 
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0), // Added top padding
            child: IconButton(
              icon: const Icon(Icons.call, color: AppTheme.primaryColor),
              onPressed: () {
                _makeCall(widget.conversation);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0), // Added top padding
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textPrimaryColor),
              onPressed: () {
                _showMoreOptions(widget.conversation);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_showQuickReplies) _buildQuickReplies(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromProvider = message['isFromProvider'] as bool;
    
    return Align(
      alignment: isFromProvider ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isFromProvider ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isFromProvider ? const Radius.circular(4) : null,
            bottomLeft: !isFromProvider ? const Radius.circular(4) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Text(
          message['text'],
          style: TextStyle(
            color: isFromProvider ? Colors.white : AppTheme.textPrimaryColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Replies',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _sendQuickReply(_quickReplies[index]),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _quickReplies[index],
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _showQuickReplies ? Icons.keyboard : Icons.quick_contacts_dialer,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              setState(() {
                _showQuickReplies = !_showQuickReplies;
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _makeCall(Map<String, dynamic> conversation) {
    String patientName = conversation['patientName'] ?? 'Patient';
    String patientPhone = conversation['patientPhone'] ?? 'Not Available';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Call $patientName',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      patientPhone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _initiateVoiceCall(patientPhone);
                            },
                            icon: Icon(Icons.phone),
                            label: Text('Voice Call'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _initiateVideoCall(patientPhone);
                            },
                            icon: Icon(Icons.videocam),
                            label: Text('Video Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
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
    );
  }

  void _showMoreOptions(Map<String, dynamic> conversation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Chat Options',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildChatOption(
                      icon: Icons.search,
                      title: 'Search Messages',
                      onTap: () {
                        Navigator.pop(context);
                        _searchMessages();
                      },
                    ),
                    _buildChatOption(
                      icon: Icons.image,
                      title: 'Send Image',
                      onTap: () {
                        Navigator.pop(context);
                        _sendImage();
                      },
                    ),
                    _buildChatOption(
                      icon: Icons.attach_file,
                      title: 'Send File',
                      onTap: () {
                        Navigator.pop(context);
                        _sendFile();
                      },
                    ),
                    _buildChatOption(
                      icon: Icons.clear_all,
                      title: 'Clear Chat',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _clearChat();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  void _initiateVoiceCall(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Initiating voice call to $phoneNumber...'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Implement actual voice call functionality
  }

  void _initiateVideoCall(String phoneNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Initiating video call to $phoneNumber...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implement actual video call functionality
  }

  void _searchMessages() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Messages'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  void _sendImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image picker will be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implement image picker and upload functionality
  }

  void _sendFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('File picker will be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implement file picker and upload functionality
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Chat'),
        content: Text('Are you sure you want to clear all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Clear'),
          ),
        ],
      ),
    );
  }
}
