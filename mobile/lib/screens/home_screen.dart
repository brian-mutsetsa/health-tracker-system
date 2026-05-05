import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/checkin_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'daily_checkin_screen.dart';
import 'messages_screen.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';
import 'checkin_history_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _pollingTimer;
  final ApiService _apiService = ApiService();
  int _lastKnownAppointmentCount = 0;
  bool _isFirstPoll = true;
  int _unreadMessageCount = 0;
  int _upcomingAppointmentCount = 0;
  int _unreadNotificationCount = 0;
  int _lastKnownNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Initial fetch
    _fetchBadgeCounts();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      _fetchBadgeCounts();
    });
  }

  Future<void> _fetchBadgeCounts() async {
    try {
      final appointments = await _apiService.getAppointments();
      final scheduled = appointments.where((a) => a.status == 'SCHEDULED').length;
      
      if (_isFirstPoll) {
        _lastKnownAppointmentCount = appointments.length;
        _isFirstPoll = false;
      } else {
        if (appointments.length > _lastKnownAppointmentCount) {
          await NotificationService().showNotification(
            id: 1,
            title: 'New Appointment',
            body: 'You have a new appointment scheduled.',
          );
          _lastKnownAppointmentCount = appointments.length;
        } else if (appointments.length < _lastKnownAppointmentCount) {
          _lastKnownAppointmentCount = appointments.length;
        }
      }

      // Get unread messages
      int unread = 0;
      try {
        final messages = await _apiService.getMessages();
        final myId = Hive.box('settings').get('patient_id', defaultValue: '');
        unread = messages.where((m) => !m.isRead && m.senderId != myId).length;
      } catch (_) {}

      // Get notifications
      int unreadNotifs = 0;
      try {
        final patientId = Hive.box('settings').get('patient_id', defaultValue: '');
        if (patientId.isNotEmpty) {
          final notifs = await _apiService.getNotifications(patientId);
          unreadNotifs = notifs.where((n) => n['is_read'] != true).length;
          if (!_isFirstPoll && unreadNotifs > _lastKnownNotificationCount) {
            await NotificationService().showNotification(
              id: 2,
              title: 'New Notification',
              body: 'You have new health notifications.',
            );
          }
          _lastKnownNotificationCount = unreadNotifs;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          // Don't restore a badge the user already cleared by navigating to that tab
          if (_currentIndex != 2) _upcomingAppointmentCount = scheduled;
          if (_currentIndex != 3) _unreadMessageCount = unread;
          // For notifications (push screen): only increment for genuinely NEW arrivals
          final newNotifDelta = unreadNotifs > _lastKnownNotificationCount
              ? unreadNotifs - _lastKnownNotificationCount
              : 0;
          _unreadNotificationCount = _unreadNotificationCount + newNotifDelta;
        });
      }
    } catch (e) {
      print('Error polling: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, Box settingsBox, _) {
        final String savedCondition = settingsBox.get('condition', defaultValue: 'Hypertension');
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: _buildBody(savedCondition),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildBody(String condition) {
    if (_currentIndex == 2) return const AppointmentsScreen();
    if (_currentIndex == 3) return const MessagesScreen();
    if (_currentIndex == 4) return const ProfileScreen();

    return ValueListenableBuilder(
      valueListenable: Hive.box<CheckinModel>('checkins').listenable(),
      builder: (context, Box<CheckinModel> box, _) {
        List<CheckinModel> allCheckins = box.values
            .where((c) => c.condition == condition)
            .toList();
        allCheckins.sort((a, b) => b.date.compareTo(a.date));

        CheckinModel? latestCheckin = allCheckins.isNotEmpty
            ? allCheckins.first
            : null;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopSection(context),

              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Toggle Button Mock (Available/Unavailable)
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.mintGradient,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),

                      const SizedBox(height: 24),

                      // Next Appointment Mock (Matches reference)
                      _buildNextAppointmentCard(
                        context,
                        latestCheckin,
                        condition,
                      ),

                      const SizedBox(height: 32),

                      // Categories Section
                      _buildHeader(context, 'Categories', 'See All'),
                      const SizedBox(height: 16),
                      _buildCategoriesRow(context),

                      const SizedBox(height: 32),

                      // History Quick Access
                      _buildHistoryCard(context),

                      const SizedBox(height: 32),

                      // Suggested Doctors Mock
                      _buildHeader(context, 'Suggested Doctors', 'See All'),
                      const SizedBox(height: 16),
                      _buildDoctorCard(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSection(BuildContext context) {
    String formattedDate = DateFormat('MMMM d, yyyy').format(DateTime.now());
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 60,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryTeal,
        gradient: AppTheme.mintGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Today',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              // Clear the badge immediately — user is about to see the notifications
              setState(() {
                _unreadNotificationCount = 0;
                // Do NOT reset _lastKnownNotificationCount here — keeping it at the
                // current server count prevents the badge reappearing on next poll
                // for already-read notifications.
              });
              final patientId = Hive.box('settings').get('patient_id', defaultValue: '');
              if (patientId.isNotEmpty) _apiService.markAllNotificationsRead(patientId);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: AppTheme.textDark,
                  ),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadNotificationCount > 9 ? '9+' : '$_unreadNotificationCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAppointmentCard(
    BuildContext context,
    CheckinModel? latestCheckin,
    String condition,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Action / Log',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.lightMint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: AppTheme.primaryTeal,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-in: $condition',
                      style: const TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latestCheckin != null
                          ? 'Last: ${DateFormat('MMM d, h:mm a').format(latestCheckin.date)}'
                          : 'No data yet',
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.primaryTeal,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Daily log expected',
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyCheckinScreen(condition: condition),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildHeader(BuildContext context, String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title - $action coming soon!')),
            );
          },
          child: Text(
            action,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildCategoriesRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCategoryIcon(context, Icons.monitor_heart, 'Vitals', Colors.blue),
        _buildCategoryIcon(context, Icons.child_care, 'Kids', Colors.green),
        _buildCategoryIcon(context, Icons.face, 'Skin', Colors.orange),
        _buildCategoryIcon(context, Icons.psychology, 'Mind', Colors.red),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildCategoryIcon(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label category coming soon!')));
      },
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Center(child: Icon(icon, color: color, size: 28)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CheckInHistoryScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.mintGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryTeal.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'View Check-in History',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track your health progress',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.history,
                  color: AppTheme.primaryTeal,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1);
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal,
        gradient: AppTheme.mintGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: const NetworkImage(
              'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=1470&auto=format&fit=crop',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. Olivia Grant',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Family Physician',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                const Text(
                  '4.8',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }

  Widget _buildBottomNav(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding + 8, left: 24, right: 24, top: 12),
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, 0, Icons.home_rounded, 0),
            _buildNavItem(context, 1, Icons.assignment_outlined, 0),
            _buildNavItem(context, 2, Icons.calendar_month_rounded, _upcomingAppointmentCount),
            _buildNavItem(context, 3, Icons.mail_outline_rounded, _unreadMessageCount),
            _buildNavItem(context, 4, Icons.person_outline_rounded, 0),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, int badgeCount) {
    bool isSelected = _currentIndex == index;
    bool isAction = index == 1; // Check-in is a direct-action button
    return GestureDetector(
      onTap: () {
        if (isAction) {
          final condition = Hive.box('settings').get('condition', defaultValue: 'Hypertension');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DailyCheckinScreen(condition: condition)),
          );
          return;
        }
        setState(() {
          _currentIndex = index;
          // Clear the badge for the tab being opened
          if (index == 2) _upcomingAppointmentCount = 0;
          if (index == 3) _unreadMessageCount = 0;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: (isSelected || isAction)
                ? const BoxDecoration(
                    color: AppTheme.primaryTeal,
                    shape: BoxShape.circle,
                  )
                : null,
            child: Icon(
              icon,
              color: (isSelected || isAction) ? Colors.white : AppTheme.textLight,
              size: 26,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
