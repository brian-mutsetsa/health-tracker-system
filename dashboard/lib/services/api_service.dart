import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Patient {
  final String id;
  final String patientId;
  final String condition;
  final DateTime? lastCheckin;
  final String? lastRiskLevel;
  final String? lastRiskColor;
  final int totalCheckins;

  Patient({
    required this.id,
    required this.patientId,
    required this.condition,
    this.lastCheckin,
    this.lastRiskLevel,
    this.lastRiskColor,
    required this.totalCheckins,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'].toString(),
      patientId: json['patient_id'] ?? 'N/A',
      condition: json['condition'] ?? 'Unknown',
      lastCheckin: json['last_checkin'] != null
          ? DateTime.parse(json['last_checkin'])
          : null,
      lastRiskLevel: json['last_risk_level'],
      lastRiskColor: json['last_risk_color'],
      totalCheckins: json['total_checkins'] ?? 0,
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
  final String patientName;
  final String providerId;
  final String? providerName;
  final String scheduledDate;
  final String scheduledTime;
  final int durationMinutes;
  final String reason;
  final String status;

  Appointment({
    required this.id,
    required this.patientName,
    required this.providerId,
    this.providerName,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.durationMinutes,
    required this.reason,
    required this.status,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientName: json['patient_name'] ?? 'Unknown',
      providerId: json['provider_id'] ?? '',
      providerName: json['provider_name'],
      scheduledDate: json['scheduled_date'] ?? '',
      scheduledTime: json['scheduled_time'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 30,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'SCHEDULED',
    );
  }
}

class DashboardApiService {
  // CHANGE THIS to your computer's IP address (same as mobile app)
  static const String baseUrl =
      'https://health-tracker-api-blky.onrender.com/api';

  static String? currentProviderId;
  static String? currentProviderName;
  /// Holds the error type from the last failed login attempt.
  /// Values: 'not_found', 'deactivated', 'no_profile', 'invalid_credentials', or null.
  static String? lastLoginErrorType;

  /// Authenticate Provider Login
  Future<String?> login(String username, String password) async {
    DashboardApiService.lastLoginErrorType = null;
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

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('provider_id', currentProviderId!);
        await prefs.setString('provider_name', currentProviderName!);

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
}
