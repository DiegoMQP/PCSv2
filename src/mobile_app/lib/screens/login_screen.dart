import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

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

  void _checkInputs() {
    setState(() {
      _isButtonVisible = _emailController.text.isNotEmpty && 
                         _passwordController.text.isNotEmpty;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final api = ApiService();
    final result = await api.login(_emailController.text, _passwordController.text);
    
    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null && data.containsKey('username')) {
            Provider.of<UserProvider>(context, listen: false).setUser(data['username']);
        } else {
            // Fallback if data not structured as expected, use input email/username
            Provider.of<UserProvider>(context, listen: false).setUser(_emailController.text);
        }
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] != null 
                  ? result['message'].toString() 
                  : 'Login failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ]
                  ),
                  child: const Icon(Icons.shield, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 30),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: const Text(
                  "Bienvenido",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  "Ingresa para continuar",
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 40),
              
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          onChanged: (_) => _checkInputs(),
                          decoration: const InputDecoration(
                            hintText: "Correo Electrónico",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                          ),
                          validator: (value) {
                             if (value == null || value.isEmpty) return 'Requerido';
                             if (!value.contains('@')) return 'Email inválido';
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
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          onChanged: (_) => _checkInputs(),
                          decoration: const InputDecoration(
                            hintText: "Contraseña",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
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
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Iniciar Sesión", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),

               const SizedBox(height: 40),
               FadeInUp(
                 delay: const Duration(milliseconds: 600),
                 child: TextButton(
                   onPressed: () => Navigator.pushNamed(context, '/register'),
                   child: Text("¿No tienes cuenta? Regístrate", 
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
