import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/review_service.dart';

/// Rating screen shown after appointment completion
/// Allows patient to rate and review the healthcare provider
class RatingScreen extends StatefulWidget {
  final String appointmentId;
  final String providerId;
  final String providerName;
  final String providerSpecialty;
  final String? providerPhoto;

  const RatingScreen({
    super.key,
    required this.appointmentId,
    required this.providerId,
    required this.providerName,
    required this.providerSpecialty,
    this.providerPhoto,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> with SingleTickerProviderStateMixin {
  // Material 3 Colors
  static const Color _primaryColor = Color(0xFF1976D2);
  static const Color _successColor = Color(0xFF43A047);
  static const Color _errorColor = Color(0xFFE53935);
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1C1B1F);
  static const Color _textSecondary = Color(0xFF49454F);

  double _rating = 5.0; // Default to 5 stars
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ReviewService.submitReview(
        providerId: widget.providerId,
        appointmentId: widget.appointmentId,
        rating: _rating.toInt(),
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (!mounted) return;

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Thanks for your feedback!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate back
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (!mounted) return;

      print('❌ [RatingScreen] Error submitting review: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to submit review: ${e.toString()}',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _surfaceColor,
        foregroundColor: _primaryColor,
        title: const Text(
          'Rate Your Experience',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Provider Card
                _buildProviderCard(),

                const SizedBox(height: 32),

                // Rating Section
                _buildRatingSection(),

                const SizedBox(height: 32),

                // Comment Section
                _buildCommentSection(),

                const SizedBox(height: 40),

                // Submit Button
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard() {
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
      child: Column(
        children: [
          // Provider Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _primaryColor.withOpacity(0.2),
                  _primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: _primaryColor.withOpacity(0.2),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: widget.providerPhoto != null && widget.providerPhoto!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.providerPhoto!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: _primaryColor.withOpacity(0.05),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildAvatarFallback(),
                    )
                  : _buildAvatarFallback(),
            ),
          ),

          const SizedBox(height: 16),

          // Provider Name
          Text(
            widget.providerName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Provider Specialty
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.providerSpecialty,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final initials = widget.providerName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withOpacity(0.8),
            _primaryColor.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
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
      child: Column(
        children: [
          const Text(
            'How was your experience?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Star Rating
          RatingBar.builder(
            initialRating: _rating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemSize: 50,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Color(0xFFFFC107),
            ),
            onRatingUpdate: (rating) {
              setState(() => _rating = rating);
            },
            glow: true,
            glowColor: const Color(0xFFFFC107).withOpacity(0.3),
          ),

          const SizedBox(height: 16),

          // Rating Text
          Text(
            _getRatingText(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getRatingColor(),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText() {
    if (_rating == 5) return 'Excellent! 🌟';
    if (_rating >= 4) return 'Very Good! 😊';
    if (_rating >= 3) return 'Good 👍';
    if (_rating >= 2) return 'Fair 😐';
    return 'Needs Improvement 😕';
  }

  Color _getRatingColor() {
    if (_rating >= 4) return _successColor;
    if (_rating >= 3) return const Color(0xFFFFC107);
    return _errorColor;
  }

  Widget _buildCommentSection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share your thoughts (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(
              fontSize: 15,
              color: _textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Tell us about your experience...',
              hintStyle: TextStyle(
                color: _textSecondary.withOpacity(0.5),
                fontSize: 15,
              ),
              filled: true,
              fillColor: _backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: _textSecondary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: _primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitReview,
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _textSecondary.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Submit Review',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
