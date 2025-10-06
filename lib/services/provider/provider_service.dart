import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/provider/provider_model.dart';
import '../../data/models/location_models.dart' as location_models;

enum AppointmentRequestStatus { pending, accepted, rejected, cancelled, completed }
enum ProviderAvailabilityStatus { online, offline, busy }
enum MessageType { appointment, emergency, general, payment }

class AppointmentRequest {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final location_models.UserLocation patientLocation;
  final String serviceType;
  final DateTime requestedDateTime;
  final DateTime createdAt;
  final AppointmentRequestStatus status;
  final String? specialInstructions;
  final double estimatedFee;
  final int estimatedDuration; // in minutes
  final bool isEmergency;
  final double? rating;
  final String? review;
  
  const AppointmentRequest({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.patientLocation,
    required this.serviceType,
    required this.requestedDateTime,
    required this.createdAt,
    this.status = AppointmentRequestStatus.pending,
    this.specialInstructions,
    required this.estimatedFee,
    required this.estimatedDuration,
    this.isEmergency = false,
    this.rating,
    this.review,
  });

  // Helper method to get location as string
  String get patientLocationString {
    return patientLocation.address ?? 'Address not provided';
  }

  AppointmentRequest copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientPhone,
    location_models.UserLocation? patientLocation,
    String? serviceType,
    DateTime? requestedDateTime,
    DateTime? createdAt,
    AppointmentRequestStatus? status,
    String? specialInstructions,
    double? estimatedFee,
    int? estimatedDuration,
    bool? isEmergency,
    double? rating,
    String? review,
  }) {
    return AppointmentRequest(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      patientLocation: patientLocation ?? this.patientLocation,
      serviceType: serviceType ?? this.serviceType,
      requestedDateTime: requestedDateTime ?? this.requestedDateTime,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      estimatedFee: estimatedFee ?? this.estimatedFee,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      isEmergency: isEmergency ?? this.isEmergency,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}

class ProviderProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String specialization;
  final String bio;
  final int experience;
  final double rating;
  final int totalPatients;
  final double consultationFee;
  final bool emergencyNotifications;
  final bool smsNotifications;
  final bool autoAccept;
  
  const ProviderProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.specialization,
    required this.bio,
    required this.experience,
    required this.rating,
    required this.totalPatients,
    required this.consultationFee,
    this.emergencyNotifications = true,
    this.smsNotifications = true,
    this.autoAccept = false,
  });

  ProviderProfile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? specialization,
    String? bio,
    int? experience,
    double? rating,
    int? totalPatients,
    double? consultationFee,
    bool? emergencyNotifications,
    bool? smsNotifications,
    bool? autoAccept,
  }) {
    return ProviderProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      experience: experience ?? this.experience,
      rating: rating ?? this.rating,
      totalPatients: totalPatients ?? this.totalPatients,
      consultationFee: consultationFee ?? this.consultationFee,
      emergencyNotifications: emergencyNotifications ?? this.emergencyNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      autoAccept: autoAccept ?? this.autoAccept,
    );
  }
}

class EarningsData {
  final double totalEarnings;
  final int totalAppointments;
  final List<DailyEarning> dailyEarnings;
  final List<Map<String, dynamic>> recentTransactions;
  final Map<String, Map<String, dynamic>> serviceBreakdown;

  const EarningsData({
    required this.totalEarnings,
    required this.totalAppointments,
    required this.dailyEarnings,
    required this.recentTransactions,
    required this.serviceBreakdown,
  });
}

class DailyEarning {
  final DateTime date;
  final double earnings;
  final int appointments;

  const DailyEarning({
    required this.date,
    required this.earnings,
    required this.appointments,
  });
}

class ProviderMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderPhone;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final MessageType type;

  const ProviderMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderPhone,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.type = MessageType.general,
  });

  ProviderMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhone,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? attachmentUrl,
    MessageType? type,
  }) {
    return ProviderMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      type: type ?? this.type,
    );
  }
}

class ProviderService extends ChangeNotifier {
  static final ProviderService _instance = ProviderService._internal();
  factory ProviderService() => _instance;
  ProviderService._internal();

