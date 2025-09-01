import 'package:flutter/material.dart';

/// Healthcare service provider that manages available services and specialties
/// This simulates a database-backed service for real-world applications
class HealthcareServiceProvider {
  
  // Medical specialties available in the system
  static final Map<String, MedicalSpecialtyData> _medicalSpecialties = {
    'generalMedicine': MedicalSpecialtyData(
      id: 'generalMedicine',
      name: 'General Medicine',
      description: 'Primary care and general health consultations',
      icon: Icons.medical_services_rounded,
      averageConsultationTime: 30,
      isAvailable: true,
      practitioners: 15,
    ),
    'cardiology': MedicalSpecialtyData(
      id: 'cardiology',
      name: 'Cardiology',
      description: 'Heart and cardiovascular system care',
      icon: Icons.favorite_rounded,
      averageConsultationTime: 45,
      isAvailable: true,
      practitioners: 8,
    ),
    'neurology': MedicalSpecialtyData(
      id: 'neurology',
      name: 'Neurology',
      description: 'Brain, spine, and nervous system disorders',
      icon: Icons.psychology_rounded,
      averageConsultationTime: 50,
      isAvailable: true,
      practitioners: 6,
    ),
    'pediatrics': MedicalSpecialtyData(
      id: 'pediatrics',
      name: 'Pediatrics',
      description: 'Medical care for infants, children, and adolescents',
      icon: Icons.child_care_rounded,
      averageConsultationTime: 40,
      isAvailable: true,
      practitioners: 12,
    ),
    'gynecology': MedicalSpecialtyData(
      id: 'gynecology',
      name: 'Gynecology',
      description: 'Women\'s reproductive health and wellness',
      icon: Icons.woman_rounded,
      averageConsultationTime: 35,
      isAvailable: true,
      practitioners: 9,
    ),
    'orthopedics': MedicalSpecialtyData(
      id: 'orthopedics',
      name: 'Orthopedics',
      description: 'Bone, joint, and musculoskeletal system care',
      icon: Icons.accessible_rounded,
      averageConsultationTime: 40,
      isAvailable: true,
      practitioners: 7,
    ),
    'dermatology': MedicalSpecialtyData(
      id: 'dermatology',
      name: 'Dermatology',
      description: 'Skin, hair, and nail health treatments',
      icon: Icons.face_rounded,
      averageConsultationTime: 25,
      isAvailable: true,
      practitioners: 5,
    ),
    'psychiatry': MedicalSpecialtyData(
      id: 'psychiatry',
      name: 'Psychiatry',
      description: 'Mental health and psychological wellness',
      icon: Icons.psychology_alt_rounded,
      averageConsultationTime: 60,
      isAvailable: true,
      practitioners: 10,
    ),
    'ophthalmology': MedicalSpecialtyData(
      id: 'ophthalmology',
      name: 'Ophthalmology',
      description: 'Eye care and vision health services',
      icon: Icons.visibility_rounded,
      averageConsultationTime: 30,
      isAvailable: true,
      practitioners: 4,
    ),
    'ent': MedicalSpecialtyData(
      id: 'ent',
      name: 'ENT (Otolaryngology)',
      description: 'Ear, nose, and throat specialist care',
      icon: Icons.hearing_rounded,
      averageConsultationTime: 35,
      isAvailable: true,
      practitioners: 6,
    ),
    'urology': MedicalSpecialtyData(
      id: 'urology',
      name: 'Urology',
      description: 'Urinary system and male reproductive health',
      icon: Icons.water_drop_rounded,
      averageConsultationTime: 35,
      isAvailable: true,
      practitioners: 5,
    ),
    'gastroenterology': MedicalSpecialtyData(
      id: 'gastroenterology',
      name: 'Gastroenterology',
      description: 'Digestive system and gastrointestinal care',
      icon: Icons.restaurant_rounded,
      averageConsultationTime: 45,
      isAvailable: true,
      practitioners: 4,
    ),
    'oncology': MedicalSpecialtyData(
      id: 'oncology',
      name: 'Oncology',
      description: 'Cancer treatment and specialized care',
      icon: Icons.local_hospital_rounded,
      averageConsultationTime: 60,
      isAvailable: true,
      practitioners: 8,
    ),
    'emergency': MedicalSpecialtyData(
      id: 'emergency',
      name: 'Emergency Medicine',
      description: 'Urgent care and emergency medical services',
      icon: Icons.emergency_rounded,
      averageConsultationTime: 20,
      isAvailable: true,
      practitioners: 18,
    ),
  };

