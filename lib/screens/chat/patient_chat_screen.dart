import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../services/chat_service.dart';

class PatientChatScreen extends StatefulWidget {
  final Map<String, dynamic> doctorInfo;
  final String? appointmentId;

  const PatientChatScreen({
    super.key,
    required this.doctorInfo,
    this.appointmentId,
  });

  @override
  State<PatientChatScreen> createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocus = FocusNode();
  final ChatService _chatService = ChatService();
  
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;
  late String _doctorId;
  
  List<PatientChatMessage> _messages = [];
  bool _showQuickReplies = false;
  bool _isTyping = false;
  final bool _doctorTyping = false;
  Timer? _typingTimer;

  final List<String> _patientQuickReplies = [
    "Thank you, Doctor 🙏",
    "When is my next appointment? 📅",
    "I'm feeling better now ✅",
    "I have some concerns 😟",
    "Can you clarify the dosage? 💊",
    "I need to reschedule 🔄",
    "This is urgent! 🚨",
    "I'm experiencing side effects 💊",
  ];

  @override
  void initState() {
    super.initState();
    _doctorId = widget.doctorInfo['id'] ?? widget.doctorInfo['userId'] ?? '';
    _initializeAnimations();
    _initializeChat();
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

  void _initializeChat() {
    print('🔵 PATIENT: Initializing chat for doctor: $_doctorId');
    
    // Initialize conversation with real-time Firestore listener
    _chatService.initializeConversation(_doctorId);
    
    // Mark messages as read
    _chatService.markConversationAsRead(_doctorId);
    
    // Listen to chat service updates
    _chatService.addListener(_onChatUpdate);
    
    // Load initial messages
    _loadMessages();
  }

  void _onChatUpdate() {
    print('🔔 PATIENT: Chat update received');
    if (mounted) {
      _loadMessages();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _loadMessages() {
    print('📥 PATIENT: Loading messages for doctor: $_doctorId');
    final chatMessages = _chatService.getConversationMessages(_doctorId);
    print('📊 PATIENT: Retrieved ${chatMessages.length} messages from ChatService');
    
    if (chatMessages.isNotEmpty) {
      print('📝 PATIENT: First message: ${chatMessages.first.content}');
      print('📝 PATIENT: Last message: ${chatMessages.last.content}');
    } else {
      print('⚠️ PATIENT: No messages returned from ChatService!');
    }
    
    setState(() {
      _messages = chatMessages.map((msg) {
        return PatientChatMessage(
          id: msg.id,
          text: msg.content,
          isFromPatient: msg.isFromCurrentUser,
          timestamp: msg.timestamp,
          type: _getMessageType(msg.type),
          status: msg.isFromCurrentUser 
              ? PatientMessageStatus.delivered 
              : PatientMessageStatus.read,
        );
      }).toList();
    });
    
    print('✅ PATIENT: setState called with ${_messages.length} messages');
  }

  PatientMessageType _getMessageType(MessageType type) {
    switch (type) {
      case MessageType.system:
        return PatientMessageType.appointment;
      case MessageType.location:
      case MessageType.image:
      case MessageType.file:
        return PatientMessageType.medicalRecord;
      default:
        return PatientMessageType.text;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocus.dispose();
    _typingAnimationController.dispose();
    _typingTimer?.cancel();
    _chatService.removeListener(_onChatUpdate);
    _chatService.disposeConversation(_doctorId);
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

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    print('📤 PATIENT: Attempting to send message to doctor: $_doctorId');
    print('📝 PATIENT: Message content: $content');

    // Clear input immediately for better UX
    _messageController.clear();
    setState(() {
      _isTyping = false;
    });

    // Send message to Firestore via ChatService
    print('🔥 PATIENT: Calling ChatService.sendMessage()');
    await _chatService.sendMessage(
      _doctorId,
      content,
      MessageType.text,
    );
    print('✅ PATIENT: sendMessage() completed');

    // Mark as read (since we're viewing the chat)
    await _chatService.markConversationAsRead(_doctorId);

    _scrollToBottom();
    HapticFeedback.lightImpact();
  }

  void _sendQuickReply(String message) async {
    setState(() {
      _showQuickReplies = false;
    });

    // Send quick reply to Firestore via ChatService
    await _chatService.sendMessage(
      _doctorId,
      message,
      MessageType.text,
    );

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildDoctorInfoCard(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_doctorTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _doctorTyping) {
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
      toolbarHeight: 70,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildDoctorAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dr. ${widget.doctorInfo['name'] ?? 'Doctor'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  _getDoctorStatusText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getDoctorStatusColor(),
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
          onPressed: () => _requestVideoCall(),
        ),
        IconButton(
          icon: const Icon(Icons.call, color: AppTheme.primaryColor),
          onPressed: () => _requestVoiceCall(),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textPrimaryColor),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'appointment',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text('Schedule Appointment'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'medical_records',
              child: Row(
                children: [
                  Icon(Icons.folder_shared, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Text('Share Medical Records'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'emergency',
              child: Row(
                children: [
                  Icon(Icons.local_hospital, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Report Emergency'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoctorAvatar() {
    final isOnline = widget.doctorInfo['isOnline'] ?? true;
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
          child: Icon(
            widget.doctorInfo['avatar'] != null ? Icons.person : Icons.local_hospital,
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

  Widget _buildDoctorInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildDoctorAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${widget.doctorInfo['name'] ?? 'Doctor'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  widget.doctorInfo['specialty'] ?? 'General Physician',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.doctorInfo['rating'] ?? '4.8'} • ${widget.doctorInfo['experience'] ?? '10+'} years exp',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Online',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDoctorStatusText() {
    if (_doctorTyping) return 'typing...';
    if (widget.doctorInfo['isOnline'] == true) return 'Online';
    return 'Last seen 2h ago';
  }

  Color _getDoctorStatusColor() {
    if (_doctorTyping) return AppTheme.primaryColor;
    if (widget.doctorInfo['isOnline'] == true) return const Color(0xFF10B981);
    return Colors.grey.shade500;
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildDoctorAvatar(),
          const SizedBox(width: 8),
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

  Widget _buildMessageBubble(PatientChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isFromPatient 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isFromPatient) ...[
            _buildDoctorAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isFromPatient 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isFromPatient 
                        ? AppTheme.primaryColor 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: message.isFromPatient ? const Radius.circular(4) : null,
                      bottomLeft: !message.isFromPatient ? const Radius.circular(4) : null,
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
                      if (message.type == PatientMessageType.urgent)
                        _buildUrgentBadge(),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.isFromPatient 
                              ? Colors.white 
                              : AppTheme.textPrimaryColor,
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
                    if (message.isFromPatient) ...[
                      const SizedBox(width: 4),
                      _buildMessageStatusIcon(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (message.isFromPatient) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildUrgentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        '🚨 URGENT',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(PatientMessageStatus status) {
    switch (status) {
      case PatientMessageStatus.sent:
        return Icon(Icons.done, size: 14, color: Colors.grey.shade400);
      case PatientMessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: Colors.grey.shade400);
      case PatientMessageStatus.read:
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
              itemCount: _patientQuickReplies.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _sendQuickReply(_patientQuickReplies[index]),
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
                        _patientQuickReplies[index],
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
                  hintText: 'Ask your doctor...',
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
                  'Share with Doctor',
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
                    Icons.local_hospital,
                    'Symptoms',
                    AppTheme.primaryColor,
                    () => _handleAttachment('symptoms'),
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

    switch (type) {
      case 'camera':
        message = '📸 Photo shared with doctor';
        break;
      case 'gallery':
        message = '🖼️ Image from gallery shared';
        break;
      case 'document':
        message = '📄 Medical document shared';
        break;
      case 'location':
        message = '📍 Current location shared';
        break;
      case 'voice':
        message = '🎤 Voice message recorded';
        break;
      case 'symptoms':
        message = '🏥 Symptom report submitted';
        break;
    }

    final newMessage = PatientChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: message,
      isFromPatient: true,
      timestamp: DateTime.now(),
      type: PatientMessageType.text,
      status: PatientMessageStatus.sent,
    );

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();
    HapticFeedback.lightImpact();
  }

  void _requestVideoCall() {
    HapticFeedback.mediumImpact();
    _showCallDialog('Video Call Request', Icons.videocam);
  }

  void _requestVoiceCall() {
    HapticFeedback.mediumImpact();
    _showCallDialog('Voice Call Request', Icons.call);
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
        content: Text('Request $title with Dr. ${widget.doctorInfo['name']}?\\n\\nThis will send a call request that the doctor can accept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendCallRequest(title.toLowerCase());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _sendCallRequest(String callType) {
    final message = PatientChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '📞 $callType requested - waiting for doctor to accept',
      isFromPatient: true,
      timestamp: DateTime.now(),
      type: PatientMessageType.text,
      status: PatientMessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'appointment':
        _scheduleAppointment();
        break;
      case 'medical_records':
        _shareMedicalRecords();
        break;
      case 'emergency':
        _reportEmergency();
        break;
    }
  }

  void _scheduleAppointment() {
    final message = PatientChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '📅 I would like to schedule an appointment. Please let me know your available slots.',
      isFromPatient: true,
      timestamp: DateTime.now(),
      type: PatientMessageType.text,
      status: PatientMessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
  }

  void _shareMedicalRecords() {
    final message = PatientChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '📋 Medical records and test results shared',
      isFromPatient: true,
      timestamp: DateTime.now(),
      type: PatientMessageType.text,
      status: PatientMessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
  }

  void _reportEmergency() {
    final message = PatientChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: '🚨 EMERGENCY: I need immediate medical attention!',
      isFromPatient: true,
      timestamp: DateTime.now(),
      type: PatientMessageType.urgent,
      status: PatientMessageStatus.sent,
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();
    HapticFeedback.heavyImpact();
  }
}

// Supporting classes
class PatientChatMessage {
  final String id;
  final String text;
  final bool isFromPatient;
  final DateTime timestamp;
  final PatientMessageType type;
  PatientMessageStatus status;

  PatientChatMessage({
    required this.id,
    required this.text,
    required this.isFromPatient,
    required this.timestamp,
    required this.type,
    required this.status,
  });
}

enum PatientMessageType {
  text,
  urgent,
  appointment,
  medicalRecord,
}

enum PatientMessageStatus {
  sent,
  delivered,
  read,
}