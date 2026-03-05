import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/checkin_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';

class DailyCheckinScreen extends StatefulWidget {
  final String condition;
  const DailyCheckinScreen({Key? key, required this.condition})
    : super(key: key);

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  Map<String, String> answers = {};

  List<Map<String, dynamic>> getQuestions() {
    if (widget.condition == 'Hypertension') {
      return [
        {'id': 'q1', 'question': 'Do you have a headache today?'},
        {'id': 'q2', 'question': 'Are you experiencing dizziness?'},
        {'id': 'q3', 'question': 'Do you have chest discomfort?'},
        {'id': 'q4', 'question': 'Are you short of breath?'},
        {'id': 'q5', 'question': 'Have you had a nosebleed?'},
        {'id': 'q6', 'question': 'Are you experiencing vision problems?'},
        {'id': 'q7', 'question': 'Did you take your medication today?'},
      ];
    } else if (widget.condition == 'Diabetes') {
      return [
        {'id': 'q1', 'question': 'Are you experiencing excessive thirst?'},
        {'id': 'q2', 'question': 'Are you urinating frequently?'},
        {'id': 'q3', 'question': 'Do you feel extremely fatigued?'},
        {'id': 'q4', 'question': 'Is your vision blurred?'},
        {'id': 'q5', 'question': 'Do you have slow-healing wounds?'},
        {
          'id': 'q6',
          'question': 'Are you experiencing numbness in hands/feet?',
        },
        {'id': 'q7', 'question': 'Did you take your medication today?'},
      ];
    } else {
      return [
        {'id': 'q1', 'question': 'Are you experiencing chest pain?'},
        {'id': 'q2', 'question': 'Do you have an irregular heartbeat?'},
        {'id': 'q3', 'question': 'Are you short of breath?'},
        {'id': 'q4', 'question': 'Do you have swelling in legs/ankles?'},
        {'id': 'q5', 'question': 'Do you feel extremely fatigued?'},
        {'id': 'q6', 'question': 'Are you experiencing dizziness?'},
        {'id': 'q7', 'question': 'Did you take your medication today?'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> questions = getQuestions();
    String todayDate = DateFormat('MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppTheme.textDark,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Daily Check-in',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.history,
                        color: AppTheme.primaryTeal,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightMint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          todayDate,
                          style: const TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: -0.2),

                    const SizedBox(height: 24),

                    ...questions.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> q = entry.value;
                      return _buildQuestionCard(
                            index + 1,
                            q['id'],
                            q['question'],
                          )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 100 * index))
                          .slideX(begin: 0.1);
                    }).toList(),

                    const SizedBox(height: 100), // padding for floating button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: answers.length == questions.length
                ? _submitCheckin
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
              shadowColor: AppTheme.primaryTeal.withOpacity(0.5),
            ),
            child: Text(
              'Submit Check-in (${answers.length}/${questions.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ).animate().slideY(begin: 1.0, delay: 500.ms),
      ),
    );
  }

  Widget _buildQuestionCard(int number, String id, String question) {
    String? currentAnswer = answers[id];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppTheme.mintGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: id == 'q7'
                ? [
                    _buildAnswerChip('Yes', id, currentAnswer),
                    _buildAnswerChip('No', id, currentAnswer),
                  ]
                : [
                    _buildAnswerChip('None', id, currentAnswer),
                    _buildAnswerChip('Mild', id, currentAnswer),
                    _buildAnswerChip('Severe', id, currentAnswer),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerChip(
    String label,
    String questionId,
    String? currentAnswer,
  ) {
    bool isSelected = currentAnswer == label;
    bool isMedicationQuestion = questionId == 'q7';

    Color activeColor;
    if (isMedicationQuestion) {
      activeColor = label == 'Yes' ? Colors.green : Colors.redAccent;
    } else {
      if (label == 'None')
        activeColor = AppTheme.primaryTeal;
      else if (label == 'Mild')
        activeColor = Colors.orangeAccent;
      else
        activeColor = Colors.redAccent;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          answers[questionId] = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppTheme.background,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _submitCheckin() async {
    // Score calculation logic remains unchanged
    int severeCount = answers.values
        .where((answer) => answer == 'Severe')
        .length;
    int mildCount = answers.values.where((answer) => answer == 'Mild').length;

    String riskLevel;
    String riskColor;

    if (severeCount >= 3) {
      riskLevel = 'RED';
      riskColor = 'red';
    } else if (severeCount >= 2 || (severeCount >= 1 && mildCount >= 2)) {
      riskLevel = 'ORANGE';
      riskColor = 'orange';
    } else if (severeCount >= 1 || mildCount >= 2) {
      riskLevel = 'YELLOW';
      riskColor = 'yellow';
    } else {
      riskLevel = 'GREEN';
      riskColor = 'green';
    }

    final box = Hive.box<CheckinModel>('checkins');
    final checkin = CheckinModel(
      condition: widget.condition,
      date: DateTime.now(),
      answers: answers,
      riskLevel: riskLevel,
      riskColor: riskColor,
    );
    await box.add(checkin);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const CircularProgressIndicator(color: AppTheme.primaryTeal),
          ),
        ),
      );
    }

    bool uploadSuccess = false;
    try {
      final apiService = ApiService();
      final patientId = await apiService.getPatientId();
      uploadSuccess = await apiService.uploadCheckin(checkin, patientId);
    } catch (e) {
      debugPrint('Failed to upload to Django: $e');
    }

    if (mounted) {
      Navigator.of(context).pop(); // dismiss loading
    }

    if (!mounted) return;

    Color displayColor = _getColorFromString(riskColor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite, color: displayColor, size: 40),
            ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              riskLevel,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getRiskMessage(riskLevel),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: uploadSuccess
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    uploadSuccess ? Icons.cloud_done : Icons.cloud_off,
                    color: uploadSuccess ? Colors.green : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    uploadSuccess ? 'Synced to Cloud' : 'Saved Locally',
                    style: TextStyle(
                      fontSize: 13,
                      color: uploadSuccess
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    if (colorString == 'green') return Colors.green;
    if (colorString == 'yellow') return Colors.yellow[700]!;
    if (colorString == 'orange') return Colors.orange;
    if (colorString == 'red') return Colors.red;
    return Colors.grey;
  }

  String _getRiskMessage(String riskLevel) {
    if (riskLevel == 'GREEN')
      return "You're doing well! Keep monitoring daily.";
    if (riskLevel == 'YELLOW')
      return "Minor symptoms detected. Continue monitoring closely.";
    if (riskLevel == 'ORANGE')
      return "Concerning symptoms. Consider contacting your healthcare provider.";
    if (riskLevel == 'RED')
      return "Urgent symptoms detected. Seek medical attention soon.";
    return "";
  }
}
