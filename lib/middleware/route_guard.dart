import 'package:flutter/material.dart';
import '../services/provider_auth_service.dart';
import '../services/auth_service.dart';

/// Route guard middleware to prevent unauthorized access
class RouteGuard {
  
  /// Check if current user can access provider screens
  static Future<bool> canAccessProviderScreens() async {
    try {
      return await ProviderAuthService.isCurrentUserProvider();
    } catch (e) {
      print('❌ Error checking provider access: $e');
      return false;
    }
  }
  
  /// Check if current user can access patient screens  
  static Future<bool> canAccessPatientScreens() async {
    try {
      final authService = AuthService();
      final role = await authService.getUserRole();
      return role == 'patient';
    } catch (e) {
      print('❌ Error checking patient access: $e');
      return false;
    }
  }
  
  /// Middleware widget for provider routes
  static Widget providerRouteGuard({
    required Widget child,
    Widget? unauthorizedWidget,
  }) {
    return FutureBuilder<bool>(
      future: canAccessProviderScreens(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.data == true) {
          return child;
        } else {
          return unauthorizedWidget ?? _buildUnauthorizedScreen(
            context: context,
            message: 'Accès refusé. Vous devez être un professionnel de santé.',
            redirectRoute: '/login',
            redirectLabel: 'Connexion Patient',
          );
        }
      },
    );
  }
  
  /// Middleware widget for patient routes
  static Widget patientRouteGuard({
    required Widget child,
    Widget? unauthorizedWidget,
  }) {
    return FutureBuilder<bool>(
      future: canAccessPatientScreens(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.data == true) {
          return child;
        } else {
          return unauthorizedWidget ?? _buildUnauthorizedScreen(
            context: context,
            message: 'Accès refusé. Vous devez être un patient.',
            redirectRoute: '/provider-login',
            redirectLabel: 'Connexion Professionnel',
          );
        }
      },
    );
  }
  
  /// Build unauthorized access screen
  static Widget _buildUnauthorizedScreen({
    required BuildContext context,
    required String message,
    required String redirectRoute,
    required String redirectLabel,
  }) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              SizedBox(height: 24),
              Text(
                'Accès non autorisé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    redirectRoute,
                    (route) => false,
                  );
                },
                icon: Icon(Icons.login),
                label: Text(redirectLabel),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}