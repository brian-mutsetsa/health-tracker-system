import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/checkin_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'checkin_history_screen.dart';

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

  late final TextEditingController _bpSystolicController;
  late final TextEditingController _bpDiastolicController;
  late final TextEditingController _glucoseController;

  @override
  void initState() {
    super.initState();
    _bpSystolicController = TextEditingController();
    _bpDiastolicController = TextEditingController();
    _glucoseController = TextEditingController();
  }

  @override
  void dispose() {
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _glucoseController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> getQuestions() {
    if (widget.condition == 'Hypertension') {
      return [
        {'id': 'q1', 'question': 'Did you experience headaches today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q2', 'question': 'Did you feel dizziness or lightheadedness today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q3', 'question': 'Did you experience blurred or disturbed vision?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q4', 'question': 'Did you feel chest discomfort or pressure?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q5', 'question': 'Did you experience shortness of breath during normal activities?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q6', 'question': 'Did you feel unusual fatigue or weakness today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q7', 'question': 'Did you experience nosebleeds today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q8', 'question': 'Did you feel your heart beating rapidly or irregularly (palpitations)?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q9', 'question': 'Did you take your prescribed blood pressure medication today?', 'type': 'scale', 'options': ['Yes fully', 'Missed once', 'Missed more than once', 'Did not take']},
        {'id': 'q10', 'question': 'Did you consume foods high in salt today?', 'type': 'scale', 'options': ['None', 'Small amount', 'Moderate', 'High intake']},
        {'id': 'q11', 'question': 'Did you experience high levels of stress today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q12', 'question': 'Did you experience any swelling in your limbs or face today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
      ];
    } else if (widget.condition == 'Diabetes') {
      return [
        {'id': 'q1', 'question': 'Did you experience excessive thirst today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q2', 'question': 'Did you urinate more frequently than usual today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q3', 'question': 'Did you feel unusually hungry today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q4', 'question': 'Did you feel tired or fatigued today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q5', 'question': 'Did you experience blurred vision today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q6', 'question': 'Did you experience numbness or tingling in your hands or feet?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q7', 'question': 'Did you notice slow healing of wounds or cuts?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q8', 'question': 'Did you feel dizziness or shakiness today? (possible low blood sugar)', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q9', 'question': 'Did you take your diabetes medication or insulin today?', 'type': 'scale', 'options': ['Yes fully', 'Missed once', 'Missed more than once', 'Did not take']},
        {'id': 'q10', 'question': 'Did you follow your recommended diet today?', 'type': 'scale', 'options': ['Yes fully', 'Minor deviations', 'Moderate deviations', 'Did not follow']},
        {'id': 'q11', 'question': 'Did you perform physical activity or exercise today?', 'type': 'scale', 'options': ['None', 'Light activity', 'Moderate', 'Vigorous']},
        {'id': 'q12', 'question': 'Did you experience nausea or digestive discomfort today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
      ];
    } else {
      // Cardiovascular
      return [
        {'id': 'q1', 'question': 'Did you experience chest pain or pressure today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q2', 'question': 'Did you feel shortness of breath today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q3', 'question': 'Did you experience swelling in your legs, feet, or ankles?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q4', 'question': 'Did you feel unusually tired or weak today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q5', 'question': 'Did you experience dizziness or fainting today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q6', 'question': 'Did you feel irregular or rapid heartbeats (palpitations)?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q7', 'question': 'Did you experience pain spreading to your arm, neck, or jaw?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q8', 'question': 'Did you experience sudden sweating without physical activity?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
        {'id': 'q9', 'question': 'Did you take your heart medication today?', 'type': 'scale', 'options': ['Yes fully', 'Missed once', 'Missed more than once', 'Did not take']},
        {'id': 'q10', 'question': 'Did you perform any physical activity today?', 'type': 'scale', 'options': ['None', 'Light activity', 'Moderate', 'Vigorous']},
        {'id': 'q11', 'question': 'Did you consume alcohol or smoke today?', 'type': 'scale', 'options': ['None', 'Small amount', 'Moderate amount', 'High amount']},
        {'id': 'q12', 'question': 'Did you feel unusually stressed or anxious today?', 'type': 'scale', 'options': ['None', 'Mild', 'Moderate', 'Severe']},
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
    int score = 0;
    answers.forEach((key, value) {
      if (key.endsWith('_text')) return;
      final qNum = int.tryParse(key.replaceAll('q', ''));
      if (qNum == null) return;
      // Physical activity questions are GOOD (higher = healthier → invert score)
      final isActivityQ = (widget.condition == 'Diabetes' && qNum == 11) ||
          (widget.condition == 'Cardiovascular' && qNum == 10);
      score += isActivityQ ? (3 - value) : value;
    });
    return score;
  }

  Map<String, dynamic> getRiskLevel() {
    int score = calculateRiskScore();
    if (score >= 20) {
      return {'level': 'RED', 'color': Colors.redAccent, 'message': 'High Risk - Seek medical attention'};
    } else if (score >= 13) {
      return {'level': 'ORANGE', 'color': Colors.orangeAccent, 'message': 'Moderate Risk - Monitor closely'};
    } else if (score >= 6) {
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
      String questionKey = 'q$i';
      if (!answers.containsKey(questionKey)) {
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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckInHistoryScreen()));
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
          child: _buildQuestionCard(q, index).animate().fadeIn(delay: Duration(milliseconds: 100 * index)),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    String id = question['id'];
    String questionText = question['question'];
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
                  questionText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAnswerOptions(question, currentAnswer),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(Map<String, dynamic> question, int? currentAnswer) {
    String id = question['id'];
    String questionType = question['type'] ?? 'scale';

    // Text input for optional readings
    if (questionType == 'text') {
      return TextField(
        onChanged: (value) {
          setState(() {
            answers['${id}_text'] = 0; // Mark as answered
            // Keep the string representation separate since answers is Map<String, int>
          });
        },
        decoration: InputDecoration(
          hintText: question['placeholder'] ?? 'Enter value',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.number,
      );
    }

    // Use options from question definition - different for each question type
    List<String> options = question['options'] ?? ['None', 'Mild', 'Moderate', 'Severe'];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(options.length, (index) {
        return _buildScaleButton(index, options[index], id, currentAnswer);
      }),
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
                'Risk Score: ${calculateRiskScore()}/${answers.length * 3}',
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
          // We need to fetch the specific option text to accurately reflect what the user clicked.
          List<String> options = (q['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['None', 'Mild', 'Moderate', 'Severe'];
          String answerLabel = (answer != null && answer < options.length) ? options[answer] : (answers['${q['id']}_text_value']?.toString() ?? 'None');

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
        ...[  // always show on review screen
          Text('Optional Vitals', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildNumericInput('Blood Pressure (Systolic)', _bpSystolicController, (val) {
            bpSystolic = val;
          }, 'mmHg'),
          const SizedBox(height: 12),
          _buildNumericInput('Blood Pressure (Diastolic)', _bpDiastolicController, (val) {
            bpDiastolic = val;
          }, 'mmHg'),
          const SizedBox(height: 12),
          _buildNumericInput('Blood Glucose', _glucoseController, (val) {
            bloodGlucose = val;
          }, 'mg/dL'),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildNumericInput(String label, TextEditingController controller, Function(double?) onChanged, String unit) {

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
    Map<String, String> processedAnswers = {};
    answers.forEach((key, value) {
      if (!key.endsWith('_text')) {
        processedAnswers[key] = value.toString();
      }
    });
    // q12 is now a required scale question — no override needed

    String riskLevel = getRiskLevel()['level'];
    String riskColor = riskLevel.toLowerCase();

    final box = Hive.box<CheckinModel>('checkins');
    final checkin = CheckinModel(
      condition: widget.condition,
      date: DateTime.now(),
      answers: processedAnswers,
      riskLevel: riskLevel,
      riskColor: riskColor,
      bpSystolic: bpSystolic,
      bpDiastolic: bpDiastolic,
      bloodGlucose: bloodGlucose,
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
