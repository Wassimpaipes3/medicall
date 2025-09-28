import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthTestWidget extends StatefulWidget {
  const AuthTestWidget({super.key});

  @override
  _AuthTestWidgetState createState() => _AuthTestWidgetState();
}

class _AuthTestWidgetState extends State<AuthTestWidget> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _status = 'Not authenticated';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Auth Test')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_status),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final user = await _authService.signUp(
                      _emailController.text,
                      _passwordController.text,
                    );
                    setState(() {
                      _status = user != null ? 'Signed up successfully!' : 'Sign up failed';
                    });
                  },
                  child: Text('Sign Up'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final user = await _authService.signIn(
                      _emailController.text,
                      _passwordController.text,
                    );
                    setState(() {
                      _status = user != null ? 'Signed in successfully!' : 'Sign in failed';
                    });
                  },
                  child: Text('Sign In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}