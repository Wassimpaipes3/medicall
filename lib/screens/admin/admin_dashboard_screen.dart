import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/real_time_role_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => isLoading = true);
      
      final querySnapshot = await _firestore.collection('users').get();
      
      users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': data['email'] ?? '',
          'nom': data['nom'] ?? '',
          'prenom': data['prenom'] ?? '',
          'role': data['role'] ?? 'patient',
        };
      }).toList();
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement: $e')),
      );
    }
  }

  Future<void> _changeUserRole(String userId, String currentRole) async {
    // Role options
    final roles = [
      {'value': 'patient', 'label': 'Patient'},
      {'value': 'doctor', 'label': 'Docteur'},
      {'value': 'professional', 'label': 'Professionnel'},
      {'value': 'admin', 'label': 'Administrateur'},
    ];

    // Show role selection dialog
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) {
            return RadioListTile<String>(
              title: Text(role['label']!),
              value: role['value']!,
              groupValue: currentRole,
              onChanged: (value) => Navigator.of(context).pop(value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedRole != null && selectedRole != currentRole) {
      await _updateUserRole(userId, selectedRole);
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Use the admin change role method
      final success = await RealTimeRoleService.adminChangeUserRole(
        targetUserId: userId,
        newRole: newRole,
        adminUserId: 'admin_test', // In real app, get current admin ID
        reason: 'Admin dashboard role change',
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle mis à jour avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload users to reflect changes
        await _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du rôle'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRoleBadgeText(String role) {
    switch (role) {
      case 'patient':
        return 'Patient';
      case 'doctor':
      case 'docteur':
        return 'Docteur';
      case 'professional':
        return 'Pro';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  Color _getRoleBadgeColor(String role) {
    switch (role) {
      case 'patient':
        return Colors.blue;
      case 'doctor':
      case 'docteur':
        return Colors.green;
      case 'professional':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administration'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? Center(
                  child: Text(
                    'Aucun utilisateur trouvé',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _getRoleBadgeColor(user['role']),
                            child: Text(
                              user['prenom']?.isNotEmpty == true
                                  ? user['prenom'][0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim(),
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(user['email'] ?? ''),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleBadgeColor(user['role']),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getRoleBadgeText(user['role']),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue[600]),
                            onPressed: () => _changeUserRole(
                              user['id'],
                              user['role'],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushReplacementNamed('/login');
        },
        backgroundColor: Colors.red[600],
        icon: Icon(Icons.logout, color: Colors.white),
        label: Text('Déconnexion', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}