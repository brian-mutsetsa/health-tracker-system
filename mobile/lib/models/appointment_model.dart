class AppointmentModel {
  final int id;
  final String providerId;
  final String? providerName;
  final String scheduledDate;
  final String scheduledTime;
  final String status;
  final String reason;

  AppointmentModel({
    required this.id,
    required this.providerId,
    this.providerName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.status,
    required this.reason,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      providerId: json['provider_id'] ?? 'provider',
      providerName: json['provider_name'],
      scheduledDate: json['scheduled_date'],
      scheduledTime: json['scheduled_time'],
      status: json['status'] ?? 'SCHEDULED',
      reason: json['reason'] ?? '',
    );
  }
}
