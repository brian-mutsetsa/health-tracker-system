import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ConditionSelectionScreen extends StatefulWidget {
  final bool isFirstTime;

  const ConditionSelectionScreen({super.key, this.isFirstTime = true});

  @override
  State<ConditionSelectionScreen> createState() =>
      _ConditionSelectionScreenState();
}

class _ConditionSelectionScreenState extends State<ConditionSelectionScreen> {
  String? selectedCondition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (!widget.isFirstTime)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppTheme.textDark,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  Expanded(
                    child: Text(
                      widget.isFirstTime ? 'Welcome' : 'Select Condition',
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(fontSize: 24),
                      textAlign: widget.isFirstTime
                          ? TextAlign.center
                          : TextAlign.left,
                    ),
                  ),
                  if (!widget.isFirstTime) const SizedBox(width: 48), // balance
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Which condition are you monitoring?',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 20),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(begin: 0.1),

                    const SizedBox(height: 8),

                    Text(
                      'Select one to get personalized tracking.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 40),

                    _buildConditionCard(
                      'Hypertension',
                      'High Blood Pressure',
                      Icons.favorite,
                      Colors.redAccent,
                      200.ms,
                    ),
                    const SizedBox(height: 16),
                    _buildConditionCard(
                      'Diabetes',
                      'Blood Sugar Management',
                      Icons.water_drop,
                      Colors.orangeAccent,
                      300.ms,
                    ),
                    const SizedBox(height: 16),
                    _buildConditionCard(
                      'Heart Disease',
                      'Cardiovascular Health',
                      Icons.monitor_heart,
                      Colors.purpleAccent,
                      400.ms,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: selectedCondition == null
                    ? null
                    : () async {
                        final settingsBox = Hive.box('settings');
                        await settingsBox.put('condition', selectedCondition);

                        if (!mounted) return;

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppTheme.primaryTeal,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ).animate().slideY(begin: 1.0, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionCard(
    String title,
    String subtitle,
    IconData icon,
    Color badgeColor,
    Duration delay,
  ) {
    bool isSelected = selectedCondition == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCondition = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightMint : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryTeal.withOpacity(0.5)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected ? AppTheme.darkTeal : AppTheme.textDark,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppTheme.primaryTeal
                          : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryTeal,
              ).animate().scale(curve: Curves.easeOutBack),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: 0.1);
  }
}
