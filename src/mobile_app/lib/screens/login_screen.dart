import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isButtonVisible = false;

  // New State Variables
  String? _errorMessage;
  bool _isHoveringRegister = false;
  bool _showServerFailUI = false;

  void _checkInputs() {
    setState(() {
      _isButtonVisible = _emailController.text.isNotEmpty && 
                         _passwordController.text.isNotEmpty;
      _errorMessage = null; // Clear error
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
        _isLoading = true;
        _errorMessage = null;
    });

    final api = ApiService();
    final result = await api.login(_emailController.text, _passwordController.text);
    
    if (!mounted) return;

    if (result['success']) {
        setState(() => _isLoading = false);
        final data = result['data'] as Map<String, dynamic>?;
        
        if (data != null && data.containsKey('username')) {
            final username = data['username'];
            final name = data['name'];
            final location = data['location'];
            final role = data['role'];
            Provider.of<UserProvider>(context, listen: false).setUser(
              username,
              name: name?.toString(),
              location: location?.toString(),
              role: role?.toString(),
            );
        } else {
            Provider.of<UserProvider>(context, listen: false).setUser(_emailController.text);
        }
        Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
        final msg = result['message'].toString();
        final int statusCode = (result['statusCode'] as int?) ?? 0;
        // Check for connection/server errors (5xx or connection failure)
        if (msg.contains('Connection error') || statusCode >= 500 || msg.contains('500') || msg.contains('503') || msg.contains('Database not available')) {
            bool health = await api.checkHealth();
            if (health) {
                 setState(() {
                     _isLoading = false;
                     _errorMessage = "Error interno del servidor. Intente más tarde.";
                 });
            } else {
                 bool portOpen = await api.checkPort();
                 setState(() => _isLoading = false);
                 if (!portOpen) {
                     setState(() => _showServerFailUI = true);
                 } else {
                     setState(() => _errorMessage = context.trStatic('service_unavailable'));
                 }
            }
        } else {
            setState(() {
                _isLoading = false;
                _errorMessage = msg;
            });
        }
    }
  }

  void _retryConnection() {
      setState(() {
          _showServerFailUI = false;
          _isLoading = false;
          _errorMessage = null;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (_showServerFailUI) {
        return Scaffold(
            backgroundColor: const Color(0xFF1C1C1E),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Icon(Icons.dns, size: 80, color: Colors.redAccent),
                        const SizedBox(height: 20),
                        Text(context.tr('server_error_title'), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(context.tr('server_error_desc'), style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                            onPressed: _retryConnection,
                            icon: const Icon(Icons.refresh),
                            label: Text(context.tr('retry')),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                            )
                        )
                    ],
                ),
            )
        );
    }

    // Check if desktop
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme background instead of hardcoded white
      body: SafeArea(
        child: isDesktop 
        ? Row(
            children: [
               Expanded(
                 child: Container(
                   color: const Color(0xFF1C1C1E), // Dark sidebar for login to match style
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Consumer<UserProvider>(builder: (context, user, _) {return const SizedBox();}), // Dummy to avoid lint errors if needed or remove
                       const Text("PCS Security", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 2)),
                       const SizedBox(height: 10),
                       Text(context.tr('secure_access'), style: const TextStyle(color: Colors.grey, fontSize: 18))
                     ],
                   ),
                 ),
               ),
               Expanded(
                 child: Center(
                   child: Container(
                     width: 450,
                     padding: const EdgeInsets.all(40),
                     child: _buildLoginForm(context),
                   ),
                 ),
               )
            ],
          )
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: _buildLoginForm(context),
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (MediaQuery.of(context).size.width <= 900) ...[
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Text(
              "PCS Security",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: const Text(
            context.tr('welcome'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
        FadeInUp(
          delay: const Duration(milliseconds: 300),
          child: Text(
            context.tr('sign_in'),
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ),
        const SizedBox(height: 40),
        
        if (_errorMessage != null)
            FadeInDown(
                child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200)
                    ),
                    child: Row(
                        children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade800, fontSize: 13))),
                        ],
                    ),
                ),
            ),

        Form(
          key: _formKey,
          child: Column(
            children: [
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color, // Adaptive color
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    onChanged: (_) => _checkInputs(),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: context.tr('email_hint'),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    validator: (value) {
                        if (value == null || value.isEmpty) return context.trStatic('required');
                        if (!value.contains('@')) return context.trStatic('invalid_email');
                        return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color, // Adaptive color
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: (_) => _checkInputs(),
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: context.tr('password'),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        if (_isButtonVisible)
          ZoomIn(
            duration: const Duration(milliseconds: 300),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(context.tr('login_btn'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: MouseRegion(
                onEnter: (_) => setState(() => _isHoveringRegister = true),
                onExit: (_) => setState(() => _isHoveringRegister = false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register'),
                    child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.bold,
                            fontSize: _isHoveringRegister ? 16 : 14,
                        ),
                        child: const Text("¿No tienes cuenta? Regístrate"),
                    ),
                ),
            ),
          ),
            ],
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
