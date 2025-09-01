class UserLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;
  final DateTime timestamp;
  final double? accuracy;

  UserLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
    required this.timestamp,
    this.accuracy,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      address: json['address'],
      name: json['name'],
      timestamp: DateTime.parse(json['timestamp']),
      accuracy: json['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
    };
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? name,
    DateTime? timestamp,
    double? accuracy,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}

enum ProviderStatus { available, busy, offline, enRoute }

class HealthcareProvider {
  final String id;
  final String name;
  final String specialty;
  final UserLocation? currentLocation;
  final ProviderStatus status;
  final double rating;
  final int totalReviews;
  final String profileImage;
  final String phoneNumber;
  final List<String> services;
  final Map<String, double> pricing;
  final double? distanceFromPatient;
  final int? estimatedArrivalMinutes;
  final DateTime? lastLocationUpdate;

  HealthcareProvider({
    required this.id,
    required this.name,
    required this.specialty,
    this.currentLocation,
    required this.status,
    required this.rating,
    required this.totalReviews,
    required this.profileImage,
    required this.phoneNumber,
    required this.services,
    required this.pricing,
    this.distanceFromPatient,
    this.estimatedArrivalMinutes,
    this.lastLocationUpdate,
  });

  factory HealthcareProvider.fromJson(Map<String, dynamic> json) {
    return HealthcareProvider(
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'],
      currentLocation: json['currentLocation'] != null
          ? UserLocation.fromJson(json['currentLocation'])
          : null,
      status: ProviderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ProviderStatus.offline,
      ),
      rating: json['rating'].toDouble(),
      totalReviews: json['totalReviews'],
      profileImage: json['profileImage'],
      phoneNumber: json['phoneNumber'],
      services: List<String>.from(json['services']),
      pricing: Map<String, double>.from(
        json['pricing'].map((key, value) => MapEntry(key, value.toDouble())),
      ),
      distanceFromPatient: json['distanceFromPatient']?.toDouble(),
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'],
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.parse(json['lastLocationUpdate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'currentLocation': currentLocation?.toJson(),
      'status': status.toString().split('.').last,
      'rating': rating,
      'totalReviews': totalReviews,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'services': services,
      'pricing': pricing,
      'distanceFromPatient': distanceFromPatient,
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'lastLocationUpdate': lastLocationUpdate?.toIso8601String(),
    };
  }

  HealthcareProvider copyWith({
    String? id,
    String? name,
    String? specialty,
    UserLocation? currentLocation,
    ProviderStatus? status,
    double? rating,
    int? totalReviews,
    String? profileImage,
    String? phoneNumber,
    List<String>? services,
    Map<String, double>? pricing,
    double? distanceFromPatient,
    int? estimatedArrivalMinutes,
    DateTime? lastLocationUpdate,
  }) {
    return HealthcareProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      services: services ?? this.services,
      pricing: pricing ?? this.pricing,
      distanceFromPatient: distanceFromPatient ?? this.distanceFromPatient,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
    );
  }
}

class SavedLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String type; // home, work, hospital, etc.
  final DateTime createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.createdAt,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum AppointmentStatus { pending, confirmed, inProgress, completed, cancelled }

class Appointment {
  final String id;
  final String patientId;
  final String providerId;
  final HealthcareProvider? provider;
  final UserLocation patientLocation;
  final DateTime scheduledDateTime;
  final AppointmentStatus status;
  final String serviceType;
  final Map<String, dynamic> pricing;
  final String? notes;
  final UserLocation? providerCurrentLocation;
  final int? estimatedArrivalMinutes;
  final DateTime? providerDepartedAt;
  final DateTime? providerArrivedAt;
  final DateTime? completedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.providerId,
    this.provider,
    required this.patientLocation,
    required this.scheduledDateTime,
    required this.status,
    required this.serviceType,
    required this.pricing,
    this.notes,
    this.providerCurrentLocation,
    this.estimatedArrivalMinutes,
    this.providerDepartedAt,
    this.providerArrivedAt,
    this.completedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patientId'],
      providerId: json['providerId'],
      provider: json['provider'] != null
          ? HealthcareProvider.fromJson(json['provider'])
          : null,
      patientLocation: UserLocation.fromJson(json['patientLocation']),
      scheduledDateTime: DateTime.parse(json['scheduledDateTime']),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      serviceType: json['serviceType'],
      pricing: Map<String, dynamic>.from(json['pricing']),
      notes: json['notes'],
      providerCurrentLocation: json['providerCurrentLocation'] != null
          ? UserLocation.fromJson(json['providerCurrentLocation'])
          : null,
      estimatedArrivalMinutes: json['estimatedArrivalMinutes'],
      providerDepartedAt: json['providerDepartedAt'] != null
          ? DateTime.parse(json['providerDepartedAt'])
          : null,
      providerArrivedAt: json['providerArrivedAt'] != null
          ? DateTime.parse(json['providerArrivedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'providerId': providerId,
      'provider': provider?.toJson(),
      'patientLocation': patientLocation.toJson(),
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'serviceType': serviceType,
      'pricing': pricing,
      'notes': notes,
      'providerCurrentLocation': providerCurrentLocation?.toJson(),
      'estimatedArrivalMinutes': estimatedArrivalMinutes,
      'providerDepartedAt': providerDepartedAt?.toIso8601String(),
      'providerArrivedAt': providerArrivedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? providerId,
    HealthcareProvider? provider,
    UserLocation? patientLocation,
    DateTime? scheduledDateTime,
    AppointmentStatus? status,
    String? serviceType,
    Map<String, dynamic>? pricing,
    String? notes,
    UserLocation? providerCurrentLocation,
    int? estimatedArrivalMinutes,
    DateTime? providerDepartedAt,
    DateTime? providerArrivedAt,
    DateTime? completedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      providerId: providerId ?? this.providerId,
      provider: provider ?? this.provider,
      patientLocation: patientLocation ?? this.patientLocation,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      pricing: pricing ?? this.pricing,
      notes: notes ?? this.notes,
      providerCurrentLocation: providerCurrentLocation ?? this.providerCurrentLocation,
      estimatedArrivalMinutes: estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      providerDepartedAt: providerDepartedAt ?? this.providerDepartedAt,
      providerArrivedAt: providerArrivedAt ?? this.providerArrivedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class RouteInfo {
  final List<UserLocation> routePoints;
  final double distanceInKm;
  final int durationInMinutes;
  final String polylineEncoded;
  final double estimatedCost;

  RouteInfo({
    required this.routePoints,
    required this.distanceInKm,
    required this.durationInMinutes,
    required this.polylineEncoded,
    required this.estimatedCost,
  });

  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      routePoints: (json['routePoints'] as List)
          .map((point) => UserLocation.fromJson(point))
          .toList(),
      distanceInKm: json['distanceInKm'].toDouble(),
      durationInMinutes: json['durationInMinutes'],
      polylineEncoded: json['polylineEncoded'],
      estimatedCost: json['estimatedCost'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'routePoints': routePoints.map((point) => point.toJson()).toList(),
      'distanceInKm': distanceInKm,
      'durationInMinutes': durationInMinutes,
      'polylineEncoded': polylineEncoded,
      'estimatedCost': estimatedCost,
    };
  }
}
