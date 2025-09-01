import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing appointment storage and retrieval
class AppointmentStorage {
  static const String _appointmentsKey = 'stored_appointments';
  static const String _upcomingKey = 'upcoming_appointments';

  /// Save an appointment to local storage
  static Future<void> saveAppointment(Map<String, dynamic> appointment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing appointments
      final existingData = prefs.getString(_appointmentsKey);
      List<Map<String, dynamic>> appointments = [];
      
      if (existingData != null) {
        final List<dynamic> decoded = jsonDecode(existingData);
        appointments = decoded.cast<Map<String, dynamic>>();
      }
      
      // Add new appointment
      appointments.add(appointment);
      
      // Save back to storage
      await prefs.setString(_appointmentsKey, jsonEncode(appointments));
      
    } catch (e) {
      print('Error saving appointment: $e');
      rethrow;
    }
  }

  /// Get all stored appointments
  static Future<List<Map<String, dynamic>>> getAllAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_appointmentsKey);
      
      if (data == null) return [];
      
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
      
    } catch (e) {
      print('Error loading appointments: $e');
      return [];
    }
  }

  /// Get upcoming appointments (future dates only)
  static Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final allAppointments = await getAllAppointments();
      final now = DateTime.now();
      
      return allAppointments.where((appointment) {
        try {
          final dateTimeStr = appointment['dateTime'] as String?;
          if (dateTimeStr == null) return false;
          
          final appointmentDate = DateTime.parse(dateTimeStr);
          return appointmentDate.isAfter(now);
        } catch (e) {
          return false;
        }
      }).toList();
      
    } catch (e) {
      print('Error loading upcoming appointments: $e');
      return [];
    }
  }

  /// Get past appointments (historical data)
  static Future<List<Map<String, dynamic>>> getPastAppointments() async {
    try {
      final allAppointments = await getAllAppointments();
      final now = DateTime.now();
      
      return allAppointments.where((appointment) {
        try {
          final dateTimeStr = appointment['dateTime'] as String?;
          if (dateTimeStr == null) return false;
          
          final appointmentDate = DateTime.parse(dateTimeStr);
          return appointmentDate.isBefore(now);
        } catch (e) {
          return false;
        }
      }).toList();
      
    } catch (e) {
      print('Error loading past appointments: $e');
      return [];
    }
  }

  /// Delete an appointment by ID
  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      final allAppointments = await getAllAppointments();
      List<Map<String, dynamic>> filteredAppointments;
      
      // If appointmentId is empty, remove the first appointment with empty ID
      if (appointmentId.isEmpty) {
        bool removedOne = false;
        filteredAppointments = allAppointments.where((appointment) {
          final appointmentIdStr = appointment['id']?.toString() ?? '';
          if (!removedOne && appointmentIdStr.isEmpty) {
            removedOne = true;
            return false; // Remove this one
          }
          return true; // Keep this one
        }).toList();
      } else {
        // Normal deletion by ID
        filteredAppointments = allAppointments
            .where((appointment) => appointment['id'] != appointmentId)
            .toList();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appointmentsKey, jsonEncode(filteredAppointments));
      
    } catch (e) {
      print('Error deleting appointment: $e');
      rethrow;
    }
  }

  /// Update appointment status
  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      final allAppointments = await getAllAppointments();
      
      for (var appointment in allAppointments) {
        if (appointment['id'] == appointmentId) {
          appointment['status'] = status;
          break;
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appointmentsKey, jsonEncode(allAppointments));
      
    } catch (e) {
      print('Error updating appointment status: $e');
      rethrow;
    }
  }

  /// Clear all appointments (for testing/reset)
  static Future<void> clearAllAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appointmentsKey);
    } catch (e) {
      print('Error clearing appointments: $e');
      rethrow;
    }
  }

  /// Get appointment count
  static Future<int> getAppointmentCount() async {
    try {
      final appointments = await getAllAppointments();
      return appointments.length;
    } catch (e) {
      print('Error getting appointment count: $e');
      return 0;
    }
  }
}
