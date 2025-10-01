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
    
    // Check if appointmentId is null or empty
    if (widget.appointmentId == null || widget.appointmentId!.isEmpty) {
      print('❌ [LiveTrackingScreen] ERROR: No appointmentId provided!');
    } else {
      print('✅ [LiveTrackingScreen] Valid appointmentId: ${widget.appointmentId}');
    }
    
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
        title: Text('Live Tracking${widget.appointmentId != null ? ' - ${widget.appointmentId}' : ''}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 100,
        actions: [
          if (widget.appointmentId != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tracking appointment: ${widget.appointmentId}')),
                );
              },
            ),
        ],
      ),
      body: widget.appointmentId == null || widget.appointmentId!.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'No Appointment ID',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Cannot load tracking without appointment ID',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : FlutterMapTrackingWidget(
              appointmentId: widget.appointmentId,
              showNearbyProviders: false,
            ),
    );
  }
}
