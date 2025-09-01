import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_models.dart';
import 'location_service.dart';

class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  
  // Getters
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  Set<Circle> get circles => _circles;
  GoogleMapController? get mapController => _mapController;

  /// Initialize map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Create custom marker from asset
  Future<BitmapDescriptor> createCustomMarker({
    required String assetPath,
    Size size = const Size(100, 100),
  }) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: size.width.toInt(),
        targetHeight: size.height.toInt(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData != null) {
        return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error creating custom marker: $e');
    }
    
    // Fallback to default marker
    return BitmapDescriptor.defaultMarker;
  }

  /// Add patient marker
  Future<void> addPatientMarker(UserLocation location) async {
    final markerId = MarkerId('patient_location');
    
    final marker = Marker(
      markerId: markerId,
      position: LatLng(location.latitude, location.longitude),
      infoWindow: InfoWindow(
        title: 'Your Location',
        snippet: location.address ?? 'Current position',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );

    _markers.removeWhere((m) => m.markerId == markerId);
    _markers.add(marker);
  }

  /// Add provider markers
  Future<void> addProviderMarkers(List<HealthcareProvider> providers) async {
    // Remove existing provider markers
    _markers.removeWhere((marker) => marker.markerId.value.startsWith('provider_'));

    for (final provider in providers) {
      if (provider.currentLocation == null) continue;

      final markerId = MarkerId('provider_${provider.id}');
      final hue = _getProviderMarkerHue(provider.status);
      
      final marker = Marker(
        markerId: markerId,
        position: LatLng(
          provider.currentLocation!.latitude,
          provider.currentLocation!.longitude,
        ),
        infoWindow: InfoWindow(
          title: provider.name,
          snippet: '${provider.specialty} • ${provider.distanceFromPatient?.toStringAsFixed(1)} km away',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        onTap: () => _onProviderMarkerTapped(provider),
      );

      _markers.add(marker);
    }
  }

  /// Get marker hue based on provider status
  double _getProviderMarkerHue(ProviderStatus status) {
    switch (status) {
      case ProviderStatus.available:
        return BitmapDescriptor.hueGreen;
      case ProviderStatus.busy:
        return BitmapDescriptor.hueOrange;
      case ProviderStatus.offline:
        return BitmapDescriptor.hueRed;
      case ProviderStatus.enRoute:
        return BitmapDescriptor.hueViolet;
    }
  }

  /// Handle provider marker tap
  void _onProviderMarkerTapped(HealthcareProvider provider) {
    // This could trigger a bottom sheet or dialog
    debugPrint('Provider tapped: ${provider.name}');
  }

  /// Draw route between two points
  Future<RouteInfo?> drawRoute({
    required LatLng start,
    required LatLng end,
    Color polylineColor = Colors.blue,
    double polylineWidth = 5.0,
    String routeId = 'main_route',
  }) async {
    try {
      // For demo purposes, we'll create a simple route
      // In production, you'd use Google Directions API
      final routeResult = await _getDirectionsFromAPI(start, end);
      
      if (routeResult != null) {
        final polylineId = PolylineId(routeId);
        final polyline = Polyline(
          polylineId: polylineId,
          color: polylineColor,
          width: polylineWidth.toInt(),
          points: routeResult.routePoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
        );

        _polylines.removeWhere((p) => p.polylineId == polylineId);
        _polylines.add(polyline);

        return routeResult;
      }
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }

    return null;
  }

  /// Get directions from API (mock implementation)
  Future<RouteInfo?> _getDirectionsFromAPI(LatLng start, LatLng end) async {
    // Mock route calculation
    final distance = _locationService.calculateDistance(
      start.latitude, start.longitude,
      end.latitude, end.longitude,
    );
    
    final duration = _locationService.calculateEstimatedArrival(
      UserLocation(latitude: start.latitude, longitude: start.longitude, timestamp: DateTime.now()),
      UserLocation(latitude: end.latitude, longitude: end.longitude, timestamp: DateTime.now()),
    );

    // Create simple route points (in production, use Google Directions API)
    final routePoints = [
      UserLocation(latitude: start.latitude, longitude: start.longitude, timestamp: DateTime.now()),
      UserLocation(latitude: end.latitude, longitude: end.longitude, timestamp: DateTime.now()),
    ];

    return RouteInfo(
      routePoints: routePoints,
      distanceInKm: distance,
      durationInMinutes: duration,
      polylineEncoded: '', // Would be from Google API
      estimatedCost: _calculateTravelCost(distance),
    );
  }

  /// Calculate travel cost based on distance
  double _calculateTravelCost(double distanceInKm) {
    const baseFee = 10.0;
    const perKmRate = 2.5;
    return baseFee + (distanceInKm * perKmRate);
  }

  /// Add geofence circle
  void addGeofence({
    required LatLng center,
    required double radiusInKm,
    String circleId = 'geofence',
    Color fillColor = Colors.blue,
    Color strokeColor = Colors.blue,
  }) {
    final circleId_ = CircleId(circleId);
    final circle = Circle(
      circleId: circleId_,
      center: center,
      radius: radiusInKm * 1000, // Convert to meters
      fillColor: fillColor.withOpacity(0.2),
      strokeColor: strokeColor,
      strokeWidth: 2,
    );

    _circles.removeWhere((c) => c.circleId == circleId_);
    _circles.add(circle);
  }

  /// Remove geofence
  void removeGeofence(String circleId) {
    _circles.removeWhere((c) => c.circleId.value == circleId);
  }

  /// Animate camera to location
  Future<void> animateToLocation({
    required LatLng location,
    double zoom = 15.0,
  }) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, zoom),
      );
    }
  }

  /// Animate camera to fit markers
  Future<void> animateToFitMarkers({
    EdgeInsets padding = const EdgeInsets.all(50.0),
  }) async {
    if (_mapController == null || _markers.isEmpty) return;

    final bounds = _calculateBounds(_markers.map((m) => m.position).toList());
    
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  /// Calculate bounds for multiple points
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Update provider location in real-time
  Future<void> updateProviderLocation(String providerId, UserLocation location) async {
    final markerId = MarkerId('provider_$providerId');
    final existingMarker = _markers.firstWhere(
      (marker) => marker.markerId == markerId,
      orElse: () => throw StateError('Marker not found'),
    );

    if (_markers.contains(existingMarker)) {
      final updatedMarker = existingMarker.copyWith(
        positionParam: LatLng(location.latitude, location.longitude),
      );

      _markers.removeWhere((marker) => marker.markerId == markerId);
      _markers.add(updatedMarker);
    }
  }

  /// Clear all markers
  void clearMarkers() {
    _markers.clear();
  }

  /// Clear all polylines
  void clearPolylines() {
    _polylines.clear();
  }

  /// Clear all circles
  void clearCircles() {
    _circles.clear();
  }

  /// Clear all map elements
  void clearAll() {
    _markers.clear();
    _polylines.clear();
    _circles.clear();
  }

  /// Get map style JSON
  String getMapStyle() {
    // Return custom map style for better healthcare app aesthetics
    return '''
    [
      {
        "featureType": "poi.medical",
        "stylers": [
          {
            "visibility": "on"
          }
        ]
      },
      {
        "featureType": "poi.business",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
    ''';
  }

  /// Set map style
  Future<void> setMapStyle() async {
    if (_mapController != null) {
      try {
        await _mapController!.setMapStyle(getMapStyle());
      } catch (e) {
        debugPrint('Error setting map style: $e');
      }
    }
  }
}
