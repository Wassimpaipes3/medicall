import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../core/services/call_service.dart';
import '../../routes/app_routes.dart';
import '../../services/provider/provider_service.dart';
import '../../widgets/provider/provider_navigation_bar.dart';

class EnhancedMessagesScreen extends StatefulWidget {
  const EnhancedMessagesScreen({super.key});

  @override
  State<EnhancedMessagesScreen> createState() => _EnhancedMessagesScreenState();
}

class _EnhancedMessagesScreenState extends State<EnhancedMessagesScreen>
    with TickerProviderStateMixin {
  final ProviderService _providerService = ProviderService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<ProviderMessage> _allMessages = [];
  List<ProviderMessage> _filteredMessages = [];
  Map<String, List<ProviderMessage>> _groupedMessages = {};
  
  bool _isLoading = true;
  String _searchQuery = '';
  MessageType? _selectedFilter;
  Timer? _refreshTimer;

  final List<MessageType> _filterOptions = [
    MessageType.appointment,
    MessageType.emergency,
    MessageType.general,
    MessageType.payment,
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMessages();
    _startPeriodicRefresh();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _loadMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      await _providerService.initialize();
      final messages = await _providerService.getMessages();
      
      setState(() {
        _allMessages = messages;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load messages: $e');
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredMessages = _allMessages.where((message) {
      final matchesSearch = _searchQuery.isEmpty ||
          message.senderName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          message.content.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _selectedFilter == null || message.type == _selectedFilter;
      
      return matchesSearch && matchesFilter;
    }).toList();

    _groupedMessages = _groupMessagesByDate(_filteredMessages);
  }

  Map<String, List<ProviderMessage>> _groupMessagesByDate(List<ProviderMessage> messages) {
    final grouped = <String, List<ProviderMessage>>{};
    
    for (final message in messages) {
      final dateKey = _getDateKey(message.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(message);
    }
    
    // Sort messages within each group by timestamp (newest first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
    
    return grouped;
  }

  String _getDateKey(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildMessagesList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ProviderNavigationBar(
        selectedIndex: 2,
        onTap: (index) => _handleNavigation(index),
      ),
      floatingActionButton: _buildComposeButton(),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _allMessages.where((m) => !m.isRead).length;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimaryColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$unreadCount new',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear, color: AppTheme.textSecondaryColor),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                ..._filterOptions.map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildFilterChip(_getFilterLabel(filter), filter),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, MessageType? filter) {
    final isSelected = _selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? null : filter;
          _applyFilters();
        });
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _getFilterLabel(MessageType type) {
    switch (type) {
      case MessageType.appointment:
        return 'Appointments';
      case MessageType.emergency:
        return 'Emergency';
      case MessageType.general:
        return 'General';
      case MessageType.payment:
        return 'Payment';
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_filteredMessages.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _groupedMessages.length,
        itemBuilder: (context, index) {
          final dateKey = _groupedMessages.keys.elementAt(index);
          final messages = _groupedMessages[dateKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(dateKey),
              ...messages.map((message) => _buildMessageCard(message)),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.message,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? 'No messages found' : 'No messages yet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try adjusting your search terms or filters.'
                  : 'Messages from patients will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(ProviderMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _openMessage(message),
        onLongPress: () => _showMessageOptions(message),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: message.isRead 
                  ? Colors.grey.withOpacity(0.2)
                  : AppTheme.primaryColor.withOpacity(0.3),
              width: message.isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: message.isRead 
                    ? Colors.black.withOpacity(0.05)
                    : AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageAvatar(message),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: message.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        _buildMessageTypeChip(message.type),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: message.isRead 
                            ? AppTheme.textSecondaryColor
                            : AppTheme.textPrimaryColor,
                        fontWeight: message.isRead ? FontWeight.normal : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const Spacer(),
                        if (!message.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
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

  Widget _buildMessageAvatar(ProviderMessage message) {
    Color avatarColor;
    IconData avatarIcon;
    
    switch (message.type) {
      case MessageType.emergency:
        avatarColor = Colors.red;
        avatarIcon = Icons.local_hospital;
        break;
      case MessageType.appointment:
        avatarColor = Colors.blue;
        avatarIcon = Icons.calendar_today;
        break;
      case MessageType.payment:
        avatarColor = Colors.green;
        avatarIcon = Icons.payment;
        break;
      case MessageType.general:
      default:
        avatarColor = AppTheme.primaryColor;
        avatarIcon = Icons.person;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: avatarColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: avatarColor.withOpacity(0.3)),
      ),
      child: Icon(
        avatarIcon,
        color: avatarColor,
        size: 20,
      ),
    );
  }

  Widget _buildMessageTypeChip(MessageType type) {
    Color chipColor;
    String chipText;
    
    switch (type) {
      case MessageType.emergency:
        chipColor = Colors.red;
        chipText = 'URGENT';
        break;
      case MessageType.appointment:
        chipColor = Colors.blue;
        chipText = 'APPT';
        break;
      case MessageType.payment:
        chipColor = Colors.green;
        chipText = 'PAY';
        break;
      case MessageType.general:
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        chipText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComposeButton() {
    return FloatingActionButton(
      onPressed: _composeMessage,
      backgroundColor: AppTheme.primaryColor,
      child: const Icon(Icons.edit, color: Colors.white),
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _openMessage(ProviderMessage message) async {
    HapticFeedback.lightImpact();
    
    if (!message.isRead) {
      try {
        await _providerService.markMessageAsRead(message.id);
        await _loadMessages();
      } catch (e) {
        _showErrorSnackBar('Failed to mark message as read: $e');
      }
    }
    
    // Open detailed message view
    _showMessageDetails(message);
  }

  void _showMessageDetails(ProviderMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  _buildMessageAvatar(message),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          _formatMessageTime(message.timestamp),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimaryColor,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _replyToMessage(message);
                            },
                            icon: const Icon(Icons.reply),
                            label: const Text('Reply'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _callSender(message.senderPhone);
                            },
                            icon: const Icon(Icons.call, color: Colors.white),
                            label: const Text('Call', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
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
      ),
    );
  }

  void _showMessageOptions(ProviderMessage message) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: AppTheme.primaryColor),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.call, color: Colors.green),
              title: const Text('Call'),
              onTap: () {
                Navigator.pop(context);
                _callSender(message.senderPhone);
              },
            ),
            ListTile(
              leading: Icon(
                message.isRead ? Icons.mark_as_unread : Icons.mark_email_read,
                color: Colors.blue,
              ),
              title: Text(message.isRead ? 'Mark as Unread' : 'Mark as Read'),
              onTap: () {
                Navigator.pop(context);
                _toggleReadStatus(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _composeMessage() {
    HapticFeedback.lightImpact();
    _showInfoSnackBar('Opening message composer...');
    // Implement message composition screen
  }

  void _replyToMessage(ProviderMessage message) {
    HapticFeedback.lightImpact();
    _showInfoSnackBar('Opening reply to ${message.senderName}...');
    // Implement reply functionality
  }

  void _callSender(String phoneNumber) {
    CallService.makeCall(
      phoneNumber,
      context: context,
    );
  }

  void _toggleReadStatus(ProviderMessage message) async {
    try {
      if (message.isRead) {
        await _providerService.markMessageAsUnread(message.id);
      } else {
        await _providerService.markMessageAsRead(message.id);
      }
      await _loadMessages();
    } catch (e) {
      _showErrorSnackBar('Failed to update message status: $e');
    }
  }

  void _deleteMessage(ProviderMessage message) async {
    try {
      await _providerService.deleteMessage(message.id);
      await _loadMessages();
      _showInfoSnackBar('Message deleted');
    } catch (e) {
      _showErrorSnackBar('Failed to delete message: $e');
    }
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.providerDashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.enhancedAppointmentManagement);
        break;
      case 2:
        // Already on messages
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRoutes.enhancedEarnings);
        break;
      case 4:
        Navigator.pushReplacementNamed(context, AppRoutes.providerProfile);
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
