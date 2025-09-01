import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../controllers/navigation_controller.dart';
import 'ai_chat_screen.dart';
import 'provider_chat_screen.dart';

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

  final List<Map<String, dynamic>> _chatList = [
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
    },
    {
      'id': '1',
      'name': 'Dr. Sarah Johnson',
      'specialty': 'Cardiologist',
      'lastMessage': 'Your test results look good. Let\'s schedule a follow-up.',
      'time': '2:30 PM',
      'unreadCount': 2,
      'isOnline': true,
      'avatar': 'assets/images/doctor1.png',
      'isAI': false,
    },
    {
      'id': '2',
      'name': 'Dr. Ahmed Hassan',
      'specialty': 'Neurologist',
      'lastMessage': 'Please take your medication as prescribed.',
      'time': '11:45 AM',
      'unreadCount': 0,
      'isOnline': false,
      'avatar': 'assets/images/doctor2.png',
      'isAI': false,
    },
    {
      'id': '3',
      'name': 'Nurse Lisa Chen',
      'specialty': 'Critical Care',
      'lastMessage': 'Reminder: Your appointment is tomorrow at 10 AM.',
      'time': 'Yesterday',
      'unreadCount': 1,
      'isOnline': true,
      'avatar': 'assets/images/nurse1.png',
      'isAI': false,
    },
    {
      'id': '4',
      'name': 'Dr. Maria Garcia',
      'specialty': 'Pediatrician',
      'lastMessage': 'The vaccination schedule has been updated.',
      'time': '2 days ago',
      'unreadCount': 0,
      'isOnline': false,
      'avatar': 'assets/images/doctor3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openChat(Map<String, dynamic> chat) {
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
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              ProviderChatScreen(
                providerId: chat['id']?.toString() ?? 'unknown',
                providerName: chat['name']?.toString() ?? 'Provider',
                specialty: chat['specialty']?.toString(),
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
    }
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
          // TODO: Start new chat
          HapticFeedback.mediumImpact();
        },
        child: const Icon(
          Icons.add_comment_rounded,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildChatList() {
    if (_chatList.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _chatList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildHeader();
        }
        
        final chat = _chatList[index - 1];
        return _buildChatCard(chat, index - 1);
      },
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
