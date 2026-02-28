import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/checkin_model.dart';
import '../services/api_service.dart';
import 'history_screen.dart';

class DailyCheckinScreen extends StatefulWidget {
  final String condition;
  
  const DailyCheckinScreen({Key? key, required this.condition}) : super(key: key);

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
        {'id': 'q6', 'question': 'Are you experiencing numbness in hands/feet?'},
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
    String todayDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Daily Check-in'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Text(
                todayDate,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Answer honestly for accurate health tracking',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              ...questions.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> q = entry.value;
                return Column(
                  children: [
                    _buildQuestionCard(index + 1, q['id'], q['question']),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
              
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: answers.length == questions.length ? () {
                  _submitCheckin();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  'Submit Check-in (${answers.length}/${questions.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int number, String id, String question) {
    String? currentAnswer = answers[id];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildAnswerChip('None', id, currentAnswer),
              _buildAnswerChip('Mild', id, currentAnswer),
              _buildAnswerChip('Severe', id, currentAnswer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerChip(String label, String questionId, String? currentAnswer) {
    bool isSelected = currentAnswer == label;
    Color chipColor;
    
    if (label == 'None') {
      chipColor = Colors.green;
    } else if (label == 'Mild') {
      chipColor = Colors.orange;
    } else {
      chipColor = Colors.red;
    }
    
    return GestureDetector(
      onTap: () {
        setState(() {
          answers[questionId] = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _submitCheckin() async {
    int severeCount = answers.values.where((answer) => answer == 'Severe').length;
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
    
    // Save to Hive (local storage)
    final box = Hive.box<CheckinModel>('checkins');
    final checkin = CheckinModel(
      condition: widget.condition,
      date: DateTime.now(),
      answers: answers,
      riskLevel: riskLevel,
      riskColor: riskColor,
    );
    await box.add(checkin);
    
    // Upload to Django API
    bool uploadSuccess = false;
    try {
      final apiService = ApiService();
      final patientId = await apiService.getPatientId();
      uploadSuccess = await apiService.uploadCheckin(checkin, patientId);
    } catch (e) {
      print('Failed to upload to Django: $e');
      // Continue anyway - data is saved locally
    }
    
    if (!mounted) return;
    
    Color displayColor = _getColorFromString(riskColor);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              color: displayColor,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              riskLevel,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getRiskMessage(riskLevel),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              uploadSuccess 
                  ? 'Check-in saved & uploaded!' 
                  : 'Check-in saved locally!',
              style: TextStyle(
                fontSize: 14,
                color: uploadSuccess ? Colors.green[700] : Colors.orange[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow[700]!;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRiskMessage(String riskLevel) {
    switch (riskLevel) {
      case 'GREEN':
        return "You're doing well! Keep monitoring daily.";
      case 'YELLOW':
        return "Minor symptoms detected. Continue monitoring closely.";
      case 'ORANGE':
        return "Concerning symptoms. Consider contacting your healthcare provider.";
      case 'RED':
        return "Urgent symptoms detected. Seek medical attention soon.";
      default:
        return "";
    }
  }
}