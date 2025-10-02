import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage reviews and ratings for healthcare providers
class ReviewService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Submit a new review for a provider
  /// Updates provider's average rating automatically
  static Future<void> submitReview({
    required String providerId,
    required String appointmentId,
    required int rating, // 1-5 stars
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    print('⭐ [ReviewService] Submitting review');
    print('   🩺 Provider ID: $providerId');
    print('   ⭐ Rating: $rating stars');
    print('   💬 Comment: ${comment ?? "(none)"}');

    try {
      // Create review document
      final reviewData = {
        'idpat': user.uid,
        'idpro': providerId,
        'appointmentId': appointmentId,
        'note': rating,
        'commentaire': comment ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('avis').add(reviewData);
      print('✅ Review saved to avis collection');

      // Update provider's rating
      await _updateProviderRating(providerId);
      
      print('✅ Review submission complete');
    } catch (e) {
      print('❌ Failed to submit review: $e');
      rethrow;
    }
  }

  /// Recalculate and update provider's average rating
  static Future<void> _updateProviderRating(String providerId) async {
    try {
      print('🔄 [ReviewService] Updating provider rating...');

      // Get all reviews for this provider
      final reviewsSnapshot = await _firestore
          .collection('avis')
          .where('idpro', isEqualTo: providerId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        print('⚠️ No reviews found for provider');
        return;
      }

      // Calculate average rating
      final reviews = reviewsSnapshot.docs;
      double totalRating = 0;
      for (final doc in reviews) {
        final data = doc.data();
        final note = data['note'];
        if (note is int) {
          totalRating += note.toDouble();
        } else if (note is double) {
          totalRating += note;
        }
      }

      final averageRating = totalRating / reviews.length;
      final reviewsCount = reviews.length;

      print('📊 Calculated: $averageRating stars from $reviewsCount reviews');

      // Update provider document
      // Try both 'professionals' collection with different ID patterns
      final providerQueries = [
        _firestore.collection('professionals').where('idpro', isEqualTo: providerId).limit(1),
        _firestore.collection('professionals').where('id_user', isEqualTo: providerId).limit(1),
      ];

      bool updated = false;
      for (final query in providerQueries) {
        final snapshot = await query.get();
        if (snapshot.docs.isNotEmpty) {
          final docId = snapshot.docs.first.id;
          await _firestore.collection('professionals').doc(docId).update({
            'rating': double.parse(averageRating.toStringAsFixed(1)),
            'reviewsCount': reviewsCount,
          });
          print('✅ Provider rating updated: $averageRating ($reviewsCount reviews)');
          updated = true;
          break;
        }
      }

      if (!updated) {
        print('⚠️ Provider document not found in professionals collection');
      }
    } catch (e) {
      print('❌ Failed to update provider rating: $e');
      rethrow;
    }
  }

  /// Get reviews for a specific provider
  static Future<List<ReviewData>> getProviderReviews(String providerId, {int? limit}) async {
    try {
      Query query = _firestore
          .collection('avis')
          .where('idpro', isEqualTo: providerId)
          .orderBy('createdAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final reviews = <ReviewData>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Fetch patient name
        String? patientName;
        final patientId = data['idpat'] as String?;
        if (patientId != null) {
          try {
            final userDoc = await _firestore.collection('users').doc(patientId).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              final prenom = userData?['prenom'] as String?;
              final nom = userData?['nom'] as String?;
              patientName = [prenom, nom]
                  .where((s) => s != null && s.isNotEmpty)
                  .join(' ');
            }
          } catch (e) {
            print('⚠️ Error fetching patient name: $e');
          }
        }

        reviews.add(ReviewData(
          id: doc.id,
          patientId: patientId ?? '',
          patientName: patientName ?? 'Anonymous',
          providerId: data['idpro'] as String? ?? '',
          rating: (data['note'] as num?)?.toInt() ?? 0,
          comment: data['commentaire'] as String? ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        ));
      }

      return reviews;
    } catch (e) {
      print('❌ Failed to get provider reviews: $e');
      rethrow;
    }
  }

  /// Check if patient can review this appointment
  static Future<bool> canReviewAppointment(String appointmentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if review already exists
      final existingReview = await _firestore
          .collection('avis')
          .where('appointmentId', isEqualTo: appointmentId)
          .where('idpat', isEqualTo: user.uid)
          .limit(1)
          .get();

      return existingReview.docs.isEmpty;
    } catch (e) {
      print('❌ Error checking review eligibility: $e');
      return false;
    }
  }

  /// Get provider rating info (average + count)
  static Future<ProviderRatingInfo> getProviderRatingInfo(String providerId) async {
    try {
      // Try to find provider document
      final queries = [
        _firestore.collection('professionals').where('idpro', isEqualTo: providerId).limit(1),
        _firestore.collection('professionals').where('id_user', isEqualTo: providerId).limit(1),
      ];

      for (final query in queries) {
        final snapshot = await query.get();
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          return ProviderRatingInfo(
            averageRating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            reviewsCount: (data['reviewsCount'] as num?)?.toInt() ?? 0,
          );
        }
      }

      // Fallback: calculate from reviews
      final reviews = await getProviderReviews(providerId);
      if (reviews.isEmpty) {
        return ProviderRatingInfo(averageRating: 0.0, reviewsCount: 0);
      }

      final totalRating = reviews.fold<double>(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;

      return ProviderRatingInfo(
        averageRating: double.parse(averageRating.toStringAsFixed(1)),
        reviewsCount: reviews.length,
      );
    } catch (e) {
      print('❌ Error getting provider rating info: $e');
      return ProviderRatingInfo(averageRating: 0.0, reviewsCount: 0);
    }
  }
}

/// Review data model
class ReviewData {
  final String id;
  final String patientId;
  final String patientName;
  final String providerId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  ReviewData({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.providerId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  /// Get anonymized patient name (first name + initial)
  String get anonymizedName {
    final parts = patientName.split(' ');
    if (parts.isEmpty) return 'Anonymous';
    if (parts.length == 1) return parts[0];
    return '${parts[0]} ${parts[1][0]}.';
  }
}

/// Provider rating information
class ProviderRatingInfo {
  final double averageRating;
  final int reviewsCount;

  ProviderRatingInfo({
    required this.averageRating,
    required this.reviewsCount,
  });
}
