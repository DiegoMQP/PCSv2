import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../providers/language_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _serverError = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = L.of(lang, 'fillAll'));
      return;
    }
    setState(() { _loading = true; _error = null; _serverError = false; });
    final res = await ApiService().login(_userCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>?;
      Provider.of<UserProvider>(context, listen: false).setUser(
        data?['username']?.toString() ?? _userCtrl.text.trim(),
        name: data?['name']?.toString(),
        location: data?['location']?.toString(),
        role: data?['role']?.toString(),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      final int statusCode = (res['statusCode'] as int?) ?? 0;
      final isServerErr = statusCode >= 500 || statusCode == 503;
      setState(() {
        _serverError = isServerErr;
        _error = isServerErr
            ? L.of(lang, 'serverError')
            : (res['message']?.toString() ?? L.of(lang, 'invalidCreds'));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0A84FF);
    const bg = Color(0xFF1C1C1E);
    const card = Color(0xFF2C2C2E);
    const surface = Color(0xFF3A3A3C);

    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Language toggle (top-right)
          Positioned(
            top: 20,
            right: 24,
            child: _LangButton(lang: lang),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title (no logo circle)
                      const SizedBox(height: 4),
                      Text(
                        L.of(lang, 'loginTitle'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        L.of(lang, 'loginSubtitle'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Error
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF453A).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFF453A).withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFFF453A), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Color(0xFFFF453A),
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              ]),
                              if (_serverError) ...[
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: _login,
                                  icon: const Icon(Icons.refresh, size: 15, color: primary),
                                  label: Text(L.of(lang, 'retry'),
                                      style: const TextStyle(color: primary, fontSize: 13)),
                                  style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                ),
                              ],
                            ],
                          ),
                        ),

                      // Username
                      _darkField(
                        controller: _userCtrl,
                        label: L.of(lang, 'username'),
                        icon: Icons.person_outline_rounded,
                        surface: surface,
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      _darkField(
                        controller: _passCtrl,
                        label: L.of(lang, 'password'),
                        icon: Icons.lock_outline_rounded,
                        surface: surface,
                        obscure: _obscure,
                        toggleObscure: () => setState(() => _obscure = !_obscure),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 28),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  L.of(lang, 'loginBtn'),
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        L.of(lang, 'footer'),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.2), fontSize: 11),
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

  Widget _darkField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color surface,
    bool obscure = false,
    VoidCallback? toggleObscure,
    void Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: toggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: toggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// Language toggle button widget
class _LangButton extends StatelessWidget {
  final LanguageProvider lang;
  const _LangButton({required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: lang.toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 16, color: Color(0xFF0A84FF)),
            const SizedBox(width: 6),
            Text(
              lang.isEnglish ? 'EN' : 'ES',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.swap_horiz_rounded, size: 15, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
