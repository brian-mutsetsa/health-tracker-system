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
          tabs: [
            const Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
            const Tab(
              icon: Icon(Icons.monitor_heart_outlined),
              text: 'Check-ins',
            ),
            Tab(
              text: 'Clinical',
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.local_hospital_outlined),
                  if (_clinicalVisits.any((v) => !v.isCompleted))
                    Positioned(
                      top: -3,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${_clinicalVisits.where((v) => !v.isCompleted).length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppTheme.primaryTeal,
                ),
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
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Profile  -  Demographics, contact details, baseline vitals and medical history.\n'
                        'Check-ins  -  Daily health logs submitted by the patient (BP, glucose, risk score).\n'
                        'Clinical  -  Doctor visit records. Use the Add Visit button to log an in-person consult.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          height: 1.5,
                        ),
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
            _infoRow(
              'National ID',
              p.idNumber?.isNotEmpty == true ? p.idNumber! : 'N/A',
            ),
            _infoRow(
              'Phone',
              p.phoneNumber?.isNotEmpty == true ? p.phoneNumber! : 'N/A',
            ),
          ]),
          const SizedBox(height: 12),

          // Location
          _sectionCard('Location', Icons.location_on_outlined, [
            _infoRow(
              'District',
              p.district?.isNotEmpty == true ? p.district! : 'N/A',
            ),
            _infoRow(
              'Home Address',
              p.homeAddress?.isNotEmpty == true ? p.homeAddress! : 'N/A',
            ),
          ]),
          const SizedBox(height: 12),

          // Emergency contact
          _sectionCard('Emergency Contact', Icons.emergency_outlined, [
            _infoRow(
              'Name',
              p.emergencyContactName?.isNotEmpty == true
                  ? p.emergencyContactName!
                  : 'N/A',
            ),
            _infoRow(
              'Phone',
              p.emergencyContactPhone?.isNotEmpty == true
                  ? p.emergencyContactPhone!
                  : 'N/A',
            ),
            _infoRow(
              'Relation',
              p.emergencyContactRelation?.isNotEmpty == true
                  ? p.emergencyContactRelation!
                  : 'N/A',
            ),
          ]),
          const SizedBox(height: 12),

          // Medical info
          _sectionCard(
            'Medical Information',
            Icons.medical_information_outlined,
            [
              _infoRow('Condition', p.condition),
              _infoRow('Status', p.status),
              _infoRow(
                'Baseline BP',
                p.bpSystolic != null
                    ? '${p.bpSystolic}/${p.bpDiastolic} mmHg'
                    : 'N/A',
              ),
              _infoRow(
                'Baseline Glucose',
                p.bloodGlucose != null ? '${p.bloodGlucose} mg/dL' : 'N/A',
              ),
              _infoRow(
                'Weight',
                p.weightKg != null ? '${p.weightKg} kg' : 'N/A',
              ),
              _infoRow(
                'Medical History',
                p.medicalHistory?.isNotEmpty == true
                    ? p.medicalHistory!
                    : 'N/A',
              ),
              _infoRow(
                'Medications',
                p.medications?.isNotEmpty == true ? p.medications! : 'N/A',
              ),
              _infoRow(
                'Allergies',
                p.allergies?.isNotEmpty == true ? p.allergies! : 'N/A',
              ),
            ],
          ),
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
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  since,
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
                ),
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
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
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
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  static const Map<String, String> _qLabels = {
    'q1': 'Headaches',
    'q2': 'Dizziness / lightheadedness',
    'q3': 'Blurred / disturbed vision',
    'q4': 'Chest discomfort or pressure',
    'q5': 'Shortness of breath',
    'q6': 'Unusual fatigue or weakness',
    'q7': 'Nosebleeds',
    'q8': 'Palpitations (rapid/irregular heartbeat)',
    'q9': 'Took prescribed medication',
    'q10': 'High-salt food intake',
    'q11': 'High stress levels',
    'q12': 'Swelling in limbs or face',
  };

  static const List<String> _severity = ['None', 'Mild', 'Moderate', 'Severe'];

  String _answerLabel(String qId, int value) {
    if (qId == 'q9') {
      const opts = [
        'Yes fully',
        'Missed once',
        'Missed more than once',
        'Did not take',
      ];
      return value >= 0 && value < opts.length ? opts[value] : '$value';
    }
    if (qId == 'q10') {
      const opts = ['None', 'Small amount', 'Moderate', 'High intake'];
      return value >= 0 && value < opts.length ? opts[value] : '$value';
    }
    return value >= 0 && value < _severity.length ? _severity[value] : '$value';
  }

  Widget _buildCheckinsTab() {
    if (_checkins.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.monitor_heart_outlined,
              size: 64,
              color: AppTheme.textLight,
            ),
            SizedBox(height: 12),
            Text(
              'No check-ins recorded yet',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ],
        ),
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
        final date = c['date'] != null
            ? DateTime.parse(c['date']).toLocal()
            : null;
        final condition = (c['condition'] as String?) ?? '';
        final bp = c['blood_pressure_systolic'] != null
            ? '${c['blood_pressure_systolic']}/${c['blood_pressure_diastolic']} mmHg'
            : null;
        final glucose = c['blood_glucose_reading'] != null
            ? '${c['blood_glucose_reading']} mg/dL'
            : null;
        final answers = (c['answers'] as Map?)?.cast<String, dynamic>() ?? {};
        final sortedAnswers = answers.entries.toList()
          ..sort((a, b) {
            final ai = int.tryParse(a.key.replaceAll('q', '')) ?? 99;
            final bi = int.tryParse(b.key.replaceAll('q', '')) ?? 99;
            return ai.compareTo(bi);
          });

        return Card(
          elevation: 0,
          color: bg,
          clipBehavior: Clip.hardEdge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: EdgeInsets.zero,
            backgroundColor: bg,
            collapsedBackgroundColor: bg,
            shape: const Border(),
            collapsedShape: const Border(),
            // ── Collapsed header ────────────────────────────────────────
            leading: Container(
              width: 8,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Text(
                    level,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (condition.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    condition,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ],
            ),
            subtitle: date != null
                ? Text(
                    _fmtDate(date),
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 12,
                    ),
                  )
                : null,
            // ── Expanded body ────────────────────────────────────────────
            children: [
              const Divider(height: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vitals row
                    if (bp != null || glucose != null) ...[
                      Text(
                        'Vitals',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (bp != null) ...[
                            const Icon(
                              Icons.favorite_border,
                              size: 13,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bp,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (glucose != null) ...[
                            const Icon(
                              Icons.water_drop_outlined,
                              size: 13,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              glucose,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (answers.isNotEmpty) const SizedBox(height: 12),
                    ],
                    // Answers
                    if (answers.isNotEmpty) ...[
                      Text(
                        'Symptom Responses',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...sortedAnswers.map((e) {
                        final label = _qLabels[e.key] ?? e.key;
                        final val = (e.value as num?)?.toInt() ?? 0;
                        final answer = _answerLabel(e.key, val);
                        final isNeutral = val == 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isNeutral
                                      ? Colors.grey.shade100
                                      : color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  answer,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isNeutral
                                        ? AppTheme.textLight
                                        : color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Clinical Visits Tab ────────────────────────────────────────────────────

  Widget _buildClinicalTab(Patient p) {
    final drafts = _clinicalVisits.where((v) => !v.isCompleted).toList();
    final completed = _clinicalVisits.where((v) => v.isCompleted).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_clinicalVisits.length} visit record(s)',
                style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
              ),
              FilledButton.icon(
                onPressed: () => _showAddVisitDialog(p),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Visit'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _clinicalVisits.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 64,
                        color: AppTheme.textLight,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No clinical visits recorded yet',
                        style: TextStyle(color: AppTheme.textLight),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Pending draft visits (auto-created from appointments) ──
                    if (drafts.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.pending_actions,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pending Visit Records (${drafts.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...drafts.map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _draftVisitCard(v, p),
                        ),
                      ),
                      const Divider(height: 24),
                    ],
                    // ── Completed visit records ──
                    if (completed.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Completed Visits (${completed.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...completed.map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _visitCard(v),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  // ─── Draft visit card (auto-created from appointment) ───────────────────────
  Widget _draftVisitCard(ClinicalVisit v, Patient p) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.orange, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'DRAFT – Awaiting Completion',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _fmtDate(v.visitDate),
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (v.appointmentReason != null && v.appointmentReason!.isNotEmpty)
              _visitRow(
                Icons.event_note_outlined,
                'Appointment Reason',
                v.appointmentReason!,
              ),
            const SizedBox(height: 4),
            _visitRow(Icons.person_outline, 'Provider', v.hcwId),
            // ── Reference summary from last check-in ──
            if (v.previousDataSnapshot != null) ...[
              const SizedBox(height: 10),
              _buildReferenceChips(v.previousDataSnapshot!),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showFillVisitDialog(v, p),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Fill In & Complete Visit'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact chips showing the reference vitals from the previous check-in.
  Widget _buildReferenceChips(Map<String, dynamic> snapshot) {
    final checkin = snapshot['last_checkin'] as Map<String, dynamic>?;
    final baseline = snapshot['patient_baseline'] as Map<String, dynamic>?;

    if (checkin == null && baseline == null) return const SizedBox.shrink();

    final items = <String>[];
    if (checkin != null) {
      if (checkin['blood_pressure_systolic'] != null)
        items.add(
          'Last BP: ${checkin['blood_pressure_systolic']}/${checkin['blood_pressure_diastolic']}',
        );
      if (checkin['blood_glucose_reading'] != null)
        items.add('Last Glucose: ${checkin['blood_glucose_reading']} mg/dL');
      items.add('Last Risk: ${checkin['risk_level'] ?? '-'}');
    } else if (baseline != null) {
      if (baseline['blood_pressure_systolic'] != null)
        items.add(
          'Baseline BP: ${baseline['blood_pressure_systolic']}/${baseline['blood_pressure_diastolic']}',
        );
      if (baseline['blood_glucose_baseline'] != null)
        items.add(
          'Baseline Glucose: ${baseline['blood_glucose_baseline']} mg/dL',
        );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reference (last check-in)',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: items
              .map(
                (t) => Chip(
                  label: Text(t, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.orange.shade50,
                  side: BorderSide(color: Colors.orange.shade200),
                ),
              )
              .toList(),
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
    if (v.temperature != null) vitals.add('Temp: ${v.temperature} °C');
    if (v.oxygenSaturation != null) vitals.add('SpO2: ${v.oxygenSaturation}%');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmtDate(v.visitDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: [
                    if (v.appointmentId != null)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightMint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Appointment',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      'by ${v.hcwId}',
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (v.appointmentReason != null &&
                v.appointmentReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _visitRow(
                Icons.event_note_outlined,
                'Reason',
                v.appointmentReason!,
              ),
            ],
            if (vitals.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: vitals
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppTheme.lightMint,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (v.medicationIntake.isNotEmpty) ...[
              const SizedBox(height: 8),
              _visitRow(
                Icons.medication_outlined,
                'Medications',
                v.medicationIntake,
              ),
            ],
            if (v.comments.isNotEmpty) ...[
              const SizedBox(height: 4),
              _visitRow(Icons.comment_outlined, 'Comments', v.comments),
            ],
            if (v.changesMade.isNotEmpty) ...[
              const SizedBox(height: 4),
              _visitRow(Icons.edit_note, 'Changes Made', v.changesMade),
            ],
            // ── Previous reference comparison (collapsed) ──
            if (v.previousDataSnapshot != null &&
                v.previousDataSnapshot!['last_checkin'] != null) ...[
              const SizedBox(height: 8),
              _buildReferenceChips(v.previousDataSnapshot!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _visitRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.textLight),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Fill-in Draft Visit Dialog ─────────────────────────────────────────────

  void _showFillVisitDialog(ClinicalVisit v, Patient p) {
    // Pre-fill controllers from the existing draft values
    final sbpC = TextEditingController(text: v.systolicBp?.toString() ?? '');
    final dbpC = TextEditingController(text: v.diastolicBp?.toString() ?? '');
    final hrC = TextEditingController(text: v.heartRate?.toString() ?? '');
    final glucC = TextEditingController(text: v.bloodGlucose?.toString() ?? '');
    final wtC = TextEditingController(text: v.weightKg?.toString() ?? '');
    final tempC = TextEditingController(text: v.temperature?.toString() ?? '');
    final spo2C = TextEditingController(
      text: v.oxygenSaturation?.toString() ?? '',
    );
    final medC = TextEditingController(text: v.medicationIntake);
    final commentC = TextEditingController(text: v.comments);
    final changesC = TextEditingController(text: v.changesMade);
    bool saving = false;

    // Build reference rows from previousDataSnapshot
    final snap = v.previousDataSnapshot;
    final checkin = snap?['last_checkin'] as Map<String, dynamic>?;
    final baseline = snap?['patient_baseline'] as Map<String, dynamic>?;
    final lastAppt = snap?['last_appointment'] as Map<String, dynamic>?;

    Widget refRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_note,
                        color: Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Complete Visit Record',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            if (v.appointmentReason != null &&
                                v.appointmentReason!.isNotEmpty)
                              Text(
                                'Reason: ${v.appointmentReason}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // ── Two-column body ─────────────────────────────────────
                  LayoutBuilder(
                    builder: (_, box) {
                      final wide = box.maxWidth > 500;
                      final referencePanel = Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Previous Reference',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (checkin != null) ...[
                              refRow(
                                'Last check-in:',
                                checkin['date']?.toString() ?? '—',
                              ),
                              if (checkin['systolic_bp'] != null)
                                refRow(
                                  'BP:',
                                  '${checkin['systolic_bp']}/${checkin['diastolic_bp']} mmHg',
                                ),
                              if (checkin['blood_glucose'] != null)
                                refRow(
                                  'Glucose:',
                                  '${checkin['blood_glucose']} mg/dL',
                                ),
                              if (checkin['risk_level'] != null)
                                refRow(
                                  'Risk level:',
                                  checkin['risk_level'].toString(),
                                ),
                            ] else if (baseline != null) ...[
                              const Text(
                                'No check-in yet. Showing baseline:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (baseline['systolic_bp'] != null)
                                refRow(
                                  'Baseline BP:',
                                  '${baseline['systolic_bp']}/${baseline['diastolic_bp']} mmHg',
                                ),
                              if (baseline['blood_glucose'] != null)
                                refRow(
                                  'Baseline glucose:',
                                  '${baseline['blood_glucose']} mg/dL',
                                ),
                            ] else
                              const Text(
                                'No previous data available.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            if (lastAppt != null &&
                                lastAppt['reason'] != null) ...[
                              const Divider(height: 12),
                              refRow(
                                'Last appt:',
                                lastAppt['reason'].toString(),
                              ),
                              if (lastAppt['comments'] != null &&
                                  (lastAppt['comments'] as String).isNotEmpty)
                                refRow(
                                  'Notes:',
                                  lastAppt['comments'].toString(),
                                ),
                            ],
                          ],
                        ),
                      );

                      final formPanel = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Vitals',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryTeal,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _visitField(
                                  sbpC,
                                  'Systolic BP',
                                  TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _visitField(
                                  dbpC,
                                  'Diastolic BP',
                                  TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _visitField(
                                  hrC,
                                  'Heart Rate (bpm)',
                                  TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _visitField(
                                  glucC,
                                  'Glucose (mg/dL)',
                                  TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _visitField(
                                  wtC,
                                  'Weight (kg)',
                                  TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _visitField(
                                  tempC,
                                  'Temp (°C)',
                                  TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _visitField(
                                  spo2C,
                                  'SpO2 (%)',
                                  TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Clinical Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryTeal,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _visitField(
                            medC,
                            'Medication Intake',
                            TextInputType.text,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          _visitField(
                            commentC,
                            'Comments',
                            TextInputType.text,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 8),
                          _visitField(
                            changesC,
                            'Changes Made',
                            TextInputType.text,
                            maxLines: 2,
                          ),
                        ],
                      );

                      return SingleChildScrollView(
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 200, child: referencePanel),
                                  const SizedBox(width: 16),
                                  Expanded(child: formPanel),
                                ],
                              )
                            : Column(
                                children: [
                                  referencePanel,
                                  const SizedBox(height: 16),
                                  formPanel,
                                ],
                              ),
                      );
                    },
                  ),

                  // ── Actions ─────────────────────────────────────────────
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                setS(() => saving = true);
                                final data = <String, dynamic>{
                                  'is_completed': true,
                                  'comments': commentC.text.trim(),
                                  'medication_intake': medC.text.trim(),
                                  'changes_made': changesC.text.trim(),
                                };
                                _addIfNotEmpty(
                                  data,
                                  'systolic_bp',
                                  sbpC.text,
                                  int.tryParse,
                                );
                                _addIfNotEmpty(
                                  data,
                                  'diastolic_bp',
                                  dbpC.text,
                                  int.tryParse,
                                );
                                _addIfNotEmpty(
                                  data,
                                  'heart_rate',
                                  hrC.text,
                                  int.tryParse,
                                );
                                _addIfNotEmpty(
                                  data,
                                  'blood_glucose',
                                  glucC.text,
                                  int.tryParse,
                                );
                                _addIfNotEmpty(
                                  data,
                                  'weight_kg',
                                  wtC.text,
                                  double.tryParse,
                                );
                                _addIfNotEmpty(
                                  data,
                                  'temperature',
                                  tempC.text,
                                  double.tryParse,
                                );
                                _addIfNotEmpty(
                                  data,
                                  'oxygen_saturation',
                                  spo2C.text,
                                  double.tryParse,
                                );

                                final err = await _apiService
                                    .updateClinicalVisit(
                                      p.patientId,
                                      v.id,
                                      data,
                                    );
                                if (!mounted) return;
                                Navigator.pop(ctx);
                                if (err == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Visit completed'),
                                      backgroundColor: AppTheme.primaryTeal,
                                    ),
                                  );
                                  _loadData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $err'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  setS(() => saving = false);
                                }
                              },
                        icon: saving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Complete & Save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
          title: const Text(
            'Add Clinical Visit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vital Signs',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTeal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _visitField(
                          _sbpC,
                          'Systolic BP (mmHg)',
                          TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _visitField(
                          _dbpC,
                          'Diastolic BP (mmHg)',
                          TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _visitField(
                          _hrC,
                          'Heart Rate (bpm)',
                          TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _visitField(
                          _glucC,
                          'Blood Glucose (mg/dL)',
                          TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _visitField(
                          _wtC,
                          'Weight (kg)',
                          TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _visitField(
                          _tempC,
                          'Temperature (C)',
                          TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _visitField(
                          _spo2C,
                          'SpO2 (%)',
                          TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Clinical Notes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTeal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _visitField(
                    _medC,
                    'Medication Intake',
                    TextInputType.text,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  _visitField(
                    _commentC,
                    'Comments',
                    TextInputType.text,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  _visitField(
                    _changesC,
                    'Changes Made',
                    TextInputType.text,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setS(() => saving = true);
                      final hcwId = DashboardApiService.currentProviderId ?? '';
                      final visitData = <String, dynamic>{
                        'hcw_id': hcwId,
                        'visit_date': DateTime.now().toIso8601String(),
                        'comments': _commentC.text.trim(),
                        'medication_intake': _medC.text.trim(),
                        'changes_made': _changesC.text.trim(),
                      };
                      _addIfNotEmpty(
                        visitData,
                        'systolic_bp',
                        _sbpC.text,
                        int.tryParse,
                      );
                      _addIfNotEmpty(
                        visitData,
                        'diastolic_bp',
                        _dbpC.text,
                        int.tryParse,
                      );
                      _addIfNotEmpty(
                        visitData,
                        'heart_rate',
                        _hrC.text,
                        int.tryParse,
                      );
                      _addIfNotEmpty(
                        visitData,
                        'blood_glucose',
                        _glucC.text,
                        int.tryParse,
                      );
                      _addIfNotEmpty(
                        visitData,
                        'weight_kg',
                        _wtC.text,
                        double.tryParse,
                      );
                      _addIfNotEmpty(
                        visitData,
                        'temperature',
                        _tempC.text,
                        double.tryParse,
                      );
                      _addIfNotEmpty(
                        visitData,
                        'oxygen_saturation',
                        _spo2C.text,
                        double.tryParse,
                      );

                      final err = await _apiService.addClinicalVisit(
                        p.patientId,
                        visitData,
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      if (err == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clinical visit recorded'),
                            backgroundColor: AppTheme.primaryTeal,
                          ),
                        );
                        _loadData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $err'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
              ),
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Visit'),
            ),
          ],
        ),
      ),
    );
  }

  void _addIfNotEmpty(
    Map<String, dynamic> map,
    String key,
    String raw,
    dynamic Function(String) parser,
  ) {
    if (raw.trim().isNotEmpty) {
      final v = parser(raw.trim());
      if (v != null) map[key] = v;
    }
  }

  Widget _visitField(
    TextEditingController c,
    String label,
    TextInputType kt, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      keyboardType: kt,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
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
