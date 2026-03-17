import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/checkin_model.dart';
import '../theme/app_theme.dart';

class CheckInHistoryScreen extends StatefulWidget {
  const CheckInHistoryScreen({super.key});

  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  late final Box<CheckinModel> _checkinsBox;
  List<CheckinModel> _checkins = [];

  @override
  void initState() {
    super.initState();
    _checkinsBox = Hive.box<CheckinModel>('checkins');
    _loadCheckins();
  }

  void _loadCheckins() {
    List<CheckinModel> all = _checkinsBox.values.toList();
    
    // Sort by date descending
    all.sort((a, b) => b.date.compareTo(a.date));

    setState(() => _checkins = all);
    print('✓ Loaded ${_checkins.length} check-ins from local storage');
  }

  Color _getRiskColor(String riskColor) {
    switch (riskColor.toUpperCase()) {
      case 'GREEN':
        return Colors.green;
      case 'YELLOW':
        return Colors.amber;
      case 'ORANGE':
        return Colors.orange;
      case 'RED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _calculateScore(Map<String, String> answers) {
    int total = 0;
    for (var value in answers.values) {
      total += int.tryParse(value) ?? 0;
    }
    return total;
  }

  int _calculateMaxScore(Map<String, String> answers) {
    int numericCount = 0;
    for (var value in answers.values) {
      if (int.tryParse(value) != null) numericCount++;
    }
    return numericCount * 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                color: AppTheme.primaryTeal,
                gradient: AppTheme.mintGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Text(
                      'Check-in History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _loadCheckins,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            Expanded(
              child: _checkins.isEmpty
                  ? _buildEmptyState()
                  : _buildCheckInsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Check-ins Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your first daily check-in\nto see your health history',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _checkins.length,
      itemBuilder: (context, index) {
        final checkin = _checkins[index];
        final riskColor = _getRiskColor(checkin.riskColor);
        final score = _calculateScore(checkin.answers);
        final formatted = DateFormat('MMM d · h:mm a').format(checkin.date);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Date and Risk Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatted,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: riskColor, width: 1.5),
                      ),
                      child: Text(
                        checkin.riskLevel,
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.assessment, size: 18, color: AppTheme.primaryTeal),
                      const SizedBox(width: 8),
                      Text(
                        'Score: $score / ${_calculateMaxScore(checkin.answers)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Optional Vitals
                if (checkin.bpSystolic != null || checkin.bloodGlucose != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      if (checkin.bpSystolic != null)
                        _buildVitalBadge(
                          'BP',
                          '${checkin.bpSystolic?.toInt()}/${checkin.bpDiastolic?.toInt()} mmHg',
                          Icons.favorite,
                        ),
                      if (checkin.bloodGlucose != null)
                        _buildVitalBadge(
                          'Glucose',
                          '${checkin.bloodGlucose?.toInt()} mg/dL',
                          Icons.water_drop,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.2);
      },
    );
  }

  Widget _buildVitalBadge(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryTeal),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
