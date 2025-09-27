import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import 'dart:io';

class FirebaseStorageDebugScreen extends StatefulWidget {
  const FirebaseStorageDebugScreen({super.key});

  @override
  _FirebaseStorageDebugScreenState createState() => _FirebaseStorageDebugScreenState();
}

class _FirebaseStorageDebugScreenState extends State<FirebaseStorageDebugScreen> {
  List<String> logs = [];
  
  void addLog(String message) {
    setState(() {
      logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print(message);
  }

  Future<void> testFirebaseStorage() async {
    logs.clear();
    
    try {
      addLog('🔄 Testing Firebase Storage...');
      
      // 1. Check Firebase initialization
      if (Firebase.apps.isEmpty) {
        addLog('⚠️ Firebase not initialized, initializing...');
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      addLog('✅ Firebase initialized');
      
      // 2. Check authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        addLog('❌ No user logged in');
        return;
      }
      addLog('✅ User authenticated: ${user.uid}');
      addLog('📧 User email: ${user.email}');
      
      // 3. Test Firebase Storage connection
      final storage = FirebaseStorage.instance;
      addLog('🔗 Storage instance: ${storage.bucket}');
      
      // 4. Try to list files in root (test permissions)
      try {
        final rootRef = storage.ref();
        addLog('📂 Testing root access...');
        final listResult = await rootRef.list(const ListOptions(maxResults: 1));
        addLog('✅ Root access successful, found ${listResult.items.length} items');
      } catch (e) {
        addLog('❌ Root access failed: $e');
      }
      
      // 5. Test creating a simple text file
      try {
        final testRef = storage.ref().child('test').child('${user.uid}_test.txt');
        addLog('📝 Testing simple text upload to: ${testRef.fullPath}');
        
        final testData = 'Hello Firebase Storage - ${DateTime.now()}';
        final uploadTask = testRef.putString(testData);
        await uploadTask;
        
        addLog('✅ Text upload successful');
        
        // Try to get download URL
        final downloadUrl = await testRef.getDownloadURL();
        addLog('🔗 Download URL: ${downloadUrl.substring(0, 50)}...');
        
        // Clean up
        await testRef.delete();
        addLog('🗑️ Test file deleted');
        
      } catch (e) {
        addLog('❌ Text upload failed: $e');
      }
      
      // 6. Test profile_images directory access
      try {
        final profileDir = storage.ref().child('profile_images');
        addLog('📂 Testing profile_images directory...');
        final listResult = await profileDir.list(const ListOptions(maxResults: 10));
        addLog('✅ Profile directory accessible, found ${listResult.items.length} files');
      } catch (e) {
        addLog('❌ Profile directory access failed: $e');
      }
      
      addLog('🏁 Storage test completed');
      
    } catch (e) {
      addLog('💥 Critical error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Storage Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: testFirebaseStorage,
              child: Text('Test Firebase Storage'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                Color color = Colors.black;
                if (log.contains('❌')) color = Colors.red;
                if (log.contains('✅')) color = Colors.green;
                if (log.contains('⚠️')) color = Colors.orange;
                
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}