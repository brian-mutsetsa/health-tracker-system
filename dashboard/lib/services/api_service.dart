import 'dart:convert';
import 'package:http/http.dart' as http;

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
      patientId: json['patient_id'],
      condition: json['condition'],
      lastCheckin: json['last_checkin'] != null 
          ? DateTime.parse(json['last_checkin']) 
          : null,
      lastRiskLevel: json['last_risk_level'],
      lastRiskColor: json['last_risk_color'],
      totalCheckins: json['total_checkins'] ?? 0,
    );
  }
}

class DashboardApiService {
  // CHANGE THIS to your computer's IP address (same as mobile app)
  static const String baseUrl = 'http://192.168.100.18:8000/api';

  Future<List<Patient>> getPatients() async {
    try {
      print('📤 Fetching patients from: $baseUrl/patients/');
      
      final response = await http.get(
        Uri.parse('$baseUrl/patients/'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📨 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        print('✅ Received ${data.length} patients');
        
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
      return allPatients.where((p) => 
        p.lastRiskLevel == 'RED' || p.lastRiskLevel == 'ORANGE'
      ).toList();
    } catch (e) {
      print('❌ Error fetching high risk patients: $e');
      return [];
    }
  }

  Future<Map<String, int>> getStats() async {
    try {
      List<Patient> patients = await getPatients();
      
      int totalPatients = patients.length;
      int highRisk = patients.where((p) => 
        p.lastRiskLevel == 'RED' || p.lastRiskLevel == 'ORANGE'
      ).length;
      int totalCheckins = patients.fold(0, (sum, p) => sum + p.totalCheckins);
      
      return {
        'total_patients': totalPatients,
        'high_risk': highRisk,
        'total_checkins': totalCheckins,
      };
    } catch (e) {
      print('❌ Error fetching stats: $e');
      return {
        'total_patients': 0,
        'high_risk': 0,
        'total_checkins': 0,
      };
    }
  }
}