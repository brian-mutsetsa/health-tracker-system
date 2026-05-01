import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final providerId = prefs.getString('provider_id');
    final providerName = prefs.getString('provider_name');
    if (providerId != null && providerName != null) {
      DashboardApiService.currentProviderId = providerId;
      DashboardApiService.currentProviderName = providerName;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                DashboardScreen(providerName: providerName),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_nameController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your provider username and password'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final errorMsg = await DashboardApiService().login(
      _nameController.text.trim(),
      _passController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMsg == null && DashboardApiService.currentProviderName != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              DashboardScreen(
                providerName: DashboardApiService.currentProviderName!,
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      final errorType = DashboardApiService.lastLoginErrorType;
      if (errorType == 'not_found') {
        _showLoginErrorDialog(
          icon: Icons.person_off_outlined,
          iconColor: Colors.orange.shade700,
          title: 'Account Not Found',
          message: errorMsg ?? 'No account found with that username.',
          hint: 'Double-check your username or contact your administrator.',
        );
      } else if (errorType == 'deactivated') {
        _showLoginErrorDialog(
          icon: Icons.block,
          iconColor: Colors.red.shade700,
          title: 'Account Deactivated',
          message: errorMsg ?? 'Your account has been deactivated.',
          hint: 'Please contact your administrator to reactivate your account.',
        );
      } else {
        // Generic error — show a SnackBar for wrong password / network issues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg ?? 'Invalid credentials.'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showLoginErrorDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String hint,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 800;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side: Beautiful Gradient / Graphic (Hidden on small screens)
          if (MediaQuery.of(context).size.width > 800)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.mintGradient,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.monitor_heart,
                            size: 80,
                            color: Colors.white,
                          ),
                        ).animate().scale(
                          delay: 200.ms,
                          curve: Curves.easeOutBack,
                        ),
                        const SizedBox(height: 48),
                        Text(
                          'Empowering\nHealthcare\nProviders.',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: 64,
                                height: 1.1,
                              ),
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                        const SizedBox(height: 24),
                        const Text(
                          'Monitor your patients across conditions, manage risk, and streamline your clinical workflow all in one unified platform.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Right Side: Login Form
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: EdgeInsets.all(isMobile ? 24.0 : 48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (MediaQuery.of(context).size.width <= 800) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: AppTheme.mintGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.monitor_heart,
                                size: 40,
                                color: Colors.white,
                              ),
                            ).animate().scale(),
                            const SizedBox(height: 24),
                          ],
                          Text(
                            'Welcome Back',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontSize: isMobile ? 26 : 40,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Enter your credentials to access the provider dashboard.',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                      const SizedBox(height: 48),

                      // Username
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Provider ID / Name',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Dr. Smith',
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: AppTheme.textLight,
                              ),
                            ),
                            onSubmitted: (_) => _login(),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                      const SizedBox(height: 24),

                      // Password Mock
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Password',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppTheme.textLight,
                              ),
                            ),
                            onSubmitted: (_) => _login(),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppTheme.primaryTeal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                      const SizedBox(height: 48),
                      const Center(
                        child: Text(
                          'Health Tracker System © 2026',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
