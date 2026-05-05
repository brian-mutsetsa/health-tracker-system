import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Patient {
  final String id;
  final String patientId;
  final String name;
  final String surname;
  final String condition;
  final DateTime? lastCheckin;
  final String? lastRiskLevel;
  final String? lastRiskColor;
  final int totalCheckins;
  final String? gender;
  final String? dateOfBirth;
  final int? age;
  final String? idNumber;
  final String? phoneNumber;
  final String? district;
  final String? homeAddress;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final double? weightKg;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? bloodGlucose;
  final String? medicalHistory;
  final String? medications;
  final String? allergies;
  final String? primaryProviderId;
  final String status;

  Patient({
    required this.id,
    required this.patientId,
    required this.name,
    this.surname = '',
    required this.condition,
    this.lastCheckin,
    this.lastRiskLevel,
    this.lastRiskColor,
    required this.totalCheckins,
    this.gender,
    this.dateOfBirth,
    this.age,
    this.idNumber,
    this.phoneNumber,
    this.district,
    this.homeAddress,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.weightKg,
    this.bpSystolic,
    this.bpDiastolic,
    this.bloodGlucose,
    this.medicalHistory,
    this.medications,
    this.allergies,
    this.primaryProviderId,
    this.status = 'ACTIVE',
  });

  String get displayName {
    final full = [name, surname].where((s) => s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : patientId;
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'].toString(),
      patientId: json['patient_id'] ?? 'N/A',
      name: (json['name'] as String?)?.isNotEmpty == true ? json['name'] : '',
      surname: (json['surname'] as String?) ?? '',
      condition: json['condition'] ?? 'Unknown',
      lastCheckin: json['last_checkin'] != null
          ? DateTime.parse(json['last_checkin'])
          : null,
      lastRiskLevel: json['last_risk_level'],
      lastRiskColor: json['last_risk_color'],
      totalCheckins: json['total_checkins'] ?? 0,
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      age: json['age'],
      idNumber: json['id_number'],
      phoneNumber: json['phone_number'],
      district: json['district'],
      homeAddress: json['home_address'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      emergencyContactRelation: json['emergency_contact_relation'],
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      bpSystolic: json['blood_pressure_systolic'],
      bpDiastolic: json['blood_pressure_diastolic'],
      bloodGlucose: json['blood_glucose_baseline'],
      medicalHistory: json['medical_history'],
      medications: json['medications'],
      allergies: json['allergies'],
      primaryProviderId: json['primary_provider_id'],
      status: json['status'] ?? 'ACTIVE',
    );
  }
}

class ClinicalVisit {
  final int id;
  final String hcwId;
  final DateTime visitDate;
  final int? systolicBp;
  final int? diastolicBp;
  final int? heartRate;
  final int? bloodGlucose;
  final double? weightKg;
  final double? temperature;
  final double? oxygenSaturation;
  final String comments;
  final String medicationIntake;
  final String changesMade;

  ClinicalVisit({
    required this.id,
    required this.hcwId,
    required this.visitDate,
    this.systolicBp,
    this.diastolicBp,
    this.heartRate,
    this.bloodGlucose,
    this.weightKg,
    this.temperature,
    this.oxygenSaturation,
    this.comments = '',
    this.medicationIntake = '',
    this.changesMade = '',
  });

  factory ClinicalVisit.fromJson(Map<String, dynamic> json) {
    return ClinicalVisit(
      id: json['id'],
      hcwId: json['hcw_id'] ?? '',
      visitDate: DateTime.parse(json['visit_date']),
      systolicBp: json['systolic_bp'],
      diastolicBp: json['diastolic_bp'],
      heartRate: json['heart_rate'],
      bloodGlucose: json['blood_glucose'],
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      oxygenSaturation: (json['oxygen_saturation'] as num?)?.toDouble(),
      comments: json['comments'] ?? '',
      medicationIntake: json['medication_intake'] ?? '',
      changesMade: json['changes_made'] ?? '',
    );
  }
}

class DashboardNotification {
  final int id;
  final String userId;
  final String notificationType;
  final String message;
  final bool isRead;
  final String? relatedPatientId;
  final DateTime createdAt;

  DashboardNotification({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.message,
    required this.isRead,
    this.relatedPatientId,
    required this.createdAt,
  });

  factory DashboardNotification.fromJson(Map<String, dynamic> json) {
    return DashboardNotification(
      id: json['id'],
      userId: json['user_id'] ?? '',
      notificationType: json['notification_type'] ?? 'GENERAL',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      relatedPatientId: json['related_patient_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Message {
  final int id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'],
    );
  }
}

class Appointment {
  final int id;
  final int? patientPk;
  final String patientName;
  final String patientIdStr;
  final String providerId;
  final String? providerName;
  final String scheduledDate;
  final String scheduledTime;
  final int durationMinutes;
  final String reason;
  final String status;
  final String initiatedBy;

  Appointment({
    required this.id,
    this.patientPk,
    required this.patientName,
    this.patientIdStr = '',
    required this.providerId,
    this.providerName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.durationMinutes,
    required this.reason,
    required this.status,
    this.initiatedBy = 'PROVIDER',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientPk: json['patient'],
      patientName: json['patient_name'] ?? 'Unknown',
      patientIdStr: json['patient_id_str'] ?? '',
      providerId: json['provider_id'] ?? '',
      providerName: json['provider_name'],
      scheduledDate: json['scheduled_date'] ?? '',
      scheduledTime: json['scheduled_time'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 30,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'SCHEDULED',
      initiatedBy: json['initiated_by'] ?? 'PROVIDER',
    );
  }
}

class DashboardApiService {
  // CHANGE THIS to your computer's IP address (same as mobile app)
  static const String baseUrl =
      'https://health-tracker-api-blky.onrender.com/api';

  static String? currentProviderId;
  static String? currentProviderName;
  /// Specialty of the logged-in provider. Empty string means not yet configured.
  static String currentProviderSpecialty = '';
  /// Holds the error type from the last failed login attempt.
  /// Values: 'not_found', 'deactivated', 'invalid_credentials', or null.
  static String? lastLoginErrorType;
  /// True when the logged-in account has no specialty/hospital configured yet.
  static bool setupIncomplete = false;

  /// Authenticate Provider Login
  Future<String?> login(String username, String password) async {
    DashboardApiService.lastLoginErrorType = null;
    DashboardApiService.setupIncomplete = false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        currentProviderId = data['provider_id'];
        currentProviderName = '${data['last_name']}';
        currentProviderSpecialty = (data['specialty'] as String?) ?? '';
        DashboardApiService.setupIncomplete = data['setup_incomplete'] == true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('provider_id', currentProviderId!);
        await prefs.setString('provider_name', currentProviderName!);
        await prefs.setString('provider_specialty', currentProviderSpecialty);

        return null; // Success — no error message
      }

      // Store the error type so the UI can show the right dialog
      DashboardApiService.lastLoginErrorType = data['error_type'] as String?;
      return data['error'] as String? ?? 'Login failed. Please try again.';
    } catch (e) {
      print('❌ Error during login: $e');
      return 'Network error or server unreachable.';
    }
  }

  /// Returns 'deactivated' if the admin has deactivated this account since login,
  /// 'ok' if the session is still valid, or null if the check could not complete.
  Future<String?> verifySession() async {
    final providerId = currentProviderId;
    if (providerId == null) return null;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify/?provider_id=$providerId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        return data['error_type'] as String? ?? 'deactivated';
      }
      return 'ok';
    } catch (_) {
      return null; // Network error — don't force logout
    }
  }

  Future<List<Patient>> getPatients() async {
    try {
      final providerId = currentProviderId ?? '';
      print('📤 Fetching patients from: $baseUrl/patients/?provider_id=$providerId');

      final response = await http.get(
        Uri.parse('$baseUrl/patients/?provider_id=$providerId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle paginated response: {count, page, page_size, total_pages, results}
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('results')) {
          // Paginated response
          data = responseData['results'];
          print('✅ Received ${data.length} patients (paginated)');
        } else if (responseData is List) {
          // Direct array response
          data = responseData;
          print('✅ Received ${data.length} patients');
        } else {
          print('❌ Unexpected response format: $responseData');
          return [];
        }

        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        print('❌ Failed to load patients: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching patients: $e');
      return [];
    }
  }

  Future<List<Patient>> getHighRiskPatients() async {
    try {
      List<Patient> allPatients = await getPatients();
      return allPatients
          .where((p) => p.lastRiskLevel == 'RED' || p.lastRiskLevel == 'ORANGE')
          .toList();
    } catch (e) {
      print('❌ Error fetching high risk patients: $e');
      return [];
    }
  }

  Future<List<dynamic>> getPatientCheckinsRaw(String patientId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/patient/$patientId/checkins/'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data;
      }
      return [];
    } else {
      throw Exception('Failed to load patient records');
    }
  }

  Future<List<Message>> getMessages(String patientId) async {
    final providerId = currentProviderId ?? 'provider';
    final response = await http.get(
      Uri.parse('$baseUrl/messages/?user_id=$providerId&other_id=$patientId'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> sendMessage(String recipientId, String content) async {
    final providerId = currentProviderId ?? 'provider';
    final response = await http.post(
      Uri.parse('$baseUrl/messages/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sender_id': providerId,
        'receiver_id': recipientId,
        'content': content,
      }),
    );
    return response.statusCode == 201;
  }

  Future<void> updateTypingStatus(String patientId, bool isTyping) async {
    try {
      final providerId = currentProviderId ?? 'provider';
      await http.post(
        Uri.parse('$baseUrl/typing/update/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': providerId,
          'chat_partner_id': patientId,
          'is_typing': isTyping,
        }),
      );
    } catch (e) {
      print('❌ Error updating typing status: $e');
    }
  }

  Future<bool> getTypingStatus(String patientId) async {
    try {
      final providerId = currentProviderId ?? 'provider';
      final response = await http.get(
        Uri.parse(
          '$baseUrl/typing/status/?user_id=$providerId&partner_id=$patientId',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_typing'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error fetching typing status: $e');
      return false;
    }
  }

  Future<List<Appointment>> getAppointments() async {
    try {
      final providerId = currentProviderId ?? '';
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/?provider_id=$providerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        List<dynamic> data;
        if (responseData is Map && responseData.containsKey('results')) {
          data = responseData['results'];
        } else if (responseData is List) {
          data = responseData;
        } else {
          return [];
        }
        return data.map((json) => Appointment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching appointments: $e');
      return [];
    }
  }

  Future<bool> completeAppointment(int appointmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/$appointmentId/complete/'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error completing appointment: $e');
      return false;
    }
  }

  Future<bool> cancelAppointment(int appointmentId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/appointments/$appointmentId/cancel/'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error cancelling appointment: $e');
      return false;
    }
  }

  Future<bool> updateAppointmentStatus(int appointmentId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/appointments/$appointmentId/update/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating appointment: $e');
      return false;
    }
  }

  /// Create a new appointment (provider-initiated → status=SCHEDULED immediately).
  /// Returns null on success, or an error string on failure.
  Future<String?> createAppointment({
    required int patientPk,
    required String scheduledDate,
    required String scheduledTime,
    required String reason,
    String initiatedBy = 'PROVIDER',
  }) async {
    try {
      final providerId = currentProviderId ?? '';
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient': patientPk,
          'provider_id': providerId,
          'scheduled_date': scheduledDate,
          'scheduled_time': scheduledTime,
          'reason': reason,
          'duration_minutes': 30,
          'initiated_by': initiatedBy,
        }),
      );
      if (response.statusCode == 201) return null;
      if (response.statusCode == 409) {
        final data = jsonDecode(response.body);
        return data['error'] ?? 'This time slot is already booked.';
      }
      return 'Failed to create appointment (${response.statusCode})';
    } catch (e) {
      print('❌ Error creating appointment: $e');
      return 'Network error creating appointment.';
    }
  }

  /// Returns the list of already-booked HH:MM time strings for a provider on a date.
  /// Optionally pass [patientId] to also grey out slots where that patient is already booked.
  Future<List<String>> getBookedSlots(String providerId, String date, {String? patientId}) async {
    try {
      final extra = patientId != null ? '&patient_id=$patientId' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/booked-slots/?provider_id=$providerId&date=$date$extra'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['booked_times'] ?? []);
      }
      return [];
    } catch (e) {
      print('❌ Error fetching booked slots: $e');
      return [];
    }
  }

  /// Approve a patient-requested PENDING appointment → sets it to SCHEDULED.
  Future<bool> approveAppointment(int appointmentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/$appointmentId/approve/'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error approving appointment: $e');
      return false;
    }
  }

  Future<Map<String, int>> getStats() async {
    try {
      List<Patient> patients = await getPatients();

      int totalPatients = patients.length;
      int highRisk = patients
          .where((p) => p.lastRiskLevel == 'RED' || p.lastRiskLevel == 'ORANGE')
          .length;
      int totalCheckins = patients.fold(0, (sum, p) => sum + p.totalCheckins);

      return {
        'total_patients': totalPatients,
        'high_risk': highRisk,
        'total_checkins': totalCheckins,
      };
    } catch (e) {
      print('❌ Error fetching stats: $e');
      return {'total_patients': 0, 'high_risk': 0, 'total_checkins': 0};
    }
  }

  Future<List<DashboardNotification>> getNotifications(
      String userId, {bool unreadOnly = false}) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/notifications/?user_id=$userId&unread_only=${unreadOnly ? 'true' : 'false'}');
      final response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items =
            data is List ? data : (data['results'] ?? []);
        return items
            .map((j) => DashboardNotification.fromJson(j))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      return [];
    }
  }

  Future<bool> markNotificationRead(int id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read/'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error marking notification read: $e');
      return false;
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/notifications/mark-all-read/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );
    } catch (_) {}
  }

  Future<bool> deleteNotification(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$id/delete/'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Fetch full patient detail (includes checkins).
  Future<Patient?> getPatientDetail(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patient/$patientId/'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return Patient.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('❌ Error fetching patient detail: $e');
      return null;
    }
  }

  /// Fetch clinical visit records for a patient.
  Future<List<ClinicalVisit>> getClinicalVisits(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patient/$patientId/clinical-visits/'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((j) => ClinicalVisit.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching clinical visits: $e');
      return [];
    }
  }

  /// HCW submits a new clinical visit record.
  Future<String?> addClinicalVisit(String patientId, Map<String, dynamic> visitData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patient/$patientId/clinical-visits/add/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(visitData),
      );
      if (response.statusCode == 201) return null;
      final data = jsonDecode(response.body);
      return data.toString();
    } catch (e) {
      print('❌ Error adding clinical visit: $e');
      return 'Network error.';
    }
  }

  /// Register a new patient (HCW-initiated with expanded fields).
  Future<Map<String, dynamic>> registerPatient(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patients/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'error': body['error'] ?? body.toString()};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
