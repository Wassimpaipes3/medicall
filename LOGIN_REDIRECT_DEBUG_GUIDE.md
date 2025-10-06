# 🔍 LOGIN REDIRECT DEBUGGING GUIDE

## The Problem

Role change works (saves to correct collection) but doesn't redirect to the matching home screen.

---

## 🔍 Debug Steps

### Step 1: Check What Route Is Being Returned

Add debug logging to see what route is being generated:

**In `lib/services/role_redirect_service.dart`** - `getRedirectRoute()`:

```dart
static Future<String> getRedirectRoute() async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('❌ [Redirect] No user logged in');
      return '/login';
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (!userDoc.exists) {
      debugPrint('❌ [Redirect] User document not found');
      return '/home';
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final role = userData['role'] as String?;

    debugPrint('👤 [Redirect] User role: $role');  // ← ADD THIS

    await _cleanupOldRoleDocuments(user.uid, role);

    // Return appropriate route based on role
    String redirectRoute;
    switch (role) {
      case 'patient':
        redirectRoute = '/home';
        break;
      case 'doctor':
      case 'docteur':
      case 'infirmier':
      case 'nurse':
      case 'professional':
        redirectRoute = '/provider-dashboard';
        break;
      case 'admin':
        redirectRoute = '/admin-dashboard';
        break;
      default:
        debugPrint('⚠️ [Redirect] Unknown role: $role, defaulting to patient');
        redirectRoute = '/home';
    }

    debugPrint('🎯 [Redirect] Redirecting to: $redirectRoute');  // ← ADD THIS
    return redirectRoute;
  } catch (e) {
    debugPrint('❌ [Redirect] Error: $e');
    return '/home';
  }
}
```

---

### Step 2: Check Login Screen Is Using The Route

**In `lib/screens/auth/login_screen.dart`**:

```dart
if (result['success'] == true) {
  final redirectRoute = result['redirectRoute'] ?? '/home';
  
  // ← ADD DEBUG LOGGING
  debugPrint('✅ [Login] Login successful');
  debugPrint('🎯 [Login] Redirect route: $redirectRoute');
  debugPrint('📍 [Login] Navigating to: $redirectRoute');
  
  Navigator.pushReplacementNamed(context, redirectRoute);
}
```

---

### Step 3: Verify Routes Are Registered

Check `lib/main.dart` to ensure routes exist:

```dart
routes: {
  '/home': (context) => ...,                    // ✅ Patient
  '/provider-dashboard': (context) => ...,      // ✅ Provider
  '/admin-dashboard': (context) => ...,         // ✅ Admin
}
```

---

### Step 4: Check RouteGuard Isn't Blocking

The routes use `RouteGuard.providerRouteGuard()`. Let me check if this is blocking the navigation:

**In `lib/middleware/route_guard.dart`** (or wherever RouteGuard is):

```dart
static Widget providerRouteGuard({required Widget child}) {
  return FutureBuilder(
    future: _checkProviderRole(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final isProvider = snapshot.data == true;
      debugPrint('🛡️ [RouteGuard] Is provider: $isProvider');  // ← ADD THIS
      
      if (!isProvider) {
        debugPrint('❌ [RouteGuard] Not a provider, redirecting to home');  // ← ADD THIS
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/home');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      
      return child;
    },
  );
}
```

---

## 🐛 Potential Issues

### Issue 1: RouteGuard Checking Old Role

**Problem**: RouteGuard might be checking the role BEFORE it's updated in Firestore

**Solution**: Ensure role is updated BEFORE navigation happens

---

### Issue 2: Real-Time Monitoring Interfering

**Problem**: Real-time monitoring might detect the change and redirect again

**Flow**:
1. Login → Navigate to `/provider-dashboard`
2. Real-time monitoring starts
3. Sees role = "infirmier"
4. Triggers `_handleRoleChange()`
5. Redirects again (possibly to wrong place?)

**Solution**: Check `real_time_role_service.dart` - `_handleRoleChange()`:

