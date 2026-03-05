import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  void _finishTutorial(BuildContext context) async {
    final settingsBox = Hive.box('settings');
    await settingsBox.put('has_seen_tutorial', true);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightMint,
      body: Stack(
        children: [
          // Background Gradient (top to middle)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Container(
              decoration: const BoxDecoration(gradient: AppTheme.mintGradient),
            ),
          ),

          // Doctor Image Placeholder (Mocking the doctor with folded arms)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Image.network(
              'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=1470&auto=format&fit=crop', // Beautiful high quality doctor image
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ).animate().fade(duration: 800.ms).scale(begin: const Offset(1.05, 1.05)),
          ),

          // Bottom White Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Little indicator dots
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 12,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 12,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 32),

                  Text(
                        'Connect With Trusted\nDoctors Instantly',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(fontSize: 28, height: 1.2),
                      )
                      .animate()
                      .slideY(begin: 0.2, curve: Curves.easeOut)
                      .fadeIn(),

                  const SizedBox(height: 16),

                  Text(
                        'Skip the waiting room. Track your symptoms, get AI risk analysis, and manage your health from anywhere all in one app.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      )
                      .animate()
                      .slideY(begin: 0.2, delay: 100.ms, curve: Curves.easeOut)
                      .fadeIn(),

                  const Spacer(),

                  // Get Started Button mimicking the reference exactly
                  GestureDetector(
                    onTap: () => _finishTutorial(context),
                    child:
                        Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppTheme.mintGradient,
                                      ),
                                      child: const Icon(
                                        Icons.keyboard_double_arrow_right,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Get Started',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontSize: 16),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.only(right: 20),
                                    child: Icon(
                                      Icons.keyboard_double_arrow_right,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .slideY(
                              begin: 0.2,
                              delay: 200.ms,
                              curve: Curves.easeOut,
                            )
                            .fadeIn(),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
