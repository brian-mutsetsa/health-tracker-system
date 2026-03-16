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
  const DailyCheckinScreen({super.key, required this.condition});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  int currentStep = 0; // 0-4 (steps 1-4 + review)
  Map<String, int> answers = {}; // Store 0-3 values
  double? bpSystolic;
  double? bpDiastolic;
  double? bloodGlucose;
  bool isSubmitting = false;

  List<Map<String, dynamic>> getQuestions() {
    if (widget.condition == 'Hypertension') {
      return [
        {'id': 'q1', 'question': 'Do you have a headache today?'},
        {'id': 'q2', 'question': 'Are you experiencing dizziness?'},
        {'id': 'q3', 'question': 'Do you have chest discomfort?'},
        {'id': 'q4', 'question': 'Are you short of breath?'},
        {'id': 'q5', 'question': 'Have you had a nosebleed?'},
        {'id': 'q6', 'question': 'Are you experiencing vision problems?'},
        {'id': 'q7', 'question': 'Do you have fatigue?'},
        {'id': 'q8', 'question': 'Is your jaw clenching?'},
        {'id': 'q9', 'question': 'Are you experiencing back pain?'},
        {'id': 'q10', 'question': 'Do you feel anxious?'},
        {'id': 'q11', 'question': 'Did you take your medication today?'},
        {'id': 'q12', 'question': 'Any other symptoms?'},
      ];
    } else if (widget.condition == 'Diabetes') {
      return [
        {'id': 'q1', 'question': 'Are you experiencing excessive thirst?'},
        {'id': 'q2', 'question': 'Are you urinating frequently?'},
        {'id': 'q3', 'question': 'Do you feel extremely fatigued?'},
        {'id': 'q4', 'question': 'Is your vision blurred?'},
        {'id': 'q5', 'question': 'Do you have slow-healing wounds?'},
        {'id': 'q6', 'question': 'Are you experiencing numbness in hands/feet?'},
        {'id': 'q7', 'question': 'Do you have tingling sensations?'},
        {'id': 'q8', 'question': 'Are you having difficulty concentrating?'},
        {'id': 'q9', 'question': 'Do you have dry skin?'},
        {'id': 'q10', 'question': 'Are you experiencing mood changes?'},
        {'id': 'q11', 'question': 'Did you take your medication today?'},
        {'id': 'q12', 'question': 'Any other symptoms?'},
      ];
    } else {
      return [
        {'id': 'q1', 'question': 'Are you experiencing chest pain?'},
        {'id': 'q2', 'question': 'Do you have an irregular heartbeat?'},
        {'id': 'q3', 'question': 'Are you short of breath?'},
        {'id': 'q4', 'question': 'Do you have swelling in legs/ankles?'},
        {'id': 'q5', 'question': 'Do you feel extremely fatigued?'},
        {'id': 'q6', 'question': 'Are you experiencing dizziness?'},
        {'id': 'q7', 'question': 'Do you have palpitations?'},
        {'id': 'q8', 'question': 'Are you experiencing nausea?'},
        {'id': 'q9', 'question': 'Do you have cold/clammy hands?'},
        {'id': 'q10', 'question': 'Are you experiencing shoulder/arm pain?'},
        {'id': 'q11', 'question': 'Did you take your medication today?'},
        {'id': 'q12', 'question': 'Any other symptoms?'},
      ];
    }
  }

  List<Map<String, dynamic>> getQuestionsForStep(int step) {
    List<Map<String, dynamic>> allQuestions = getQuestions();
    int startIndex = step * 3;
    int endIndex = (step + 1) * 3;
    return allQuestions.sublist(startIndex, endIndex);
  }

  int calculateRiskScore() {
    return answers.values.fold(0, (sum, val) => sum + val);
  }

  Map<String, dynamic> getRiskLevel() {
    int score = calculateRiskScore();
    if (score >= 24) {
      return {'level': 'RED', 'color': Colors.redAccent, 'message': 'High Risk - Seek medical attention'};
    } else if (score >= 16) {
      return {'level': 'ORANGE', 'color': Colors.orangeAccent, 'message': 'Moderate Risk - Monitor closely'};
    } else if (score >= 8) {
      return {'level': 'YELLOW', 'color': Colors.yellow, 'message': 'Low-Moderate Risk - Stay aware'};
    } else {
      return {'level': 'GREEN', 'color': Colors.green, 'message': 'Low Risk - Keep maintaining'};
    }
  }

  void _goToNextStep() {
    if (currentStep < 3) {
      setState(() {
        currentStep++;
      });
    } else if (currentStep == 3) {
      setState(() {
        currentStep = 4; // Go to review
      });
    }
  }

  void _goToPreviousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  bool _isStepComplete() {
    int stepNum = currentStep;
    int startQ = stepNum * 3 + 1;
    int endQ = (stepNum + 1) * 3;
    
    for (int i = startQ; i <= endQ; i++) {
      if (!answers.containsKey('q$i')) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    String todayDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
    double progressPercent = (currentStep + 1) / 5; // 5 steps total (4 + review)

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textDark, size: 20),
                      onPressed: currentStep > 0 ? _goToPreviousStep : () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Daily Check-in',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.history, color: AppTheme.primaryTeal, size: 22),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentStep == 4 
                      ? 'Review & Submit'
                      : 'Step ${currentStep + 1} of 4',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryTeal),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercent,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todayDate,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: currentStep == 4
                    ? _buildReviewScreen()
                    : _buildStepContent(),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (currentStep > 0)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                        onPressed: _goToPreviousStep,
                        child: const Text('Back', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isStepComplete() || currentStep == 4 ? AppTheme.primaryTeal : Colors.grey[300],
                      ),
                      onPressed: (_isStepComplete() || currentStep == 4) ? (currentStep == 4 ? _submitCheckin : _goToNextStep) : null,
                      child: Text(
                        currentStep == 4 ? 'Submit Check-in' : 'Next',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    var questionsForStep = getQuestionsForStep(currentStep);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: questionsForStep.asMap().entries.map((entry) {
        int index = entry.key;
        var q = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildQuestionCard(q['id'], q['question'], index).animate().fadeIn(delay: Duration(milliseconds: 100 * index)),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionCard(String id, String question, int index) {
    int? currentAnswer = answers[id];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
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
                  gradient: AppTheme.mintGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primaryTeal.withValues(alpha: 0.3), blurRadius: 8)],
                ),
                child: Center(
                  child: Text(
                    '${(currentStep * 3) + index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildScaleButton(0, 'None', id, currentAnswer),
              _buildScaleButton(1, 'Mild', id, currentAnswer),
              _buildScaleButton(2, 'Moderate', id, currentAnswer),
              _buildScaleButton(3, 'Severe', id, currentAnswer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScaleButton(int value, String label, String questionId, int? currentAnswer) {
    bool isSelected = currentAnswer == value;
    
    Color getColor(int v) {
      switch (v) {
        case 0: return AppTheme.primaryTeal;
        case 1: return Colors.amber;
        case 2: return Colors.orange;
        case 3: return Colors.redAccent;
        default: return Colors.grey;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          answers[questionId] = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? getColor(value) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? getColor(value) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: getColor(value).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textLight,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewScreen() {
    var riskData = getRiskLevel();
    List<Map<String, dynamic>> allQuestions = getQuestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Risk level card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (riskData['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: riskData['color'] as Color, width: 2),
          ),
          child: Column(
            children: [
              Text(
                riskData['level'],
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: riskData['color'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                riskData['message'],
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),
              Text(
                'Risk Score: ${calculateRiskScore()}/36',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // All answers summary
        Text('Your Answers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),

        ...allQuestions.asMap().entries.map((entry) {
          int index = entry.key;
          var q = entry.value;
          int? answer = answers[q['id']];
          String answerLabel = ['None', 'Mild', 'Moderate', 'Severe'][answer ?? 0];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q${index + 1}', style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                        Text(q['question'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.lightMint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(answerLabel, style: const TextStyle(fontSize: 13, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Optional vitals section
        if (currentStep == 3) ...[
          Text('Optional Vitals', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildNumericInput('Blood Pressure (Systolic)', bpSystolic, (val) {
            setState(() => bpSystolic = val);
          }, 'mmHg'),
          const SizedBox(height: 12),
          _buildNumericInput('Blood Pressure (Diastolic)', bpDiastolic, (val) {
            setState(() => bpDiastolic = val);
          }, 'mmHg'),
          const SizedBox(height: 12),
          _buildNumericInput('Blood Glucose', bloodGlucose, (val) {
            setState(() => bloodGlucose = val);
          }, 'mg/dL'),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildNumericInput(String label, double? value, Function(double?) onChanged, String unit) {
    TextEditingController controller = TextEditingController(text: value?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            decoration: InputDecoration(
              hintText: 'Enter value',
              suffixText: unit,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (val) {
              onChanged(val.isEmpty ? null : double.tryParse(val));
            },
          ),
        ],
      ),
    );
  }

  void _submitCheckin() async {
    setState(() => isSubmitting = true);

    // Convert answers to strings for CheckinModel
    Map<String, String> finalAnswers = answers.map((key, value) => MapEntry(key, value.toString()));

    String riskLevel = getRiskLevel()['level'];
    String riskColor = riskLevel.toLowerCase();

    final box = Hive.box<CheckinModel>('checkins');
    final checkin = CheckinModel(
      condition: widget.condition,
      date: DateTime.now(),
      answers: finalAnswers,
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
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
      debugPrint('Failed to upload: $e');
    }

    if (mounted) Navigator.of(context).pop();
    setState(() => isSubmitting = false);

    if (!mounted) return;

    Color displayColor = getRiskLevel()['color'];
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
              decoration: BoxDecoration(color: displayColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.favorite, color: displayColor, size: 40),
            ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
            const SizedBox(height: 24),
            Text(riskLevel, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: displayColor)),
            const SizedBox(height: 12),
            Text(getRiskLevel()['message'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppTheme.textDark, height: 1.4)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: uploadSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(uploadSuccess ? Icons.cloud_done : Icons.cloud_off, color: uploadSuccess ? Colors.green : Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    uploadSuccess ? 'Synced to Cloud' : 'Saved Locally',
                    style: TextStyle(fontSize: 13, color: uploadSuccess ? Colors.green[700] : Colors.orange[700], fontWeight: FontWeight.bold),
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
}
