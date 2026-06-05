import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/services/api_service.dart';

void main() async {
  DashboardApiService.currentProviderId = 'DR001';
  final api = DashboardApiService();
  try {
    final patients = await api.getPatients();
    print('Success: ${patients.length} patients parsed.');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