  ProviderUser? _currentProvider;
  final List<AppointmentRequest> _pendingRequests = [];
  final List<AppointmentRequest> _activeAppointments = [];
  final List<AppointmentRequest> _completedAppointments = [];
  final List<ProviderMessage> _messages = [];
  final StreamController<List<AppointmentRequest>> _requestsController = 
      StreamController<List<AppointmentRequest>>.broadcast();
  final StreamController<ProviderUser?> _providerController = 
      StreamController<ProviderUser?>.broadcast();
  
  ProviderAvailabilityStatus _currentStatus = ProviderAvailabilityStatus.offline;
  EarningsData? _earningsData;

  // Getters
  ProviderUser? get currentProvider => _currentProvider;
  List<AppointmentRequest> get pendingRequests => List.unmodifiable(_pendingRequests);
  List<AppointmentRequest> get activeAppointments => List.unmodifiable(_activeAppointments);
  List<AppointmentRequest> get completedAppointments => List.unmodifiable(_completedAppointments);
  List<ProviderMessage> get messages => List.unmodifiable(_messages);
  Stream<List<AppointmentRequest>> get requestsStream => _requestsController.stream;
  Stream<ProviderUser?> get providerStream => _providerController.stream;
  ProviderAvailabilityStatus get currentStatus => _currentStatus;
  EarningsData? get earningsData => _earningsData;

  // Initialize provider service
  Future<void> initialize() async {
    await _loadMockData();
    notifyListeners();
  }

  // Authentication
  Future<bool> loginProvider(String email, String password) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      _currentProvider = ProviderUser(
        id: 'provider_1',
        fullName: 'Dr. Sarah Johnson',
        email: email,
        phoneNumber: '+213 555 123 4567',
        providerType: ProviderType.doctor,
        specialty: 'General Medicine',
        yearsOfExperience: 8,
        rating: 4.8,
        totalReviews: 1250,
        joinedDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
        workingHours: WorkingHours(
          schedule: {
            'Monday': const DaySchedule(isWorking: true, startTime: '09:00', endTime: '17:00'),
            'Tuesday': const DaySchedule(isWorking: true, startTime: '09:00', endTime: '17:00'),
            'Wednesday': const DaySchedule(isWorking: true, startTime: '09:00', endTime: '17:00'),
            'Thursday': const DaySchedule(isWorking: true, startTime: '09:00', endTime: '17:00'),
            'Friday': const DaySchedule(isWorking: true, startTime: '09:00', endTime: '17:00'),
            'Saturday': const DaySchedule(isWorking: false),
            'Sunday': const DaySchedule(isWorking: false),
          },
        ),
        pricingConfig: const PricingConfig(
          baseRate: 150.0,
          emergencyRate: 300.0,
          acceptsInsurance: true,
          acceptedPaymentMethods: ['cash', 'card', 'insurance'],
        ),
      );
      
      _currentStatus = ProviderAvailabilityStatus.offline;
      _providerController.add(_currentProvider);
      
      await initialize();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentProvider = null;
    _currentStatus = ProviderAvailabilityStatus.offline;
    _pendingRequests.clear();
    _activeAppointments.clear();
    _completedAppointments.clear();
    _messages.clear();
    _earningsData = null;
    
