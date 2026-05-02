import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../models/appointment_model.dart';
import '../services/api_service.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final ApiService _apiService = ApiService();
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    final appointments = await _apiService.getAppointments();
    // Sort so newest dates come first
    appointments.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    
    if (mounted) {
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 24,
              right: 24,
              bottom: 24,
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
                const Text(
                  'Appointments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _showScheduleDialog,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadAppointments,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                  )
                : _appointments.isEmpty
                    ? const Center(
                        child: Text(
                          'No appointments scheduled.',
                          style: TextStyle(color: AppTheme.textLight, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _appointments[index];
                          return _buildAppointmentCard(appointment);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel apt) {
    final date = DateTime.tryParse(apt.scheduledDate);
    final formattedDate = date != null ? DateFormat('MMM d, yyyy').format(date) : apt.scheduledDate;

    final isPending = apt.status == 'PENDING';
    Color statusColor = AppTheme.textLight;
    if (apt.status == 'SCHEDULED') statusColor = Colors.orange;
    if (apt.status == 'COMPLETED') statusColor = Colors.green;
    if (apt.status == 'CANCELLED' || apt.status == 'NO_SHOW') statusColor = Colors.red;
    if (isPending) statusColor = Colors.amber.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isPending ? Border.all(color: Colors.amber.shade300, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPending ? 'Awaiting Approval' : apt.status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppTheme.primaryTeal),
              const SizedBox(width: 8),
              Text(
                apt.scheduledTime,
                style: const TextStyle(color: AppTheme.textDark, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.medical_services, size: 16, color: AppTheme.primaryTeal),
              const SizedBox(width: 8),
              Text(
                apt.providerName != null ? 'Dr. ${apt.providerName}' : 'Provider: ${apt.providerId}',
                style: const TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (apt.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFEEEEEE)),
            const SizedBox(height: 8),
            Text(
              'Reason: ${apt.reason}',
              style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
            ),
          ]
        ],
      ),
    );
  }

  static const _timeSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '14:00', '14:30', '15:00',
    '15:30', '16:00', '16:30',
  ];

  void _showScheduleDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String? selectedTime;
    List<String> bookedSlots = [];
    bool loadingSlots = false;
    final reasonController = TextEditingController();

    Future<void> fetchSlots(StateSetter setDialogState, DateTime date) async {
      setDialogState(() => loadingSlots = true);
      final providerId = await _apiService.getAssignedProviderId();
      if (providerId.isNotEmpty) {
        final slots = await _apiService.getBookedSlots(providerId, date);
        setDialogState(() {
          bookedSlots = slots;
          loadingSlots = false;
          if (selectedTime != null && bookedSlots.contains(selectedTime)) {
            selectedTime = null;
          }
        });
      } else {
        setDialogState(() => loadingSlots = false);
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Request Appointment'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primaryTeal),
                    title: const Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedDate = date;
                          selectedTime = null;
                          bookedSlots = [];
                        });
                        await fetchSlots(setDialogState, date);
                      }
                    },
                  ),
                  const Divider(),
                  // Time slot grid
                  Row(
                    children: [
                      const Text('Select Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      if (loadingSlots)
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeSlots.map((slot) {
                      final isBooked = bookedSlots.contains(slot);
                      final isSelected = selectedTime == slot;
                      return GestureDetector(
                        onTap: isBooked ? null : () => setDialogState(() => selectedTime = slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isBooked
                                ? Colors.grey.shade200
                                : isSelected
                                    ? AppTheme.primaryTeal
                                    : Colors.white,
                            border: Border.all(
                              color: isBooked
                                  ? Colors.grey.shade300
                                  : isSelected
                                      ? AppTheme.primaryTeal
                                      : Colors.grey.shade400,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            slot,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isBooked
                                  ? Colors.grey.shade400
                                  : isSelected
                                      ? Colors.white
                                      : AppTheme.textDark,
                              decoration: isBooked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Reason field
                  const Text('Reason (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Need medication review',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Patient-requested appointments require provider approval before confirmation.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedTime == null
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);
                      final patientId = Hive.box('settings').get('patient_id', defaultValue: '');
                      final error = await _apiService.createAppointment(
                        patientId: patientId,
                        scheduledDate: selectedDate,
                        scheduledTime: selectedTime!,
                        reason: reasonController.text.trim().isEmpty
                            ? 'Patient requested'
                            : reasonController.text.trim(),
                      );
                      if (mounted) {
                        if (error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Request sent — awaiting provider approval'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await _loadAppointments();
                        } else if (error == 'conflict') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ That time slot is already booked. Please choose another time.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('❌ $error'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Request'),
            ),
          ],
        ),
      ),
    );
    // Preload booked slots for the initial date is done when dialog opens via StatefulBuilder
  }
}