```dart
Future<void> _handleRoleChange(String? newRole) async {
  debugPrint('🔄 [RoleMonitoring] Role changed from $_currentRole to $newRole');
  
  // Skip if role didn't actually change
  if (newRole == _currentRole) {
    debugPrint('⏭️ [RoleMonitoring] Role unchanged, skipping');
    return;
  }
  
  // ... rest of the code
}
```

---

### Issue 3: _cleanupOldRoleDocuments Deleting New Document

We already fixed this with `_shouldKeepDocument()`, but let's verify:

```dart
static bool _shouldKeepDocument(String collection, String? currentRole) {
  switch (currentRole) {
    case 'patient':
      return collection == 'patients';
    case 'doctor':
    case 'docteur':
    case 'infirmier':   // ✅ Should be here
    case 'nurse':       // ✅ Should be here
    case 'professional':
      return collection == 'professionals';
    default:
      return false;
  }
}
```

---

## 🧪 Test Procedure

### Test 1: Login With Existing Infirmier User

1. Have a user with role="infirmier" in Firestore
2. Login with that user
3. Check console logs:
   ```
   👤 [Redirect] User role: infirmier
   🎯 [Redirect] Redirecting to: /provider-dashboard
   ✅ [Login] Login successful
   🎯 [Login] Redirect route: /provider-dashboard
   📍 [Login] Navigating to: /provider-dashboard
   ```
4. **Expected**: Navigate to provider dashboard
5. **Check**: Is `/provider-dashboard` route registered?
6. **Check**: Does `RouteGuard.providerRouteGuard()` allow infirmier?

---

### Test 2: Role Change Then Login

1. Change user role from "patient" to "infirmier" in admin
2. Logout
3. Login again
4. Check logs
5. **Expected**: Navigate to provider dashboard

---

### Test 3: Real-Time Role Change

1. Login as patient
2. While logged in, have admin change role to "infirmier"
3. Check logs:
   ```
   🔄 [RoleMonitoring] Role changed from patient to infirmier
   🧭 Navigating to: /provider-dashboard
   ```
4. **Expected**: Automatically navigate to provider dashboard

---

## 🔧 Most Likely Issues

### 1. RouteGuard Not Recognizing Infirmier

**File**: `lib/middleware/route_guard.dart`

**Fix**: Update `_checkProviderRole()` to recognize infirmier:

```dart
static Future<bool> _checkProviderRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  if (!doc.exists) return false;

  final role = doc.data()?['role'] as String?;
  
  // ✅ Check if role is provider-type
  return role == 'doctor' || 
         role == 'docteur' || 
         role == 'infirmier' ||     // ← ADD THIS
         role == 'nurse' ||         // ← ADD THIS
         role == 'professional' ||
         role == 'provider';
}
```

---

### 2. Real-Time Monitoring Initial State Issue

**File**: `lib/services/real_time_role_service.dart`

**Problem**: `_currentRole` starts as `null`, so first role change might not trigger properly

**Fix**: Set initial role when starting monitoring:

```dart
Future<void> startRoleMonitoring() async {
  try {
    final user = _auth.currentUser;
    if (user == null) return;

    _currentUserId = user.uid;
    
    // ✅ Get initial role to avoid false trigger
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>?;
      _currentRole = data?['role'] as String?;
      debugPrint('🎯 Initial role set to: $_currentRole');
    }

    // Listen to real-time changes
    _roleSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(_onRoleDocumentChanged);

    debugPrint('✅ Real-time role monitoring started');
  } catch (e) {
    debugPrint('❌ Error starting role monitoring: $e');
  }
}
```

---

## 📝 Summary

The most likely issues are:

1. ✅ **RouteGuard not recognizing infirmier/nurse** - Check `route_guard.dart`
2. ✅ **Real-time monitoring initial state** - Set `_currentRole` on start
3. ⚠️ **Routes not registered** - Verify in `main.dart`
4. ⚠️ **Navigation timing** - Role change happens after navigation

**Next Steps**:
1. Add debug logging to see exact flow
2. Check RouteGuard allows infirmier
3. Verify initial role state in monitoring
4. Test with console logs
