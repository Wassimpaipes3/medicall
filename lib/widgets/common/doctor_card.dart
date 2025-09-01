import 'package:flutter/material.dart';
import 'package:firstv/core/theme.dart';

class DoctorCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String specialty;
  final double rating;
  final VoidCallback onTap;

  const DoctorCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppDecor? decor = theme.extension<AppDecor>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: decor?.subtleGradient,
          color: decor == null ? Theme.of(context).cardColor : null,
          borderRadius: decor?.cardRadius ?? BorderRadius.circular(16),
          boxShadow: decor?.softShadows ?? const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: decor?.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundImage: NetworkImage(imageUrl),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            Text(
              specialty,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  rating.toString(),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
