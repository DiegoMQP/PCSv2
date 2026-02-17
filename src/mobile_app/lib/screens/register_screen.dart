import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;
  
  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();
  final _locationController = TextEditingController(); // Location input

  double _passwordStrength = 0.0;

  void _checkStrength(String val) {
    double strength = 0;
    if (val.length > 5) strength += 0.3;
    if (val.length > 8) strength += 0.3;
    if (val.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (val.contains(RegExp(r'[0-9]'))) strength += 0.2;
    setState(() => _passwordStrength = strength);
  }

  Color get _strengthColor {
    if (_passwordStrength < 0.4) return Colors.red;
    if (_passwordStrength < 0.7) return Colors.orange;
    return Colors.green;
  }

  Future<void> _handleRegister() async {
    // Basic validation
    if (_passwordController.text != _confirmPasswordController.text) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Las contraseñas no coinciden")));
        }
        return;
    }

    // Combine code and location? Or just pass location as the "Code + House" string?
    // For now, let's assume the backend 'location' field stores the specific metadata (House)
    // and we validated the 'Code' exists separately.
    
    final api = ApiService();
    final result = await api.register(
        _emailController.text, 
        _passwordController.text,
        "${_codeController.text} - ${_locationController.text}", // Passing both for now
        _nameController.text
    );

    if (mounted) {
      if (result['success']) {
        Provider.of<UserProvider>(context, listen: false).setUser(
            _emailController.text,
            name: _nameController.text
        );
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] != null ? result['message'].toString() : 'Error en registro'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextStep() async {
    if (_currentStep < _totalSteps - 1) {
      if (_currentStep == 0) {
         if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos")));
             return;
         }
      }
      if (_currentStep == 1) {
          if (_passwordController.text.length < 6) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contraseña muy corta")));
             return;
          }
      }
      setState(() => _currentStep++);
    } else {
      // Step 2: Validation before Register
      if (_codeController.text.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa el código")));
           return;
      }
      
      showDialog(barrierDismissible: false, context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      final api = ApiService();
      final valid = await api.verifyLocation(_codeController.text);
      
      if (mounted) {
          Navigator.pop(context); // Close loading
          if (valid['success'] == true) {
               _handleRegister();
          } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Código de Fraccionamiento inválido")));
          }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text("Registro"),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Progress Bar
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _getStepTitle(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: PageController(initialPage: _currentStep), // Just for structure, state controls view
                children: [
                  _buildCurrentStepContent(), // Simplified for demo
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _currentStep == _totalSteps - 1 ? "Finalizar Registro" : "Continuar",
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )));
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return "Datos Personales";
      case 1: return "Seguridad";
      case 2: return "Vinculación";
      default: return "";
    }
  }

  Widget _buildCurrentStepContent() {
    // Manually switching content based on step
    switch (_currentStep) {
      case 0:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildInput("Nombre completo", _nameController),
              _buildInput("Teléfono Móvil", _phoneController, type: TextInputType.phone),
              _buildInput("Correo Electrónico", _emailController, type: TextInputType.emailAddress),
            ],
          ),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInput("Contraseña", _passwordController, obscure: true, onChanged: _checkStrength),
              _buildInput("Confirmar contraseña", _confirmPasswordController, obscure: true),
              const SizedBox(height: 10),
              if (_passwordController.text.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                    minHeight: 4,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text("Debe tener al menos 8 caracteres.", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                )
              ]
            ],
          ),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Ingresa el código único proporcionado por tu administración.", style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 20),
              _buildInput("Código de Fraccionamiento (Ej. PCS-2024)", _codeController),
              const SizedBox(height: 20),
              _buildInput("Ubicación / Casa (Ej. Manzana A Lote 3)", _locationController),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInput(String hint, TextEditingController controller, {bool obscure = false, TextInputType? type, Function(String)? onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
