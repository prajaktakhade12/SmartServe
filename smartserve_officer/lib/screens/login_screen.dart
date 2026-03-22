import 'package:flutter/material.dart';
import '../core/officer_session.dart';
import '../core/officer_strings.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String language;
  final void Function(String) onLanguageChanged;

  const LoginScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool    _loading  = false;
  bool    _obscure  = true;
  String? _error;

  // ── Local language state ─────────────────────────────────────────────────
  // We keep a LOCAL copy so the screen rebuilds immediately when the user
  // taps a language button — without waiting for the parent to rebuild.
  late String _lang;

  @override
  void initState() {
    super.initState();
    _lang = widget.language; // initialise from parent
  }

  @override
  void didUpdateWidget(LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep in sync if parent changes language externally
    if (oldWidget.language != widget.language) {
      setState(() => _lang = widget.language);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Change language both locally AND in parent ───────────────────────────
  void _changeLanguage(String code) {
    setState(() => _lang = code);       // instant local rebuild
    widget.onLanguageChanged(code);     // propagate to parent
  }

  Future<void> _login() async {
    if (_usernameCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      setState(() =>
          _error = OfficerStrings.text('enter_credentials', _lang));
      return;
    }
    setState(() {
      _loading = true;
      _error   = null;
    });

    final result = await ApiService.officerLogin(
        _usernameCtrl.text.trim(), _passwordCtrl.text.trim());
    setState(() => _loading = false);

    if (result.containsKey('error')) {
      setState(() => _error =
          result['error'] == 'Invalid username or password'
              ? OfficerStrings.text('invalid_credentials', _lang)
              : result['error']);
    } else {
      final o = result['officer'];
      await OfficerSession.save(
        id:          o['id'],
        name:        o['name'],
        username:    o['username'],
        category:    o['category'],
        role:        o['role'],
        designation: o['designation'] ?? '',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            language:          _lang,
            onLanguageChanged: widget.onLanguageChanged,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [

        // ── Left Panel (Branding) ────────────────────────────────────────────
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryDark, AppTheme.primary,
                         Color(0xFF1976D2)],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle),
                  child: const Icon(Icons.location_city_rounded,
                      size: 80, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Text(OfficerStrings.text('app_name', _lang),
                    style: const TextStyle(
                        fontSize: 42, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 12),
                Text(OfficerStrings.text('officer_portal', _lang),
                    style: const TextStyle(
                        fontSize: 20, color: Colors.white70,
                        letterSpacing: 1.5)),
                const SizedBox(height: 48),
                _featureItem(Icons.assignment_rounded,
                    OfficerStrings.text('feature_manage', _lang)),
                _featureItem(Icons.update_rounded,
                    OfficerStrings.text('feature_update', _lang)),
                _featureItem(Icons.bar_chart_rounded,
                    OfficerStrings.text('feature_stats', _lang)),
                _featureItem(Icons.groups_rounded,
                    OfficerStrings.text('feature_team', _lang)),
              ],
            ),
          ),
        ),

        // ── Right Panel (Form) ───────────────────────────────────────────────
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Language toggle (top-right) ──────────────────────────
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language_rounded,
                          size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      _langBtn('en', 'EN'),
                      const SizedBox(width: 4),
                      _langBtn('hi', 'हि'),
                      const SizedBox(width: 4),
                      _langBtn('mr', 'म'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Welcome text — changes instantly with language
                Text(OfficerStrings.text('welcome_back', _lang),
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark)),
                const SizedBox(height: 8),
                Text(OfficerStrings.text('sign_in_subtitle', _lang),
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 48),

                // Username field
                Text(OfficerStrings.text('username', _lang),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameCtrl,
                  decoration: InputDecoration(
                    hintText: OfficerStrings.text('username_hint', _lang),
                    prefixIcon: const Icon(Icons.person_rounded,
                        color: AppTheme.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 2)),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 20),

                // Password field
                Text(OfficerStrings.text('password', _lang),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: OfficerStrings.text('password_hint', _lang),
                    prefixIcon: const Icon(Icons.lock_rounded,
                        color: AppTheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 2)),
                  ),
                  onSubmitted: (_) => _login(),
                ),

                // Error box
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200)),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade600, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13)),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 32),

                // Sign In button
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
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.login_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 10),
                              Text(
                                OfficerStrings.text('sign_in', _lang),
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ]),
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: Text(
                    OfficerStrings.text('version', _lang),
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // Language button — calls _changeLanguage so it rebuilds immediately
  Widget _langBtn(String code, String label) {
    final selected = _lang == code;
    return GestureDetector(
      onTap: () => _changeLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? AppTheme.primary : Colors.grey.shade500,
              fontSize: 12,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
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
        Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
      ]),
    );
  }
}