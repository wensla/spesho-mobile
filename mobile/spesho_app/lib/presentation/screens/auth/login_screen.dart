import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_userCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      body: isDesktop
          ? _buildDesktop(context, auth)
          : _buildMobile(context, auth),
    );
  }

  // ── Desktop: split-screen ────────────────────────────────────────────────────

  Widget _buildDesktop(BuildContext context, AuthProvider auth) {
    return Row(
      children: [
        // Left: hero image with overlay + branding
        Expanded(
          flex: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Rice image as decoration (most reliable in Flutter web)
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/login_bg.jpg'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    // Warm golden color filter to make rice look rich
                    colorFilter: ColorFilter.mode(
                      Color(0x1AD4AA00),
                      BlendMode.srcOver,
                    ),
                  ),
                ),
              ),
              // Multi-stop gradient: transparent at top, dark at bottom for branding
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.45, 0.75, 1.0],
                    colors: [
                      Color(0x00000000),
                      Color(0x1A000000),
                      Color(0x88000000),
                      Color(0xDD000000),
                    ],
                  ),
                ),
              ),
              // Branding anchored to bottom-left
              Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.grain,
                          size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'SPESHO',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Grain Stock & Sales Management',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      height: 2,
                      width: 60,
                      color: const Color(0xFFD4AA00),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right: login form on white panel
        Expanded(
          flex: 42,
          child: Container(
            color: Colors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: _buildFormContent(auth),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile: full-screen image background ─────────────────────────────────────

  Widget _buildMobile(BuildContext context, AuthProvider auth) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/login_bg.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              colorFilter: ColorFilter.mode(
                Color(0x1AD4AA00),
                BlendMode.srcOver,
              ),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x55000000), Color(0xDD000000)],
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const Icon(Icons.grain, size: 52, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'SPESHO',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 5,
                      ),
                    ),
                    const Text(
                      'Grain Stock & Sales Management',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 32),
                    _buildFormContent(auth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared form ──────────────────────────────────────────────────────────────

  Widget _buildFormContent(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to your account',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(children: [
            TextFormField(
              controller: _userCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter username' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => auth.loading ? null : _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter password' : null,
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AA00),
                  disabledBackgroundColor: const Color(0xFFD4AA00).withValues(alpha: 0.6),
                  foregroundColor: Colors.black87,
                  disabledForegroundColor: Colors.black54,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: auth.loading
                    ? Row(mainAxisSize: MainAxisSize.min, children: [
                        const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black54),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Signing in...',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ])
                    : const Text(
                        'SIGN IN',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 15),
                      ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '© Spesho — Products Management System',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }
}
