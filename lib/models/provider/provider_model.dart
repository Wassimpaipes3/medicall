import '../../data/models/location_models.dart';

enum ProviderType { doctor, nurse }

enum ProviderStatus { 
  offline, 
  online, 
  busy,
  enRoute, 
  inService,
  break_ 
}

enum VerificationStatus { 
  pending, 
  verified, 
  rejected, 
  expired 
}

class ProviderUser {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final ProviderType providerType;
  final String specialty;
  final String bio;
  final String profileImageUrl;
  final double rating;
  final int totalReviews;
  final int yearsOfExperience;
  final List<String> certifications;
  final VerificationStatus verificationStatus;
  final DateTime joinedDate;
  final bool isAvailable;
  final ProviderStatus currentStatus;
  final UserLocation? currentLocation;
  final WorkingHours workingHours;
  final PricingConfig pricingConfig;

  const ProviderUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.providerType,
    required this.specialty,
    this.bio = '',
    this.profileImageUrl = '',
    this.rating = 0.0,
    this.totalReviews = 0,
    this.yearsOfExperience = 0,
    this.certifications = const [],
    this.verificationStatus = VerificationStatus.pending,
    required this.joinedDate,
    this.isAvailable = false,
    this.currentStatus = ProviderStatus.offline,
    this.currentLocation,
    required this.workingHours,
    required this.pricingConfig,
  });

  ProviderUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    ProviderType? providerType,
    String? specialty,
    String? bio,
    String? profileImageUrl,
    double? rating,
    int? totalReviews,
    int? yearsOfExperience,
    List<String>? certifications,
    VerificationStatus? verificationStatus,
    DateTime? joinedDate,
    bool? isAvailable,
    ProviderStatus? currentStatus,
    UserLocation? currentLocation,
    WorkingHours? workingHours,
    PricingConfig? pricingConfig,
  }) {
    return ProviderUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      providerType: providerType ?? this.providerType,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      certifications: certifications ?? this.certifications,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      joinedDate: joinedDate ?? this.joinedDate,
      isAvailable: isAvailable ?? this.isAvailable,
      currentStatus: currentStatus ?? this.currentStatus,
      currentLocation: currentLocation ?? this.currentLocation,
      workingHours: workingHours ?? this.workingHours,
      pricingConfig: pricingConfig ?? this.pricingConfig,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'providerType': providerType.name,
      'specialty': specialty,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'totalReviews': totalReviews,
      'yearsOfExperience': yearsOfExperience,
      'certifications': certifications,
      'verificationStatus': verificationStatus.name,
      'joinedDate': joinedDate.toIso8601String(),
      'isAvailable': isAvailable,
      'currentStatus': currentStatus.name,
      'currentLocation': currentLocation?.toJson(),
      'workingHours': workingHours.toJson(),
      'pricingConfig': pricingConfig.toJson(),
    };
  }

  factory ProviderUser.fromJson(Map<String, dynamic> json) {
    return ProviderUser(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      providerType: ProviderType.values.firstWhere(
        (e) => e.name == json['providerType'],
        orElse: () => ProviderType.nurse,
      ),
      specialty: json['specialty'],
      bio: json['bio'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      certifications: List<String>.from(json['certifications'] ?? []),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      joinedDate: DateTime.parse(json['joinedDate']),
      isAvailable: json['isAvailable'] ?? false,
      currentStatus: ProviderStatus.values.firstWhere(
        (e) => e.name == json['currentStatus'],
        orElse: () => ProviderStatus.offline,
      ),
      currentLocation: json['currentLocation'] != null 
          ? UserLocation.fromJson(json['currentLocation'])
          : null,
      workingHours: WorkingHours.fromJson(json['workingHours']),
      pricingConfig: PricingConfig.fromJson(json['pricingConfig']),
    );
  }
}

class WorkingHours {
  final Map<String, DaySchedule> schedule;
  final bool isFlexible;
  final List<String> breakTimes;

  const WorkingHours({
    required this.schedule,
    this.isFlexible = false,
    this.breakTimes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'schedule': schedule.map((key, value) => MapEntry(key, value.toJson())),
      'isFlexible': isFlexible,
      'breakTimes': breakTimes,
    };
  }

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      schedule: (json['schedule'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, DaySchedule.fromJson(value)),
      ),
      isFlexible: json['isFlexible'] ?? false,
      breakTimes: List<String>.from(json['breakTimes'] ?? []),
    );
  }
}

class DaySchedule {
  final bool isWorking;
  final String startTime;
  final String endTime;

  const DaySchedule({
    required this.isWorking,
    this.startTime = '09:00',
    this.endTime = '17:00',
  });

  Map<String, dynamic> toJson() {
    return {
      'isWorking': isWorking,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isWorking: json['isWorking'] ?? false,
      startTime: json['startTime'] ?? '09:00',
      endTime: json['endTime'] ?? '17:00',
    );
  }
}

class PricingConfig {
  final double baseRate;
  final double emergencyRate;
  final double nightRate;
  final double weekendRate;
  final bool acceptsInsurance;
  final List<String> acceptedPaymentMethods;

  const PricingConfig({
    required this.baseRate,
    this.emergencyRate = 0.0,
    this.nightRate = 0.0,
    this.weekendRate = 0.0,
    this.acceptsInsurance = false,
    this.acceptedPaymentMethods = const ['cash', 'card'],
  });

  Map<String, dynamic> toJson() {
    return {
      'baseRate': baseRate,
      'emergencyRate': emergencyRate,
      'nightRate': nightRate,
      'weekendRate': weekendRate,
      'acceptsInsurance': acceptsInsurance,
      'acceptedPaymentMethods': acceptedPaymentMethods,
    };
  }

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      baseRate: (json['baseRate'] ?? 0.0).toDouble(),
      emergencyRate: (json['emergencyRate'] ?? 0.0).toDouble(),
      nightRate: (json['nightRate'] ?? 0.0).toDouble(),
      weekendRate: (json['weekendRate'] ?? 0.0).toDouble(),
      acceptsInsurance: json['acceptsInsurance'] ?? false,
      acceptedPaymentMethods: List<String>.from(
        json['acceptedPaymentMethods'] ?? ['cash', 'card']
      ),
    );
  }
}
