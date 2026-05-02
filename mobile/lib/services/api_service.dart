import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/checkin_model.dart';
import '../models/message_model.dart';
import '../models/appointment_model.dart';

class ApiService {
  // Change this to your computer's IP address when testing on real device
  // For emulator, use 10.0.2.2
  // For localhost testing, use 127.0.0.1
  static const String baseUrl =
      'https://health-tracker-api-blky.onrender.com/api';

  // Generate or get patient ID
  Future<String> getPatientId() async {
    final settingsBox = Hive.box('settings');
    String? patientId = settingsBox.get('patient_id');

    if (patientId == null) {
      patientId = 'patient_${DateTime.now().millisecondsSinceEpoch}';
      await settingsBox.put('patient_id', patientId);
    }

    return patientId;
  }

  // Get dynamically assigned provider ID based on condition
  Future<String> getAssignedProviderId() async {
    final settingsBox = Hive.box('settings');
    final String condition = settingsBox.get('condition', defaultValue: 'Unknown');
    
    switch (condition.toLowerCase()) {
      case 'hypertension':
        return 'DR002';
      case 'diabetes':
        return 'DR003';
      case 'asthma':
        return 'DR004';
      case 'cardiovascular':
        return 'DR005';
      default:
        return 'DR001'; // General Practice fallback
    }
  }

  // Patient login - returns patient data if successful
  Future<Map<String, dynamic>?> patientLogin(
      String patientId, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/patient-login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_id': patientId,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final patientData = jsonDecode(response.body);
        // Save to Hive for session
        final settingsBox = Hive.box('settings');
        await settingsBox.put('patient_id', patientId);
        await settingsBox.put('patient_name', patientData['name']);
        await settingsBox.put('condition', patientData['condition']);
        await settingsBox.put('session_token', patientData['session_token']);
        print('✅ Login successful: ${patientData['name']}');
        return patientData;
      } else {
        print('❌ Login failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  // Register new patient
  Future<Map<String, dynamic>?> registerPatient(Map<String, dynamic> registrationData) async {
    try {
      print('📝 Attempting patient registration...');
      print('📦 Registration data: $registrationData');
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/patients/register/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(registrationData),
          )
          .timeout(const Duration(seconds: 15));

      print('📨 Response status: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final patientData = jsonDecode(response.body);
        print('✅ Registration successful: ${patientData['patient_id']}');
        return patientData;
      } else {
        print('❌ Registration failed: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Registration error: $e');
      return null;
    }
  }

  // Upload check-in to Django API
  Future<bool> uploadCheckin(CheckinModel checkin, String patientId) async {
    final condition = Hive.box(
      'settings',
    ).get('condition', defaultValue: 'Unknown');

    // Convert string answers back to integers for backend validation
    final intAnswers = <String, int>{};
    checkin.answers.forEach((k, v) {
      intAnswers[k] = int.tryParse(v) ?? 0;
    });

    final requestBody = {
      'patient_id': patientId,
      'condition': condition,
      'date': checkin.date.toIso8601String(),
      'answers': intAnswers,
      'risk_level': checkin.riskLevel,
      'risk_color': checkin.riskColor,
      'blood_pressure_systolic': checkin.bpSystolic?.round(),
      'blood_pressure_diastolic': checkin.bpDiastolic?.round(),
      'blood_glucose_reading': checkin.bloodGlucose?.round(),
    };

    print('📤 ATTEMPTING TO UPLOAD TO: $baseUrl/checkin/submit/');
    print('📦 Request body: $requestBody');

    int maxRetries = 3;
    int currentRetry = 0;

    while (currentRetry < maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/checkin/submit/'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 45));

        print('📨 Response status: ${response.statusCode}');
        print('📨 Response body: ${response.body}');

        if (response.statusCode == 201) {
          print('✅ Check-in uploaded successfully to Django');
          return true;
        } else {
          print('❌ Failed to upload check-in: ${response.statusCode}');
          print('Response: ${response.body}');
          return false;
        }
      } catch (e) {
        currentRetry++;
        print(
          '❌ Error uploading check-in (Attempt $currentRetry/$maxRetries): $e',
        );
        if (currentRetry >= maxRetries) {
          return false;
        }
        // Wait 5 seconds before retrying to allow Render more time to wake up
        await Future.delayed(const Duration(seconds: 5));
      }
    }
    return false;
  }

  // Sync all local check-ins to Django
  Future<void> syncAllCheckins() async {
    try {
      final patientId = await getPatientId();
      final box = Hive.box<CheckinModel>('checkins');

      int successCount = 0;
      int failCount = 0;

      for (var checkin in box.values) {
        bool success = await uploadCheckin(checkin, patientId);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      print('✅ Synced $successCount check-ins, $failCount failed');
    } catch (e) {
      print('❌ Error syncing check-ins: $e');
    }
  }

  // Fetch historical check-ins from backend and populate local Hive
  Future<void> fetchAndPopulateCheckinsFromAPI(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/patient/$patientId/checkins/'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final checkinsBox = Hive.box<CheckinModel>('checkins');
        
        // Clear existing check-ins first to prevent duplicates on re-login
        await checkinsBox.clear();
        
        for (var checkinJson in data) {
          try {
            // Parse the check-in JSON
            final date = DateTime.parse(checkinJson['date']);
            final rawAnswers = checkinJson['answers'] is Map ? checkinJson['answers'] : {};
            final answers = <String, String>{};
            rawAnswers.forEach((k, v) => answers[k.toString()] = v.toString());
            
            final checkin = CheckinModel(
              condition: checkinJson['condition'] ?? 'Unknown',
              date: date,
              answers: answers,
              riskLevel: checkinJson['risk_level'] ?? 'GREEN',
              riskColor: (checkinJson['risk_color'] ?? 'green').toLowerCase(),
              bpSystolic: checkinJson['blood_pressure_systolic']?.toDouble(),
              bpDiastolic: checkinJson['blood_pressure_diastolic']?.toDouble(),
              bloodGlucose: checkinJson['blood_glucose_reading']?.toDouble(),
            );
            
            await checkinsBox.add(checkin);
          } catch (e) {
            print('⚠️ Error parsing check-in: $e');
          }
        }
        
        print('✅ Populated ${data.length} historical check-ins from API');
      }
    } catch (e) {
      print('⚠️ Could not fetch check-ins from API (might be offline): $e');
      // Don't fail login if API is unreachable - just log warning
    }
  }

