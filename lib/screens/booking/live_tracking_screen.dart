import 'package:flutter/material.dart';
import '../../widgets/maps/flutter_map_tracking_widget.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String? appointmentId;
  
  const LiveTrackingScreen({
    super.key,
    this.appointmentId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    print('🗺️ [LiveTrackingScreen] Initialized with appointmentId: ${widget.appointmentId}');
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 100, // Increased from 74 to 100 for much lower positioning from top
      ),
      body: FlutterMapTrackingWidget(
        appointmentId: widget.appointmentId,
        showNearbyProviders: widget.appointmentId == null,
      ),
    );
  }
}
