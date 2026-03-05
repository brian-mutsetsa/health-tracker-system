import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/checkin_model.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    'My Consultations',
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
                        Icons.more_vert,
                        color: AppTheme.textDark,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Hive.box<CheckinModel>(
                  'checkins',
                ).listenable(),
                builder: (context, Box<CheckinModel> box, _) {
                  if (box.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  List<CheckinModel> checkins = box.values.toList();
                  checkins.sort((a, b) => b.date.compareTo(a.date));

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 10),
                      // Top Banner Card
                      _buildLabResultCard(),

                      const SizedBox(height: 32),
                      const Text(
                        'Recent Check-ins',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ).animate().fadeIn(),
                      const SizedBox(height: 16),

                      ...checkins.asMap().entries.map((entry) {
                        return _buildCheckinCard(
                              context,
                              entry.value,
                              isLatest: entry.key == 0,
                            )
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 100 * entry.key),
                            )
                            .slideX(begin: 0.1);
                      }).toList(),

                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.history,
              size: 60,
              color: AppTheme.textLight,
            ),
          ).animate().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          const Text(
            'No consultations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Complete your first daily check-in.',
            style: TextStyle(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildLabResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lightMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.science, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Analysis Ready',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your latest insights are available.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.mintGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'View',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildCheckinCard(
    BuildContext context,
    CheckinModel checkin, {
    required bool isLatest,
  }) {
    Color riskColor = _getColorFromString(checkin.riskColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLatest ? AppTheme.primaryTeal : Colors.white,
        gradient: isLatest ? AppTheme.mintGradient : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isLatest
            ? [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isLatest
                      ? Colors.white.withOpacity(0.2)
                      : riskColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    checkin.riskLevel[0],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isLatest ? Colors.white : riskColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkin.condition,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isLatest ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Risk: ${checkin.riskLevel}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isLatest ? Colors.white70 : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isLatest ? Colors.white : AppTheme.lightMint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Details',
                  style: TextStyle(
                    color: isLatest ? AppTheme.primaryTeal : AppTheme.darkTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: isLatest ? Colors.white.withOpacity(0.2) : Colors.grey[200],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 16,
                    color: isLatest ? Colors.white70 : AppTheme.textLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMMM d, yyyy').format(checkin.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: isLatest ? Colors.white70 : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isLatest ? Colors.white70 : AppTheme.textLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('h:mm a').format(checkin.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: isLatest ? Colors.white70 : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    if (colorString == 'green') return Colors.green;
    if (colorString == 'yellow') return Colors.amber;
    if (colorString == 'orange') return Colors.orange;
    if (colorString == 'red') return Colors.red;
    return Colors.grey;
  }
}
