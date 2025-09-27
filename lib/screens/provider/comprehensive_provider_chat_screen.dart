import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme.dart';

class ComprehensiveProviderChatScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ComprehensiveProviderChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ComprehensiveProviderChatScreen> createState() => _ComprehensiveProviderChatScreenState();
}

class _ComprehensiveProviderChatScreenState extends State<ComprehensiveProviderChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();
  
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  
  List<ChatMessage> _messages = [];
  bool _showQuickReplies = false;
  bool _isTyping = false;
  bool _patientTyping = false;
  Timer? _typingTimer;
  Timer? _autoReplyTimer;

  final List<String> _quickReplies = [
    "I'm on my way 🚗",
    "I'll be there in 10 minutes ⏰",
    "Please wait, running slightly late 🕒",
    "Thank you for your patience 🙏",
    "Service completed successfully ✅",
    "Please provide feedback 📝",
    "Emergency response activated 🚨",
    "Preparing medical equipment 🏥",
  ];

  final List<String> _emergencyResponses = [
    "🚨 EMERGENCY RESPONSE ACTIVATED",
    "📍 Location received - dispatching immediately",
    "🏥 Medical team is on standby",
    "📞 Contacting emergency services if needed",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChatHistory();
    _startTypingSimulation();
  }

  void _initializeAnimations() {
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _loadChatHistory() {
    final messages = [
      ChatMessage(
        id: '1',
        text: 'Hi Doctor! I need your services urgently. I\'m having chest pain and shortness of breath.',
        isFromProvider: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: MessageType.emergency,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '2',
        text: '🚨 EMERGENCY RESPONSE ACTIVATED\\n\\nI\'ve received your emergency request. I\'m preparing medical equipment and will be there shortly. Please try to stay calm and follow these instructions:\\n\\n1. Sit down and try to relax\\n2. Take slow, deep breaths\\n3. If pain worsens, call 911 immediately',
        isFromProvider: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
        type: MessageType.emergency,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '3',
        text: 'Thank you doctor! I\'m feeling a bit better now. When can I expect you?',
        isFromProvider: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        type: MessageType.text,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '4',
        text: 'I\'m currently 5 minutes away from your location. I have all the necessary medical equipment with me. Please have your ID ready and make sure someone can let me in.',
        isFromProvider: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        type: MessageType.text,
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '5',
        text: '📍 My exact location',
        isFromProvider: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        type: MessageType.location,
        status: MessageStatus.read,
        locationData: {
          'latitude': 37.7749,
          'longitude': -122.4194,
          'address': '123 Main Street, San Francisco, CA',
        },
      ),
      ChatMessage(
        id: '6',
        text: 'Perfect! I can see your location. I\'ll be there in 2 minutes. Please stay where you are.',
        isFromProvider: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        type: MessageType.text,
        status: MessageStatus.delivered,
      ),
    ];

    setState(() {
      _messages = messages;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _startTypingSimulation() {
    // Simulate patient typing occasionally
    Timer.periodic(const Duration(seconds: 45), (timer) {
      if (mounted && !_patientTyping) {
        _simulatePatientTyping();
      }
    });
  }

  void _simulatePatientTyping() {
    setState(() {
      _patientTyping = true;
    });
    
    _typingAnimationController.repeat();
    
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _patientTyping = false;
        });
        _typingAnimationController.stop();
        
        // Occasionally send an auto-reply from patient
        if (DateTime.now().second % 3 == 0) {
          _sendAutoReply();
        }
      }
    });
  }

  void _sendAutoReply() {
    final replies = [
      'Thank you for the update!',
      'I appreciate your professionalism',
      'Looking forward to your arrival',
      'The symptoms are stable now',
    ];
    
    final reply = replies[DateTime.now().second % replies.length];
    
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: reply,
      isFromProvider: false,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.delivered,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    _typingAnimationController.dispose();
    _typingTimer?.cancel();
    _autoReplyTimer?.cancel();
    super.dispose();
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

    // Check for emergency keywords
    final isEmergency = _isEmergencyMessage(content);

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: content,
      isFromProvider: true,
      timestamp: DateTime.now(),
      type: isEmergency ? MessageType.emergency : MessageType.text,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(newMessage);
      _isTyping = false;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate message delivery
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          newMessage.status = MessageStatus.delivered;
        });
      }
    });

    // Simulate message being read
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          newMessage.status = MessageStatus.read;
        });
      }
    });

    HapticFeedback.lightImpact();
  }

  bool _isEmergencyMessage(String message) {
    final emergencyKeywords = [
      'emergency', 'urgent', 'help', 'pain', 'bleeding', 
      'unconscious', 'breathing', 'chest pain', 'heart attack'
    ];
    
    return emergencyKeywords.any((keyword) => 
      message.toLowerCase().contains(keyword)
    );
  }

  void _sendQuickReply(String message) {
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isFromProvider: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(newMessage);
      _showQuickReplies = false;
    });

    _scrollToBottom();
    HapticFeedback.lightImpact();
  }

  void _onMessageChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });
    } else if (text.isEmpty && _isTyping) {
      setState(() {
        _isTyping = false;
      });
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_patientTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _patientTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          if (_showQuickReplies) _buildQuickReplies(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      toolbarHeight: 80,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildPatientAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.conversation['patientName'] ?? 'Patient',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: AppTheme.primaryColor),
          onPressed: () => _startVideoCall(),
        ),
        IconButton(
          icon: const Icon(Icons.call, color: AppTheme.primaryColor),
          onPressed: () => _startVoiceCall(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textPrimaryColor),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'emergency',
              child: Row(
                children: [
                  Icon(Icons.medical_services, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Emergency Protocol'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'location',
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text('Share Location'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'appointment',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text('Schedule Follow-up'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientAvatar() {
    final isOnline = widget.conversation['isOnline'] ?? false;
    return Stack(
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
                AppTheme.primaryColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  String _getStatusText() {
    if (_patientTyping) return 'typing...';
    if (widget.conversation['isOnline'] == true) return 'Online';
    return 'Last seen 1h ago';
  }

  Color _getStatusColor() {
    if (_patientTyping) return AppTheme.primaryColor;
    if (widget.conversation['isOnline'] == true) return const Color(0xFF10B981);
    return Colors.grey.shade500;
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    const SizedBox(width: 4),
                    _buildTypingDot(1),
                    const SizedBox(width: 4),
                    _buildTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    final delay = index * 0.2;
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        final animValue = (_typingAnimation.value - delay).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -4 * animValue),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromProvider 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isFromProvider) ...[
            _buildPatientAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isFromProvider 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isFromProvider ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: message.isFromProvider ? const Radius.circular(4) : null,
                      bottomLeft: !message.isFromProvider ? const Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type == MessageType.emergency)
                        _buildEmergencyBadge(),
                      if (message.type == MessageType.location)
                        _buildLocationMessage(message)
                      else
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.isFromProvider ? Colors.white : AppTheme.textPrimaryColor,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (message.isFromProvider) ...[
                      const SizedBox(width: 4),
                      _buildMessageStatusIcon(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (message.isFromProvider) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildEmergencyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '🚨 EMERGENCY',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocationMessage(ChatMessage message) {
    final locationData = message.locationData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, color: Colors.red, size: 16),
            SizedBox(width: 4),
            Text(
              'Location Shared',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 32, color: Colors.grey),
                SizedBox(height: 4),
                Text(
                  'Map Preview',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (locationData != null) ...[
          const SizedBox(height: 4),
          Text(
            locationData['address'] ?? 'Location',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icon(Icons.done, size: 14, color: Colors.grey.shade400);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: Colors.grey.shade400);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: Color(0xFF10B981));
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withOpacity(0.1),
                            AppTheme.primaryColor.withOpacity(0.05),
                          ],
                        ),
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
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _showQuickReplies ? Icons.keyboard : Icons.auto_awesome,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() {
                  _showQuickReplies = !_showQuickReplies;
                });
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.attach_file,
                color: AppTheme.primaryColor,
              ),
              onPressed: _showAttachmentOptions,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocus,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _isTyping 
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            ),
                          ),
                        )
                      : null,
                ),
                onChanged: _onMessageChanged,
                onSubmitted: (_) => _sendMessage(),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
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
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Send Attachment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildAttachmentOption(
                    Icons.camera_alt,
                    'Camera',
                    Colors.green,
                    () => _handleAttachment('camera'),
                  ),
                  _buildAttachmentOption(
                    Icons.photo_library,
                    'Gallery',
                    Colors.blue,
                    () => _handleAttachment('gallery'),
                  ),
                  _buildAttachmentOption(
                    Icons.description,
                    'Document',
                    Colors.orange,
                    () => _handleAttachment('document'),
                  ),
                  _buildAttachmentOption(
                    Icons.location_on,
                    'Location',
                    Colors.red,
                    () => _handleAttachment('location'),
                  ),
                  _buildAttachmentOption(
                    Icons.mic,
                    'Voice Note',
                    Colors.purple,
                    () => _handleAttachment('voice'),
                  ),
                  _buildAttachmentOption(
                    Icons.medical_services,
                    'Medical Report',
                    AppTheme.primaryColor,
                    () => _handleAttachment('medical'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAttachment(String type) {
    String message = '';
    MessageType messageType = MessageType.text;

    switch (type) {
      case 'camera':
        message = '📸 Photo captured and sent';
        break;
      case 'gallery':
        message = '🖼️ Image from gallery sent';
        break;
      case 'document':
        message = '📄 Document attached';
        break;
      case 'location':
        message = '📍 Current location shared';
        messageType = MessageType.location;
        break;
      case 'voice':
        message = '🎤 Voice message recorded';
        break;
      case 'medical':
        message = '🏥 Medical report attached';
        break;
    }

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isFromProvider: true,
      timestamp: DateTime.now(),
      type: messageType,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();
    HapticFeedback.lightImpact();
  }

  void _startVideoCall() {
    HapticFeedback.mediumImpact();
    _showCallDialog('Video Call', Icons.videocam);
  }

  void _startVoiceCall() {
    HapticFeedback.mediumImpact();
    _showCallDialog('Voice Call', Icons.call);
  }

  void _showCallDialog(String title, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text('Start $title with ${widget.conversation['patientName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateCall(title.toLowerCase());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _initiateCall(String callType) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '📞 $callType initiated',
      isFromProvider: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'emergency':
        _sendEmergencyMessage();
        break;
      case 'location':
        _shareLocation();
        break;
      case 'appointment':
        _scheduleFollowUp();
        break;
    }
  }

  void _sendEmergencyMessage() {
    final emergencyMessage = _emergencyResponses[0];
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: emergencyMessage,
      isFromProvider: true,
      timestamp: DateTime.now(),
      type: MessageType.emergency,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
    HapticFeedback.heavyImpact();
  }

  void _shareLocation() {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '📍 My current location',
      isFromProvider: true,
      timestamp: DateTime.now(),
      type: MessageType.location,
      status: MessageStatus.sent,
      locationData: {
        'latitude': 37.7849,
        'longitude': -122.4094,
        'address': '456 Medical Center Dr, San Francisco, CA',
      },
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
  }

  void _scheduleFollowUp() {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '📅 Follow-up appointment scheduled for tomorrow at 2:00 PM. You will receive a confirmation shortly.',
      isFromProvider: true,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
  }
}

// Supporting classes
class ChatMessage {
  final String id;
  final String text;
  final bool isFromProvider;
  final DateTime timestamp;
  final MessageType type;
  MessageStatus status;
  final Map<String, dynamic>? locationData;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromProvider,
    required this.timestamp,
    required this.type,
    required this.status,
    this.locationData,
  });
}

enum MessageType {
  text,
  emergency,
  location,
  image,
  voice,
  document,
}

enum MessageStatus {
  sent,
  delivered,
  read,
}