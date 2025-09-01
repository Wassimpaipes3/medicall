import 'dart:math';
import '../models/location_models.dart';
import 'location_service.dart';

class PricingService {
  static final PricingService _instance = PricingService._internal();
  factory PricingService() => _instance;
  PricingService._internal();

  final LocationService _locationService = LocationService();

  // Base pricing constants
  static const double _baseConsultationFee = 75.0;
  static const double _baseTravelFee = 10.0;
  static const double _perKmRate = 2.5;
  static const double _nightSurcharge = 1.2; // 20% increase
  static const double _weekendSurcharge = 1.15; // 15% increase
  static const double _emergencySurcharge = 1.5; // 50% increase

  /// Calculate total cost for a service
  Map<String, dynamic> calculateServiceCost({
    required HealthcareProvider provider,
    required UserLocation patientLocation,
    required String serviceType,
    required DateTime appointmentDateTime,
    bool isEmergency = false,
  }) {
    // Base service cost
    double serviceCost = provider.pricing[serviceType] ?? _baseConsultationFee;
    
    // Travel cost calculation
    double travelCost = _calculateTravelCost(
      provider.currentLocation!,
      patientLocation,
    );
    
    // Time-based surcharges
    double timeSurcharge = _calculateTimeSurcharge(appointmentDateTime);
    
    // Emergency surcharge
    double emergencySurcharge = isEmergency ? _emergencySurcharge : 1.0;
    
    // Calculate total
    double subtotal = serviceCost + travelCost;
    double surchargedAmount = subtotal * timeSurcharge * emergencySurcharge;
    
    // Calculate taxes (example: 8% tax)
    double taxRate = 0.08;
    double taxes = surchargedAmount * taxRate;
    double total = surchargedAmount + taxes;

    return {
      'serviceCost': serviceCost,
      'travelCost': travelCost,
      'subtotal': subtotal,
      'timeSurcharge': timeSurcharge,
      'emergencySurcharge': emergencySurcharge,
      'surchargedAmount': surchargedAmount,
      'taxes': taxes,
      'taxRate': taxRate,
      'total': total,
      'breakdown': _createPriceBreakdown(
        serviceCost: serviceCost,
        travelCost: travelCost,
        timeSurcharge: timeSurcharge,
        emergencySurcharge: emergencySurcharge,
        taxes: taxes,
        isEmergency: isEmergency,
        appointmentDateTime: appointmentDateTime,
      ),
    };
  }

  /// Calculate travel cost based on distance
  double _calculateTravelCost(UserLocation from, UserLocation to) {
    double distance = _locationService.calculateDistance(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    
    return _baseTravelFee + (distance * _perKmRate);
  }

  /// Calculate time-based surcharge
  double _calculateTimeSurcharge(DateTime appointmentDateTime) {
    double surcharge = 1.0;
    
    // Night surcharge (10 PM - 6 AM)
    int hour = appointmentDateTime.hour;
    if (hour >= 22 || hour < 6) {
      surcharge *= _nightSurcharge;
    }
    
    // Weekend surcharge (Saturday and Sunday)
    int weekday = appointmentDateTime.weekday;
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      surcharge *= _weekendSurcharge;
    }
    
    return surcharge;
  }

  /// Create detailed price breakdown
  List<Map<String, dynamic>> _createPriceBreakdown({
    required double serviceCost,
    required double travelCost,
    required double timeSurcharge,
    required double emergencySurcharge,
    required double taxes,
    required bool isEmergency,
    required DateTime appointmentDateTime,
  }) {
    List<Map<String, dynamic>> breakdown = [];

    // Service cost
    breakdown.add({
      'type': 'service',
      'description': 'Service Fee',
      'amount': serviceCost,
      'icon': 'medical_services',
    });

    // Travel cost
    breakdown.add({
      'type': 'travel',
      'description': 'Travel & Distance Fee',
      'amount': travelCost,
      'icon': 'directions_car',
    });

    // Time surcharges
    if (timeSurcharge > 1.0) {
      double surchargeAmount = (serviceCost + travelCost) * (timeSurcharge - 1.0);
      
      if (_isNightTime(appointmentDateTime)) {
        breakdown.add({
          'type': 'surcharge',
          'description': 'Night Time Surcharge (20%)',
          'amount': surchargeAmount,
          'icon': 'nightlight',
        });
      }
      
      if (_isWeekend(appointmentDateTime)) {
        breakdown.add({
          'type': 'surcharge',
          'description': 'Weekend Surcharge (15%)',
          'amount': surchargeAmount,
          'icon': 'weekend',
        });
      }
    }

    // Emergency surcharge
    if (isEmergency) {
      double emergencyAmount = (serviceCost + travelCost) * (emergencySurcharge - 1.0);
      breakdown.add({
        'type': 'emergency',
        'description': 'Emergency Service Surcharge (50%)',
        'amount': emergencyAmount,
        'icon': 'emergency',
      });
    }

    // Taxes
    breakdown.add({
      'type': 'tax',
      'description': 'Taxes & Fees (8%)',
      'amount': taxes,
      'icon': 'receipt',
    });

    return breakdown;
  }