    _providerController.add(null);
    notifyListeners();
  }

  // Status Management
  Future<ProviderAvailabilityStatus> getAvailabilityStatus() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentStatus;
  }

  Future<void> updateAvailabilityStatus(ProviderAvailabilityStatus status) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _currentStatus = status;
      
      if (_currentProvider != null) {
        _currentProvider = _currentProvider!.copyWith(
          currentStatus: status == ProviderAvailabilityStatus.online 
              ? ProviderStatus.online 
              : ProviderStatus.offline,
          isAvailable: status == ProviderAvailabilityStatus.online,
        );
        _providerController.add(_currentProvider);
      }
      
      HapticFeedback.lightImpact();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  // Appointment Management
  Future<void> acceptAppointment(String appointmentId) async {
    try {
      final index = _pendingRequests.indexWhere((req) => req.id == appointmentId);
      if (index != -1) {
        final appointment = _pendingRequests[index].copyWith(
          status: AppointmentRequestStatus.accepted,
        );
        
        _pendingRequests.removeAt(index);
        _activeAppointments.add(appointment);
        
        _requestsController.add(_pendingRequests);
        HapticFeedback.lightImpact();
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to accept appointment: $e');
    }
  }

  Future<void> rejectAppointment(String appointmentId) async {
    try {
      final index = _pendingRequests.indexWhere((req) => req.id == appointmentId);
      if (index != -1) {
        _pendingRequests.removeAt(index);
        _requestsController.add(_pendingRequests);
        HapticFeedback.lightImpact();
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to reject appointment: $e');
    }
  }

  Future<void> completeAppointment(String appointmentId) async {
    try {
      // 1. Update Firestore FIRST so patient can see status change
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // 2. Then update local state
      final index = _activeAppointments.indexWhere((req) => req.id == appointmentId);
      if (index != -1) {
        final appointment = _activeAppointments[index].copyWith(
          status: AppointmentRequestStatus.completed,
        );
        
        _activeAppointments.removeAt(index);
        _completedAppointments.insert(0, appointment);
        
        HapticFeedback.lightImpact();
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to complete appointment: $e');
    }
  }

  // Messages Management
  Future<List<ProviderMessage>> getMessages() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_messages);
  }

  // Additional getter methods for compatibility
  Future<ProviderUser?> getCurrentProvider() async {
    return _currentProvider;
  }

  Future<List<AppointmentRequest>> getPendingRequests() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_pendingRequests);
  }

  Future<List<AppointmentRequest>> getActiveAppointments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_activeAppointments);
  }

  Future<List<AppointmentRequest>> getCompletedAppointments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_completedAppointments);
  }

  Future<bool> respondToRequest(String requestId, bool accept) async {
    try {
      if (accept) {
        await acceptAppointment(requestId);
      } else {
        await rejectAppointment(requestId);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateProviderStatus(dynamic status) async {
    ProviderAvailabilityStatus availabilityStatus;
    
    if (status is ProviderStatus) {
      // Convert ProviderStatus to ProviderAvailabilityStatus
      switch (status) {
        case ProviderStatus.online:
        case ProviderStatus.inService:
          availabilityStatus = ProviderAvailabilityStatus.online;
        case ProviderStatus.busy:
        case ProviderStatus.enRoute:
          availabilityStatus = ProviderAvailabilityStatus.busy;
        case ProviderStatus.offline:
        case ProviderStatus.break_:
          availabilityStatus = ProviderAvailabilityStatus.offline;
      }
    } else if (status is ProviderAvailabilityStatus) {
      availabilityStatus = status;
    } else {
      availabilityStatus = ProviderAvailabilityStatus.offline;
    }
    
    await updateAvailabilityStatus(availabilityStatus);
  }

  Future<void> sendMessage(String recipientId, String content) async {
    try {
      final newMessage = ProviderMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _currentProvider?.id ?? 'provider_1',
        senderName: _currentProvider?.fullName ?? 'Provider',
        senderPhone: _currentProvider?.phoneNumber ?? '+213 555 123 4567',
        content: content,
        timestamp: DateTime.now(),
        isRead: true,
        type: MessageType.general,
      );
      
      _messages.insert(0, newMessage);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(isRead: true);
      notifyListeners();
    }
  }

  Future<void> markMessageAsUnread(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final messageIndex = _messages.indexWhere((m) => m.id == messageId);
    if (messageIndex != -1) {
      _messages[messageIndex] = _messages[messageIndex].copyWith(isRead: false);
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  // Earnings Management
  Future<EarningsData> getEarningsData(String period) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Generate realistic earnings data based on period
    final random = Random();
    final now = DateTime.now();
    final daysInPeriod = _getDaysInPeriod(period);
    
    final dailyEarnings = <DailyEarning>[];
    double totalEarnings = 0;
    int totalAppointments = 0;
    
    for (int i = daysInPeriod - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final appointmentCount = random.nextInt(5);
      final earnings = appointmentCount * (2000 + random.nextInt(3000)).toDouble();
      
      totalEarnings += earnings;
      totalAppointments += appointmentCount;
      
      dailyEarnings.add(DailyEarning(
        date: date,
        earnings: earnings,
        appointments: appointmentCount,
      ));
    }
    
    // Generate recent transactions
    final recentTransactions = <Map<String, dynamic>>[];
    for (int i = 0; i < 10; i++) {
      recentTransactions.add({
        'id': 'txn_$i',
        'description': 'Consultation - ${_getRandomPatientName()}',
        'amount': 2000 + random.nextInt(3000),
        'date': now.subtract(Duration(hours: i * 6)),
      });
    }
    
    // Generate service breakdown
    final services = ['General Consultation', 'Emergency Care', 'Blood Tests', 'Vaccination', 'Health Checkup'];
    final serviceBreakdown = <String, Map<String, dynamic>>{};
    
    for (final service in services) {
      final count = random.nextInt(10) + 1;
      final earnings = count * (1500 + random.nextInt(2000));
      serviceBreakdown[service] = {
        'count': count,
        'earnings': earnings.toDouble(),
      };
    }
    
    return EarningsData(
      totalEarnings: totalEarnings,
      totalAppointments: totalAppointments,
      dailyEarnings: dailyEarnings,
      recentTransactions: recentTransactions,
      serviceBreakdown: serviceBreakdown,
    );
  }

  int _getDaysInPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'day':
        return 1;
      case 'week':
        return 7;
      case 'month':
        return 30;
      case 'year':
        return 365;
      default:
        return 7;
    }
  }

  String _getRandomPatientName() {
    final names = ['Ahmed Ali', 'Fatima Zahra', 'Omar Mansouri', 'Amina Belkacem', 'Youssef Touzani'];
    final random = Random();
    return names[random.nextInt(names.length)];
  }

  // Profile Management
  Future<ProviderProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    return const ProviderProfile(
      id: 'provider_1',
      name: 'Dr. Sarah Johnson',
      phone: '+213 555 123 4567',
      email: 'dr.sarah@healthcare.com',
      address: '123 Medical Center, Algiers, Algeria',
      specialization: 'General Practice',
      bio: 'Experienced healthcare provider with over 8 years of experience in general medicine and emergency care.',
      experience: 8,
      rating: 4.8,
      totalPatients: 1250,
      consultationFee: 2500.0,
      emergencyNotifications: true,
      smsNotifications: true,
      autoAccept: false,
    );
  }

  Future<void> updateProfile(ProviderProfile profile) async {
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }

  // Mock data loading
  Future<void> _loadMockData() async {
    _pendingRequests.clear();
    _activeAppointments.clear();
    _completedAppointments.clear();
    _messages.clear();

    // Create mock location
    final mockLocation = location_models.UserLocation(
      latitude: 36.7528,
      longitude: 3.0420,
      address: '123 Main St, Algiers, Algeria',
      timestamp: DateTime.now(),
    );

    // Mock pending requests
    _pendingRequests.addAll([
      AppointmentRequest(
        id: 'req_1',
        patientId: 'patient_1',
        patientName: 'Ahmed Bennani',
        patientPhone: '+213 555 123 456',
        patientLocation: mockLocation,
        serviceType: 'General Consultation',
        requestedDateTime: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        estimatedFee: 5000,
        estimatedDuration: 30,
        specialInstructions: 'Patient has mild fever and headache symptoms.',
        isEmergency: false,
      ),
      AppointmentRequest(
        id: 'req_2',
        patientId: 'patient_2',
        patientName: 'Fatima Khadra',
        patientPhone: '+213 555 789 012',
        patientLocation: mockLocation,
        serviceType: 'Emergency Care',
        requestedDateTime: DateTime.now().add(const Duration(minutes: 30)),
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        estimatedFee: 15000,
        estimatedDuration: 60,
        specialInstructions: 'URGENT: Patient experiencing severe chest pain and shortness of breath.',
        isEmergency: true,
      ),
    ]);

    // Mock active appointments
    _activeAppointments.addAll([
      AppointmentRequest(
        id: 'active_1',
        patientId: 'patient_3',
        patientName: 'Omar Mansouri',
        patientPhone: '+213 555 345 678',
        patientLocation: mockLocation,
        serviceType: 'Blood Pressure Check',
        requestedDateTime: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        estimatedFee: 3000,
        estimatedDuration: 20,
        status: AppointmentRequestStatus.accepted,
        isEmergency: false,
      ),
    ]);

    // Mock completed appointments
    _completedAppointments.addAll([
      AppointmentRequest(
        id: 'completed_1',
        patientId: 'patient_4',
        patientName: 'Amina Belkacem',
        patientPhone: '+213 555 901 234',
        patientLocation: mockLocation,
        serviceType: 'Diabetes Check',
        requestedDateTime: DateTime.now().subtract(const Duration(hours: 3)),
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        estimatedFee: 7500,
        estimatedDuration: 45,
        status: AppointmentRequestStatus.completed,
        rating: 4.8,
        review: 'Excellent service! Very professional and thorough.',
        isEmergency: false,
      ),
      AppointmentRequest(
        id: 'completed_2',
        patientId: 'patient_5',
        patientName: 'Youssef Touzani',
        patientPhone: '+213 555 567 890',
        patientLocation: mockLocation,
        serviceType: 'Vaccination',
        requestedDateTime: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        estimatedFee: 4500,
        estimatedDuration: 15,
        status: AppointmentRequestStatus.completed,
        rating: 5.0,
        review: 'Quick and painless vaccination. Highly recommended!',
        isEmergency: false,
      ),
    ]);

    // Mock messages
    _messages.addAll([
      ProviderMessage(
        id: 'msg_1',
        senderId: 'patient_1',
        senderName: 'Ahmed Bennani',
        senderPhone: '+213 555 123 001',
        content: 'Hello Doctor, I have a question about my prescription for the antibiotics you prescribed last week.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
        type: MessageType.general,
      ),
      ProviderMessage(
        id: 'msg_2',
        senderId: 'patient_4',
        senderName: 'Amina Belkacem',
        senderPhone: '+213 555 123 004',
        content: 'Thank you for the excellent service yesterday! The home visit was very professional.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
        type: MessageType.general,
      ),
      ProviderMessage(
        id: 'msg_3',
        senderId: 'system',
        senderName: 'MediCall System',
        senderPhone: '+213 555 000 000',
        content: 'Your weekly earnings report is ready to view. Total: 87,500 DA',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: false,
        type: MessageType.payment,
      ),
      ProviderMessage(
        id: 'msg_4',
        senderId: 'patient_2',
        senderName: 'Omar Khaled',
        senderPhone: '+213 555 123 002',
        content: 'URGENT: My child has a high fever and difficulty breathing. Please help!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        type: MessageType.emergency,
      ),
      ProviderMessage(
        id: 'msg_5',
        senderId: 'patient_3',
        senderName: 'Fatima Zahra',
        senderPhone: '+213 555 123 003',
        content: 'Appointment confirmation for tomorrow at 2 PM. Looking forward to seeing you.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
        type: MessageType.appointment,
      ),
    ]);

    _requestsController.add(_pendingRequests);
    notifyListeners();
  }

  /// Update provider profile information
  Future<void> updateProviderProfile(ProviderUser updatedProvider) async {
    try {
      // TODO: Implement actual database update
      // For now, we'll simulate the update
      
      // Update local provider data
      _currentProvider = updatedProvider;
      
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // In a real implementation, this would:
      // 1. Send HTTP request to backend API
      // 2. Update user data in database
      // 3. Update cached user data locally
      
      print('Provider profile updated: ${updatedProvider.fullName}');
      
    } catch (e) {
      throw Exception('Failed to update provider profile: $e');
    }
  }

  @override
  void dispose() {
    _requestsController.close();
    _providerController.close();
    super.dispose();
  }
}
