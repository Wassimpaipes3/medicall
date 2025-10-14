import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to fetch analytics data for provider dashboard charts
class ProviderAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get earnings data over time periods
  static Future<List<EarningsData>> getEarningsAnalytics({
    required AnalyticsPeriod period,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      List<EarningsData> earningsData = [];
      
      switch (period) {
        case AnalyticsPeriod.daily:
          // Get last 7 days
          for (int i = 6; i >= 0; i--) {
            final date = now.subtract(Duration(days: i));
            final dayStart = DateTime(date.year, date.month, date.day);
            final dayEnd = dayStart.add(const Duration(days: 1));
            
            final earnings = await _getEarningsForPeriod(user.uid, dayStart, dayEnd);
            earningsData.add(EarningsData(
              date: dayStart,
              amount: earnings,
              label: _formatDateLabel(dayStart, period),
            ));
          }
          break;
          
        case AnalyticsPeriod.weekly:
          // Get last 8 weeks
          for (int i = 7; i >= 0; i--) {
            final weekStart = now.subtract(Duration(days: (now.weekday - 1) + (i * 7)));
            final weekEnd = weekStart.add(const Duration(days: 7));
            
            final earnings = await _getEarningsForPeriod(user.uid, weekStart, weekEnd);
            earningsData.add(EarningsData(
              date: weekStart,
              amount: earnings,
              label: _formatDateLabel(weekStart, period),
            ));
          }
          break;
          
        case AnalyticsPeriod.monthly:
          // Get last 6 months
          for (int i = 5; i >= 0; i--) {
            final monthStart = DateTime(now.year, now.month - i, 1);
            final monthEnd = DateTime(now.year, now.month - i + 1, 1);
            
            final earnings = await _getEarningsForPeriod(user.uid, monthStart, monthEnd);
            earningsData.add(EarningsData(
              date: monthStart,
              amount: earnings,
              label: _formatDateLabel(monthStart, period),
            ));
          }
          break;
      }
      
      return earningsData;
    } catch (e) {
      print('❌ Error fetching earnings analytics: $e');
      return [];
    }
  }

  /// Get appointments completion data over time
  static Future<List<AppointmentData>> getAppointmentsAnalytics({
    required AnalyticsPeriod period,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final now = DateTime.now();
      List<AppointmentData> appointmentData = [];
      
      switch (period) {
        case AnalyticsPeriod.daily:
          // Get last 7 days
          for (int i = 6; i >= 0; i--) {
            final date = now.subtract(Duration(days: i));
            final dayStart = DateTime(date.year, date.month, date.day);
            final dayEnd = dayStart.add(const Duration(days: 1));
            
            final stats = await _getAppointmentStatsForPeriod(user.uid, dayStart, dayEnd);
            appointmentData.add(AppointmentData(
              date: dayStart,
              completed: stats['completed'] ?? 0,
              pending: stats['pending'] ?? 0,
              cancelled: stats['cancelled'] ?? 0,
              label: _formatDateLabel(dayStart, period),
            ));
          }
          break;
          
        case AnalyticsPeriod.weekly:
          // Get last 8 weeks
          for (int i = 7; i >= 0; i--) {
            final weekStart = now.subtract(Duration(days: (now.weekday - 1) + (i * 7)));
            final weekEnd = weekStart.add(const Duration(days: 7));
            
            final stats = await _getAppointmentStatsForPeriod(user.uid, weekStart, weekEnd);
            appointmentData.add(AppointmentData(
              date: weekStart,
              completed: stats['completed'] ?? 0,
              pending: stats['pending'] ?? 0,
              cancelled: stats['cancelled'] ?? 0,
              label: _formatDateLabel(weekStart, period),
            ));
          }
          break;
          
        case AnalyticsPeriod.monthly:
          // Get last 6 months
          for (int i = 5; i >= 0; i--) {
            final monthStart = DateTime(now.year, now.month - i, 1);
            final monthEnd = DateTime(now.year, now.month - i + 1, 1);
            
            final stats = await _getAppointmentStatsForPeriod(user.uid, monthStart, monthEnd);
            appointmentData.add(AppointmentData(
              date: monthStart,
              completed: stats['completed'] ?? 0,
              pending: stats['pending'] ?? 0,
              cancelled: stats['cancelled'] ?? 0,
              label: _formatDateLabel(monthStart, period),
            ));
          }
          break;
      }
      
      return appointmentData;
    } catch (e) {
      print('❌ Error fetching appointments analytics: $e');
      return [];
    }
  }

  /// Get ratings distribution data
  static Future<List<RatingData>> getRatingsAnalytics({
    AnalyticsPeriod period = AnalyticsPeriod.weekly,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Calculate date range based on period
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case AnalyticsPeriod.daily:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case AnalyticsPeriod.weekly:
          startDate = now.subtract(Duration(days: 7));
          break;
        case AnalyticsPeriod.monthly:
          startDate = now.subtract(Duration(days: 30));
          break;
      }

      // Fetch all reviews and filter manually
      final allReviews = await _firestore
          .collection('avis')
          .get();

      Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      
      for (var review in allReviews.docs) {
        final data = review.data();
        
        // Check provider ID (support multiple field names)
        final providerId = data['idpro'] as String? ?? data['professionnelId'] as String?;
        if (providerId != user.uid) continue;
        
        // Check date (support multiple field names)
        final dateField = data['dateCreation'] ?? data['createdAt'] ?? data['date'];
        if (dateField != null) {
          final reviewDate = (dateField as Timestamp).toDate();
          if (reviewDate.isBefore(startDate)) continue;
        }
        
        final rating = (data['note'] as num?)?.round() ?? 
                      (data['rating'] as num?)?.round() ?? 
                      (data['etoiles'] as num?)?.round() ?? 0;
        
        if (rating >= 1 && rating <= 5) {
          ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
        }
      }

      return ratingCounts.entries.map((entry) => 
        RatingData(rating: entry.key, count: entry.value)
      ).toList();
      
    } catch (e) {
      print('❌ Error fetching ratings analytics: $e');
      return [];
    }
  }

  /// Helper method to get earnings for a specific period
  static Future<double> _getEarningsForPeriod(String userId, DateTime start, DateTime end) async {
    // Fetch all appointments and filter manually to avoid complex index requirements
    final allAppointments = await _firestore
        .collection('appointments')
        .get();

    double total = 0;
    for (var appointment in allAppointments.docs) {
      final data = appointment.data();
      
      // Check provider ID (support multiple field names)
      final providerId = data['idpro'] as String? ?? data['professionnelId'] as String?;
      if (providerId != userId) continue;
      
      // Check status (support multiple field names)
      final status = data['status'] as String? ?? data['etat'] as String?;
      if (status != 'accepted' && status != 'completed' && status != 'confirmé' && status != 'terminé') continue;
      
      // Check date (support multiple field names)
      final dateField = data['createdAt'] ?? data['updatedAt'] ?? data['dateRendezVous'];
      if (dateField == null) continue;
      
      final appointmentDate = (dateField as Timestamp).toDate();
      if (appointmentDate.isBefore(start) || appointmentDate.isAfter(end)) continue;
      
      // Get price (support multiple field names)
      final price = (data['prix'] as num?)?.toDouble() ?? 
                   (data['tarif'] as num?)?.toDouble() ?? 
                   (data['price'] as num?)?.toDouble() ?? 
                   100.0;
      total += price;
    }
    
    return total;
  }

  /// Helper method to get appointment statistics for a period
  static Future<Map<String, int>> _getAppointmentStatsForPeriod(
    String userId, 
    DateTime start, 
    DateTime end,
  ) async {
    // Fetch all appointments and filter manually
    final allAppointments = await _firestore
        .collection('appointments')
        .get();

    int completed = 0;
    int pending = 0;
    int cancelled = 0;

    for (var appointment in allAppointments.docs) {
      final data = appointment.data();
      
      // Check provider ID (support multiple field names)
      final providerId = data['idpro'] as String? ?? data['professionnelId'] as String?;
      if (providerId != userId) continue;
      
      // Check date (support multiple field names)
      final dateField = data['createdAt'] ?? data['updatedAt'] ?? data['dateRendezVous'];
      if (dateField == null) continue;
      
      final appointmentDate = (dateField as Timestamp).toDate();
      if (appointmentDate.isBefore(start) || appointmentDate.isAfter(end)) continue;
      
      // Check status (support multiple field names)
      final status = data['status'] as String? ?? data['etat'] as String?;
      
      switch (status) {
        case 'accepted':
        case 'completed':
        case 'confirmé':
        case 'terminé':
          completed++;
          break;
        case 'pending':
        case 'en_attente':
          pending++;
          break;
        case 'cancelled':
        case 'annulé':
          cancelled++;
          break;
      }
    }

    return {
      'completed': completed,
      'pending': pending,
      'cancelled': cancelled,
    };
  }

  /// Format date labels based on period
  static String _formatDateLabel(DateTime date, AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.daily:
        return '${date.day}/${date.month}';
      case AnalyticsPeriod.weekly:
        return 'W${_getWeekOfYear(date)}';
      case AnalyticsPeriod.monthly:
        return _getMonthName(date.month);
    }
  }

  /// Get week number of year
  static int _getWeekOfYear(DateTime date) {
    final firstJan = DateTime(date.year, 1, 1);
    final daysSinceFirstJan = date.difference(firstJan).inDays;
    return ((daysSinceFirstJan + firstJan.weekday) / 7).ceil();
  }

  /// Get month name
  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

/// Analytics period enum
enum AnalyticsPeriod { daily, weekly, monthly }

/// Earnings data model
class EarningsData {
  final DateTime date;
  final double amount;
  final String label;

  const EarningsData({
    required this.date,
    required this.amount,
    required this.label,
  });
}

/// Appointment data model
class AppointmentData {
  final DateTime date;
  final int completed;
  final int pending;
  final int cancelled;
  final String label;

  const AppointmentData({
    required this.date,
    required this.completed,
    required this.pending,
    required this.cancelled,
    required this.label,
  });
}

/// Rating data model
class RatingData {
  final int rating;
  final int count;

  const RatingData({
    required this.rating,
    required this.count,
  });
}