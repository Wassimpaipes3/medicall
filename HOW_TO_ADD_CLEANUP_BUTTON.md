# 🎯 How to Add Cleanup Button to Your App

## ✅ EASIEST METHOD: Add to Any Screen

### Step 1: Import the widget

Add this to the TOP of any screen file:

```dart
import 'package:firstv/widgets/cleanup_requests_button.dart';
```

### Step 2: Add the button anywhere

**Example locations:**

---

## 📍 **Option 1: Provider Dashboard (Floating Button)**

File: `lib/screens/provider/provider_dashboard_screen.dart`

Add this to the `Scaffold`:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(...),
    body: ...,
    
    // 🔥 ADD THIS:
    floatingActionButton: CleanupRequestsFAB(),
  );
}
```

---

## 📍 **Option 2: Add to Settings/Profile Screen**

File: Any settings screen

```dart
Column(
  children: [
    ListTile(
      title: Text('Account Settings'),
      trailing: Icon(Icons.chevron_right),
    ),
    ListTile(
      title: Text('Notifications'),
      trailing: Icon(Icons.chevron_right),
    ),
    
    // 🔥 ADD THIS:
    Padding(
      padding: EdgeInsets.all(16),
      child: CleanupRequestsButton(),
    ),
  ],
)
```

---

## 📍 **Option 3: Add to AppBar Actions**

```dart
AppBar(
  title: Text('Dashboard'),
  actions: [
    // 🔥 ADD THIS:
    IconButton(
      icon: Icon(Icons.delete_sweep),
      onPressed: () async {
        final result = await ProviderRequestCleanupHelper.cleanupAllRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted ${result['deleted']} old requests'),
            backgroundColor: Colors.green,
          ),
        );
      },
    ),
  ],
)
```

---

## 📍 **Option 4: Add to Drawer Menu**

```dart
Drawer(
  child: ListView(
    children: [
      DrawerHeader(...),
      ListTile(title: Text('Dashboard')),
      ListTile(title: Text('Profile')),
      Divider(),
      
      // 🔥 ADD THIS:
      Padding(
        padding: EdgeInsets.all(16),
        child: CleanupRequestsButton(),
      ),
    ],
  ),
)
```

---

## 🚀 **QUICK TEST: Add to main.dart**

The FASTEST way to test (temporary):

File: `lib/main.dart`

Find the home screen and add a FAB:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Test')),
        body: Center(child: Text('Home')),
        
        // 🔥 ADD THIS FOR TESTING:
        floatingActionButton: CleanupRequestsFAB(),
      ),
    );
  }
}
```

---

## 📱 **SIMPLEST WAY: Direct Function Call**

If you just want to run it once without UI:

```dart
import 'package:firstv/services/provider_request_cleanup_helper.dart';

// Call anywhere in your code:
Future<void> runCleanup() async {
  final result = await ProviderRequestCleanupHelper.cleanupAllRequests();
  print('✅ Deleted ${result['deleted']} documents');
}
```

---

## 🎬 **COMPLETE EXAMPLE: Provider Dashboard**

Here's a complete example you can copy-paste:

```dart
// lib/screens/provider/provider_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:firstv/widgets/cleanup_requests_button.dart'; // 👈 ADD THIS

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provider Dashboard'),
      ),
      body: Column(
        children: [
          // Your existing dashboard content...
          
          // 👇 ADD THIS AT THE BOTTOM:
          Padding(
            padding: EdgeInsets.all(16),
            child: CleanupRequestsButton(),
          ),
        ],
      ),
      
      // OR use floating button:
      floatingActionButton: CleanupRequestsFAB(), // 👈 ADD THIS
    );
  }
}
```

---

## ⚡ **INSTANT TEST (No UI needed)**

Want to run it RIGHT NOW without adding buttons?

1. Open **Firebase Console**: https://console.firebase.google.com/project/nursinghomecare-1807f/functions

2. Find `manualCleanupProviderRequests` function

3. Click **"Test function"** 

4. Enter: `{}`

5. Click **"Run"**

6. Done! All old requests deleted! ✅

---

## 🎯 **MY RECOMMENDATION**

**For testing NOW:**
- Add `CleanupRequestsFAB()` to your main provider dashboard
- It's a floating button that appears in bottom-right corner
- One tap to clean everything

**For production:**
- Remove the button after initial cleanup
- Automatic system will handle new requests (10 min TTL)

---

## 📝 **Quick Checklist**

- [ ] Import: `import 'package:firstv/widgets/cleanup_requests_button.dart';`
- [ ] Add widget: `CleanupRequestsButton()` or `CleanupRequestsFAB()`
- [ ] Run app
- [ ] Tap button
- [ ] Confirm deletion
- [ ] Check Firebase Console - documents deleted! ✅

**That's it!** 🎉
