import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Checking Firebase status...';
  final TextEditingController _emailController = TextEditingController(text: 'test@example.com');
  final TextEditingController _passwordController = TextEditingController(text: 'password123');

  @override
  void initState() {
    super.initState();
    _checkFirebaseStatus();
  }

  Future<void> _checkFirebaseStatus() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        setState(() {
          _status = '❌ Firebase not initialized - initializing now...';
        });
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      
      setState(() {
        _status = '''
✅ Firebase Status: CONNECTED
📱 Project ID: ${auth.app.options.projectId}
🔑 App ID: ${auth.app.options.appId}
👤 Current User: ${currentUser?.email ?? 'Not signed in'}
🌐 Auth Domain: ${auth.app.options.authDomain ?? 'Not set'}
''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Firebase Error: ${e.toString()}';
      });
    }
  }

  Future<void> _testSignUp() async {
    try {
      setState(() {
        _status = '🔄 Creating account...';
      });
      
      final auth = FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      setState(() {
        _status = '''
✅ SIGNUP SUCCESS!
👤 User: ${credential.user?.email}
🆔 UID: ${credential.user?.uid}
📧 Verified: ${credential.user?.emailVerified}
''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Signup failed: ${e.toString()}';
      });
    }
  }

  Future<void> _testSignIn() async {
    try {
      setState(() {
        _status = '🔄 Signing in...';
      });
      
      final auth = FirebaseAuth.instance;
      final credential = await auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      setState(() {
        _status = '''
✅ LOGIN SUCCESS!
👤 User: ${credential.user?.email}
🆔 UID: ${credential.user?.uid}
📧 Verified: ${credential.user?.emailVerified}
''';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Login failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Auth Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                _status,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Test Sign Up'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Test Sign In'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkFirebaseStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text('Refresh Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}