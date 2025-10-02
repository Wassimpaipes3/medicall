import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to manage reviews and ratings for healthcare providers
class ReviewService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// DEBUG: List all documents in avis collection
  static Future<void> listAllReviews() async {
    try {
      print('📋 [ReviewService] Listing all documents in avis collection...');
      print('   Firestore instance: $_firestore');
      print('   App name: ${_firestore.app.name}');
      print('   Project ID: ${_firestore.app.options.projectId}');
      
      final snapshot = await _firestore.collection('avis').get();
      
      print('   Total documents: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('   ⚠️ Collection is EMPTY or documents were deleted');
      } else {
        for (var doc in snapshot.docs) {
          print('   - Document ID: ${doc.id}');
          print('     Data: ${doc.data()}');
        }
      }
    } catch (e) {
      print('❌ Error listing reviews: $e');
    }
  }

  /// DEBUG: Complete diagnostic
  static Future<void> runDiagnostics() async {
    print('🔧 [ReviewService] Running complete diagnostics...');
    print('═══════════════════════════════════════════════════');
    
    // 1. Check authentication
    final user = _auth.currentUser;
    print('1️⃣ Authentication:');
    print('   Logged in: ${user != null}');
    print('   User ID: ${user?.uid ?? "N/A"}');
    print('   Email: ${user?.email ?? "N/A"}');
    print('');
    
    // 2. Check Firestore connection
    print('2️⃣ Firestore Configuration:');
    print('   Project ID: ${_firestore.app.options.projectId}');
    print('   App name: ${_firestore.app.name}');
    print('');
    
    // 3. List all collections
    print('3️⃣ Checking avis collection...');
    await listAllReviews();
    print('');
    
    // 4. Try to create a test document
    if (user != null) {
      print('4️⃣ Testing document creation...');
      try {
        final testDoc = await _firestore.collection('avis').add({
          'test': true,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });
        print('   ✅ Test document created: ${testDoc.id}');
        
        // Verify it exists
        final verify = await _firestore.collection('avis').doc(testDoc.id).get();
        print('   ✅ Test document verified: ${verify.exists}');
        
        // Delete test document
        await testDoc.delete();
        print('   ✅ Test document deleted');
      } catch (e) {
        print('   ❌ Test failed: $e');
      }
    }
    
    print('═══════════════════════════════════════════════════');
    print('🔧 Diagnostics complete');
  }

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
    print('   👤 User ID: ${user.uid}');
    print('   🩺 Provider ID: $providerId');
    print('   📋 Appointment ID: $appointmentId');
    print('   ⭐ Rating: $rating stars');
    print('   💬 Comment: ${comment ?? "(empty)"}');

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

      print('📤 [ReviewService] Attempting to write to Firestore...');
      print('   Collection: avis');
      print('   Data keys: ${reviewData.keys.toList()}');
      print('   Data: $reviewData');
      
      try {
        final docRef = await _firestore.collection('avis').add(reviewData);
        print('✅ Review saved to avis collection with ID: ${docRef.id}');
        
        // VERIFY: Read back the document to confirm it exists
        print('🔍 [ReviewService] Verifying document was saved...');
        await Future.delayed(const Duration(milliseconds: 500)); // Wait for Firestore to sync
        
        final verifyDoc = await _firestore.collection('avis').doc(docRef.id).get();
        if (verifyDoc.exists) {
          print('✅ VERIFIED: Document exists in Firestore');
          print('   Document ID: ${verifyDoc.id}');
          print('   Document data: ${verifyDoc.data()}');
        } else {
          print('❌ WARNING: Document not found after creation!');
          print('   This could indicate a database configuration issue');
        }
        
      } catch (firestoreError) {
        print('❌ Firestore write error: $firestoreError');
        print('   Error type: ${firestoreError.runtimeType}');
        if (firestoreError.toString().contains('PERMISSION_DENIED')) {
          print('   ⚠️ PERMISSION DENIED - Check Firestore rules for /avis collection');
        }
        rethrow;
      }

      // DEBUG: List all reviews to verify it's really there
      print('📋 [ReviewService] Listing all reviews after save...');
      await listAllReviews();
      
      // Update provider's rating
      print('🔄 [ReviewService] Updating provider rating...');
      await _updateProviderRating(providerId);
      
      print('✅ Review submission complete');
    } catch (e, stackTrace) {
      print('❌ Failed to submit review: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Recalculate and update provider's average rating
  static Future<void> _updateProviderRating(String providerId) async {
    try {
      print('🔄 [ReviewService] _updateProviderRating called for provider: $providerId');

      // Get all reviews for this provider
      print('📥 [ReviewService] Fetching reviews for provider...');
      final reviewsSnapshot = await _firestore
          .collection('avis')
          .where('idpro', isEqualTo: providerId)
          .get();

      print('📊 [ReviewService] Found ${reviewsSnapshot.docs.length} reviews');

      if (reviewsSnapshot.docs.isEmpty) {
        print('⚠️ No reviews found for provider - skipping rating update');
        return;
      }

      // Calculate average rating
      final reviews = reviewsSnapshot.docs;
      double totalRating = 0;
      print('🧮 [ReviewService] Calculating average...');
      for (final doc in reviews) {
        final data = doc.data();
        final note = data['note'];
        print('   Review ${doc.id}: note = $note');
        if (note is int) {
          totalRating += note.toDouble();
        } else if (note is double) {
          totalRating += note;
        }
      }

      final averageRating = totalRating / reviews.length;
      final reviewsCount = reviews.length;

      print('📊 Calculated average: ${averageRating.toStringAsFixed(1)} stars from $reviewsCount reviews');

      // Update provider document
      // Try both 'professionals' collection with different ID patterns
      print('🔍 [ReviewService] Searching for provider in professionals collection...');
      
      final providerQueries = [
        _firestore.collection('professionals').where('idpro', isEqualTo: providerId).limit(1),
        _firestore.collection('professionals').where('id_user', isEqualTo: providerId).limit(1),
      ];

      bool updated = false;
      int queryIndex = 0;
      for (final query in providerQueries) {
        queryIndex++;
        print('   Query $queryIndex: ${queryIndex == 1 ? "idpro" : "id_user"} == $providerId');
        
        final snapshot = await query.get();
        print('   Found ${snapshot.docs.length} documents');
        
        if (snapshot.docs.isNotEmpty) {
          final docId = snapshot.docs.first.id;
          final docData = snapshot.docs.first.data();
          print('   ✅ Found provider document: $docId');
          print('   Current data: $docData');
          
          print('📝 [ReviewService] Updating provider rating...');
          await _firestore.collection('professionals').doc(docId).update({
            'rating': double.parse(averageRating.toStringAsFixed(1)),
            'reviewsCount': reviewsCount,
          });
          print('✅ Provider rating updated successfully!');
          print('   New rating: ${averageRating.toStringAsFixed(1)}');
          print('   Reviews count: $reviewsCount');
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
