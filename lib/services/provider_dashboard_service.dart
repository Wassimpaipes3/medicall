import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to fetch real dashboard statistics for providers
class ProviderDashboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get provider's dashboard statistics
  static Future<DashboardStats> getDashboardStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      print('📊 Fetching dashboard stats for provider: ${user.uid}');

      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Fetch appointments for today
      final todayAppointments = await _firestore
          .collection('appointments')
          .where('professionnelId', isEqualTo: user.uid)
          .where('dateRendezVous', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('dateRendezVous', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      // Fetch all appointments for provider (for overall stats)
      final allAppointments = await _firestore
          .collection('appointments')
          .where('professionnelId', isEqualTo: user.uid)
          .get();

      // Fetch reviews for provider
      final reviews = await _firestore
          .collection('avis')
          .where('professionnelId', isEqualTo: user.uid)
          .get();

      // Calculate statistics
      final stats = _calculateStats(todayAppointments, allAppointments, reviews);
      
      print('✅ Dashboard stats calculated: ${stats.toString()}');
      return stats;

    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      // Return default stats on error
      return DashboardStats(
        todayEarnings: 0,
        completedTasks: 0,
        pendingTasks: 0,
        averageRating: 0.0,
      );
    }
  }

  /// Calculate statistics from appointments and reviews
  static DashboardStats _calculateStats(
    QuerySnapshot todayAppointments,
    QuerySnapshot allAppointments,
    QuerySnapshot reviews,
  ) {
    // Today's earnings calculation
    double todayEarnings = 0;
    int completedToday = 0;
    int pendingToday = 0;

    for (var appointment in todayAppointments.docs) {
      final data = appointment.data() as Map<String, dynamic>;
      final etat = data['etat'] as String?;
      final tarif = (data['tarif'] as num?)?.toDouble() ?? 100.0; // Default consultation fee

      if (etat == 'confirmé' || etat == 'terminé') {
        todayEarnings += tarif;
        completedToday++;
      } else if (etat == 'en_attente' || etat == 'pending') {
        pendingToday++;
      }
    }

    // Calculate overall completed tasks (from all appointments)
    int totalCompleted = 0;
    for (var appointment in allAppointments.docs) {
      final data = appointment.data() as Map<String, dynamic>;
      final etat = data['etat'] as String?;
      
      if (etat == 'confirmé' || etat == 'terminé') {
        totalCompleted++;
      }
    }

    // Calculate average rating
    double averageRating = 0.0;
    if (reviews.docs.isNotEmpty) {
      double totalRating = 0;
      for (var review in reviews.docs) {
        final data = review.data() as Map<String, dynamic>;
        final rating = (data['note'] as num?)?.toDouble() ?? 
                      (data['rating'] as num?)?.toDouble() ?? 
                      (data['etoiles'] as num?)?.toDouble() ?? 0.0;
        totalRating += rating;
      }
      averageRating = totalRating / reviews.docs.length;
    }

    return DashboardStats(
      todayEarnings: todayEarnings.round(),
      completedTasks: totalCompleted,
      pendingTasks: pendingToday,
      averageRating: averageRating,
    );
  }

  /// Get pending appointment requests for provider
  static Future<List<AppointmentRequest>> getPendingRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final pendingAppointments = await _firestore
          .collection('appointments')
          .where('professionnelId', isEqualTo: user.uid)
          .where('etat', whereIn: ['en_attente', 'pending'])
          .orderBy('dateRendezVous', descending: false)
          .limit(10)
          .get();

      return pendingAppointments.docs.map((doc) {
        final data = doc.data();
        return AppointmentRequest.fromFirestore(doc.id, data);
      }).toList();

    } catch (e) {
      print('❌ Error fetching pending requests: $e');
      return [];
    }
  }

  /// Get monthly earnings for provider
  static Future<double> getMonthlyEarnings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0.0;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1);

      final monthlyAppointments = await _firestore
          .collection('appointments')
          .where('professionnelId', isEqualTo: user.uid)
          .where('etat', whereIn: ['confirmé', 'terminé'])
          .where('dateRendezVous', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('dateRendezVous', isLessThan: Timestamp.fromDate(monthEnd))
          .get();

      double monthlyEarnings = 0;
      for (var appointment in monthlyAppointments.docs) {
        final data = appointment.data();
        final tarif = (data['tarif'] as num?)?.toDouble() ?? 100.0;
        monthlyEarnings += tarif;
      }

      return monthlyEarnings;

    } catch (e) {
      print('❌ Error fetching monthly earnings: $e');
      return 0.0;
    }
  }

  /// Stream of real-time dashboard updates
  static Stream<DashboardStats> getDashboardStatsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(DashboardStats(
        todayEarnings: 0,
        completedTasks: 0,
        pendingTasks: 0,
        averageRating: 0.0,
      ));
    }

    return _firestore
        .collection('appointments')
        .where('professionnelId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((_) async => await getDashboardStats());
  }
}

/// Dashboard statistics model
class DashboardStats {
  final int todayEarnings;
  final int completedTasks;
  final int pendingTasks;
  final double averageRating;

  const DashboardStats({
    required this.todayEarnings,
    required this.completedTasks,
    required this.pendingTasks,
    required this.averageRating,
  });

  @override
  String toString() {
    return 'DashboardStats(earnings: \$$todayEarnings, completed: $completedTasks, pending: $pendingTasks, rating: ${averageRating.toStringAsFixed(1)})';
  }
}

/// Appointment request model for pending requests
class AppointmentRequest {
  final String id;
  final String patientId;
  final String patientNom;
  final String patientPrenom;
  final DateTime dateRendezVous;
  final String motifConsultation;
  final double tarif;
  final String etat;

  const AppointmentRequest({
    required this.id,
    required this.patientId,
    required this.patientNom,
    required this.patientPrenom,
    required this.dateRendezVous,
    required this.motifConsultation,
    required this.tarif,
    required this.etat,
  });

  factory AppointmentRequest.fromFirestore(String id, Map<String, dynamic> data) {
    return AppointmentRequest(
      id: id,
      patientId: data['patientId'] ?? '',
      patientNom: data['patientNom'] ?? 'Patient',
      patientPrenom: data['patientPrenom'] ?? '',
      dateRendezVous: (data['dateRendezVous'] as Timestamp?)?.toDate() ?? DateTime.now(),
      motifConsultation: data['motifConsultation'] ?? 'Consultation générale',
      tarif: (data['tarif'] as num?)?.toDouble() ?? 100.0,
      etat: data['etat'] ?? 'pending',
    );
  }

  String get patientFullName => '$patientPrenom $patientNom'.trim();
}