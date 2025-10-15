# 🔧 Provider Dashboard Migration Steps

## Current Status

✅ **Completed:**
1. Created `AppointmentRequestService` with all necessary methods
2. Created Cloud Functions for auto-cleanup
3. Added complete documentation in `APPOINTMENT_REQUEST_SYSTEM.md`
4. Updated imports in provider_dashboard_screen.dart
5. Added stream subscription fields
6. Created `_startRequestsStream()` and `_startAppointmentsStream()` methods

❌ **Remaining Issues:**
1. `initState()` still calls `_startScheduleUpdates()` (line 70) - should be removed
2. `dispose()` still references `_scheduleSubscription` (line 158) - needs update
3. `_buildRequestCard()` expects old model type - needs signature change
4. `_buildTodayScheduleSection()` references `_todaySchedule` - needs to use `_upcomingAppointments`
5. Section title "Today's Schedule" - should be "Upcoming Appointments"

---

## 🔨 Step-by-Step Fixes

### 1. Fix `initState()` Method (Line ~68-70)

**Current Code:**
```dart
_loadProviderData();
_startStatusUpdates();
_startScheduleUpdates(); // ❌ Remove this
_initializeLocationTracking();
```

**Fixed Code:**
```dart
_loadProviderData(); // This now calls _startRequestsStream() and _startAppointmentsStream()
_startStatusUpdates();
_initializeLocationTracking();
```

---

### 2. Fix `dispose()` Method (Line ~156-160)

**Current Code:**
```dart
@override
void dispose() {
  _fadeController.dispose();
  _slideController.dispose();
  _pulseController.dispose();
  _staggerController.dispose();
  _statusTimer?.cancel();
  _scheduleSubscription?.cancel(); // ❌ Replace
  super.dispose();
}
```

**Fixed Code:**
```dart
@override
void dispose() {
  _fadeController.dispose();
  _slideController.dispose();
  _pulseController.dispose();
  _staggerController.dispose();
  _statusTimer?.cancel();
  _requestsSubscription?.cancel(); // ✅ Cancel requests stream
  _appointmentsSubscription?.cancel(); // ✅ Cancel appointments stream
  super.dispose();
}
```

---

### 3. Fix `_buildRequestCard()` Signature (Line ~1058)

**Current Code:**
```dart
Widget _buildRequestCard(DashboardService.AppointmentRequest request) {
  // ... implementation
}
```

**Fixed Code:**
```dart
Widget _buildRequestCard(RequestService.AppointmentRequest request) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showRequestDetailsDialog(request);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Patient name and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Patient avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text(
                          request.patientName.isNotEmpty 
                              ? request.patientName[0].toUpperCase()
                              : 'P',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Patient name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.patientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (request.patientPhone.isNotEmpty)
                              Text(
                                request.patientPhone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Time ago badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.isExpired 
                        ? Colors.red.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTimeAgo(request.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: request.isExpired ? Colors.red : AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Service and appointment details
            Row(
              children: [
                Icon(Icons.medical_services, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.service,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  request.formattedDateTime,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${request.totalAmount} MAD (${request.paymentMethod})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Accept/Reject buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptAppointmentRequest(request),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectAppointmentRequest(request),
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// Helper method for time ago display
String _getTimeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  
  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else {
    return '${difference.inDays}d ago';
  }
}
```

---

### 4. Add Accept/Reject Handler Methods

**Add these methods after `_buildRequestCard()`:**

```dart
/// Accept an appointment request
Future<void> _acceptAppointmentRequest(RequestService.AppointmentRequest request) async {
  try {
    HapticFeedback.mediumImpact();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    final success = await RequestService.AppointmentRequestService
        .acceptAppointmentRequest(request.id);
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog
    
    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Accepted appointment with ${request.patientName}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Reload dashboard stats
      await _loadDashboardStats();
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to accept appointment'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    print('❌ Error accepting appointment: $e');
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog if still open
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Reject an appointment request
Future<void> _rejectAppointmentRequest(RequestService.AppointmentRequest request) async {
  try {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Appointment?'),
        content: Text(
          'Are you sure you want to reject the appointment request from ${request.patientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    HapticFeedback.mediumImpact();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    final success = await RequestService.AppointmentRequestService
        .rejectAppointmentRequest(request.id);
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog
    
    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejected appointment with ${request.patientName}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to reject appointment'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    print('❌ Error rejecting appointment: $e');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Show request details in a dialog
void _showRequestDetailsDialog(RequestService.AppointmentRequest request) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Request from ${request.patientName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phone', request.patientPhone),
            _buildDetailRow('Service', request.service),
            _buildDetailRow('Date & Time', request.formattedDateTime),
            _buildDetailRow('Price', '${request.prix} MAD'),
            _buildDetailRow('Service Fee', '${request.serviceFee} MAD'),
            _buildDetailRow('Total', '${request.totalAmount} MAD'),
            _buildDetailRow('Payment', request.paymentMethod),
            _buildDetailRow('Type', request.type),
            if (request.patientAddress != null)
              _buildDetailRow('Address', request.patientAddress!),
            if (request.notes != null && request.notes!.isNotEmpty)
              _buildDetailRow('Notes', request.notes!),
            _buildDetailRow('Requested', _getTimeAgo(request.createdAt)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _acceptAppointmentRequest(request);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Accept'),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
```

