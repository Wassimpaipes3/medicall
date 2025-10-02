import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/review_service.dart';

/// Widget to display provider's rating and reviews
/// Can be embedded in provider profile or detail pages
class ProviderReviewsWidget extends StatelessWidget {
  final String providerId;
  final bool showAllReviews; // If false, shows only preview (3 reviews)

  const ProviderReviewsWidget({
    super.key,
    required this.providerId,
    this.showAllReviews = false,
  });

  // Material 3 Colors
  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1C1B1F);
  static const Color _textSecondary = Color(0xFF49454F);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProviderRatingInfo>(
      future: ReviewService.getProviderRatingInfo(providerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          );
        }

        final ratingInfo = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating Summary Card
            _buildRatingSummary(context, ratingInfo),

            if (ratingInfo.reviewsCount > 0) ...[
              const SizedBox(height: 24),

              // Reviews List
              _buildReviewsList(context, ratingInfo),
            ],
          ],
        );
      },
    );
  }

  Widget _buildRatingSummary(BuildContext context, ProviderRatingInfo ratingInfo) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Star Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              color: Color(0xFFFFC107),
              size: 32,
            ),
          ),

          const SizedBox(width: 20),

          // Rating Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ratingInfo.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        '/ 5.0',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Star Icons
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < ratingInfo.averageRating.floor()
                          ? Icons.star
                          : (index < ratingInfo.averageRating.ceil() 
                              ? Icons.star_half 
                              : Icons.star_border),
                      color: const Color(0xFFFFC107),
                      size: 20,
                    );
                  }),
                ),

                const SizedBox(height: 8),

                Text(
                  '${ratingInfo.reviewsCount} ${ratingInfo.reviewsCount == 1 ? "Review" : "Reviews"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context, ProviderRatingInfo ratingInfo) {
    return FutureBuilder<List<ReviewData>>(
      future: ReviewService.getProviderReviews(
        providerId,
        limit: showAllReviews ? null : 3,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            ),
          );
        }

        final reviews = snapshot.data!;

        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'No reviews yet',
                style: TextStyle(
                  fontSize: 15,
                  color: _textSecondary,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Patient Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ),

            // Reviews
            ...reviews.map((review) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildReviewCard(review),
            )),

            // View All Button
            if (!showAllReviews && ratingInfo.reviewsCount > 3)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AllReviewsScreen(providerId: providerId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View All Reviews'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(ReviewData review) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _textSecondary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Stars
          Row(
            children: [
              // Patient Initial Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.2),
                      _primaryColor.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.anonymizedName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.anonymizedName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFFFC107),
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        if (review.createdAt != null)
                          Text(
                            _formatDate(review.createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
                color: _textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

/// Full screen to show all reviews
class AllReviewsScreen extends StatelessWidget {
  final String providerId;

  const AllReviewsScreen({
    super.key,
    required this.providerId,
  });

  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _surfaceColor = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _surfaceColor,
        foregroundColor: _primaryColor,
        title: const Text(
          'All Reviews',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ProviderReviewsWidget(
            providerId: providerId,
            showAllReviews: true,
          ),
        ),
      ),
    );
  }
}
