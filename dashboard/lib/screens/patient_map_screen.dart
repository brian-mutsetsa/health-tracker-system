import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'patient_detail_screen.dart';

/// Map of Zimbabwe showing all patients as colour-coded pins by risk level.
/// Visible only when logged in as the super admin (provider_id == 'admin').
class PatientMapScreen extends StatefulWidget {
  final List<Patient> patients;
  const PatientMapScreen({super.key, required this.patients});

  @override
  State<PatientMapScreen> createState() => _PatientMapScreenState();
}

class _PatientMapScreenState extends State<PatientMapScreen> {
  // Zimbabwe district approximate centroids (lat, lng)
  static const Map<String, LatLng> _districtCoords = {
    // Harare Province
    'Harare': LatLng(-17.8292, 31.0522),
    'Epworth': LatLng(-17.8833, 31.1500),
    'Chitungwiza': LatLng(-18.0125, 31.0756),
    // Mashonaland East
    'Goromonzi': LatLng(-17.8500, 31.3500),
    'Marondera': LatLng(-18.1833, 31.5500),
    'Seke': LatLng(-17.9500, 31.1800),
    'Makoni': LatLng(-18.3500, 32.1000),
    // Mashonaland Central
    'Mazowe': LatLng(-17.5000, 30.9667),
    'Bindura': LatLng(-17.3000, 31.3333),
    'Zvimba': LatLng(-17.6500, 30.0833),
    // Mashonaland West
    'Hurungwe': LatLng(-16.4167, 29.9167),
    // Midlands
    'Gweru': LatLng(-19.4500, 29.8167),
    'Shurugwi': LatLng(-19.6667, 30.0000),
    'Chirumhanzu': LatLng(-19.5500, 30.1500),
    'Kwekwe': LatLng(-18.9281, 29.8147),
    // Manicaland
    'Mutare': LatLng(-18.9707, 32.6709),
    'Mutasa': LatLng(-18.7667, 32.7667),
    'Buhera': LatLng(-19.8333, 31.8333),
    // Masvingo
    'Masvingo': LatLng(-20.0651, 30.8277),
    'Gutu': LatLng(-20.6500, 31.1833),
    'Chiredzi': LatLng(-21.0500, 31.6667),
    // Matabeleland North
    'Hwange': LatLng(-18.3636, 26.4990),
    'Binga': LatLng(-17.6167, 27.3500),
    // Matabeleland South
    'Bulawayo': LatLng(-20.1500, 28.5833),
    'Umguza': LatLng(-19.9167, 28.7667),
    'Matobo': LatLng(-20.3667, 28.5167),
    'Insiza': LatLng(-20.5667, 29.0500),
    // Matebeleland / Other
    'Beitbridge': LatLng(-22.2167, 29.9833),
  };

  // Zimbabwe centroid fallback
  static const LatLng _zimbabweCenter = LatLng(-19.0154, 29.1549);

  String _filterRisk = 'ALL';

  Color _riskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'RED':    return Colors.red;
      case 'ORANGE': return Colors.orange;
      case 'YELLOW': return Colors.amber;
      case 'GREEN':  return Colors.green;
      default:       return Colors.grey;
    }
  }

  LatLng _coordsFor(Patient p) {
    final district = (p.district ?? '').trim();
    if (district.isEmpty) return _zimbabweCenter;
    // Exact match
    if (_districtCoords.containsKey(district)) return _districtCoords[district]!;
    // Partial match (e.g. "Harare CBD" -> "Harare")
    for (final entry in _districtCoords.entries) {
      if (district.toLowerCase().contains(entry.key.toLowerCase())) return entry.value;
    }
    return _zimbabweCenter;
  }

  List<Patient> get _filtered {
    if (_filterRisk == 'ALL') return widget.patients;
    return widget.patients.where((p) => p.lastRiskLevel == _filterRisk).toList();
  }

  @override
  Widget build(BuildContext context) {
    final patients = _filtered;
    final counts = {
      'RED': widget.patients.where((p) => p.lastRiskLevel == 'RED').length,
      'ORANGE': widget.patients.where((p) => p.lastRiskLevel == 'ORANGE').length,
      'YELLOW': widget.patients.where((p) => p.lastRiskLevel == 'YELLOW').length,
      'GREEN': widget.patients.where((p) => p.lastRiskLevel == 'GREEN').length,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + filter chips
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Patient Distribution Map',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 4),
              Text('${widget.patients.length} patients across Zimbabwe',
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 14)),
              const SizedBox(height: 16),
              // Risk filter chips
              Wrap(
                spacing: 8,
                children: [
                  _filterChip('ALL', 'All (${widget.patients.length})', Colors.blueGrey),
                  _filterChip('RED', 'High Risk (${counts['RED']})', Colors.red),
                  _filterChip('ORANGE', 'Elevated (${counts['ORANGE']})', Colors.orange),
                  _filterChip('YELLOW', 'Moderate (${counts['YELLOW']})', Colors.amber),
                  _filterChip('GREEN', 'Stable (${counts['GREEN']})', Colors.green),
                ],
              ),
            ],
          ),
        ),
        // Map
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-19.0154, 29.1549),
                  initialZoom: 6.2,
                  maxZoom: 14,
                  minZoom: 5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.healthtracker.dashboard',
                  ),
                  MarkerLayer(
                    markers: patients.map((p) {
                      final pos = _coordsFor(p);
                      final color = _riskColor(p.lastRiskLevel);
                      return Marker(
                        point: pos,
                        width: 36,
                        height: 36,
                        child: GestureDetector(
                          onTap: () => _showPatientPopup(context, p),
                          child: Tooltip(
                            message: '${p.name} (${p.patientId})\n${p.condition} - ${p.lastRiskLevel ?? 'GREEN'}',
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label, Color color) {
    final selected = _filterRisk == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filterRisk = value),
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(0.15),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : AppTheme.textLight,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(color: selected ? color : Colors.grey.shade300),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _showPatientPopup(BuildContext context, Patient p) {
    final color = _riskColor(p.lastRiskLevel);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(backgroundColor: color, child: const Icon(Icons.person, color: Colors.white, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                          Text('${p.patientId}  |  ${p.condition}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _popupRow('District', p.district ?? 'Unknown'),
                    _popupRow('Risk Level', p.lastRiskLevel ?? 'GREEN'),
                    _popupRow('Check-ins', '${p.totalCheckins}'),
                    if (p.lastCheckin != null)
                      _popupRow('Last Check-in', '${p.lastCheckin!.day}/${p.lastCheckin!.month}/${p.lastCheckin!.year}'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open Patient Record'),
                        style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => PatientDetailScreen(patient: p)));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _popupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
