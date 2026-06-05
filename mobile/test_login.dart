import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://health-tracker-system-production.up.railway.app/api/auth/patient-login/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'patient_id': 'PT001', 'password': 'test123'}),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
