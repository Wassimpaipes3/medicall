import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../chat/patient_chat_screen.dart';
import '../provider/comprehensive_provider_chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedNotifications = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
    _loadNotifications();
  }

  /// Load notifications from Firebase
  Future<void> _loadNotifications() async {
    print('🔄 START: Loading notifications...');
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('🔔 Loading notifications for user: ${user.uid}');
      print('   Collection: notifications');
      print('   Filter: destinataire == ${user.uid}');

      // Try without orderBy first to see if data exists
      print('   Step 1: Checking if ANY notifications exist...');
      final allNotificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('destinataire', isEqualTo: user.uid)
          .limit(5)
          .get();

      print('   Found ${allNotificationsSnapshot.docs.length} notifications (without ordering)');
      
      if (allNotificationsSnapshot.docs.isEmpty) {
        print('   ℹ️ No notifications found for this user');
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
        return;
      }

      // Show sample notification structure
      if (allNotificationsSnapshot.docs.isNotEmpty) {
        final sampleDoc = allNotificationsSnapshot.docs.first;
        print('   Sample notification data:');
        print('   ${sampleDoc.data()}');
      }

      print('   Step 2: Loading with orderBy...');
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('destinataire', isEqualTo: user.uid)
          .orderBy('datetime', descending: true)
          .limit(50)
          .get();

      print('   Found ${notificationsSnapshot.docs.length} notifications (with ordering)');

      final List<Map<String, dynamic>> notifications = [];
      for (var doc in notificationsSnapshot.docs) {
        final data = doc.data();
        
        // Extract title from message (e.g., "🔔 Title text..." -> "Title")
        String fullMessage = data['message'] ?? '';
        String title = 'Notification';
        String message = fullMessage;
        
        // Split message into title and body if it contains emoji or special format
        if (fullMessage.contains('🔔')) {
          fullMessage = fullMessage.replaceFirst('🔔', '').trim();
          final parts = fullMessage.split('.');
          if (parts.isNotEmpty) {
            title = parts[0].trim();
            if (parts.length > 1) {
              message = parts.sublist(1).join('.').trim();
            } else {
              message = title;
            }
          }
        }
        
        final notification = {
          'id': doc.id,
          'title': title,
          'message': message.isNotEmpty ? message : fullMessage,
          'time': _formatTimestamp(data['datetime']),
          'type': data['type'] ?? 'general',
          'isRead': data['read'] ?? false,
          'icon': _getIconForType(data['type'] ?? 'general'),
          'color': _getColorForType(data['type'] ?? 'general'),
          'senderId': data['senderId'],
          'payload': data['payload'],
        };
        notifications.add(notification);
        print('   📬 $title: $message');
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      print('✅ Loaded ${_notifications.length} notifications successfully');
    } catch (e, stackTrace) {
      print('❌ Error loading notifications: $e');
      print('   Stack trace: $stackTrace');
      
      // Check for specific error types
      if (e.toString().contains('index')) {
        print('   ⚠️ INDEX ERROR: Firestore index might be missing!');
        print('   Solution: Deploy firestore indexes with: firebase deploy --only firestore:indexes');
      } else if (e.toString().contains('permission')) {
        print('   ⚠️ PERMISSION ERROR: Check Firestore security rules!');
      }
      
      setState(() {
        _isLoading = false;
      });
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Format Firestore timestamp to readable time ago
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Just now';
      }

      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks > 1 ? 's' : ''} ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  /// Get icon based on notification type
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
      case 'rendez_vous':
        return Icons.calendar_today_rounded;
      case 'message':
      case 'chat':
        return Icons.message_rounded;
      case 'report':
      case 'rapport':
      case 'result':
        return Icons.assignment_rounded;
      case 'medication':
      case 'medicament':
        return Icons.medication_rounded;
      case 'payment':
      case 'paiement':
        return Icons.payment_rounded;
      case 'booking':
      case 'reservation':
        return Icons.book_online_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// Get color based on notification type
  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
      case 'rendez_vous':
        return Colors.blue;
      case 'message':
      case 'chat':
        return Colors.purple;
      case 'report':
      case 'rapport':
      case 'result':
        return Colors.green;
      case 'medication':
      case 'medicament':
        return Colors.orange;
      case 'payment':
      case 'paiement':
        return Colors.teal;
      case 'booking':
      case 'reservation':
        return Colors.indigo;
      default:
        return AppTheme.primaryColor;
    }
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

  /// Mark notification as read in Firebase
  Future<void> _markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
        }
      });

      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read in Firebase
  Future<void> _markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get all unread notifications
      final unreadNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('destinataire', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();

      // Mark each as read
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      setState(() {
        for (var notification in _notifications) {
          notification['isRead'] = true;
        }
      });

      print('✅ All notifications marked as read');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark notifications as read'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Delete a single notification
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();

      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        _selectedNotifications.remove(notificationId);
      });

      print('✅ Notification deleted: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete notification'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Delete selected notifications
  Future<void> _deleteSelectedNotifications() async {
    if (_selectedNotifications.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (var notificationId in _selectedNotifications) {
        final docRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc(notificationId);
        batch.delete(docRef);
      }

      await batch.commit();

      setState(() {
        _notifications.removeWhere((n) => _selectedNotifications.contains(n['id']));
        final count = _selectedNotifications.length;
        _selectedNotifications.clear();
        _isSelectionMode = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count notification${count > 1 ? 's' : ''} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      });

      print('✅ Deleted ${_selectedNotifications.length} notifications');
    } catch (e) {
      print('❌ Error deleting selected notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete notifications'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Delete all notifications
  Future<void> _deleteAllNotifications() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications?'),
        content: Text('This will permanently delete all ${_notifications.length} notifications. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get all user's notifications
      final allNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('destinataire', isEqualTo: user.uid)
          .get();

      // Delete in batch
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in allNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      setState(() {
        _notifications.clear();
        _selectedNotifications.clear();
        _isSelectionMode = false;
      });

      print('✅ All notifications deleted');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete notifications'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNotifications.clear();
      }
    });
  }

  /// Toggle notification selection
  void _toggleNotificationSelection(String notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
      } else {
        _selectedNotifications.add(notificationId);
      }
    });
  }

  /// Handle notification tap - Navigate to relevant screen
  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final type = (notification['type'] ?? '').toLowerCase();
    final payload = notification['payload'] as Map<String, dynamic>?;

    print('🔔 Handling notification tap: type=$type');

    try {
      switch (type) {
        case 'message':
        case 'chat':
          await _navigateToChat(notification, payload);
          break;

        case 'appointment':
        case 'rendez_vous':
        case 'booking':
        case 'reservation':
          // Navigate to appointments screen
          if (mounted) {
            Navigator.pushNamed(context, '/appointments');
          }
          break;

        default:
          print('ℹ️ No specific action for notification type: $type');
          break;
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open notification'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Navigate to appropriate chat screen based on user role
  Future<void> _navigateToChat(Map<String, dynamic> notification, Map<String, dynamic>? payload) async {
    try {
      final senderId = payload?['senderId'] ?? notification['senderId'];
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (senderId == null || senderId.toString().isEmpty) {
        print('❌ No sender ID found in notification');
        return;
      }

      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }

      print('   Loading sender info for: $senderId');
      print('   Current user: ${currentUser.uid}');

      // Get current user's role
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!currentUserDoc.exists) {
        print('❌ Current user document not found');
        return;
      }

      final currentUserRole = currentUserDoc.data()?['role'] ?? 'patient';
      print('   Current user role: $currentUserRole');

      // Fetch sender information from Firestore
      final senderInfo = await _getProviderInfo(senderId);
      
      if (senderInfo == null) {
        print('❌ Could not load sender information');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load sender information'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('✅ Sender info loaded: ${senderInfo['name']} (${senderInfo['role']})');

      // Navigate to appropriate chat screen based on current user's role
      if (mounted) {
        if (currentUserRole == 'patient') {
          // Patient tapped notification from provider -> PatientChatScreen
          print('   Navigating to PatientChatScreen...');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientChatScreen(
                doctorInfo: senderInfo,
                appointmentId: payload?['appointmentId'],
              ),
            ),
          );
        } else {
          // Provider tapped notification from patient -> ComprehensiveProviderChatScreen
          print('   Navigating to ComprehensiveProviderChatScreen...');
          
          // Build conversation object for ComprehensiveProviderChatScreen
          final conversationData = {
            'id': senderId,
            'userId': senderId,
            'patientId': senderId,
            'patientName': senderInfo['name'],
            'patientAvatar': senderInfo['avatar'],
            'lastMessage': notification['message'] ?? 'New message',
            'lastMessageTime': notification['time'] ?? 'Now',
            'unreadCount': 0,
            'isOnline': true,
            'serviceType': 'Chat',
            'status': 'active',
            'timestamp': DateTime.now(),
          };
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComprehensiveProviderChatScreen(
                conversation: conversationData,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error navigating to chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get provider/user information from Firestore
  /// Works for both professionals (doctors/nurses) and patients
  Future<Map<String, dynamic>?> _getProviderInfo(String userId) async {
    try {
      // First, get basic user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('❌ User not found: $userId');
        return null;
      }

      final userData = userDoc.data()!;
      final prenom = userData['prenom'] ?? '';
      final nom = userData['nom'] ?? '';
      final photoProfile = userData['photo_profile'];
      final role = userData['role'] ?? 'patient';

      // Try to get professional info (might not exist if sender is a patient)
      final professionalDoc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(userId)
          .get();

      String displayName;
      String profession = '';
      String specialite = '';
      bool isNurse = false;
      String? avatar = photoProfile;

      if (professionalDoc.exists) {
        // This is a professional (doctor/nurse)
        final professionalData = professionalDoc.data()!;
        profession = professionalData['profession'] ?? '';
        specialite = professionalData['specialite'] ?? '';
        final photoUrl = professionalData['photo_url'];
        
        // Determine if nurse or doctor
        isNurse = profession.toLowerCase().contains('nurse') || 
                  profession.toLowerCase().contains('infirmier');
        
        // Build name with proper prefix
        displayName = isNurse ? '$prenom $nom' : 'Dr. $prenom $nom';
        
        // Use photo_profile if available, otherwise photo_url
        avatar = photoProfile ?? photoUrl;
        
        print('   Professional info: $displayName (${isNurse ? 'Nurse' : 'Doctor'})');
      } else {
        // This is a patient or regular user
        displayName = '$prenom $nom';
        profession = 'patient';
        print('   Patient info: $displayName');
      }

      final userInfo = {
        'id': userId,
        'name': displayName,
        'prenom': prenom,
        'nom': nom,
        'specialty': specialite,
        'profession': profession,
        'avatar': avatar,
        'isNurse': isNurse,
        'role': role,
      };
      
      return userInfo;
    } catch (e) {
      print('❌ Error fetching user info: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 114, // Increased from 88 to 114 for much lower positioning from top
        titleSpacing: 12, // Added proper title spacing
        leading: IconButton(
          iconSize: 24, // Increased icon size
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textPrimaryColor,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 22, // Increased from 20 to 22
          ),
        ),
        actions: [
          // Selection mode - show delete button for selected
          if (_isSelectionMode && _selectedNotifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelectedNotifications,
              tooltip: 'Delete ${_selectedNotifications.length} selected',
            ),
          
          // Selection mode - show cancel button
          if (_isSelectionMode)
            TextButton(
              onPressed: _toggleSelectionMode,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          // Normal mode - show mark all read button
          if (!_isSelectionMode && unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          
          // Normal mode - show menu with delete options
          if (!_isSelectionMode && _notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.textPrimaryColor),
              onSelected: (value) {
                switch (value) {
                  case 'select':
                    _toggleSelectionMode();
                    break;
                  case 'delete_all':
                    _deleteAllNotifications();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.checklist, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Select Notifications'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Delete All'),
                    ],
                  ),
                ),
              ],
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
              child: _buildNotificationsList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList() {
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
              'Loading notifications...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _notifications.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }
          
          final notification = _notifications[index - 1];
          return _buildNotificationCard(notification, index - 1);
        },
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
    
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
              Icons.notifications_rounded,
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
                      ? 'You have $unreadCount unread notifications'
                      : 'All caught up!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Stay updated with your health',
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

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final notificationId = notification['id'];
    final isSelected = _selectedNotifications.contains(notificationId);
    
    return Dismissible(
      key: Key(notificationId),
      direction: _isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification?'),
            content: const Text('Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteNotification(notificationId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : notification['isRead']
                  ? null
                  : Border.all(
                      color: notification['color'].withOpacity(0.3),
                      width: 1,
                    ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              
              if (_isSelectionMode) {
                // In selection mode, toggle selection
                _toggleNotificationSelection(notificationId);
              } else {
                // Normal mode - mark as read and navigate
                if (!notification['isRead']) {
                  _markAsRead(notification['id']);
                }
                _handleNotificationTap(notification);
              }
            },
            onLongPress: () {
              // Long press enters selection mode
              if (!_isSelectionMode) {
                HapticFeedback.mediumImpact();
                setState(() {
                  _isSelectionMode = true;
                  _selectedNotifications.add(notificationId);
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selection checkbox (only in selection mode)
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        _toggleNotificationSelection(notificationId);
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: notification['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notification['icon'],
                      color: notification['color'],
                      size: 24,
                    ),
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
                                notification['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: notification['isRead'] 
                                      ? FontWeight.w600 
                                      : FontWeight.w700,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                            if (!notification['isRead'] && !_isSelectionMode)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: notification['color'],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          notification['message'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondaryColor,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          notification['time'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondaryColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              Icons.notifications_none_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll receive notifications about appointments,\nmessages, and health updates here',
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
