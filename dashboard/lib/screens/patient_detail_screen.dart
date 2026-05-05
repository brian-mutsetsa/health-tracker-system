import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = DashboardApiService();
  late TabController _tabController;

  Patient? _fullPatient;
  List<ClinicalVisit> _clinicalVisits = [];
  List<dynamic> _checkins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final patientId = widget.patient.patientId;
    final results = await Future.wait([
      _apiService.getPatientDetail(patientId),
      _apiService.getClinicalVisits(patientId),
      _apiService.getPatientCheckinsRaw(patientId),
    ]);
    if (mounted) {
      setState(() {
        _fullPatient = (results[0] as Patient?) ?? widget.patient;
        _clinicalVisits = results[1] as List<ClinicalVisit>;
        _checkins = results[2] as List<dynamic>;
        _loading = false;
      });
    }
  }

  Color _riskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'RED':
        return Colors.red;
      case 'ORANGE':
        return Colors.orange;
      case 'YELLOW':
        return Colors.amber;
      case 'GREEN':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _riskBg(String? level) {
    switch (level?.toUpperCase()) {
      case 'RED':
        return Colors.red.shade50;
      case 'ORANGE':
        return Colors.orange.shade50;
      case 'YELLOW':
        return Colors.amber.shade50;
      case 'GREEN':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _fullPatient ?? widget.patient;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              'ID: ${p.patientId}  |  ${p.condition}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
            Tab(icon: Icon(Icons.monitor_heart_outlined), text: 'Check-ins'),
            Tab(icon: Icon(Icons.local_hospital_outlined), text: 'Clinical'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(p),
                _buildCheckinsTab(),
                _buildClinicalTab(p),
              ],
            ),
    );
  }

  // ─── Profile Tab ────────────────────────────────────────────────────────────

  Widget _buildProfileTab(Patient p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab guide card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightMint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppTheme.primaryTeal),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Record Guide',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.primaryTeal),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Profile  -  Demographics, contact details, baseline vitals and medical history.\n'
                        'Check-ins  -  Daily health logs submitted by the patient (BP, glucose, risk score).\n'
                        'Clinical  -  Doctor visit records. Use the Add Visit button to log an in-person consult.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textLight, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Risk banner
          if (p.lastRiskLevel != null)
            _riskBanner(p.lastRiskLevel!, p.lastCheckin),
          const SizedBox(height: 16),

          // Personal info
          _sectionCard('Personal Information', Icons.person_outline, [
            _infoRow('Full Name', '${p.name} ${p.surname}'.trim()),
            _infoRow('Patient ID', p.patientId),
            _infoRow('Date of Birth', p.dateOfBirth ?? 'N/A'),
            _infoRow('Age', p.age != null ? '${p.age} years' : 'N/A'),
            _infoRow('Gender', _genderLabel(p.gender)),
            _infoRow('National ID', p.idNumber?.isNotEmpty == true ? p.idNumber! : 'N/A'),
            _infoRow('Phone', p.phoneNumber?.isNotEmpty == true ? p.phoneNumber! : 'N/A'),
          ]),
          const SizedBox(height: 12),

          // Location
          _sectionCard('Location', Icons.location_on_outlined, [
            _infoRow('District', p.district?.isNotEmpty == true ? p.district! : 'N/A'),
            _infoRow('Home Address', p.homeAddress?.isNotEmpty == true ? p.homeAddress! : 'N/A'),
          ]),
          const SizedBox(height: 12),

          // Emergency contact
          _sectionCard('Emergency Contact', Icons.emergency_outlined, [
            _infoRow('Name', p.emergencyContactName?.isNotEmpty == true ? p.emergencyContactName! : 'N/A'),
            _infoRow('Phone', p.emergencyContactPhone?.isNotEmpty == true ? p.emergencyContactPhone! : 'N/A'),
            _infoRow('Relation', p.emergencyContactRelation?.isNotEmpty == true ? p.emergencyContactRelation! : 'N/A'),
          ]),
          const SizedBox(height: 12),

          // Medical info
          _sectionCard('Medical Information', Icons.medical_information_outlined, [
            _infoRow('Condition', p.condition),
            _infoRow('Status', p.status),
            _infoRow('Baseline BP',
                p.bpSystolic != null ? '${p.bpSystolic}/${p.bpDiastolic} mmHg' : 'N/A'),
            _infoRow('Baseline Glucose',
                p.bloodGlucose != null ? '${p.bloodGlucose} mg/dL' : 'N/A'),
            _infoRow('Weight', p.weightKg != null ? '${p.weightKg} kg' : 'N/A'),
            _infoRow('Medical History',
                p.medicalHistory?.isNotEmpty == true ? p.medicalHistory! : 'N/A'),
            _infoRow('Medications',
                p.medications?.isNotEmpty == true ? p.medications! : 'N/A'),
            _infoRow('Allergies',
                p.allergies?.isNotEmpty == true ? p.allergies! : 'N/A'),
          ]),
        ],
      ),
    );
  }

  Widget _riskBanner(String level, DateTime? lastCheckin) {
    final color = _riskColor(level);
    final bg = _riskBg(level);
    final label = level == 'RED'
        ? 'High Risk - Action Required'
        : level == 'ORANGE'
            ? 'Elevated Risk - Monitor Closely'
            : level == 'YELLOW'
                ? 'Moderate Risk - Attention Needed'
                : 'Low Risk - Stable';
    final since = lastCheckin != null
        ? 'Last check-in: ${_fmtDate(lastCheckin)}'
        : 'No check-ins yet';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.monitor_heart, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text(since,
                    style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, List<Widget> rows) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: AppTheme.primaryTeal),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textDark)),
            ]),
            const Divider(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _genderLabel(String? g) {
    switch (g) {
      case 'M':
        return 'Male';
      case 'F':
        return 'Female';
      case 'O':
        return 'Other';
      default:
        return 'N/A';
    }
  }

  // ─── Check-ins Tab ──────────────────────────────────────────────────────────

  Widget _buildCheckinsTab() {
    if (_checkins.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.monitor_heart_outlined, size: 64, color: AppTheme.textLight),
          SizedBox(height: 12),
          Text('No check-ins recorded yet',
              style: TextStyle(color: AppTheme.textLight)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _checkins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = _checkins[index];
        final level = (c['risk_level'] as String?) ?? 'GREEN';
        final color = _riskColor(level);
        final bg = _riskBg(level);
        final date = c['date'] != null ? DateTime.parse(c['date']).toLocal() : null;
        final bp = c['blood_pressure_systolic'] != null
            ? '${c['blood_pressure_systolic']}/${c['blood_pressure_diastolic']} mmHg'
            : null;
        final glucose = c['blood_glucose_reading'] != null
            ? '${c['blood_glucose_reading']} mg/dL'
            : null;

        return Card(
          elevation: 0,
          color: bg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: color.withOpacity(0.3))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 50,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            level,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                          if (date != null)
                            Text(_fmtDate(date),
                                style: const TextStyle(
                                    color: AppTheme.textLight, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (bp != null) ...[
                            const Icon(Icons.favorite_border,
                                size: 12, color: AppTheme.textLight),
                            const SizedBox(width: 4),
                            Text(bp,
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textLight)),
                            const SizedBox(width: 12),
                          ],
                          if (glucose != null) ...[
                            const Icon(Icons.water_drop_outlined,
                                size: 12, color: AppTheme.textLight),
                            const SizedBox(width: 4),
                            Text(glucose,
                                style: const TextStyle(
                                    fontSize: 12, color: AppTheme.textLight)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Clinical Visits Tab ────────────────────────────────────────────────────

  Widget _buildClinicalTab(Patient p) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_clinicalVisits.length} visit record(s)',
                  style: const TextStyle(
                      color: AppTheme.textLight, fontSize: 13)),
              FilledButton.icon(
                onPressed: () => _showAddVisitDialog(p),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Visit'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _clinicalVisits.isEmpty
              ? const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.local_hospital_outlined,
                        size: 64, color: AppTheme.textLight),
                    SizedBox(height: 12),
                    Text('No clinical visits recorded yet',
                        style: TextStyle(color: AppTheme.textLight)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _clinicalVisits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _visitCard(_clinicalVisits[index]),
                ),
        ),
      ],
    );
  }

  Widget _visitCard(ClinicalVisit v) {
    final vitals = <String>[];
    if (v.systolicBp != null)
      vitals.add('BP: ${v.systolicBp}/${v.diastolicBp} mmHg');
    if (v.heartRate != null) vitals.add('HR: ${v.heartRate} bpm');
    if (v.bloodGlucose != null) vitals.add('Glucose: ${v.bloodGlucose} mg/dL');
    if (v.weightKg != null) vitals.add('Weight: ${v.weightKg} kg');
    if (v.temperature != null) vitals.add('Temp: ${v.temperature} C');
    if (v.oxygenSaturation != null) vitals.add('SpO2: ${v.oxygenSaturation}%');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmtDate(v.visitDate),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                      fontSize: 14)),
              Text('Recorded by ${v.hcwId}',
                  style: const TextStyle(
                      color: AppTheme.textLight, fontSize: 12)),
            ],
          ),
          if (vitals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: vitals
                  .map((t) => Chip(
                        label: Text(t,
                            style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppTheme.lightMint,
                      ))
                  .toList(),
            ),
          ],
          if (v.medicationIntake.isNotEmpty) ...[
            const SizedBox(height: 8),
            _visitRow(Icons.medication_outlined, 'Medications', v.medicationIntake),
          ],
          if (v.comments.isNotEmpty) ...[
            const SizedBox(height: 4),
            _visitRow(Icons.comment_outlined, 'Comments', v.comments),
          ],
          if (v.changesMade.isNotEmpty) ...[
            const SizedBox(height: 4),
            _visitRow(Icons.edit_note, 'Changes Made', v.changesMade),
          ],
        ]),
      ),
    );
  }

  Widget _visitRow(IconData icon, String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: AppTheme.textLight),
      const SizedBox(width: 6),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
            children: [
              TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    ]);
  }

  // ─── Add Clinical Visit Dialog ───────────────────────────────────────────────

  void _showAddVisitDialog(Patient p) {
    final _sbpC = TextEditingController();
    final _dbpC = TextEditingController();
    final _hrC = TextEditingController();
    final _glucC = TextEditingController();
    final _wtC = TextEditingController();
    final _tempC = TextEditingController();
    final _spo2C = TextEditingController();
    final _medC = TextEditingController();
    final _commentC = TextEditingController();
    final _changesC = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Clinical Visit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vital Signs',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTeal,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _visitField(_sbpC, 'Systolic BP (mmHg)',
                            TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _visitField(_dbpC, 'Diastolic BP (mmHg)',
                            TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _visitField(
                            _hrC, 'Heart Rate (bpm)', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _visitField(_glucC, 'Blood Glucose (mg/dL)',
                            TextInputType.number)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _visitField(
                            _wtC, 'Weight (kg)', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _visitField(
                            _tempC, 'Temperature (C)', TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _visitField(
                            _spo2C, 'SpO2 (%)', TextInputType.number)),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Clinical Notes',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTeal,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  _visitField(_medC, 'Medication Intake', TextInputType.text,
                      maxLines: 2),
                  const SizedBox(height: 8),
                  _visitField(_commentC, 'Comments', TextInputType.text,
                      maxLines: 2),
                  const SizedBox(height: 8),
                  _visitField(_changesC, 'Changes Made', TextInputType.text,
                      maxLines: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setS(() => saving = true);
                      final hcwId =
                          DashboardApiService.currentProviderId ?? '';
                      final visitData = <String, dynamic>{
                        'hcw_id': hcwId,
                        'visit_date': DateTime.now().toIso8601String(),
                        'comments': _commentC.text.trim(),
                        'medication_intake': _medC.text.trim(),
                        'changes_made': _changesC.text.trim(),
                      };
                      _addIfNotEmpty(visitData, 'systolic_bp', _sbpC.text, int.tryParse);
                      _addIfNotEmpty(visitData, 'diastolic_bp', _dbpC.text, int.tryParse);
                      _addIfNotEmpty(visitData, 'heart_rate', _hrC.text, int.tryParse);
                      _addIfNotEmpty(visitData, 'blood_glucose', _glucC.text, int.tryParse);
                      _addIfNotEmpty(visitData, 'weight_kg', _wtC.text, double.tryParse);
                      _addIfNotEmpty(visitData, 'temperature', _tempC.text, double.tryParse);
                      _addIfNotEmpty(visitData, 'oxygen_saturation', _spo2C.text, double.tryParse);

                      final err = await _apiService.addClinicalVisit(
                          p.patientId, visitData);
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      if (err == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Clinical visit recorded'),
                              backgroundColor: AppTheme.primaryTeal),
                        );
                        _loadData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: $err'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Visit'),
            ),
          ],
        ),
      ),
    );
  }

  void _addIfNotEmpty(Map<String, dynamic> map, String key, String raw,
      dynamic Function(String) parser) {
    if (raw.trim().isNotEmpty) {
      final v = parser(raw.trim());
      if (v != null) map[key] = v;
    }
  }

  Widget _visitField(TextEditingController c, String label, TextInputType kt,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: kt,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 12, color: AppTheme.textLight),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}
