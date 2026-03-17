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
      id: json['id'] is int ? json['id'] : 0,
      providerId: json['provider_id']?.toString() ?? 'provider',
      providerName: json['provider_name']?.toString(),
      scheduledDate: json['scheduled_date']?.toString() ?? '',
      scheduledTime: json['scheduled_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'SCHEDULED',
      reason: json['reason']?.toString() ?? '',
    );
  }
}
