import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final AppointmentRequestService _appointmentService = AppointmentRequestService();
  
  List<Map<String, dynamic>> _pendingAppointments = [];
  List<Map<String, dynamic>> _acceptedAppointments = [];
  List<Map<String, dynamic>> _completedAppointments = [];
  
  bool _isLoading = false;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
    _setupNotificationTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _setupNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkUpcomingAppointments();
    });
  }

  void _checkUpcomingAppointments() {
    // Method implementation
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load pending appointments
      final pendingList = await _appointmentService.getFilteredAppointments('pending');
      
      // Load accepted appointments  
      final acceptedList = await _appointmentService.getFilteredAppointments('accepted');
      
      // Load completed appointments
      final completedList = await _appointmentService.getFilteredAppointments('completed');

      setState(() {
        _pendingAppointments = pendingList;
        _acceptedAppointments = acceptedList;
        _completedAppointments = completedList;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading appointments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Rendez-vous'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En Attente'),
            Tab(text: 'Acceptés'),
            Tab(text: 'Terminés'),
          ],
        ),
      ),
      body: TabBarView(
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
    return const Center(child: Text('Pending appointments'));
  }

  Widget _buildAcceptedTab() {
    return const Center(child: Text('Accepted appointments'));
  }

  Widget _buildCompletedTab() {
    return const Center(child: Text('Completed appointments'));
  }
}