import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/checkin_model.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog first
              await _performLogout(); // Then perform logout & navigate
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      // Clear all user data
      await _settingsBox.delete('patient_id');
      await _settingsBox.delete('patient_name');
      await _settingsBox.delete('condition');
      await _settingsBox.delete('session_token');
      await _settingsBox.put('is_logged_in', false);

      // Clear check-ins from local storage (must use typed box)
      final checkinsBox = Hive.box<CheckinModel>('checkins');
      await checkinsBox.clear();

      print('✓ User logged out successfully');

      if (!mounted) return;

      // Navigate back to login
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = _settingsBox.get('patient_name', defaultValue: 'Unknown Patient');
    final patientId = _settingsBox.get('patient_id', defaultValue: 'N/A');
    final condition = _settingsBox.get('condition', defaultValue: 'N/A');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with gradient
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryTeal,
                  gradient: AppTheme.mintGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.primaryTeal,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      patientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Details Card
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Patient ID Card
                    _buildDetailCard(
                      icon: Icons.badge,
                      label: 'Patient ID',
                      value: patientId,
                    ),
                    const SizedBox(height: 12),

                    // Condition Card with Change button
                    _buildDetailCard(
                      icon: Icons.medical_information,
                      label: 'Condition',
                      value: condition,
                      trailing: TextButton(
                        onPressed: _showChangeConditionDialog,
                        child: const Text('Change', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Health Tracker',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Phase 1 & 2 Complete',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangeConditionDialog() {
    final conditions = ['Hypertension', 'Diabetes', 'Cardiovascular', 'Asthma'];
    final current = _settingsBox.get('condition', defaultValue: '');

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Condition'),
        children: conditions.map((c) => SimpleDialogOption(
          onPressed: () async {
            await _settingsBox.put('condition', c);
            Navigator.pop(ctx);
            setState(() {});
          },
          child: Row(
            children: [
              Icon(
                c == current ? Icons.radio_button_checked : Icons.radio_button_off,
                color: c == current ? AppTheme.primaryTeal : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(c, style: TextStyle(
                fontWeight: c == current ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              )),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
