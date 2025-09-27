import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.blue.shade50,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Account Section
          const Text(
            'Compte',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Edit Profile
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blue),
            title: const Text('Modifier le profil'),
            subtitle: const Text('Nom, email, téléphone, photo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to edit profile
            },
          ),
          
          // Change Password
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.blue),
            title: const Text('Changer le mot de passe'),
            subtitle: const Text('Sécurité de votre compte'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to change password
            },
          ),
          
          const Divider(height: 32),
          
          // Notifications Section
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Notification Settings
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Colors.blue),
            title: const Text('Paramètres de notification'),
            subtitle: const Text('Rendez-vous, rappels, messages'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          
          const Divider(height: 32),
          
          // Privacy Section
          const Text(
            'Confidentialité',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.orange),
            title: const Text('Politique de confidentialité'),
            subtitle: const Text('Comment nous protégeons vos données'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to privacy policy
            },
          ),
          
          // Terms of Service
          ListTile(
            leading: const Icon(Icons.article_outlined, color: Colors.blue),
            title: const Text('Conditions d\'utilisation'),
            subtitle: const Text('Nos termes et conditions'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to terms
            },
          ),
          
          const Divider(height: 32),
          
          // Support Section
          const Text(
            'Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Contact Support
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: const Text('Contactez-nous'),
            subtitle: const Text('Besoin d\'aide ? Nous sommes là !'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to support
            },
          ),
          
          // FAQ
          ListTile(
            leading: const Icon(Icons.quiz_outlined, color: Colors.blue),
            title: const Text('Questions fréquentes'),
            subtitle: const Text('Réponses aux questions communes'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to FAQ
            },
          ),
          
          const SizedBox(height: 32),
          
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
                  'Cette action supprimera définitivement votre compte et toutes vos données.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}