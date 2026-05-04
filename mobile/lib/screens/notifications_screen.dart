import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final settingsBox = Hive.box('settings');
    final patientId = settingsBox.get('patient_id', defaultValue: '');
    if (patientId.isNotEmpty) {
      // Mark all as read server-side as soon as this screen is opened
      await _apiService.markAllNotificationsRead(patientId);
      final notifs = await _apiService.getNotifications(patientId);
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _loading = false;
        });
      }
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    await _apiService.markNotificationRead(id);
    await _loadNotifications();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('d MMM, h:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryTeal),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 72,
                          color: AppTheme.textLight.withAlpha(100)),
                      const SizedBox(height: 16),
                      const Text(
                        'No notifications yet',
                        style:
                            TextStyle(fontSize: 18, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return _buildNotificationCard(n);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final isRead = n['is_read'] == true;
    final type = n['notification_type'] as String? ?? 'GENERAL';
    final isAlert = type == 'HIGH_RISK_ALERT';
    final isAppt = type == 'APPOINTMENT';

    final color = isAlert
        ? Colors.red
        : isAppt
            ? Colors.blue
            : AppTheme.primaryTeal;
    final icon = isAlert
        ? Icons.warning_amber_rounded
        : isAppt
            ? Icons.calendar_month
            : Icons.notifications_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : color.withOpacity(0.05),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : color.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          n['message'] ?? '',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: Text(
          _formatDate(n['created_at']),
          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
        trailing: isRead
            ? null
            : TextButton(
                onPressed: () => _markRead(n['id']),
                child: const Text('Mark read',
                    style: TextStyle(fontSize: 12)),
              ),
      ),
    );
  }
}
