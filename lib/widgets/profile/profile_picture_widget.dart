import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../services/firebase_storage_service.dart';

class ProfilePictureWidget extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final File? localImage;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final bool isCircular;
  final Color? borderColor;
  final double borderWidth;

  const ProfilePictureWidget({
    super.key,
    this.size = 80.0,
    this.imageUrl,
    this.localImage,
    this.onTap,
    this.showEditIcon = false,
    this.isCircular = true,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(12),
          border: Border.all(
            color: borderColor ?? AppTheme.primaryColor,
            width: borderWidth,
          ),
        ),
        child: Stack(
          children: [
            // Profile picture
            ClipRRect(
              borderRadius: isCircular 
                  ? BorderRadius.circular(size / 2) 
                  : BorderRadius.circular(12),
              child: _buildImageWidget(),
            ),
            // Edit icon overlay
            if (showEditIcon && onTap != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: size * 0.15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Show local image if available (for immediate preview)
    if (localImage != null) {
      return Image.file(
        localImage!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
      );
    }

    // Show network image if URL is available
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildDefaultAvatar(),
        memCacheWidth: (size * 2).round(), // Optimize memory usage
        memCacheHeight: (size * 2).round(),
      );
    }

    // Show default avatar
    return _buildDefaultAvatar();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: size,
      height: size,
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: AppTheme.primaryColor,
      ),
    );
  }
}

/// Real-time profile picture widget that listens to Firestore changes
class RealtimeProfilePictureWidget extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final bool isCircular;
  final Color? borderColor;
  final double borderWidth;
  final File? localImage; // For immediate preview during upload

  const RealtimeProfilePictureWidget({
    super.key,
    this.size = 80.0,
    this.onTap,
    this.showEditIcon = false,
    this.isCircular = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.localImage,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return ProfilePictureWidget(
        size: size,
        onTap: onTap,
        showEditIcon: showEditIcon,
        isCircular: isCircular,
        borderColor: borderColor,
        borderWidth: borderWidth,
        localImage: localImage,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? imageUrl;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          imageUrl = data?['photo_profile'] as String?;
        }

        return ProfilePictureWidget(
          size: size,
          imageUrl: imageUrl,
          localImage: localImage,
          onTap: onTap,
          showEditIcon: showEditIcon,
          isCircular: isCircular,
          borderColor: borderColor,
          borderWidth: borderWidth,
        );
      },
    );
  }
}

/// Profile picture picker widget with Firebase upload
class ProfilePicturePicker extends StatefulWidget {
  final double size;
  final bool showEditIcon;
  final bool isCircular;
  final Color? borderColor;
  final double borderWidth;
  final Function(String?)? onImageUploaded;
  final Function(String?)? onImageDeleted;

  const ProfilePicturePicker({
    super.key,
    this.size = 80.0,
    this.showEditIcon = true,
    this.isCircular = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.onImageUploaded,
    this.onImageDeleted,
  });

  @override
  State<ProfilePicturePicker> createState() => _ProfilePicturePickerState();
}

class _ProfilePicturePickerState extends State<ProfilePicturePicker> {
  File? _localImage;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return RealtimeProfilePictureWidget(
      size: widget.size,
      localImage: _localImage,
      onTap: _isUploading ? null : _showImagePicker,
      showEditIcon: widget.showEditIcon,
      isCircular: widget.isCircular,
      borderColor: widget.borderColor,
      borderWidth: widget.borderWidth,
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choisir une photo de profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 360;
                    final content = [
                      _buildImageSourceOption(
                        icon: Icons.camera_alt_outlined,
                        label: 'Caméra',
                        onTap: () => _selectImage(ImageSource.camera),
                      ),
                      _buildImageSourceOption(
                        icon: Icons.photo_library_outlined,
                        label: 'Galerie',
                        onTap: () => _selectImage(ImageSource.gallery),
                      ),
                      _buildImageSourceOption(
                        icon: Icons.delete_outline,
                        label: 'Supprimer',
                        onTap: _deleteProfilePicture,
                      ),
                    ];
                    if (isNarrow) {
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: content,
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: content.map((w)=>Flexible(child: w)).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Reduced horizontal padding to avoid overflow on small screens
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      Navigator.of(context).pop(); // Close bottom sheet
      
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _localImage = File(pickedFile.path);
          _isUploading = true;
        });

        // Upload to Firebase Storage
        try {
          final downloadUrl = await FirebaseStorageService.uploadProfilePicture(_localImage!);
          
          if (downloadUrl != null) {
            widget.onImageUploaded?.call(downloadUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Photo de profil mise à jour avec succès!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'upload: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } finally {
          setState(() {
            _isUploading = false;
            _localImage = null; // Clear local image after upload
          });
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _localImage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      Navigator.of(context).pop(); // Close bottom sheet
      
      // Get current profile picture URL
      final currentUrl = await FirebaseStorageService.getCurrentUserProfilePicture();
      
      if (currentUrl != null) {
        await FirebaseStorageService.deleteProfilePicture(currentUrl);
        widget.onImageDeleted?.call(null);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo de profil supprimée'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
