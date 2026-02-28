import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/checkin_model.dart';

class ApiService {
  // Change this to your computer's IP address when testing on real device
  // For emulator, use 10.0.2.2
  // For localhost testing, use 127.0.0.1
  static const String baseUrl = 'http://192.168.100.18:8000/api';

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

  // Upload check-in to Django API
  Future<bool> uploadCheckin(CheckinModel checkin, String patientId) async {
    try {
      final condition = Hive.box('settings').get('condition', defaultValue: 'Unknown');
      
      final requestBody = {
        'patient_id': patientId,
        'condition': condition,
        'date': checkin.date.toIso8601String(),
        'answers': checkin.answers,
        'risk_level': checkin.riskLevel,
        'risk_color': checkin.riskColor,
      };
      
      print('📤 ATTEMPTING TO UPLOAD TO: $baseUrl/checkin/submit/');
      print('📦 Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/checkin/submit/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

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
      print('❌ Error uploading check-in: $e');
      return false;
    }
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
}