  /// Check if appointment is during night time
  bool _isNightTime(DateTime dateTime) {
    int hour = dateTime.hour;
    return hour >= 22 || hour < 6;
  }

  /// Check if appointment is on weekend
  bool _isWeekend(DateTime dateTime) {
    int weekday = dateTime.weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Get estimated cost range for a service type
  Map<String, double> getServiceCostRange(String serviceType) {
    Map<String, Map<String, double>> costRanges = {
      'consultation': {'min': 50.0, 'max': 150.0},
      'checkup': {'min': 40.0, 'max': 100.0},
      'vaccination': {'min': 30.0, 'max': 80.0},
      'wound_care': {'min': 45.0, 'max': 120.0},
      'vital_signs': {'min': 25.0, 'max': 60.0},
      'ecg': {'min': 60.0, 'max': 150.0},
      'blood_pressure': {'min': 20.0, 'max': 50.0},
      'physical_therapy': {'min': 80.0, 'max': 200.0},
      'mental_health': {'min': 90.0, 'max': 250.0},
    };

    return costRanges[serviceType] ?? {'min': 50.0, 'max': 150.0};
  }

  /// Calculate distance-based pricing tiers
  List<Map<String, dynamic>> getDistancePricingTiers() {
    return [
      {
        'range': '0-2 km',
        'description': 'Within city center',
        'baseTravelFee': 10.0,
        'perKmRate': 2.0,
        'estimatedTime': '10-15 min',
      },
      {
        'range': '2-5 km',
        'description': 'Suburban areas',
        'baseTravelFee': 15.0,
        'perKmRate': 2.5,
        'estimatedTime': '15-25 min',
      },
      {
        'range': '5-10 km',
        'description': 'Extended areas',
        'baseTravelFee': 20.0,
        'perKmRate': 3.0,
        'estimatedTime': '25-40 min',
      },
      {
        'range': '10+ km',
        'description': 'Remote locations',
        'baseTravelFee': 30.0,
        'perKmRate': 3.5,
        'estimatedTime': '40+ min',
      },
    ];
  }

  /// Get pricing comparison for multiple providers
  List<Map<String, dynamic>> compareProviderPricing({
    required List<HealthcareProvider> providers,
    required UserLocation patientLocation,
    required String serviceType,
    required DateTime appointmentDateTime,
    bool isEmergency = false,
  }) {
    List<Map<String, dynamic>> comparisons = [];

    for (final provider in providers) {
      final cost = calculateServiceCost(
        provider: provider,
        patientLocation: patientLocation,
        serviceType: serviceType,
        appointmentDateTime: appointmentDateTime,
        isEmergency: isEmergency,
      );

      comparisons.add({
        'provider': provider,
        'pricing': cost,
        'costPerKm': cost['travelCost'] / 
            (provider.distanceFromPatient ?? 1.0),
        'valueScore': _calculateValueScore(provider, cost['total']),
      });
    }

    // Sort by total cost
    comparisons.sort((a, b) => 
        a['pricing']['total'].compareTo(b['pricing']['total']));

    return comparisons;
  }

  /// Calculate value score (rating vs cost)
  double _calculateValueScore(HealthcareProvider provider, double totalCost) {
    // Higher rating and lower cost = higher value score
    double ratingScore = provider.rating / 5.0; // Normalize to 0-1
    double costScore = max(0, 1.0 - (totalCost / 300.0)); // Normalize cost (assuming max $300)
    
    return (ratingScore * 0.7) + (costScore * 0.3); // Weight rating more than cost
  }

  /// Format currency for display
  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Get payment summary
  Map<String, dynamic> getPaymentSummary({
    required Map<String, dynamic> pricing,
    String? promoCode,
    double discountAmount = 0.0,
  }) {
    double total = pricing['total'];
    double finalTotal = total - discountAmount;

    return {
      'subtotal': pricing['subtotal'],
      'surcharges': pricing['surchargedAmount'] - pricing['subtotal'],
      'taxes': pricing['taxes'],
      'discount': discountAmount,
      'total': total,
      'finalTotal': finalTotal,
      'promoCode': promoCode,
      'savings': discountAmount > 0 ? discountAmount : 0.0,
    };
  }

  /// Validate pricing for appointment
  bool validatePricing({
    required HealthcareProvider provider,
    required Map<String, dynamic> calculatedPricing,
    required String serviceType,
  }) {
    // Check if service is available
    if (!provider.services.contains(serviceType)) {
      return false;
    }

    // Check if pricing is within reasonable bounds
    double total = calculatedPricing['total'];
    if (total < 20.0 || total > 1000.0) {
      return false;
    }

    // Check if provider has required pricing info
    if (!provider.pricing.containsKey(serviceType)) {
      return false;
    }

    return true;
  }
}
