import 'dart:math';

class AlgeriaLocationService {
  // Major Algerian cities with their coordinates
  static final Map<String, Map<String, dynamic>> _algerianCities = {
    'Algiers': {
      'lat': 36.7538,
      'lng': 3.0588,
      'province': 'Algiers',
      'population': 2364230,
      'isCapital': true,
    },
    'Oran': {
      'lat': 35.6969,
      'lng': -0.6331,
      'province': 'Oran',
      'population': 1454078,
      'isCapital': false,
    },
    'Constantine': {
      'lat': 36.3650,
      'lng': 6.6147,
      'province': 'Constantine',
      'population': 938475,
      'isCapital': false,
    },
    'Annaba': {
      'lat': 36.9000,
      'lng': 7.7667,
      'province': 'Annaba',
      'population': 464740,
      'isCapital': false,
    },
    'Blida': {
      'lat': 36.4711,
      'lng': 2.8277,
      'province': 'Blida',
      'population': 331779,
      'isCapital': false,
    },
    'Batna': {
      'lat': 35.5559,
      'lng': 6.1743,
      'province': 'Batna',
      'population': 290645,
      'isCapital': false,
    },
    'Djelfa': {
      'lat': 34.6814,
      'lng': 3.2631,
      'province': 'Djelfa',
      'population': 265833,
      'isCapital': false,
    },
    'Sétif': {
      'lat': 36.1906,
      'lng': 5.4137,
      'province': 'Sétif',
      'population': 252127,
      'isCapital': false,
    },
    'Sidi Bel Abbès': {
      'lat': 35.1977,
      'lng': -0.6308,
      'province': 'Sidi Bel Abbès',
      'population': 210146,
      'isCapital': false,
    },
    'Biskra': {
      'lat': 34.8481,
      'lng': 5.7281,
      'province': 'Biskra',
      'population': 207987,
      'isCapital': false,
    },
    'Tébessa': {
      'lat': 35.4048,
      'lng': 8.1239,
      'province': 'Tébessa',
      'population': 190605,
      'isCapital': false,
    },
    'Tlemcen': {
      'lat': 34.8786,
      'lng': -1.3150,
      'province': 'Tlemcen',
      'population': 173531,
      'isCapital': false,
    },
    'Ouargla': {
      'lat': 31.9539,
      'lng': 5.3250,
      'province': 'Ouargla',
      'population': 164374,
      'isCapital': false,
    },
    'Skikda': {
      'lat': 36.8706,
      'lng': 6.9093,
      'province': 'Skikda',
      'population': 156680,
      'isCapital': false,
    },
    'Tiaret': {
      'lat': 35.3711,
      'lng': 1.3170,
      'province': 'Tiaret',
      'population': 201408,
      'isCapital': false,
    },
    'Béjaïa': {
      'lat': 36.7525,
      'lng': 5.0626,
      'province': 'Béjaïa',
      'population': 176139,
      'isCapital': false,
    },
    'Béchar': {
      'lat': 31.6177,
      'lng': -2.2158,
      'province': 'Béchar',
      'population': 165627,
      'isCapital': false,
    },
    'Mostaganem': {
      'lat': 35.9315,
      'lng': 0.0892,
      'province': 'Mostaganem',
      'population': 145696,
      'isCapital': false,
    },
    'Bordj Bou Arréridj': {
      'lat': 36.0731,
      'lng': 4.7611,
      'province': 'Bordj Bou Arréridj',
      'population': 140000,
      'isCapital': false,
    },
    'Chlef': {
      'lat': 36.1654,
      'lng': 1.3347,
      'province': 'Chlef',
      'population': 178616,
      'isCapital': false,
    },
    'Médéa': {
      'lat': 36.2638,
      'lng': 2.7538,
      'province': 'Médéa',
      'population': 123535,
      'isCapital': false,
    },
  };