  // Nursing services available in the system
  static final Map<String, NursingServiceData> _nursingServices = {
    'woundCare': NursingServiceData(
      id: 'woundCare',
      name: 'Wound Care',
      description: 'Professional wound cleaning, dressing, and monitoring',
      icon: Icons.healing_rounded,
      averageServiceTime: 45,
      isAvailable: true,
      practitioners: 25,
      category: NursingCategory.clinical,
    ),
    'medicationAdministration': NursingServiceData(
      id: 'medicationAdministration',
      name: 'Medication Administration',
      description: 'Safe medication delivery and monitoring',
      icon: Icons.medication_rounded,
      averageServiceTime: 30,
      isAvailable: true,
      practitioners: 30,
      category: NursingCategory.clinical,
    ),
    'vitalsMonitoring': NursingServiceData(
      id: 'vitalsMonitoring',
      name: 'Vitals Monitoring',
      description: 'Blood pressure, temperature, and health monitoring',
      icon: Icons.monitor_heart_rounded,
      averageServiceTime: 20,
      isAvailable: true,
      practitioners: 35,
      category: NursingCategory.assessment,
    ),
    'injections': NursingServiceData(
      id: 'injections',
      name: 'Injections & Vaccinations',
      description: 'Immunizations, insulin, and medical injections',
      icon: Icons.vaccines_rounded,
      averageServiceTime: 15,
      isAvailable: true,
      practitioners: 28,
      category: NursingCategory.clinical,
    ),
    'bloodDrawing': NursingServiceData(
      id: 'bloodDrawing',
      name: 'Blood Drawing',
      description: 'Professional phlebotomy and lab sample collection',
      icon: Icons.bloodtype_rounded,
      averageServiceTime: 15,
      isAvailable: true,
      practitioners: 20,
      category: NursingCategory.diagnostic,
    ),
    'homeHealthAssessment': NursingServiceData(
      id: 'homeHealthAssessment',
      name: 'Health Assessment',
      description: 'Comprehensive health evaluation and screening',
      icon: Icons.health_and_safety_rounded,
      averageServiceTime: 60,
      isAvailable: true,
      practitioners: 22,
      category: NursingCategory.assessment,
    ),
    'postSurgicalCare': NursingServiceData(
      id: 'postSurgicalCare',
      name: 'Post-Surgical Care',
      description: 'Recovery monitoring and surgical site care',
      icon: Icons.local_hospital_rounded,
      averageServiceTime: 90,
      isAvailable: true,
      practitioners: 15,
      category: NursingCategory.specialized,
    ),
    'chronicDiseaseManagement': NursingServiceData(
      id: 'chronicDiseaseManagement',
      name: 'Chronic Disease Management',
      description: 'Diabetes, hypertension, and chronic condition care',
      icon: Icons.track_changes_rounded,
      averageServiceTime: 75,
      isAvailable: true,
      practitioners: 18,
      category: NursingCategory.specialized,
    ),
    'elderCare': NursingServiceData(
      id: 'elderCare',
      name: 'Elder Care',
      description: 'Specialized geriatric nursing and wellness support',
      icon: Icons.elderly_rounded,
      averageServiceTime: 90,
      isAvailable: true,
      practitioners: 20,
      category: NursingCategory.supportive,
    ),
    'mobilityAssistance': NursingServiceData(
      id: 'mobilityAssistance',
      name: 'Mobility Support',
      description: 'Physical therapy assistance and mobility training',
      icon: Icons.accessible_forward_rounded,
      averageServiceTime: 60,
      isAvailable: true,
      practitioners: 16,
      category: NursingCategory.supportive,
    ),
    'medicationReminders': NursingServiceData(
      id: 'medicationReminders',
      name: 'Medication Management',
      description: 'Medication scheduling and adherence support',
      icon: Icons.alarm_rounded,
      averageServiceTime: 30,
      isAvailable: true,
      practitioners: 25,
      category: NursingCategory.supportive,
    ),
    'healthEducation': NursingServiceData(
      id: 'healthEducation',
      name: 'Health Education',
      description: 'Patient education and wellness coaching',
      icon: Icons.school_rounded,
      averageServiceTime: 45,
      isAvailable: true,
      practitioners: 12,
      category: NursingCategory.educational,
    ),
  };

  // Get all available medical specialties
  static List<MedicalSpecialtyData> getAvailableMedicalSpecialties() {
    return _medicalSpecialties.values
        .where((specialty) => specialty.isAvailable && specialty.practitioners > 0)
        .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get all available nursing services
  static List<NursingServiceData> getAvailableNursingServices() {
    return _nursingServices.values
        .where((service) => service.isAvailable && service.practitioners > 0)
        .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get nursing services by category
  static List<NursingServiceData> getNursingServicesByCategory(NursingCategory category) {
    return _nursingServices.values
        .where((service) => service.category == category && service.isAvailable)
        .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  }

  // Get medical specialty by ID
  static MedicalSpecialtyData? getMedicalSpecialty(String id) {
    return _medicalSpecialties[id];
  }

  // Get nursing service by ID
  static NursingServiceData? getNursingService(String id) {
    return _nursingServices[id];
  }

  // Check if a specialty is available
  static bool isSpecialtyAvailable(String specialtyId, bool isNursingService) {
    if (isNursingService) {
      final service = _nursingServices[specialtyId];
      return service?.isAvailable == true && (service?.practitioners ?? 0) > 0;
    } else {
      final specialty = _medicalSpecialties[specialtyId];
      return specialty?.isAvailable == true && (specialty?.practitioners ?? 0) > 0;
    }
  }
}

enum NursingCategory {
  clinical,      // Hands-on medical procedures
  assessment,    // Health evaluations and monitoring
  diagnostic,    // Testing and sample collection
  specialized,   // Complex or specialized care
  supportive,    // Daily living and mobility support
  educational,   // Patient education and coaching
}

class MedicalSpecialtyData {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int averageConsultationTime; // in minutes
  final bool isAvailable;
  final int practitioners; // number of available doctors

  const MedicalSpecialtyData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.averageConsultationTime,
    required this.isAvailable,
    required this.practitioners,
  });
}

class NursingServiceData {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int averageServiceTime; // in minutes
  final bool isAvailable;
  final int practitioners; // number of available nurses
  final NursingCategory category;

  const NursingServiceData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.averageServiceTime,
    required this.isAvailable,
    required this.practitioners,
    required this.category,
  });
}
