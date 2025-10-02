import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/review_service.dart';
import '../routes/app_routes.dart';

/// Example of how to integrate the Rating & Review System
/// into your existing appointment/tracking screens

// ============================================================
// EXAMPLE 1: Navigate to Rating Screen After Appointment
// ============================================================

class AppointmentCompletionExample extends StatelessWidget {
  final String appointmentId;
  final String providerId;

  const AppointmentCompletionExample({
    super.key,
    required this.appointmentId,
    required this.providerId,
  });

  Future<void> _completeAndRate(BuildContext context) async {
    try {
      // 1. Get appointment details
      final appointmentDoc = await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) return;

      final data = appointmentDoc.data()!;
      
      // 2. Get provider details
      final providerQuery = await FirebaseFirestore.instance
          .collection('professionals')
          .where('idpro', isEqualTo: providerId)
          .limit(1)
          .get();

      if (providerQuery.docs.isEmpty) return;

      final providerData = providerQuery.docs.first.data();

      // 3. Check if patient can review
      final canReview = await ReviewService.canReviewAppointment(appointmentId);

      if (!canReview) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You have already reviewed this appointment')),
          );
        }
        return;
      }

      // 4. Navigate to rating screen
      if (context.mounted) {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.ratingScreen,
          arguments: {
            'appointmentId': appointmentId,
            'providerId': providerId,
            'providerName': providerData['nom'] ?? 'Provider',
            'providerSpecialty': providerData['specialite'] ?? '',
            'providerPhoto': providerData['profileImageUrl'],
          },
        );

        // 5. Handle result (optional)
        if (result == true && context.mounted) {
          // Review was submitted successfully
          Navigator.pop(context); // Go back to previous screen
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _completeAndRate(context),
      child: const Text('Complete & Rate'),
    );
  }
}

// ============================================================
// EXAMPLE 2: Show Rating in Provider Card
// ============================================================

class ProviderCardWithRating extends StatelessWidget {
  final String providerId;
  final String providerName;
  final String specialty;

  const ProviderCardWithRating({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(providerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(specialty),
            const SizedBox(height: 4),
            // Rating display
            FutureBuilder<ProviderRatingInfo>(
              future: ReviewService.getProviderRatingInfo(providerId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final info = snapshot.data!;

                if (info.reviewsCount == 0) {
                  return const Text(
                    'No reviews yet',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  );
                }

                return Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Color(0xFFFFC107),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      info.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${info.reviewsCount} reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EXAMPLE 3: Add Reviews to Provider Profile/Detail Screen
// ============================================================

/* 
In your existing provider detail screen, add:

import 'package:firstv/widgets/provider_reviews_widget.dart';

// Inside your build method:
Column(
  children: [
    // ... existing provider info ...
    
    const SizedBox(height: 24),
    
    // Reviews Section
    Padding(
      padding: const EdgeInsets.all(16),
      child: ProviderReviewsWidget(
        providerId: widget.providerId,
        showAllReviews: false, // Preview mode (3 reviews)
      ),
    ),
    
    // ... rest of profile ...
  ],
)
*/

// ============================================================
// EXAMPLE 4: Trigger Rating from Tracking Screen
// ============================================================

/*
In your live_tracking_screen.dart, when appointment is complete:

// After provider marks appointment as complete
void _onAppointmentComplete() async {
  // Update appointment status
  await FirebaseFirestore.instance
      .collection('appointments')
      .doc(widget.appointmentId)
      .update({'status': 'completed'});

  // Check if can review
  final canReview = await ReviewService.canReviewAppointment(
    widget.appointmentId,
  );

  if (canReview && mounted) {
    // Get provider info from appointment
    final appointmentDoc = await FirebaseFirestore.instance
        .collection('appointments')
        .doc(widget.appointmentId)
        .get();
    
    final data = appointmentDoc.data()!;
    final providerId = data['idpro'] as String;
    
    // Get provider details
    final providerQuery = await FirebaseFirestore.instance
        .collection('professionals')
        .where('idpro', isEqualTo: providerId)
        .limit(1)
        .get();
    
    if (providerQuery.docs.isNotEmpty) {
      final providerData = providerQuery.docs.first.data();
      
      // Navigate to rating screen
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.ratingScreen,
        arguments: {
          'appointmentId': widget.appointmentId,
          'providerId': providerId,
          'providerName': providerData['nom'] ?? 'Provider',
          'providerSpecialty': providerData['specialite'] ?? '',
          'providerPhoto': providerData['profileImageUrl'],
        },
      );
    }
  }
}
*/

// ============================================================
// EXAMPLE 5: Show Recent Reviews Summary
// ============================================================

class RecentReviewsPreview extends StatelessWidget {
  final String providerId;

  const RecentReviewsPreview({
    super.key,
    required this.providerId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReviewData>>(
      future: ReviewService.getProviderReviews(providerId, limit: 5),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final reviews = snapshot.data!;

        if (reviews.isEmpty) {
          return const Text('No reviews yet');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...reviews.map((review) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Stars
                  ...List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFC107),
                      size: 16,
                    );
                  }),
                  const SizedBox(width: 8),
                  // Comment preview
                  Expanded(
                    child: Text(
                      review.comment.isEmpty
                          ? '${review.anonymizedName} rated ${review.rating} stars'
                          : review.comment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}
