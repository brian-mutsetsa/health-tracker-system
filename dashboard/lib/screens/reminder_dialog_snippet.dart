  void _showReminderDialog(BuildContext context, String patientId) {
    String selectedType = 'MEDICATION';
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Send Reminder to Patient'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'MEDICATION', child: Text('Medication Reminder')),
                    DropdownMenuItem(value: 'APPOINTMENT', child: Text('Appointment Reminder')),
                    DropdownMenuItem(value: 'GENERAL', child: Text('General Reminder')),
                  ],
                  onChanged: (val) => setState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: 'Reminder Type'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'e.g. Please remember to take your evening dose of Amlodipine.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final msg = messageController.text.trim();
                  if (msg.isEmpty) return;
                  Navigator.pop(ctx);
                  
                  try {
                    await DashboardApiService().sendPatientReminder(patientId, selectedType, msg);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder sent successfully!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send reminder.')),
                      );
                    }
                  }
                },
                child: const Text('Send Reminder'),
              ),
            ],
          );
        },
      ),
    );
  }