  // Fetch messages for a specific patient
  Future<List<MessageModel>> getMessages() async {
    try {
      final patientId = await getPatientId();
      final providerId = await getAssignedProviderId();
      final response = await http.get(
        Uri.parse('$baseUrl/messages/?user_id=$patientId&other_id=$providerId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MessageModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching messages: $e');
      return [];
    }
  }

  // Send message
  Future<bool> sendMessage(String text) async {
    try {
      final patientId = await getPatientId();
      final providerId = await getAssignedProviderId();
      final response = await http.post(
        Uri.parse('$baseUrl/messages/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': patientId,
          'receiver_id': providerId,
          'content': text,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  // Update typing status
  Future<void> updateTypingStatus(bool isTyping) async {
    try {
      final patientId = await getPatientId();
      final providerId = await getAssignedProviderId();
      await http.post(
        Uri.parse('$baseUrl/typing/update/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': patientId,
          'chat_partner_id': providerId,
          'is_typing': isTyping,
        }),
      );
    } catch (e) {
      print('❌ Error updating typing status: $e');
    }
  }

  // Get typing status
  Future<bool> getTypingStatus() async {
    try {
      final patientId = await getPatientId();
      final providerId = await getAssignedProviderId();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/typing/status/?user_id=$patientId&partner_id=$providerId',
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
  
  // Fetch appointments for the patient
  Future<List<AppointmentModel>> getAppointments() async {
    try {
      final patientId = await getPatientId();
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/?patient_id=$patientId'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded['results'] is List) {
          data = decoded['results'];
        } else {
          return [];
        }
        return data.map((json) => AppointmentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching appointments: $e');
      return [];
    }
  }

  /// Returns null on success, or an error string on failure.
  /// 'conflict' is returned when the time slot is already booked.
  Future<String?> createAppointment({
    required String patientId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String reason = 'Patient requested',
  }) async {
    try {
      final providerId = await getAssignedProviderId();
      final response = await http.post(
        Uri.parse('$baseUrl/appointments/create/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_id': patientId,
          'provider_id': providerId,
          'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
          'scheduled_time': scheduledTime,
          'reason': reason,
          'initiated_by': 'PATIENT',
        }),
      );

      if (response.statusCode == 201) {
        print('✅ Appointment created successfully');
        return null;
      }
      if (response.statusCode == 409) {
        return 'conflict';
      }
      print('❌ Failed to create appointment: ${response.statusCode}');
      return 'Failed to book appointment (${response.statusCode})';
    } catch (e) {
      print('❌ Error creating appointment: $e');
      return 'Network error. Please try again.';
    }
  }

  /// Returns the list of already-booked HH:MM time strings for a provider on a date.
  Future<List<String>> getBookedSlots(String providerId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/booked-slots/?provider_id=$providerId&date=$dateStr'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
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

  /// Change the patient's password.
  /// Returns null on success or an error message string on failure.
  Future<String?> changePassword(String patientId, String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patient/$patientId/change-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('✅ Password changed for $patientId');
        return null; // success
      }
      final data = jsonDecode(response.body);
      return data['error'] as String? ?? 'Failed to change password';
    } catch (e) {
      print('❌ Error changing password: $e');
      return 'Network error. Please try again.';
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/?user_id=$patientId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data is List ? data : (data['results'] ?? []);
        return items.cast<Map<String, dynamic>>();
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
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
