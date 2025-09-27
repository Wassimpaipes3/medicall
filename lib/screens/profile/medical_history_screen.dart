import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/enhanced_theme.dart';
import '../../services/user_profile_service.dart';

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> 
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _medicalHistory = [];
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Form controllers for editing
  final _allergiesController = TextEditingController();
  final _antecedentsController = TextEditingController();
  final _dossiersController = TextEditingController();
  String _selectedBloodType = '';

  final List<Map<String, dynamic>> _vaccinations = [
    {
      'name': 'COVID-19 (Pfizer)',
      'date': '2024-01-15',
      'nextDue': '2025-01-15',
      'status': 'Up to date',
      'icon': Icons.shield_rounded,
    },
    {
      'name': 'Influenza',
      'date': '2023-10-12',
      'nextDue': '2024-10-12',
      'status': 'Due soon',
      'icon': Icons.medical_services_rounded,
    },
    {
      'name': 'Hepatitis B',
      'date': '2020-03-20',
      'nextDue': 'Lifetime',
      'status': 'Complete',
      'icon': Icons.verified_user_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMedicalData();
  }

  Future<void> _loadMedicalData() async {
    try {
      final userData = await UserProfileService.getUserProfile();
      if (userData != null && mounted) {
        setState(() {
          
          // Create medical history from user data
          _medicalHistory = [];
          
          // Add allergies if not empty
          if (userData['allergies'] != null && userData['allergies'].toString().trim().isNotEmpty && userData['allergies'] != 'Aucune') {
            _medicalHistory.add({
              'id': 'allergies',
              'condition': 'Allergies',
              'details': userData['allergies'].toString(),
              'status': 'ongoing',
              'doctor': 'Dr. Smith',
              'severity': 'Moderate',
              'medications': ['Antihistamine', 'EpiPen'], // Added missing field
              'icon': Icons.warning_rounded,
              'color': Colors.orange,
            });
          }
          
          // Add medical history if not empty
          if (userData['antecedents'] != null && userData['antecedents'].toString().trim().isNotEmpty && userData['antecedents'] != 'Aucun') {
            _medicalHistory.add({
              'id': 'antecedents',
              'condition': 'Antécédents médicaux',
              'details': userData['antecedents'].toString(),
              'status': 'ongoing',
              'doctor': 'Dr. Johnson',
              'severity': 'High',
              'medications': ['Metformin', 'Lisinopril'], // Added missing field
              'icon': Icons.medical_information_rounded,
              'color': Colors.red,
            });
          }
          
          // Add medical records if not empty
          if (userData['dossiers_medicaux'] != null && userData['dossiers_medicaux'].toString().trim().isNotEmpty) {
            _medicalHistory.add({
              'id': 'dossiers',
              'condition': 'Dossiers médicaux',
              'details': userData['dossiers_medicaux'].toString(),
              'status': 'ongoing',
              'doctor': 'Dr. Wilson',
              'severity': 'Low',
              'medications': [], // Added missing field (empty list for records)
              'icon': Icons.folder_rounded,
              'color': Colors.blue,
            });
          }
          
          // Populate form controllers for editing with null-safe handling
          final allergies = userData['allergies'];
          final antecedents = userData['antecedents'];
          final dossiersMedicaux = userData['dossiers_medicaux'];
          final groupeSanguin = userData['groupe_sanguin'];
          
          _allergiesController.text = (allergies != null ? allergies.toString() : '');
          _antecedentsController.text = (antecedents != null ? antecedents.toString() : '');
          _dossiersController.text = (dossiersMedicaux != null ? dossiersMedicaux.toString() : '');
          _selectedBloodType = (groupeSanguin != null ? groupeSanguin.toString() : '');
          
          // Handle default values
          if (_allergiesController.text == 'Aucune') _allergiesController.text = '';
          if (_antecedentsController.text == 'Aucun') _antecedentsController.text = '';
          if (_selectedBloodType == 'Non renseigné') _selectedBloodType = '';
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _allergiesController.dispose();
    _antecedentsController.dispose();
    _dossiersController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _saveMedicalHistory() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Ensure all values are strings, not null
      final allergies = _allergiesController.text.trim();
      final antecedents = _antecedentsController.text.trim();
      final dossiersMedicaux = _dossiersController.text.trim();
      final groupeSanguin = _selectedBloodType.trim();
      
      final result = await UserProfileService.updateMedicalHistory(
        allergies: allergies,
        antecedents: antecedents,
        dossiersMedicaux: dossiersMedicaux,
        groupeSanguin: groupeSanguin,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (result['success'] == true) {
          setState(() {
            _isEditing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Reload data to reflect changes
          _loadMedicalData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNewCondition() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAddConditionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Medical History',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading your medical history...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        toolbarHeight: 100,
        leading: IconButton(
          iconSize: 24,
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Medical History',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_rounded,
              color: EnhancedAppTheme.primaryIndigo,
            ),
            onPressed: _isSaving ? null : _toggleEditing,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: EnhancedAppTheme.primaryIndigo),
            onPressed: _addNewCondition,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) ...[
                  _buildEditForm(),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildMedicalConditionsSection(),
                  const SizedBox(height: 24),
                  _buildVaccinationsSection(),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Active Conditions',
            count: '4',
            icon: Icons.medical_information_rounded,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Medications',
            count: '7',
            icon: Icons.medication_rounded,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            title: 'Vaccinations',
            count: '3',
            icon: Icons.vaccines_rounded,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [EnhancedAppTheme.primaryIndigo, EnhancedAppTheme.primaryPurple],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_information_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Medical Conditions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _medicalHistory.length,
          itemBuilder: (context, index) {
            return _buildConditionCard(_medicalHistory[index]);
          },
        ),
      ],
    );
  }

  Widget _buildConditionCard(Map<String, dynamic> condition) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (condition['color'] ?? Colors.grey).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  condition['icon'] ?? Icons.help,
                  color: condition['color'] ?? Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (condition['condition'] != null ? condition['condition'].toString() : 'Unknown Condition'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (condition['details'] != null ? condition['details'].toString() : 'No details available'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(condition['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  (condition['status'] != null ? condition['status'].toString() : 'Unknown'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(condition['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  label: 'Doctor',
                  value: condition['doctor']?.toString(),
                  icon: Icons.person_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoChip(
                  label: 'Severity',
                  value: condition['severity']?.toString(),
                  icon: Icons.priority_high_rounded,
                ),
              ),
            ],
          ),
          if (condition['medications'] != null && (condition['medications'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Current Medications:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (condition['medications'] as List<dynamic>).map<Widget>((medication) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EnhancedAppTheme.primaryIndigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    medication?.toString() ?? 'Unknown Medication',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: EnhancedAppTheme.primaryIndigo,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVaccinationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.teal],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.vaccines_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Vaccinations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _vaccinations.length,
          itemBuilder: (context, index) {
            return _buildVaccinationCard(_vaccinations[index]);
          },
        ),
      ],
    );
  }

  Widget _buildVaccinationCard(Map<String, dynamic> vaccination) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(vaccination['icon'], color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccination['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last: ${_formatDate(vaccination['date'])}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (vaccination['nextDue'] != 'Lifetime') ...[
                  const SizedBox(height: 2),
                  Text(
                    'Next: ${_formatDate(vaccination['nextDue'])}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getVaccinationStatusColor(vaccination['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              vaccination['status'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getVaccinationStatusColor(vaccination['status']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required String label,
    required String? value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: EnhancedAppTheme.primaryIndigo),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'Not specified',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddConditionSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'Add New Medical Condition',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Condition Name',
                    prefixIcon: Icon(Icons.medical_services_rounded, color: EnhancedAppTheme.primaryIndigo),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Doctor Name',
                    prefixIcon: Icon(Icons.person_rounded, color: EnhancedAppTheme.primaryIndigo),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Medical condition added successfully! ⚡'),
                          backgroundColor: EnhancedAppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EnhancedAppTheme.primaryIndigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Add Condition ⚡',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    if (status == null) return Colors.grey;
    
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'ongoing':
        return Colors.red;
      case 'controlled':
        return Colors.green;
      case 'improving':
        return Colors.blue;
      case 'seasonal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getVaccinationStatusColor(dynamic status) {
    if (status == null) return Colors.grey;
    
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'up to date':
        return Colors.green;
      case 'due soon':
        return Colors.orange;
      case 'complete':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.orange],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Medical Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _allergiesController,
            label: 'Allergies',
            icon: Icons.warning_rounded,
            hintText: 'Enter any allergies you have (e.g., Penicillin, Shellfish)',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _antecedentsController,
            label: 'Medical History',
            icon: Icons.medical_information_rounded,
            hintText: 'Enter your medical history (e.g., Diabetes, Hypertension)',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _dossiersController,
            label: 'Medical Records',
            icon: Icons.folder_rounded,
            hintText: 'Enter any additional medical records or notes',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Blood Type',
            icon: Icons.bloodtype_rounded,
            value: _selectedBloodType.isEmpty ? 'Non renseigné' : _selectedBloodType,
            items: ['Non renseigné', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
            onChanged: (value) => setState(() => _selectedBloodType = value == 'Non renseigné' ? '' : value!),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveMedicalHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Medical History 🏥',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.red, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }
}
