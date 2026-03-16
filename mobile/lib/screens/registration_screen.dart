import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  // Form fields
  late TextEditingController _patientIdController;
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _weightController;
  late TextEditingController _systolicBPController;
  late TextEditingController _diastolicBPController;
  late TextEditingController _glucoseController;
  late TextEditingController _medicalHistoryController;
  late TextEditingController _medicationsController;
  late TextEditingController _allergiesController;
  
  String? _selectedCondition;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  final List<String> _conditions = ['Hypertension', 'Diabetes', 'Cardiovascular', 'Asthma'];

  @override
  void initState() {
    super.initState();
    _patientIdController = TextEditingController();
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _weightController = TextEditingController();
    _systolicBPController = TextEditingController();
    _diastolicBPController = TextEditingController();
    _glucoseController = TextEditingController();
    _medicalHistoryController = TextEditingController();
    _medicationsController = TextEditingController();
    _allergiesController = TextEditingController();
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateOfBirthController.dispose();
    _weightController.dispose();
    _systolicBPController.dispose();
    _diastolicBPController.dispose();
    _glucoseController.dispose();
    _medicalHistoryController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a condition')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare registration payload
      final registrationData = {
        'patient_id': _patientIdController.text.trim(),
        'name': _nameController.text.trim(),
        'condition': _selectedCondition,
        'password': _passwordController.text,
        'date_of_birth': _selectedDateOfBirth?.toIso8601String().split('T')[0],
        'weight_kg': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
        'blood_pressure_systolic': _systolicBPController.text.isNotEmpty ? int.parse(_systolicBPController.text) : null,
        'blood_pressure_diastolic': _diastolicBPController.text.isNotEmpty ? int.parse(_diastolicBPController.text) : null,
        'blood_glucose_baseline': _glucoseController.text.isNotEmpty ? int.parse(_glucoseController.text) : null,
        'medical_history': _medicalHistoryController.text.isEmpty ? null : _medicalHistoryController.text,
        'medications': _medicationsController.text.isEmpty ? null : _medicationsController.text,
        'allergies': _allergiesController.text.isEmpty ? null : _allergiesController.text,
      };

      // Call registration API
      final response = await _apiService.registerPatient(registrationData);

      if (response != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Registration successful! Please log in.')),
          );
          
          // Navigate back to login screen
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Registration failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
        print('Registration error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Registration'),
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Create Your Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Complete your profile with baseline health data',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // === BASIC INFORMATION ===
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),

              // Patient ID
              TextFormField(
                controller: _patientIdController,
                decoration: InputDecoration(
                  labelText: 'Patient ID *',
                  hintText: 'e.g., PT001',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Patient ID is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'John Doe',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Condition
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Health Condition *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.health_and_safety),
                ),
                value: _selectedCondition,
                onChanged: (String? newValue) {
                  setState(() => _selectedCondition = newValue);
                },
                items: _conditions.map((String condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) return 'Please select a condition';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              TextFormField(
                controller: _dateOfBirthController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth *',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: _selectDateOfBirth,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Date of birth is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm password';
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // === OPTIONAL BASELINE DATA ===
              _buildSectionHeader('Baseline Health Data (Optional)'),
              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  hintText: '70.5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.monitor_weight),
                ),
              ),
              const SizedBox(height: 16),

              // Blood Pressure (Systolic)
              TextFormField(
                controller: _systolicBPController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Blood Pressure - Systolic (mmHg)',
                  hintText: '120',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.favorite),
                ),
              ),
              const SizedBox(height: 16),

              // Blood Pressure (Diastolic)
              TextFormField(
                controller: _diastolicBPController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Blood Pressure - Diastolic (mmHg)',
                  hintText: '80',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.favorite),
                ),
              ),
              const SizedBox(height: 16),

              // Blood Glucose
              TextFormField(
                controller: _glucoseController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Blood Glucose (mg/dL)',
                  hintText: '100',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.science),
                ),
              ),
              const SizedBox(height: 30),

              // === MEDICAL HISTORY ===
              _buildSectionHeader('Medical Information (Optional)'),
              const SizedBox(height: 16),

              // Medical History
              TextFormField(
                controller: _medicalHistoryController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Medical History',
                  hintText: 'List any significant medical conditions',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 16),

              // Current Medications
              TextFormField(
                controller: _medicationsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Current Medications',
                  hintText: 'List all current medications',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.local_pharmacy),
                ),
              ),
              const SizedBox(height: 16),

              // Allergies
              TextFormField(
                controller: _allergiesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Allergies',
                  hintText: 'List any known allergies',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.warning),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 16),

              // Back to Login Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Already have an account? Sign In',
                  style: TextStyle(color: AppTheme.primaryTeal),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }
}
