import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    if (_usernameCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter username and password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await ApiService.officerLogin(
      _usernameCtrl.text.trim(), _passwordCtrl.text.trim());
    setState(() => _loading = false);

    if (result.containsKey('error')) {
      setState(() => _error = result['error']);
    } else {
      final o = result['officer'];
      await OfficerSession.save(
        id: o['id'], name: o['name'], username: o['username'],
        category: o['category'], role: o['role']);
      if (!mounted) return;
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        // Left Panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryDark, AppTheme.primary, Color(0xFF1976D2)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_city_rounded,
                      size: 80, color: Colors.white),
                ),
                const SizedBox(height: 32),
                const Text('SmartServe',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 12),
                const Text('Officer Portal',
                    style: TextStyle(fontSize: 20, color: Colors.white70,
                        letterSpacing: 1.5)),
                const SizedBox(height: 48),
                _featureItem(Icons.assignment_rounded, 'Manage Assigned Issues'),
                _featureItem(Icons.update_rounded, 'Update Issue Status'),
                _featureItem(Icons.bar_chart_rounded, 'View Statistics'),
                _featureItem(Icons.comment_rounded, 'Add Remarks & Solutions'),
              ],
            ),
          ),
        ),

        // Right Panel - Login Form
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome Back',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark)),
                const SizedBox(height: 8),
                Text('Sign in to your officer account',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 48),

                // Username
                const Text('Username', style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter your username',
                    prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 20),

                // Password
                const Text('Password', style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                  ),
                  onSubmitted: (_) => _login(),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200)),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                    ]),
                  ),
                ],

                const SizedBox(height: 32),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.login_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text('Sign In', style: TextStyle(fontSize: 17,
                                fontWeight: FontWeight.bold, color: Colors.white)),
                          ]),
                  ),
                ),

                const SizedBox(height: 40),
                Center(child: Text('SmartServe Officer Portal v1.0',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ]),
    );
  }
}
