import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

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
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
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
            ? 'El servidor tuvo un problema, intenta de nuevo'
            : (res['message']?.toString() ?? 'Credenciales inv\u00e1lidas');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0A84FF);
    const bg = Color(0xFF1C1C1E);
    const card = Color(0xFF2C2C2E);
    const surface = Color(0xFF3A3A3C);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
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
                  // ── Logo PCS ──────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A84FF), Color(0xFF0055CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A84FF).withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('PCS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PCS Access',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Panel de Control Residencial',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Error ─────────────────────────────────────
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
                              icon: const Icon(Icons.refresh, size: 15, color: Color(0xFF0A84FF)),
                              label: const Text('Reintentar', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 13)),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            ),
                          ],
                        ],
                      ),
                    ),

                  // ── Username ──────────────────────────────────
                  _darkField(
                    controller: _userCtrl,
                    label: 'Usuario',
                    icon: Icons.person_outline_rounded,
                    surface: surface,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 14),

                  // ── Password ──────────────────────────────────
                  _darkField(
                    controller: _passCtrl,
                    label: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    surface: surface,
                    obscure: _obscure,
                    toggleObscure: () => setState(() => _obscure = !_obscure),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 28),

                  // ── Button ────────────────────────────────────
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
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PCS Security © 2025',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.2), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
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

