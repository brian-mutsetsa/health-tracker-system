import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String providerName;
  const DashboardScreen({Key? key, required this.providerName})
    : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final DashboardApiService _apiService = DashboardApiService();

  List<Patient> _patients = [];
  bool _loading = true;
  Map<String, int> _stats = {
    'total_patients': 0,
    'high_risk': 0,
    'total_checkins': 0,
  };

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Poll the backend silently every 15 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadDataSilently();
    });
  }

  Future<void> _loadDataSilently() async {
    final patients = await _apiService.getPatients();
    final stats = await _apiService.getStats();

    if (mounted) {
      setState(() {
        _patients = patients;
        _stats = stats;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final patients = await _apiService.getPatients();
    final stats = await _apiService.getStats();

    setState(() {
      _patients = patients;
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          _buildSidebar(),

          // Main Content
          Expanded(
            child: Column(
              children: [
                _buildTopNav(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryTeal,
                          ),
                        )
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.mintGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monitor_heart,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'HealthTrack',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text(
              'MENU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
                letterSpacing: 1.2,
              ),
            ),
          ),

          _buildNavItem(0, Icons.grid_view_rounded, 'Dashboard'),
          _buildNavItem(1, Icons.people_outline_rounded, 'All Patients'),
          _buildNavItem(2, Icons.warning_amber_rounded, 'High Risk Alerts'),
          _buildNavItem(3, Icons.analytics_outlined, 'Analytics'),

          const Spacer(),

          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.lightMint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Help?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contact system admin for technical support.',
                  style: TextStyle(fontSize: 12, color: AppTheme.darkTeal),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Support'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textLight,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textLight,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, color: AppTheme.textLight),
              ),
              const Text(
                'Last synced Just Now',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                backgroundColor: AppTheme.primaryTeal,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${widget.providerName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Text(
                    'Cardiologist',
                    style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                tooltip: 'Logout',
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const LoginScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildPatientsView('All Managed Patients', _patients);
      case 2:
        final highRisk = _patients
            .where(
              (p) => p.lastRiskLevel == 'RED' || p.lastRiskLevel == 'ORANGE',
            )
            .toList();
        return _buildPatientsView('High Risk Action Required', highRisk);
      default:
        return _buildOverview();
    }
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: AppTheme.mintGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, Dr. ${widget.providerName}!',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: Colors.white, fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Here is what is happening with your patients today.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryTeal,
                      ),
                      onPressed: () => setState(() => _selectedIndex = 2),
                      child: Text(
                        'View Action Items ${_stats['high_risk']! > 0 ? "(${_stats['high_risk']})" : ""}',
                      ),
                    ),
                  ],
                ),
                if (MediaQuery.of(context).size.width > 900)
                  Icon(
                    Icons.monitor_heart,
                    size: 140,
                    color: Colors.white.withOpacity(0.3),
                  ).animate().scale(curve: Curves.easeOutBack),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 40),

          // Stat Cards
          Row(
            children: [
              _buildStatCard(
                'Total Patients',
                _stats['total_patients'].toString(),
                Icons.people_outline,
                Colors.blueAccent,
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                'High Risk Level',
                _stats['high_risk'].toString(),
                Icons.warning_amber_rounded,
                Colors.redAccent,
              ),
              const SizedBox(width: 24),
              _buildStatCard(
                'Overall Check-ins',
                _stats['total_checkins'].toString(),
                Icons.fact_check_outlined,
                AppTheme.primaryTeal,
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Recent Activity Table
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Patient Updates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIndex = 1),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPatientTable(_patients.take(6).toList()),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildPatientsView(String title, List<Patient> patients) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                ),
              ],
            ),
            child: _buildPatientTable(patients),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildPatientTable(List<Patient> patients) {
    if (patients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No patient data available',
            style: TextStyle(color: AppTheme.textLight, fontSize: 16),
          ),
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(2),
        5: FlexColumnWidth(2),
      },
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
          ),
          children: [
            _buildTableHeader('Patient ID'),
            _buildTableHeader('Condition'),
            _buildTableHeader('Risk Status'),
            _buildTableHeader('Logs'),
            _buildTableHeader('Last Update'),
            _buildTableHeader('Action'),
          ],
        ),
        // Data rows
        ...patients.map(
          (p) => TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF7FAFC))),
            ),
            children: [
              _buildTableCell(
                Text(
                  p.patientId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              _buildTableCell(
                Text(
                  p.condition,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
              ),
              _buildTableCell(_buildRiskPill(p.lastRiskLevel, p.lastRiskColor)),
              _buildTableCell(
                Text(
                  '${p.totalCheckins}',
                  style: const TextStyle(color: AppTheme.textLight),
                ),
              ),
              _buildTableCell(
                Text(
                  p.lastCheckin != null ? _formatDate(p.lastCheckin!) : 'Never',
                  style: const TextStyle(color: AppTheme.textLight),
                ),
              ),
              _buildTableCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.message,
                        color: AppTheme.primaryTeal,
                      ),
                      tooltip: 'Message Patient',
                      onPressed: () => _openMessageDrawer(p),
                    ),
                    if (!kIsWeb)
                      TextButton(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Downloading patient records...'),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'PDF export available on mobile only',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Export PDF',
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableCell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }

  Widget _buildRiskPill(String? riskLevel, String? color) {
    if (riskLevel == null) return const Text('N/A');
    Color riskColor = _getRiskColor(color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            riskLevel,
            style: TextStyle(
              color: riskColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String? color) {
    if (color == null) return Colors.grey;
    if (color.toLowerCase() == 'green') return Colors.green;
    if (color.toLowerCase() == 'yellow') return Colors.yellow[700]!;
    if (color.toLowerCase() == 'orange') return Colors.orange;
    if (color.toLowerCase() == 'red') return Colors.red;
    return Colors.grey;
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy h:mm a').format(date);
  }

  void _openMessageDrawer(Patient patient) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Messages',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 16,
            child: Container(
              width: MediaQuery.of(context).size.width > 600
                  ? 400
                  : MediaQuery.of(context).size.width,
              height: double.infinity,
              color: Colors.white,
              child: _MessagePanel(patient: patient, apiService: _apiService),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}

class _MessagePanel extends StatefulWidget {
  final Patient patient;
  final DashboardApiService apiService;

  const _MessagePanel({
    Key? key,
    required this.patient,
    required this.apiService,
  }) : super(key: key);

  @override
  State<_MessagePanel> createState() => _MessagePanelState();
}

class _MessagePanelState extends State<_MessagePanel> {
  final TextEditingController _msgController = TextEditingController();
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final msgs = await widget.apiService.getMessages(widget.patient.patientId);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    final success = await widget.apiService.sendMessage(
      widget.patient.patientId,
      _msgController.text.trim(),
    );

    if (success) {
      _msgController.clear();
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat: ${widget.patient.patientId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      widget.patient.condition,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadMessages,
                ),
              ],
            ),
          ),
        ),

        // Chat List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                )
              : _messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(color: AppTheme.textLight),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    // Reverse the list view layout so newest is at bottom
                    final msg = _messages[_messages.length - 1 - index];
                    final isProvider = msg.senderId == 'provider';

                    return Align(
                      alignment: isProvider
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isProvider
                              ? AppTheme.lightMint
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20).copyWith(
                            bottomRight: isProvider
                                ? const Radius.circular(0)
                                : const Radius.circular(20),
                            bottomLeft: !isProvider
                                ? const Radius.circular(0)
                                : const Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isProvider
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: TextStyle(
                                color: isProvider
                                    ? AppTheme.darkTeal
                                    : AppTheme.textDark,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('h:mm a').format(msg.timestamp),
                              style: TextStyle(
                                color: isProvider
                                    ? AppTheme.primaryTeal.withOpacity(0.6)
                                    : AppTheme.textLight,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Input Field
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.mintGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
