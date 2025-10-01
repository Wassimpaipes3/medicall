import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/provider_request_service.dart';
import '../../routes/app_routes.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});

  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  bool _accepting = false;
  String? _acceptingId;

  Future<void> _acceptRequest(ProviderRequest req) async {
    setState(() { _accepting = true; _acceptingId = req.id; });
    try {
      // Get provider current location (fallback to 0,0 if unavailable)
      Position? pos;
      try { pos = await Geolocator.getCurrentPosition(); } catch (_) {}
      final providerGeo = GeoPoint(pos?.latitude ?? 0, pos?.longitude ?? 0);

      final appointmentId = await ProviderRequestService.acceptRequestAndCreateAppointment(
        requestId: req.id,
        providerLocation: providerGeo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Accepted. Appointment ID: $appointmentId')),
      );
      
      print('🚀 [Provider] Navigating to tracking with appointmentId: $appointmentId');
      // Navigate to tracking (replace so provider can't go back to requests)
      Navigator.of(context).pushReplacementNamed(AppRoutes.tracking, arguments: {'appointmentId': appointmentId});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _accepting = false; _acceptingId = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Requests')),
      body: StreamBuilder<List<ProviderRequest>>(
        stream: ProviderRequestService.listenProviderPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (ctx, i) {
              final r = requests[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('Service: ${r.service}  •  ${r.prix.toStringAsFixed(2)}'),
                  subtitle: Text('Patient: ${r.patientId}\nPayment: ${r.paymentMethod}'),
                  trailing: _accepting && _acceptingId == r.id
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : ElevatedButton(
                          onPressed: () => _acceptRequest(r),
                          child: const Text('Accept'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
