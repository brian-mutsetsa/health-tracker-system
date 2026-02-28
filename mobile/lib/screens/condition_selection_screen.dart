import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'daily_checkin_screen.dart';
import 'home_screen.dart';

class ConditionSelectionScreen extends StatefulWidget {
  final bool isFirstTime;
  
  const ConditionSelectionScreen({Key? key, this.isFirstTime = true}) : super(key: key);

  @override
  State<ConditionSelectionScreen> createState() => _ConditionSelectionScreenState();
}

class _ConditionSelectionScreenState extends State<ConditionSelectionScreen> {
  String? selectedCondition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Welcome' : 'Select Your Condition'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.isFirstTime,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Which condition are you monitoring?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Select one to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              _buildConditionCard(
                'Hypertension',
                'High Blood Pressure',
                Icons.favorite,
                Colors.red,
              ),
              const SizedBox(height: 15),
              
              _buildConditionCard(
                'Diabetes',
                'Blood Sugar Management',
                Icons.water_drop,
                Colors.orange,
              ),
              const SizedBox(height: 15),
              
              _buildConditionCard(
                'Heart Disease',
                'Cardiovascular Health',
                Icons.monitor_heart,
                Colors.pink,
              ),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: selectedCondition == null ? null : () async {
                  final settingsBox = Hive.box('settings');
                  await settingsBox.put('condition', selectedCondition);
                  
                  if (!mounted) return;
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionCard(String title, String subtitle, IconData icon, Color color) {
    bool isSelected = selectedCondition == title;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCondition = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }
}