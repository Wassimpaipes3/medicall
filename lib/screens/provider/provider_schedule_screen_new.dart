import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../services/appointment_request_service.dart';

class ProviderScheduleScreen extends StatefulWidget {
  const ProviderScheduleScreen({Key? key}) : super(key: key);

  @override
  _ProviderScheduleScreenState createState() => _ProviderScheduleScreenState();
}

class _ProviderScheduleScreenState extends State<ProviderScheduleScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  List<AppointmentRequest> _pendingAppointments = [];
  List<UpcomingAppointment> _acceptedAppointments = [];
  List<UpcomingAppointment> _completedAppointments = [];
  
  bool _isLoading = false;
  Timer? _notificationTimer;
  String? _currentProviderId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentProviderId();
    _setupNotificationTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _getCurrentProviderId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentProviderId = user.uid;
      _loadAppointments();
    }
  }

  void _setupNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkUpcomingAppointments();
    });
  }

  void _checkUpcomingAppointments() {
    if (_acceptedAppointments.isNotEmpty) {
      final now = DateTime.now();
      final upcomingAppointments = _acceptedAppointments.where((appointment) {
        return appointment.appointmentDate.isAfter(now) && 
               appointment.appointmentDate.difference(now).inMinutes <= 30;
      }).toList();

      if (upcomingAppointments.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Rendez-vous à venir'),
            content: Text('Vous avez ${upcomingAppointments.length} rendez-vous dans les 30 prochaines minutes.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadAppointments() async {
    if (_currentProviderId == null) return;

    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load pending appointments from appointment_requests collection
      final pendingList = await AppointmentRequestService.getProviderPendingRequests(_currentProviderId!);
      
      // Load accepted appointments from appointments collection
      final acceptedList = await AppointmentRequestService.getProviderUpcomingAppointments(_currentProviderId!);
      
      // Load completed appointments from appointments collection
      final completedList = await _getCompletedAppointments(_currentProviderId!);

      if (mounted) {
        setState(() {
          _pendingAppointments = pendingList;
          _acceptedAppointments = acceptedList;
          _completedAppointments = completedList;
          _isLoading = false;
        });

        print('📋 Loaded appointments:');
        print('   • Pending: ${_pendingAppointments.length}');
        print('   • Accepted: ${_acceptedAppointments.length}');
        print('   • Completed: ${_completedAppointments.length}');
      }
    } catch (e) {
      print('❌ Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<UpcomingAppointment>> _getCompletedAppointments(String providerId) async {
    try {
      print('📅 Fetching completed appointments for provider: $providerId');

      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('idpro', isEqualTo: providerId)
          .where('status', isEqualTo: 'completed')
          .get();

      print('   ✅ Found ${snapshot.docs.length} completed appointments');

      return snapshot.docs.map((doc) {
        return UpcomingAppointment.fromFirestore(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('❌ Error fetching completed appointments: $e');
      return [];
    }
  }

  Future<void> _acceptAppointment(AppointmentRequest request) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await AppointmentRequestService.acceptAppointmentRequest(request.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous accepté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload appointments to update the lists
        await _loadAppointments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'acceptation du rendez-vous'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error accepting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeAppointment(UpcomingAppointment appointment) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update status to completed in appointments collection
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.id)
          .update({'status': 'completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendez-vous marqué comme terminé'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload appointments to update the lists
      await _loadAppointments();
    } catch (e) {
      print('❌ Error completing appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Flexible(
              child: Tab(
                child: FittedBox(
                  child: Text(
                    'En Attente',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Tab(
                child: FittedBox(
                  child: Text(
                    'Acceptés',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            Flexible(
              child: Tab(
                child: FittedBox(
                  child: Text(
                    'Terminés',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildAcceptedTab(),
                _buildCompletedTab(),
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingAppointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending_actions, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune demande en attente',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _pendingAppointments[index];
          return _buildPendingAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAcceptedTab() {
    if (_acceptedAppointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun rendez-vous accepté',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _acceptedAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _acceptedAppointments[index];
          return _buildAcceptedAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    if (_completedAppointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun rendez-vous terminé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedAppointments.length,
        itemBuilder: (context, index) {
          final appointment = _completedAppointments[index];
          return _buildCompletedAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildPendingAppointmentCard(AppointmentRequest appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EN ATTENTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  appointment.formattedDateTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName.isNotEmpty 
                            ? appointment.patientName 
                            : 'Patient non identifié',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Tél: ${appointment.patientPhone}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.service,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${appointment.prix.toStringAsFixed(2)} DH',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (appointment.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptAppointment(appointment),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Accepter', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Implement reject functionality
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedAppointmentCard(UpcomingAppointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ACCEPTÉ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  appointment.formattedDateTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName.isNotEmpty 
                            ? appointment.patientName 
                            : 'Patient non identifié',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Tél: ${appointment.patientPhone}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.service,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${appointment.prix.toStringAsFixed(2)} DH',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (appointment.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completeAppointment(appointment),
                icon: const Icon(Icons.done, color: Colors.white),
                label: const Text('Marquer comme terminé', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedAppointmentCard(UpcomingAppointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TERMINÉ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  appointment.formattedDateTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName.isNotEmpty 
                            ? appointment.patientName 
                            : 'Patient non identifié',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Tél: ${appointment.patientPhone}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.service,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${appointment.prix.toStringAsFixed(2)} DH',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (appointment.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}