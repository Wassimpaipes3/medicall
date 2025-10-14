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

      print('   📅 Today range: ${todayStart.toIso8601String()} to ${todayEnd.toIso8601String()}');

      // Fetch ALL appointments for provider first (to check both field names)
      print('   🔍 Fetching all appointments...');
      final allAppointmentsSnapshot = await _firestore
          .collection('appointments')
          .get();

      print('   📦 Total appointments in collection: ${allAppointmentsSnapshot.docs.length}');

      // Debug: Show first few appointments to see field structure
      if (allAppointmentsSnapshot.docs.isNotEmpty) {
        print('   🔍 Checking first appointment structure:');
        final firstDoc = allAppointmentsSnapshot.docs.first;
        final firstData = firstDoc.data();
        print('     Fields: ${firstData.keys.toList()}');
        print('     idpro: ${firstData['idpro']}');
        print('     professionnelId: ${firstData['professionnelId']}');
        print('     etat: ${firstData['etat']}');
        print('     status: ${firstData['status']}');
        print('     dateRendezVous: ${firstData['dateRendezVous']}');
      }

      // Filter appointments manually for this provider (handles both idpro and professionnelId)
      final allAppointments = allAppointmentsSnapshot.docs.where((doc) {
        final data = doc.data();
        final hasIdpro = data['idpro'] == user.uid;
        final hasProfessionnelId = data['professionnelId'] == user.uid;
        
        if (hasIdpro || hasProfessionnelId) {
          print('     ✅ Match found! Doc: ${doc.id}, idpro: ${data['idpro']}, professionnelId: ${data['professionnelId']}');
        }
        
        return hasIdpro || hasProfessionnelId;
      }).toList();

      print('   ✅ Found ${allAppointments.length} total appointments for provider: ${user.uid}');
      
      if (allAppointments.isEmpty) {
        print('   ⚠️ No appointments found for this provider!');
        print('   💡 Make sure appointments have either:');
        print('      - idpro = ${user.uid}');
        print('      - professionnelId = ${user.uid}');
      }

      // Filter for today's appointments (check multiple date fields)
      final todayAppointments = allAppointments.where((doc) {
        final data = doc.data();
        
        // Try multiple date field names
        final dateField = data['dateRendezVous'] ?? data['createdAt'] ?? data['updatedAt'];
        if (dateField == null) {
          print('     ⚠️ No date field found in appointment ${doc.id}');
          return false;
        }
        
        final appointmentDate = (dateField as Timestamp).toDate();
        final isToday = appointmentDate.isAfter(todayStart) && appointmentDate.isBefore(todayEnd);
        
        if (isToday) {
          print('     ✅ Today appointment: ${doc.id}, date: ${appointmentDate.toIso8601String()}, status: ${data['status'] ?? data['etat']}');
        }
        
        return isToday;
      }).toList();

      print('   ✅ Found ${todayAppointments.length} appointments for today');

      // Fetch reviews for provider (check both field names)
      print('   🔍 Fetching reviews...');
      final allReviews = await _firestore
          .collection('avis')
          .get();
      
      print('   📦 Total reviews in collection: ${allReviews.docs.length}');
      
      if (allReviews.docs.isNotEmpty) {
        print('   🔍 Checking first review structure:');
        final firstReview = allReviews.docs.first;
        final reviewData = firstReview.data();
        print('     Fields: ${reviewData.keys.toList()}');
        print('     idpro: ${reviewData['idpro']}');
        print('     professionnelId: ${reviewData['professionnelId']}');
      }
      
      final reviews = allReviews.docs.where((doc) {
        final data = doc.data();
        return data['idpro'] == user.uid || data['professionnelId'] == user.uid;
      }).toList();

      print('   ✅ Found ${reviews.length} reviews for provider: ${user.uid}');

      // Calculate statistics
      final stats = _calculateStatsFromDocs(todayAppointments, allAppointments, reviews);
      
      print('✅ Dashboard stats calculated: ${stats.toString()}');
      return stats;

    } catch (e, stackTrace) {
      print('❌ Error fetching dashboard stats: $e');
      print('   Stack trace: $stackTrace');
      // Return default stats on error
      return DashboardStats(
        todayEarnings: 0,
        completedTasks: 0,
        pendingTasks: 0,
        averageRating: 0.0,
      );
    }
  }

  /// Calculate statistics from appointments and reviews (using filtered docs)
  static DashboardStats _calculateStatsFromDocs(
    List<QueryDocumentSnapshot> todayAppointments,
    List<QueryDocumentSnapshot> allAppointments,
    List<QueryDocumentSnapshot> reviews,
  ) {
    // Today's earnings calculation
    double todayEarnings = 0;
    int completedToday = 0;
    int pendingToday = 0;

    print('   📊 Calculating today\'s stats from ${todayAppointments.length} appointments...');
    
    for (var appointment in todayAppointments) {
      final data = appointment.data() as Map<String, dynamic>;
      final etat = data['etat'] as String?;
      final status = data['status'] as String?;
      final tarif = (data['tarif'] as num?)?.toDouble() ?? 
                    (data['prix'] as num?)?.toDouble() ?? 
                    (data['price'] as num?)?.toDouble() ?? 100.0;

      print('     Appointment ${appointment.id}: etat=$etat, status=$status, tarif=$tarif');

      // Check both French and English status fields (including 'accepted')
      if (etat == 'confirmé' || etat == 'terminé' || etat == 'completed' ||
          status == 'confirmed' || status == 'completed' || status == 'accepted') {
        todayEarnings += tarif;
        completedToday++;
        print('       ✅ Counted as completed, adding $tarif to earnings');
      } else if (etat == 'en_attente' || etat == 'pending' || 
                 status == 'pending' || status == 'en_attente') {
        pendingToday++;
        print('       ⏳ Counted as pending');
      } else {
        print('       ⚠️ Status not recognized for earnings calculation');
      }
    }

    print('   💰 Today earnings: \$${todayEarnings.round()}, Completed: $completedToday, Pending: $pendingToday');

    // Calculate overall completed tasks (from all appointments)
    int totalCompleted = 0;
    for (var appointment in allAppointments) {
      final data = appointment.data() as Map<String, dynamic>;
      final etat = data['etat'] as String?;
      final status = data['status'] as String?;
      
      // Include 'accepted' status as completed
      if (etat == 'confirmé' || etat == 'terminé' || etat == 'completed' ||
          status == 'confirmed' || status == 'completed' || status == 'accepted') {
        totalCompleted++;
      }
    }

    print('   ✅ Total completed appointments: $totalCompleted');

    // Calculate average rating
    double averageRating = 0.0;
    if (reviews.isNotEmpty) {
      double totalRating = 0;
      int validRatings = 0;
      
      for (var review in reviews) {
        final data = review.data() as Map<String, dynamic>;
        final rating = (data['note'] as num?)?.toDouble() ?? 
                      (data['rating'] as num?)?.toDouble() ?? 
                      (data['etoiles'] as num?)?.toDouble() ?? 0.0;
        if (rating > 0) {
          totalRating += rating;
          validRatings++;
        }
      }
      
      if (validRatings > 0) {
        averageRating = totalRating / validRatings;
      }
    }

    print('   ⭐ Average rating: ${averageRating.toStringAsFixed(1)} from ${reviews.length} reviews');

    final stats = DashboardStats(
      todayEarnings: todayEarnings.round(),
      completedTasks: totalCompleted,
      pendingTasks: pendingToday,
      averageRating: averageRating,
    );
    
    print('');
    print('📊 ===== FINAL DASHBOARD STATS =====');
    print('   💰 Today Earnings: \$${stats.todayEarnings}');
    print('   ✅ Completed Tasks: ${stats.completedTasks}');
    print('   ⏳ Pending Tasks: ${stats.pendingTasks}');
    print('   ⭐ Average Rating: ${stats.averageRating.toStringAsFixed(1)}');
    print('=====================================');
    print('');
    
    return stats;
  }

  /// Get pending appointment requests for provider
  static Future<List<AppointmentRequest>> getPendingRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Fetch all appointments and filter manually (handles both idpro and professionnelId)
      final allAppointments = await _firestore
          .collection('appointments')
          .get();
      
      final pendingAppointments = allAppointments.docs.where((doc) {
        final data = doc.data();
        final isMyAppointment = data['idpro'] == user.uid || data['professionnelId'] == user.uid;
        final etat = data['etat'] as String?;
        final status = data['status'] as String?;
        final isPending = etat == 'en_attente' || etat == 'pending' || 
                         status == 'pending' || status == 'en_attente';
        return isMyAppointment && isPending;
      }).toList();

      // Sort by date and limit to 10
      pendingAppointments.sort((a, b) {
        final aDate = (a.data()['dateRendezVous'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bDate = (b.data()['dateRendezVous'] as Timestamp?)?.toDate() ?? DateTime.now();
        return aDate.compareTo(bDate);
      });

      final limitedPending = pendingAppointments.take(10).toList();

      return limitedPending.map((doc) {
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

      // Fetch all appointments and filter manually
      final allAppointments = await _firestore
          .collection('appointments')
          .get();
      
      final monthlyAppointments = allAppointments.docs.where((doc) {
        final data = doc.data();
        final isMyAppointment = data['idpro'] == user.uid || data['professionnelId'] == user.uid;
        if (!isMyAppointment) return false;
        
        final etat = data['etat'] as String?;
        final status = data['status'] as String?;
        final isCompleted = etat == 'confirmé' || etat == 'terminé' || etat == 'completed' ||
                           status == 'confirmed' || status == 'completed';
        if (!isCompleted) return false;
        
        final dateRendezVous = data['dateRendezVous'] as Timestamp?;
        if (dateRendezVous == null) return false;
        
        final appointmentDate = dateRendezVous.toDate();
        return appointmentDate.isAfter(monthStart) && appointmentDate.isBefore(monthEnd);
      }).toList();

      double monthlyEarnings = 0;
      for (var appointment in monthlyAppointments) {
        final data = appointment.data();
        final tarif = (data['tarif'] as num?)?.toDouble() ?? 
                     (data['prix'] as num?)?.toDouble() ?? 
                     (data['price'] as num?)?.toDouble() ?? 100.0;
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