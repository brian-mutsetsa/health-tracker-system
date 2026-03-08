import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

const double _kMobileBreakpoint = 768.0;

class DashboardScreen extends StatefulWidget {
  final String providerName;
  const DashboardScreen({Key? key, required this.providerName})
    : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  // Navigate and close drawer if it's open
  void _navigate(int index) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState!.closeDrawer();
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _kMobileBreakpoint;

        if (isMobile) {
          return _buildMobileScaffold();
        }
        return _buildDesktopScaffold();
      },
    );
  }

  // ─── Mobile Scaffold ──────────────────────────────────────────────────────

  Widget _buildMobileScaffold() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      drawer: Drawer(
        child: SafeArea(child: _buildSidebarContent(isMobile: true)),
      ),
      body: Column(
        children: [
          _buildTopNavMobile(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                    ),
                  )
                : _buildContent(isMobile: true),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryTeal,
      unselectedItemColor: AppTheme.textLight,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Overview',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline_rounded),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning_amber_rounded),
          label: 'High Risk',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'Analytics',
        ),
      ],
    );
  }

  // ─── Desktop Scaffold ─────────────────────────────────────────────────────

  Widget _buildDesktopScaffold() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                ),
              ],
            ),
            child: SafeArea(child: _buildSidebarContent(isMobile: false)),
          ),
          // Main area
          Expanded(
            child: Column(
              children: [
                _buildTopNavDesktop(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryTeal,
                          ),
                        )
                      : _buildContent(isMobile: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar Content ──────────────────────────────────────────────────────

  Widget _buildSidebarContent({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
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
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'MENU',
            style: TextStyle(
              fontSize: 11,
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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 6),
              const Text(
                'Contact system admin for technical support.',
                style: TextStyle(fontSize: 12, color: AppTheme.darkTeal),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: () => _navigate(index),
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

  // ─── Top Navs ─────────────────────────────────────────────────────────────

  Widget _buildTopNavMobile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.textDark),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const Spacer(),
            const Text(
              'HealthTrack',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: AppTheme.textLight),
            ),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryTeal,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavDesktop() {
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
                onPressed: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
        (route) => false,
      );
    }
  }

  // ─── Content Router ───────────────────────────────────────────────────────

  Widget _buildContent({required bool isMobile}) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverview(isMobile: isMobile);
      case 1:
        return _buildPatientsView(
          'All Managed Patients',
          _patients,
          isMobile: isMobile,
        );
      case 2:
        final highRisk = _patients
            .where(
              (p) => p.lastRiskLevel == 'RED' || p.lastRiskLevel == 'ORANGE',
            )
            .toList();
        return _buildPatientsView(
          'High Risk — Action Required',
          highRisk,
          isMobile: isMobile,
        );
      case 3:
        return _buildAnalytics(isMobile: isMobile);
      default:
        return _buildOverview(isMobile: isMobile);
    }
  }

  // ─── Overview ─────────────────────────────────────────────────────────────

  Widget _buildOverview({required bool isMobile}) {
    final pad = isMobile ? 16.0 : 40.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          _buildHeroBanner(isMobile: isMobile),
          SizedBox(height: isMobile ? 20 : 40),

          // Stat cards
          if (isMobile)
            Column(
              children: [
                _buildStatCardFull(
                  'Total Patients',
                  _stats['total_patients'].toString(),
                  Icons.people_outline,
                  Colors.blueAccent,
                ),
                const SizedBox(height: 12),
                _buildStatCardFull(
                  'High Risk Level',
                  _stats['high_risk'].toString(),
                  Icons.warning_amber_rounded,
                  Colors.redAccent,
                ),
                const SizedBox(height: 12),
                _buildStatCardFull(
                  'Overall Check-ins',
                  _stats['total_checkins'].toString(),
                  Icons.fact_check_outlined,
                  AppTheme.primaryTeal,
                ),
              ],
            )
          else
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

          SizedBox(height: isMobile ? 20 : 40),

          // Recent Activity
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
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
                        fontSize: 18,
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
                const SizedBox(height: 16),
                isMobile
                    ? _buildPatientCards(_patients.take(5).toList())
                    : _buildPatientTable(_patients.take(6).toList()),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildHeroBanner({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,\nDr. ${widget.providerName}!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 32,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Here is what is happening with your patients today.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryTeal,
                  ),
                  onPressed: () => setState(() => _selectedIndex = 2),
                  child: Text(
                    'View Action Items'
                    '${_stats['high_risk']! > 0 ? " (${_stats['high_risk']})" : ""}',
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile)
            Icon(
              Icons.monitor_heart,
              size: 140,
              color: Colors.white.withOpacity(0.3),
            ).animate().scale(curve: Curves.easeOutBack),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // ─── Stat Cards ───────────────────────────────────────────────────────────

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(child: _statCardBody(title, value, icon, color));
  }

  Widget _buildStatCardFull(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      child: _statCardBody(title, value, icon, color),
    );
  }

  Widget _statCardBody(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  // ─── Analytics Page ───────────────────────────────────────────────────────

  Widget _buildAnalytics({required bool isMobile}) {
    final pad = isMobile ? 16.0 : 40.0;
    final total = _stats['total_patients'] ?? 0;
    final highRisk = _stats['high_risk'] ?? 0;
    final checkins = _stats['total_checkins'] ?? 0;
    final lowRisk = total - highRisk;

    // Condition breakdown
    final conditionCounts = <String, int>{};
    for (final p in _patients) {
      conditionCounts[p.condition] = (conditionCounts[p.condition] ?? 0) + 1;
    }

    // Risk level breakdown
    final riskCounts = <String, int>{
      'GREEN': 0,
      'YELLOW': 0,
      'ORANGE': 0,
      'RED': 0,
      'Unknown': 0,
    };
    for (final p in _patients) {
      final level = p.lastRiskLevel ?? 'Unknown';
      if (riskCounts.containsKey(level)) {
        riskCounts[level] = riskCounts[level]! + 1;
      } else {
        riskCounts['Unknown'] = riskCounts['Unknown']! + 1;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: TextStyle(
              fontSize: isMobile ? 22 : 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Summary of patient data across your practice.',
            style: TextStyle(color: AppTheme.textLight, fontSize: 14),
          ),
          SizedBox(height: isMobile ? 20 : 32),

          // Summary KPI row
          if (isMobile)
            Column(
              children: [
                _buildStatCardFull(
                  'Total Patients',
                  total.toString(),
                  Icons.people_outline,
                  Colors.blueAccent,
                ),
                const SizedBox(height: 12),
                _buildStatCardFull(
                  'High Risk',
                  highRisk.toString(),
                  Icons.warning_amber_rounded,
                  Colors.redAccent,
                ),
                const SizedBox(height: 12),
                _buildStatCardFull(
                  'Low / Med Risk',
                  lowRisk.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildStatCardFull(
                  'Total Check-ins',
                  checkins.toString(),
                  Icons.fact_check_outlined,
                  AppTheme.primaryTeal,
                ),
              ],
            )
          else
            Row(
              children: [
                _buildStatCard(
                  'Total Patients',
                  total.toString(),
                  Icons.people_outline,
                  Colors.blueAccent,
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  'High Risk',
                  highRisk.toString(),
                  Icons.warning_amber_rounded,
                  Colors.redAccent,
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  'Low / Med Risk',
                  lowRisk.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                const SizedBox(width: 20),
                _buildStatCard(
                  'Total Check-ins',
                  checkins.toString(),
                  Icons.fact_check_outlined,
                  AppTheme.primaryTeal,
                ),
              ],
            ),

          SizedBox(height: isMobile ? 20 : 32),

          // Two panels: Risk breakdown + Condition breakdown
          if (isMobile)
            Column(
              children: [
                _buildRiskPanel(riskCounts),
                const SizedBox(height: 16),
                _buildConditionPanel(conditionCounts),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildRiskPanel(riskCounts)),
                const SizedBox(width: 24),
                Expanded(child: _buildConditionPanel(conditionCounts)),
              ],
            ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildRiskPanel(Map<String, int> riskCounts) {
    final colors = {
      'GREEN': Colors.green,
      'YELLOW': Colors.yellow[700]!,
      'ORANGE': Colors.orange,
      'RED': Colors.red,
      'Unknown': Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Level Distribution',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          ...riskCounts.entries.map((e) {
            final color = colors[e.key] ?? Colors.grey;
            final pct = _patients.isEmpty ? 0.0 : e.value / _patients.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${e.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConditionPanel(Map<String, int> conditionCounts) {
    final sorted = conditionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Condition Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          if (sorted.isEmpty)
            const Text(
              'No data available',
              style: TextStyle(color: AppTheme.textLight),
            )
          else
            ...sorted.take(8).map((e) {
              final pct = _patients.isEmpty ? 0.0 : e.value / _patients.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryTeal,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── Patients View ────────────────────────────────────────────────────────

  Widget _buildPatientsView(
    String title,
    List<Patient> patients, {
    required bool isMobile,
  }) {
    final pad = isMobile ? 16.0 : 40.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 20 : 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 32),
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
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
            child: isMobile
                ? _buildPatientCards(patients)
                : _buildPatientTable(patients),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ─── Desktop Table ────────────────────────────────────────────────────────

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
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEDF2F7))),
          ),
          children: [
            _th('Patient ID'),
            _th('Condition'),
            _th('Risk Status'),
            _th('Logs'),
            _th('Last Update'),
            _th('Action'),
          ],
        ),
        ...patients.map(
          (p) => TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF7FAFC))),
            ),
            children: [
              _td(
                Text(
                  p.patientId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              _td(
                Text(
                  p.condition,
                  style: const TextStyle(color: AppTheme.textDark),
                ),
              ),
              _td(_buildRiskPill(p.lastRiskLevel, p.lastRiskColor)),
              _td(
                Text(
                  '${p.totalCheckins}',
                  style: const TextStyle(color: AppTheme.textLight),
                ),
              ),
              _td(
                Text(
                  p.lastCheckin != null ? _formatDate(p.lastCheckin!) : 'Never',
                  style: const TextStyle(color: AppTheme.textLight),
                ),
              ),
              _td(
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
                        onPressed: () {
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

  Widget _th(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    child: Text(
      t,
      style: const TextStyle(
        color: AppTheme.textLight,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _td(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
    child: Align(alignment: Alignment.centerLeft, child: child),
  );

  // ─── Mobile Patient Cards ─────────────────────────────────────────────────

  Widget _buildPatientCards(List<Patient> patients) {
    if (patients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No patient data available',
            style: TextStyle(color: AppTheme.textLight, fontSize: 16),
          ),
        ),
      );
    }
    return Column(children: patients.map((p) => _buildPatientCard(p)).toList());
  }

  Widget _buildPatientCard(Patient p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  p.patientId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildRiskPill(p.lastRiskLevel, p.lastRiskColor),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow(Icons.medical_services_outlined, p.condition),
          const SizedBox(height: 4),
          _infoRow(
            Icons.access_time,
            p.lastCheckin != null
                ? _formatDate(p.lastCheckin!)
                : 'No check-in yet',
          ),
          const SizedBox(height: 4),
          _infoRow(Icons.fact_check_outlined, '${p.totalCheckins} check-ins'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.message, size: 16),
              label: const Text('Message Patient'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryTeal,
                side: const BorderSide(color: AppTheme.primaryTeal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _openMessageDrawer(p),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Shared Helpers ───────────────────────────────────────────────────────

  Widget _buildRiskPill(String? riskLevel, String? color) {
    if (riskLevel == null) return const Text('N/A');
    final riskColor = _getRiskColor(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            riskLevel,
            style: TextStyle(
              color: riskColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String? color) {
    if (color == null) return Colors.grey;
    switch (color.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow[700]!;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy h:mm a').format(date);

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

// ─── Message Panel ──────────────────────────────────────────────────────────

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
  bool _isPatientTyping = false;
  Timer? _pollingTimer;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(isPolling: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _typingDebounce?.cancel();
    widget.apiService.updateTypingStatus(widget.patient.patientId, false);
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool isPolling = false}) async {
    final msgs = await widget.apiService.getMessages(widget.patient.patientId);
    final isTyping = await widget.apiService.getTypingStatus(
      widget.patient.patientId,
    );
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isPatientTyping = isTyping;
        if (!isPolling) _isLoading = false;
      });
    }
  }

  void _onMessageChanged(String text) {
    if (_typingDebounce?.isActive ?? false) _typingDebounce!.cancel();
    widget.apiService.updateTypingStatus(widget.patient.patientId, true);
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      widget.apiService.updateTypingStatus(widget.patient.patientId, false);
    });
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    _typingDebounce?.cancel();
    widget.apiService.updateTypingStatus(widget.patient.patientId, false);
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
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryTeal,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat: ${widget.patient.patientId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.patient.condition,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadMessages,
                ),
              ],
            ),
          ),
        ),

        // Chat list
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
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[_messages.length - 1 - index];
                    final isProvider = msg.senderId == 'provider';
                    return Align(
                      alignment: isProvider
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isProvider
                              ? AppTheme.lightMint
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(18).copyWith(
                            bottomRight: isProvider
                                ? const Radius.circular(0)
                                : const Radius.circular(18),
                            bottomLeft: !isProvider
                                ? const Radius.circular(0)
                                : const Radius.circular(18),
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
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
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

        // Typing + input
        Column(
          children: [
            if (_isPatientTyping)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Patient is typing...',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
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
                        onChanged: _onMessageChanged,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 10),
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
        ),
      ],
    );
  }
}
