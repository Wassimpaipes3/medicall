import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../routes/app_routes.dart';
import '../../services/chat_service.dart';
import '../../services/provider_tracking_service.dart';
import '../../data/services/location_service.dart';

class ProviderChatScreen extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String? specialty;

  const ProviderChatScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    this.specialty,
  });

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ProviderTrackingService _trackingService = ProviderTrackingService();
  final LocationService _locationService = LocationService();
  
  bool _showQuickReplies = false;
  final bool _isProviderOnline = true;

  final List<String> _quickReplies = [
    "I'm here and ready",
    "Running 5 minutes late",
    "What's your location?",
    "Thank you",
    "I need directions",
    "Are you close?",
  ];

  @override
  void initState() {
    super.initState();
    _chatService.initializeConversation(widget.providerId);
    _chatService.markConversationAsRead(widget.providerId);
    _chatService.addListener(_onChatUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.removeListener(_onChatUpdate);
    super.dispose();
  }

  void _onChatUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    setState(() {});
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

    _chatService.sendMessage(widget.providerId, content, MessageType.text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _sendQuickReply(String message) {
    _chatService.sendMessage(widget.providerId, message, MessageType.text);
    setState(() {
      _showQuickReplies = false;
    });
    _scrollToBottom();
  }

  void _shareLocation() async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _chatService.sendLocationMessage(
          widget.providerId,
          location.latitude,
          location.longitude,
          location.address ?? 'Current location',
        );
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get location')),
        );
      }
    }
  }

  void _toggleQuickReplies() {
    setState(() {
      _showQuickReplies = !_showQuickReplies;
    });
  }

  Widget _buildMessage(ChatMessage message) {
    final isFromUser = message.isFromCurrentUser;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.local_hospital,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromUser 
                  ? AppTheme.primaryColor 
                  : AppTheme.backgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromUser ? 16 : 4),
                  bottomRight: Radius.circular(isFromUser ? 4 : 16),
                ),
                border: !isFromUser ? Border.all(
                  color: AppTheme.textLightColor.withOpacity(0.2),
                ) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: (isFromUser ? Colors.white : AppTheme.textSecondaryColor)
                          .withOpacity(0.7),
                      fontSize: AppTheme.fontSizeXSmall,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/avatar.png',
                  fit: BoxFit.cover,
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromCurrentUser ? Colors.white : AppTheme.textPrimaryColor,
            fontSize: AppTheme.fontSizeMedium,
            fontFamily: AppTheme.fontFamily,
          ),
        );
      case MessageType.location:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: message.isFromCurrentUser 
                  ? Colors.white.withOpacity(0.2) 
                  : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    color: message.isFromCurrentUser ? Colors.white : AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Location shared',
                    style: TextStyle(
                      color: message.isFromCurrentUser ? Colors.white : AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message.content,
                style: TextStyle(
                  color: message.isFromCurrentUser ? Colors.white : AppTheme.textPrimaryColor,
                  fontSize: AppTheme.fontSizeSmall,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            ],
          ],
        );
      case MessageType.system:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: AppTheme.fontSizeSmall,
              fontStyle: FontStyle.italic,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromCurrentUser ? Colors.white : AppTheme.textPrimaryColor,
            fontSize: AppTheme.fontSizeMedium,
            fontFamily: AppTheme.fontFamily,
          ),
        );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildTrackingInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider Location',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondaryColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _trackingService.isTracking 
                    ? '5 minutes away'
                    : 'Not currently tracking',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    fontFamily: AppTheme.fontFamily,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.liveTracking, arguments: {
                'appointmentId': 'demo-appointment-${DateTime.now().millisecondsSinceEpoch}',
              });
            },
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Track'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.textLightColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Replies',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickReplies.map((reply) {
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _sendQuickReply(reply),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      reply,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: AppTheme.fontSizeSmall,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _chatService.getConversationMessages(widget.providerId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 114, // Increased from 88 to 114 for much lower positioning from top
        titleSpacing: 12, // Added proper title spacing
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.local_hospital,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.providerName,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  Text(
                    'Healthcare Provider',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Add call functionality
              HapticFeedback.lightImpact();
            },
            icon: Icon(
              Icons.phone,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Column(
        children: [
          _buildTrackingInfo(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),
          Column(
            children: [
              // Quick replies section
              if (_showQuickReplies) _buildQuickReplies(),
              
              // Message input section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Location button
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _shareLocation,
                              icon: Icon(
                                Icons.location_on,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Quick replies toggle
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _toggleQuickReplies,
                              icon: Icon(
                                _showQuickReplies ? Icons.keyboard : Icons.apps,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Text input
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontFamily: AppTheme.fontFamily,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  color: AppTheme.textPrimaryColor,
                                  fontFamily: AppTheme.fontFamily,
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Send button
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _sendMessage,
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
