import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Route information model
class RouteInfo {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final String instructions;

  RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.instructions = '',
  });
}

/// Enhanced routing service supporting multiple providers
class NavigationRoutingService {
  static const String _osrmBaseUrl = 'http://router.project-osrm.org/route/v1';
  static const Duration _timeout = Duration(seconds: 10);
  
  // You can add your Mapbox or Google API keys here
  static const String? _mapboxToken = null; // Add your Mapbox token
  static const String? _googleApiKey = null; // Add your Google API key

  /// Get route between two points using best available service
  static Future<RouteInfo?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'driving', // driving, walking, cycling
  }) async {
    
    // Try OSRM first (free)
    try {
      final osrmRoute = await _getOSRMRoute(start, end, profile);
      if (osrmRoute != null) return osrmRoute;
    } catch (e) {
      print('OSRM route failed: $e');
    }
    
    // Try Mapbox if token available
    if (_mapboxToken != null) {
      try {
        final mapboxRoute = await _getMapboxRoute(start, end, profile);
        if (mapboxRoute != null) return mapboxRoute;
      } catch (e) {
        print('Mapbox route failed: $e');
      }
    }
    
    // Try Google Directions if key available
    if (_googleApiKey != null) {
      try {
        final googleRoute = await _getGoogleRoute(start, end, profile);
        if (googleRoute != null) return googleRoute;
      } catch (e) {
        print('Google route failed: $e');
      }
    }
    
    // Fallback to straight line
    return _getStraightLineRoute(start, end);
  }

  /// Get route from OSRM (free service)
  static Future<RouteInfo?> _getOSRMRoute(
    LatLng start, 
    LatLng end, 
    String profile,
  ) async {
    final url = '$_osrmBaseUrl/$profile/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson&steps=true';

    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    
    if (response.statusCode != 200) return null;
    
    final data = json.decode(response.body);
    final routes = data['routes'] as List?;
    
    if (routes == null || routes.isEmpty) return null;
    
    final route = routes[0];
    final geometry = route['geometry'];
    final coordinates = geometry['coordinates'] as List;
    
    // Convert coordinates to LatLng points
    final points = coordinates.map<LatLng>((coord) {
      return LatLng(coord[1].toDouble(), coord[0].toDouble());
    }).toList();
    
    final distance = (route['distance'] as num).toDouble() / 1000; // Convert to km
    final duration = ((route['duration'] as num) / 60).round(); // Convert to minutes
    
    // Extract turn-by-turn instructions
    String instructions = '';
    try {
      final legs = route['legs'] as List?;
      if (legs != null && legs.isNotEmpty) {
        final steps = legs[0]['steps'] as List?;
        if (steps != null) {
          instructions = steps.map((step) => step['maneuver']['instruction']).join('\n');
        }
      }
    } catch (e) {
      // Instructions are optional
    }
    
    return RouteInfo(
      points: points,
      distanceKm: distance,
      durationMinutes: duration,
      instructions: instructions,
    );
  }

  /// Get route from Mapbox Directions API
  static Future<RouteInfo?> _getMapboxRoute(
    LatLng start,
    LatLng end,
    String profile,
  ) async {
    if (_mapboxToken == null) return null;
    
    final mapboxProfile = _convertToMapboxProfile(profile);
    final url = 'https://api.mapbox.com/directions/v5/mapbox/$mapboxProfile/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?geometries=geojson&steps=true&access_token=$_mapboxToken';

    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    
    if (response.statusCode != 200) return null;
    
    final data = json.decode(response.body);
    final routes = data['routes'] as List?;
    
    if (routes == null || routes.isEmpty) return null;
    
    final route = routes[0];
    final geometry = route['geometry'];
    final coordinates = geometry['coordinates'] as List;
    
    final points = coordinates.map<LatLng>((coord) {
      return LatLng(coord[1].toDouble(), coord[0].toDouble());
    }).toList();
    
    final distance = (route['distance'] as num).toDouble() / 1000;
    final duration = ((route['duration'] as num) / 60).round();
    
    return RouteInfo(
      points: points,
      distanceKm: distance,
      durationMinutes: duration,
    );
  }

  /// Get route from Google Directions API
  static Future<RouteInfo?> _getGoogleRoute(
    LatLng start,
    LatLng end,
    String profile,
  ) async {
    if (_googleApiKey == null) return null;
    
    final mode = _convertToGoogleMode(profile);
    final url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${start.latitude},${start.longitude}'
        '&destination=${end.latitude},${end.longitude}'
        '&mode=$mode'
        '&key=$_googleApiKey';

    final response = await http.get(Uri.parse(url)).timeout(_timeout);
    
    if (response.statusCode != 200) return null;
    
    final data = json.decode(response.body);
    final routes = data['routes'] as List?;
    
    if (routes == null || routes.isEmpty) return null;
    
    final route = routes[0];
    final legs = route['legs'] as List;
    
    if (legs.isEmpty) return null;
    
    final leg = legs[0];
    final steps = leg['steps'] as List;
    
    // Extract points from all steps
    final points = <LatLng>[];
    for (final step in steps) {
      final polyline = step['polyline']['points'] as String;
      points.addAll(_decodeGooglePolyline(polyline));
    }
    
    final distance = (leg['distance']['value'] as num).toDouble() / 1000;
    final duration = ((leg['duration']['value'] as num) / 60).round();
    
    return RouteInfo(
      points: points,
      distanceKm: distance,
      durationMinutes: duration,
    );
  }

  /// Generate straight line route as ultimate fallback
  static RouteInfo _getStraightLineRoute(LatLng start, LatLng end) {
    // Calculate straight-line distance using Haversine formula
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLng = _degreesToRadians(end.longitude - start.longitude);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(start.latitude)) *
        math.cos(_degreesToRadians(end.latitude)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    
    // Estimate duration (assuming average 30 km/h in city)
    final duration = (distance / 30 * 60).round();
    
    return RouteInfo(
      points: [start, end],
      distanceKm: distance,
      durationMinutes: duration,
      instructions: 'Direct route to destination',
    );
  }

  /// Convert profile to Mapbox format
  static String _convertToMapboxProfile(String profile) {
    switch (profile.toLowerCase()) {
      case 'walking':
        return 'walking';
      case 'cycling':
        return 'cycling';
      case 'driving':
      default:
        return 'driving';
    }
  }

  /// Convert profile to Google mode
  static String _convertToGoogleMode(String profile) {
    switch (profile.toLowerCase()) {
      case 'walking':
        return 'walking';
      case 'cycling':
        return 'bicycling';
      case 'driving':
      default:
        return 'driving';
    }
  }

  /// Decode Google polyline string to LatLng points
  static List<LatLng> _decodeGooglePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

// Import math for calculations
import 'dart:math' as math;