  // Distance calculation using Haversine formula
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLng = _degreesToRadians(lng2 - lng1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Get all Algerian cities
  static List<Map<String, dynamic>> getAllCities() {
    return _algerianCities.entries.map((entry) {
      return {
        'name': entry.key,
        'lat': entry.value['lat'],
        'lng': entry.value['lng'],
        'province': entry.value['province'],
        'population': entry.value['population'],
        'isCapital': entry.value['isCapital'],
      };
    }).toList();
  }

  // Get cities by province
  static List<Map<String, dynamic>> getCitiesByProvince(String province) {
    return _algerianCities.entries
        .where((entry) => entry.value['province'] == province)
        .map((entry) => {
              'name': entry.key,
              'lat': entry.value['lat'],
              'lng': entry.value['lng'],
              'province': entry.value['province'],
              'population': entry.value['population'],
              'isCapital': entry.value['isCapital'],
            })
        .toList();
  }

  // Find nearest cities to given coordinates
  static List<Map<String, dynamic>> findNearestCities(
    double lat,
    double lng, {
    int limit = 5,
  }) {
    List<Map<String, dynamic>> cities = getAllCities();
    
    // Calculate distance for each city
    for (var city in cities) {
      city['distance'] = calculateDistance(
        lat,
        lng,
        city['lat'],
        city['lng'],
      );
    }

    // Sort by distance and return top results
    cities.sort((a, b) => a['distance'].compareTo(b['distance']));
    return cities.take(limit).toList();
  }

  // Search cities by name
  static List<Map<String, dynamic>> searchCities(String query) {
    if (query.isEmpty) return getAllCities();
    
    String lowerQuery = query.toLowerCase();
    return _algerianCities.entries
        .where((entry) => 
            entry.key.toLowerCase().contains(lowerQuery) ||
            entry.value['province'].toLowerCase().contains(lowerQuery))
        .map((entry) => {
              'name': entry.key,
              'lat': entry.value['lat'],
              'lng': entry.value['lng'],
              'province': entry.value['province'],
              'population': entry.value['population'],
              'isCapital': entry.value['isCapital'],
            })
        .toList();
  }

  // Get all provinces
  static List<String> getAllProvinces() {
    return _algerianCities.values
        .map((city) => city['province'] as String)
        .toSet()
        .toList()
        ..sort();
  }

  // Healthcare pricing based on distance and service type
  static Map<String, double> calculateHealthcarePricing({
    required double distance,
    required String serviceType,
    required String specialty,
  }) {
    // Base prices in Algerian Dinar (DZD)
    Map<String, double> basePrices = {
      'doctor_general': 3000,
      'doctor_cardiology': 5000,
      'doctor_neurology': 6000,
      'doctor_pediatrics': 4000,
      'doctor_emergency': 7000,
      'nurse_home_care': 2000,
      'nurse_wound_care': 2500,
      'nurse_medication': 1500,
      'nurse_monitoring': 1800,
    };

    String priceKey = '${serviceType.toLowerCase()}_${specialty.toLowerCase().replaceAll(' ', '_')}';
    double basePrice = basePrices[priceKey] ?? basePrices['${serviceType.toLowerCase()}_general'] ?? 2000;

    // Distance-based travel fee (100 DZD per km)
    double travelFee = distance * 100;

    // Service fee (10% of base price)
    double serviceFee = basePrice * 0.1;

    // Time-based multiplier (peak hours: 20:00-08:00 = 1.5x)
    DateTime now = DateTime.now();
    double timeMultiplier = (now.hour >= 20 || now.hour <= 8) ? 1.5 : 1.0;

    double finalBasePrice = basePrice * timeMultiplier;
    double totalPrice = finalBasePrice + travelFee + serviceFee;

    return {
      'basePrice': finalBasePrice,
      'travelFee': travelFee,
      'serviceFee': serviceFee,
      'totalPrice': totalPrice,
      'distance': distance,
      'timeMultiplier': timeMultiplier,
    };
  }

  // Get estimated arrival time based on distance and traffic
  static Map<String, dynamic> getEstimatedArrival(double distance) {
    // Average speed in Algeria: 40 km/h in cities, 60 km/h highways
    double avgSpeed = distance > 50 ? 55 : 35; // km/h
    double estimatedHours = distance / avgSpeed;
    
    // Add traffic delay (10-30% depending on time and distance)
    DateTime now = DateTime.now();
    double trafficMultiplier = 1.0;
    
    if (now.hour >= 7 && now.hour <= 9 || now.hour >= 17 && now.hour <= 19) {
      trafficMultiplier = 1.3; // Rush hour
    } else if (now.hour >= 12 && now.hour <= 14) {
      trafficMultiplier = 1.1; // Lunch time
    }
    
    estimatedHours *= trafficMultiplier;
    
    DateTime arrivalTime = now.add(Duration(
      hours: estimatedHours.floor(),
      minutes: ((estimatedHours % 1) * 60).round(),
    ));

    return {
      'estimatedHours': estimatedHours,
      'arrivalTime': arrivalTime,
      'trafficMultiplier': trafficMultiplier,
      'formattedArrival': _formatArrivalTime(arrivalTime),
      'formattedDuration': _formatDuration(estimatedHours),
    };
  }

  static String _formatArrivalTime(DateTime time) {
    String hour = time.hour.toString().padLeft(2, '0');
    String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatDuration(double hours) {
    int h = hours.floor();
    int m = ((hours % 1) * 60).round();
    
    if (h > 0 && m > 0) {
      return '${h}h ${m}m';
    } else if (h > 0) {
      return '${h}h';
    } else {
      return '${m}m';
    }
  }
}
