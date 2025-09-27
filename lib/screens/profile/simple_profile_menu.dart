import 'package:flutter/material.dart';
import 'package:firstv/routes/app_routes.dart';
import 'package:firstv/core/theme.dart';

class SimpleProfileMenuScreen extends StatelessWidget {
  const SimpleProfileMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Info Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text(
                  'John Doe', // This would come from user data
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'john.doe@example.com', // This would come from user data
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Menu Options
          _buildMenuSection('Compte', [
            _MenuOption(
              icon: Icons.edit,
              title: 'Modifier le profil',
              subtitle: 'Nom, email, photo de profil',
              onTap: () {
                // Navigate to edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
            _MenuOption(
              icon: Icons.lock_outline,
              title: 'Changer le mot de passe',
              subtitle: 'Sécurité de votre compte',
              onTap: () {
                // Navigate to change password
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildMenuSection('Préférences', [
            _MenuOption(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Gérer vos notifications',
              onTap: () {
                // Navigate to notification settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
            _MenuOption(
              icon: Icons.language_outlined,
              title: 'Langue',
              subtitle: 'Français',
              onTap: () {
                // Navigate to language settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
          ]),
          
          const SizedBox(height: 16),
          
          _buildMenuSection('Support', [
            _MenuOption(
              icon: Icons.help_outline,
              title: 'Centre d\'aide',
              subtitle: 'FAQ et support',
              onTap: () {
                // Navigate to help center
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
            _MenuOption(
              icon: Icons.privacy_tip_outlined,
              title: 'Politique de confidentialité',
              subtitle: 'Comment nous protégeons vos données',
              onTap: () {
                // Navigate to privacy policy
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
          ]),
          
          const SizedBox(height: 24),
          
          // Danger Zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Zone dangereuse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Delete Account Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to delete account screen
                      Navigator.of(context).pushNamed(AppRoutes.deleteAccount);
                    },
                    icon: const Icon(Icons.delete_forever, size: 20),
                    label: const Text('Supprimer mon compte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cette action supprimera définitivement votre compte et toutes vos données personnelles et médicales.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _showLogoutDialog(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.grey.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: options.map((option) {
              return ListTile(
                leading: Icon(option.icon, color: AppTheme.primaryColor),
                title: Text(option.title),
                subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: option.onTap,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Perform logout
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _MenuOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}