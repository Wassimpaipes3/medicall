import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _sendButtonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.elasticOut,
    ));

    // Add welcome message
    _messages.add(ChatMessage(
      message: "Hello! I'm your AI Health Assistant ⚡ How can I help you today? I can assist with:\n\n• Health questions & advice\n• Booking appointments\n• Medication reminders\n• Emergency guidance\n• General wellness tips",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _typingAnimationController.dispose();
    _sendButtonController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();
    _sendButtonController.forward().then((_) => _sendButtonController.reverse());
    
    HapticFeedback.lightImpact();
    
    setState(() {
      _messages.add(ChatMessage(
        message: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI response with realistic delay
    await Future.delayed(Duration(milliseconds: 1000 + (userMessage.length * 20)));
    
    String aiResponse = _generateAIResponse(userMessage);
    
    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(
        message: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    _scrollToBottom();
  }

  String _generateAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('appointment') || message.contains('book')) {
      return "⚡ I can help you book an appointment! Our booking system offers:\n\n• Choose from 50+ specialists\n• Select preferred location\n• Pick convenient time slots\n\nWould you like me to open the booking system for you?";
    } else if (message.contains('symptom') || message.contains('pain') || message.contains('hurt') || message.contains('sick')) {
      return "🩺 I understand you're experiencing symptoms. Here's what I recommend:\n\n• Document your symptoms with details\n• Note when they started\n• Consider severity level (1-10)\n\n⚠️ For severe symptoms, seek immediate medical attention. Would you like me to help you find the right specialist?";
    } else if (message.contains('medicine') || message.contains('medication') || message.contains('pill')) {
      return "💊 For medication guidance:\n\n• Always consult your prescribing doctor\n• Never stop medications abruptly\n• Keep track of side effects\n• Set reminders for doses\n\n🏥 Would you like me to connect you with a pharmacist or doctor for consultation?";
    } else if (message.contains('emergency') || message.contains('urgent') || message.contains('help')) {
      return "🚨 EMERGENCY PROTOCOLS:\n\n• Life-threatening: Call 911 immediately\n• Severe pain/breathing issues: Go to ER\n• Urgent but stable: Book same-day appointment\n\n⚡ I can help you find the nearest emergency room or book an urgent care appointment. What's your situation?";
    } else if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return "👋 Hello there! Great to see you!\n\nI'm your AI Health Assistant, powered by advanced medical knowledge. I'm here to:\n\n⚡ Answer health questions\n🏥 Help book appointments\n💊 Provide medication info\n🩺 Offer wellness tips\n\nWhat can I help you with today?";
    } else if (message.contains('thank')) {
      return "🙏 You're absolutely welcome! I'm always here to help.\n\n⚡ Remember, I'm available 24/7 for:\n• Quick health questions\n• Appointment booking\n• Emergency guidance\n• Wellness support\n\nIs there anything else I can assist you with?";
    } else if (message.contains('diet') || message.contains('food') || message.contains('nutrition')) {
      return "🍎 Nutrition & Diet Guidance:\n\n• Focus on whole foods & vegetables\n• Stay hydrated (8+ glasses daily)\n• Limit processed foods\n• Consider portion control\n\n⚡ For personalized diet plans, I recommend consulting with our nutritionist. Shall I help you book an appointment?";
    } else if (message.contains('exercise') || message.contains('workout') || message.contains('fitness')) {
      return "💪 Fitness & Exercise Tips:\n\n• Start with 30min daily activity\n• Mix cardio & strength training\n• Listen to your body\n• Stay consistent, not perfect\n\n🏥 For customized exercise plans or physical therapy, I can connect you with our specialists!";
    } else if (message.contains('stress') || message.contains('anxiety') || message.contains('mental')) {
      return "🧠 Mental Health Support:\n\n• Practice deep breathing\n• Regular sleep schedule\n• Stay connected with loved ones\n• Consider mindfulness/meditation\n\n⚡ Our mental health professionals are here to help. Would you like me to book a consultation with a therapist or psychiatrist?";
    } else {
      return "⚡ Thanks for reaching out! I'm here to help with all your health needs.\n\n🩺 I can assist with:\n• Medical questions & guidance\n• Appointment scheduling\n• Finding the right specialist\n• Health tips & wellness advice\n\nCould you tell me more about what specific area you need help with? I'm here to provide the best possible support!";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 114, // Increased from 88 to 114 for much lower positioning from top
        titleSpacing: 12, // Added proper title spacing
        leading: IconButton(
          iconSize: 24, // Increased icon size
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 46, // Increased from 42 to 46
              height: 46, // Increased from 42 to 46
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24), // Increased from 22 to 24
            ),
            const SizedBox(width: 16), // Increased from 12 to 16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Health Assistant',
                    style: TextStyle(
                      fontSize: 18, // Increased from 16 to 18
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Online • Always ready to help',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textPrimaryColor),
            onPressed: () => _showChatOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          _buildQuickActions(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser 
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: message.isUser ? Colors.white : AppTheme.textPrimaryColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: message.isUser 
                          ? Colors.white.withOpacity(0.8) 
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                ),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/avatar.png',
                  fit: BoxFit.cover,
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person_rounded, color: Colors.white, size: 18);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI is thinking',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final animationValue = (_typingAnimationController.value + index * 0.2) % 1.0;
        final opacity = (0.4 + 0.6 * (1 - (animationValue - 0.5).abs() * 2)).clamp(0.0, 1.0);
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickActionChip('Book Appointment', Icons.calendar_today_rounded),
          _buildQuickActionChip('Emergency Help', Icons.emergency_rounded),
          _buildQuickActionChip('Find Doctor', Icons.search_rounded),
          _buildQuickActionChip('Health Tips', Icons.lightbulb_rounded),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: AppTheme.primaryColor),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        onPressed: () {
          _messageController.text = label;
          _sendMessage();
        },
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
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Ask your AI Health Assistant...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 15,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _sendButtonAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + _sendButtonAnimation.value * 0.1,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.clear_all_rounded, color: AppTheme.primaryColor),
              title: const Text('Clear Chat History'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _messages.add(ChatMessage(
                    message: "Hello! I'm your AI Health Assistant ⚡ How can I help you today?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ));
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_rounded, color: AppTheme.primaryColor),
              title: const Text('Quick Book Appointment'),
              onTap: () {
                Navigator.pop(context);
                _messageController.text = 'I want to book an appointment';
                _sendMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency_rounded, color: Colors.red),
              title: const Text('Emergency Assistance'),
              onTap: () {
                Navigator.pop(context);
                _messageController.text = 'I need emergency help';
                _sendMessage();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
}