---

### 5. Update `_buildTodayScheduleSection()` to `_buildUpcomingAppointmentsSection()` (Line ~1280-1470)

**Changes needed:**
- Rename method from `_buildTodayScheduleSection` to `_buildUpcomingAppointmentsSection`
- Replace all `_todaySchedule` with `_upcomingAppointments`
- Replace all `_isLoadingSchedule` with `_isLoadingAppointments`
- Change title from "Today's Schedule" to "Upcoming Appointments"
- Update card UI to show relative dates (Today, Tomorrow, future dates)

**Update the section title:**
```dart
Text(
  'Upcoming Appointments',  // Changed from "Today's Schedule"
  style: TextStyle(
    color: AppTheme.primaryColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),
```

**Update the empty state:**
```dart
Text(
  'No upcoming appointments',  // Changed from "No appointments today"
  style: TextStyle(
    fontSize: 16,
    color: Colors.grey[600],
    fontWeight: FontWeight.w500,
  ),
),
Text(
  'Your accepted appointments will appear here',  // Updated message
  style: TextStyle(
    fontSize: 14,
    color: Colors.grey[500],
  ),
  textAlign: TextAlign.center,
),
```

---

### 6. Update `_buildScheduleCard()` Method

**Add support for relative date display:**

```dart
Widget _buildScheduleCard(RequestService.UpcomingAppointment appointment) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: appointment.isToday 
                  ? Colors.green.withOpacity(0.1)
                  : appointment.isTomorrow
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${appointment.appointmentDate.day}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: appointment.isToday 
                        ? Colors.green
                        : appointment.isTomorrow
                            ? Colors.blue
                            : Colors.grey[700],
                  ),
                ),
                Text(
                  appointment.dayOfWeek,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Appointment details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (appointment.isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (appointment.isTomorrow)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TOMORROW',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      appointment.appointmentTime,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.medical_services, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        appointment.service,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // View details button
          IconButton(
            onPressed: () => _showAppointmentDetailsDialog(appointment),
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    ),
  );
}

void _showAppointmentDetailsDialog(RequestService.UpcomingAppointment appointment) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Appointment Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Patient', appointment.patientName),
            _buildDetailRow('Phone', appointment.patientPhone),
            _buildDetailRow('Service', appointment.service),
            _buildDetailRow('Date', appointment.formattedDate),
            _buildDetailRow('Time', appointment.appointmentTime),
            _buildDetailRow('Price', '${appointment.prix} MAD'),
            _buildDetailRow('Payment', appointment.paymentMethod),
            _buildDetailRow('Type', appointment.type),
            if (appointment.patientAddress != null)
              _buildDetailRow('Address', appointment.patientAddress!),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              _buildDetailRow('Notes', appointment.notes!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // TODO: Add mark as complete functionality
          },
          child: const Text('Mark Complete'),
        ),
      ],
    ),
  );
}
```

---

## 📝 Summary of All Required Changes

| File | Line(s) | Change | Status |
|------|---------|--------|--------|
| `provider_dashboard_screen.dart` | 70 | Remove `_startScheduleUpdates()` | ❌ Pending |
| `provider_dashboard_screen.dart` | 158 | Update `dispose()` method | ❌ Pending |
| `provider_dashboard_screen.dart` | ~1058 | Fix `_buildRequestCard()` signature | ❌ Pending |
| `provider_dashboard_screen.dart` | After 1058 | Add accept/reject handler methods | ❌ Pending |
| `provider_dashboard_screen.dart` | ~1280-1470 | Rename section to "Upcoming Appointments" | ❌ Pending |
| `provider_dashboard_screen.dart` | ~1280-1470 | Replace `_todaySchedule` with `_upcomingAppointments` | ❌ Pending |
| `provider_dashboard_screen.dart` | ~1360 | Update `_buildScheduleCard()` with relative dates | ❌ Pending |

---

## 🚀 After Fixes

1. Hot restart the app
2. Test pending requests appear in dashboard
3. Test accept button moves request to appointments
4. Test reject button deletes request
5. Test upcoming appointments display correctly
6. Deploy Cloud Functions
7. Test auto-cleanup after 10 minutes

