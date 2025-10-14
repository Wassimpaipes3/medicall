import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../chat/patient_chat_screen.dart';

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

  /// Navigate to chat screen with provider
  Future<void> _navigateToChat(Map<String, dynamic> notification, Map<String, dynamic>? payload) async {
    try {
      final senderId = payload?['senderId'] ?? notification['senderId'];
      
      if (senderId == null || senderId.toString().isEmpty) {
        print('❌ No sender ID found in notification');
        return;
      }

      print('   Loading provider info for: $senderId');

      // Fetch provider information from Firestore
      final providerInfo = await _getProviderInfo(senderId);
      
      if (providerInfo == null) {
        print('❌ Could not load provider information');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load provider information'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('✅ Provider info loaded, navigating to chat...');

      // Navigate to patient chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientChatScreen(
              doctorInfo: providerInfo,
              appointmentId: payload?['appointmentId'],
            ),
          ),
        );
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

  /// Get provider information from Firestore
  Future<Map<String, dynamic>?> _getProviderInfo(String providerId) async {
    try {
      // First, get basic user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(providerId)
          .get();

      if (!userDoc.exists) {
        print('❌ User not found: $providerId');
        return null;
      }

      final userData = userDoc.data()!;
      final prenom = userData['prenom'] ?? '';
      final nom = userData['nom'] ?? '';
      final photoProfile = userData['photo_profile'];

      // Then get professional info
      final professionalDoc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(providerId)
          .get();

      if (!professionalDoc.exists) {
        print('❌ Professional not found: $providerId');
        return null;
      }

      final professionalData = professionalDoc.data()!;
      final profession = professionalData['profession'] ?? '';
      final specialite = professionalData['specialite'] ?? '';
      final photoUrl = professionalData['photo_url'];
      
      // Determine if nurse or doctor
      final isNurse = profession.toLowerCase().contains('nurse') || 
                     profession.toLowerCase().contains('infirmier');
      
      // Build name with proper prefix
      final displayName = isNurse ? '$prenom $nom' : 'Dr. $prenom $nom';
      
      // Use photo_profile if available, otherwise photo_url
      final avatar = photoProfile ?? photoUrl;

      final providerInfo = {
        'id': providerId,
        'name': displayName,
        'prenom': prenom,
        'nom': nom,
        'specialty': specialite,
        'profession': profession,
        'avatar': avatar,
        'isNurse': isNurse,
      };

      print('   Provider info: $displayName (${isNurse ? 'Nurse' : 'Doctor'})');
      
      return providerInfo;
    } catch (e) {
      print('❌ Error fetching provider info: $e');
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
          if (unreadCount > 0)
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
        border: notification['isRead']
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
            if (!notification['isRead']) {
              _markAsRead(notification['id']);
            }
            // Handle navigation based on notification type
            _handleNotificationTap(notification);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          if (!notification['isRead'])
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
