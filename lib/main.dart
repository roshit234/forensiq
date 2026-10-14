import 'features/evidence/evidence_history_screen.dart';
import 'features/kit_selection/select_testing_kit_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ForensIQApp());
}

class ForensIQApp extends StatelessWidget {
  const ForensIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ForensIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
          secondary: const Color(0xFF0284C7),
          surface: Colors.white,
        ),
      ),
      builder: (context, child) => WebMobileFrame(child: child!),
      home: const LoginScreen(),
    );
  }
}

/// Centers the application in a mobile mockup frame when run on Web/Desktop
class WebMobileFrame extends StatelessWidget {
  final Widget child;
  const WebMobileFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb || constraints.maxWidth > 500) {
          return Scaffold(
            backgroundColor: const Color(0xFF020617),
            body: Center(
              child: Container(
                width: 420,
                height: 880,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 36,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: child,
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}

// ============================================================================
// 1. OFFICER LOGIN SCREEN (Preserved)
// ============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _badgeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ForensIQDashboard(
            officerId: _badgeController.text.trim().toUpperCase(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A0F172A),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.biotech_rounded,
                        size: 48,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ForensIQ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Digital Forensic Field Assistant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: _badgeController,
                    decoration: InputDecoration(
                      labelText: 'Officer / Badge ID',
                      hintText: 'e.g. OF-4910',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Officer ID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Terminal Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _handleLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Authenticate & Enter',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. FORENSIQ DASHBOARD SCREEN (Diagnostics Removed, Camera Linked)
// ============================================================================
class ForensIQDashboard extends StatelessWidget {
  final String officerId;

  const ForensIQDashboard({
    super.key,
    required this.officerId,
  });

  void _handleLogout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            _buildHeader(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Officer Greeting & Live Status Pill
                    _buildOfficerProfile(),
                    const SizedBox(height: 20),

                    // 3. Primary CTA: Start New Test -> Opens CameraScreen
                    _buildPrimaryCta(context),
                    const SizedBox(height: 22),

                    // 4. Quick Actions Grid
                    _buildQuickActions(context),
                    const SizedBox(height: 24),

                    // 5. Recent Field Activity
                    _buildRecentActivity(context),
                    const SizedBox(height: 16),
                    // CHANGE 1: System & Sensor Diagnostics card completely removed here.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Icon(
              Icons.biotech_rounded,
              color: Color(0xFF38BDF8),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ForensIQ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  'Digital Forensic Field Assistant',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFE2E8F0), size: 19),
              tooltip: 'Logout Session',
              onPressed: () => _handleLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerProfile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ACTIVE OPERATOR',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Officer $officerId',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '●',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 11,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'System Ready',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCta(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // CHANGE 2: Launches the dedicated physical camera module
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectTestingKitScreen(officerId: officerId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0284C7)),
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: Color(0xFF38BDF8),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start New Test',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Capture and analyze a sample',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionTile(
          context,
          title: 'Evidence\nRecords',
          icon: Icons.shield_outlined,
          color: const Color(0xFF0284C7),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EvidenceHistoryScreen(officerId: officerId),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        _buildActionTile(
          context,
          title: 'Test\nHistory',
          icon: Icons.history_rounded,
          color: const Color(0xFF475569),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EvidenceHistoryScreen(officerId: officerId),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        _buildActionTile(
          context,
          title: 'Export\nReports',
          icon: Icons.description_outlined,
          color: const Color(0xFF0D9488),
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        height: 106,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final List<Map<String, dynamic>> mockTests = [
      {
        'id': 'FIQ-8492',
        'time': '10 min ago',
        'sample': 'Cocaine (Scott Reagent)',
        'result': 'Presumptive Positive',
        'isPositive': true,
        'status': 'Sealed',
      },
      {
        'id': 'FIQ-8491',
        'time': '1 hr ago',
        'sample': 'Heroin (Marquis Reagent)',
        'result': 'Presumptive Negative',
        'isPositive': false,
        'status': 'Synced',
      },
      {
        'id': 'FIQ-8488',
        'time': 'Yesterday',
        'sample': 'Methamphetamine Reagent',
        'result': 'Presumptive Positive',
        'isPositive': true,
        'status': 'Synced',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Field Activity',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...mockTests.map((test) => _buildTestRecordCard(test)),
      ],
    );
  }

  Widget _buildTestRecordCard(Map<String, dynamic> test) {
    final bool isPositive = test['isPositive'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                test['id'] as String,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                test['time'] as String,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            test['sample'] as String,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPositive
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Text(
                  test['result'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isPositive
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF15803D),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    test['status'] == 'Sealed'
                        ? Icons.lock_outline_rounded
                        : Icons.cloud_done_outlined,
                    size: 13,
                    color: const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    test['status'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}