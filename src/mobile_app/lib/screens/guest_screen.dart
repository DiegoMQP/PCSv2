import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final _plateController = TextEditingController();
  final _nameController = TextEditingController();
  final _usesController = TextEditingController(text: "1");
  
  String _accessType = 'Tiempo'; // Options: Tiempo, Permanente, Un uso, Limite
  String _selectedDuration = '4h';
  
  bool _showSuccess = false;
  String _generatedCode = '';

  // Camera stubs - in real app initialize CameraController
  bool _isCameraOpen = false;

  Future<void> _generateCode() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    if (user.username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Usuario no identificado")));
        return;
    }
    
    if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingrese nombre del invitado")));
        return;
    }

    // Determine final duration/type string to send
    String finalConfigs = _selectedDuration;
    if (_accessType == 'Permanente') finalConfigs = 'permanent';
    if (_accessType == 'Un uso') finalConfigs = 'one_time';
    if (_accessType == 'Limite') finalConfigs = 'limit_${_usesController.text}';

    final api = ApiService();
    final result = await api.createGuest(
        visitorName: _nameController.text,
        hostUsername: user.username,
        plate: _plateController.text,
        duration: finalConfigs
    );

    if (mounted) {
        if (result['success']) {
            setState(() {
                _generatedCode = (1000 + (DateTime.now().millisecond % 9000)).toString(); // Just for display, real ID is in DB
                _showSuccess = true;
            });
        } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${result['message']}")));
        }
    }
  }

  void _scanPlate() {
    // Simulate Opening Camera
    setState(() {
      _isCameraOpen = true;
    });
    
    // Simulate scanning after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
        if(mounted) {
            setState(() {
                _isCameraOpen = false;
                _plateController.text = "XYZ-987"; // Simulated OCR Result
            });
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Matrícula detectada: XYZ-987"), backgroundColor: Colors.green)
            );
        }
    });

  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return _buildSuccessScreen();

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar", style: TextStyle(fontSize: 14)),
        ),
        leadingWidth: 80,
        title: const Text("Visitante"),
      ),
      body: Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Stack(
                children: [
                SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        _sectionHeader("DATOS DEL INVITADO"),
                        Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildRowInput("Nombre", _nameController, "Obligatorio"),
                      Divider(height: 1, indent: 20, color: Colors.grey[200]),
                      _buildRowInput("Placa", _plateController, "Opcional"),
                      Divider(height: 1, indent: 20, color: Colors.grey[200]),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Expanded(child: _secondaryBtn(Icons.camera_alt, "Escanear", _scanPlate)),
                            const SizedBox(width: 10),
                            Expanded(child: _secondaryBtn(Icons.image, "Subir Foto", () {})),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                _sectionHeader("TIPO DE ACCESO"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _typeChip("Tiempo"),
                              const SizedBox(width: 8),
                              _typeChip("Permanente"),
                              const SizedBox(width: 8),
                              _typeChip("Un uso"),
                              const SizedBox(width: 8),
                              _typeChip("Limite"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Divider(color: Colors.grey[200]),
                        const SizedBox(height: 15),
                        
                        // Conditional UI based on Selection
                        if (_accessType == 'Tiempo') ...[
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: ['30m', '4h', '12h', '24h'].map((e) => _durationChip(e)).toList(),
                             ),
                             const SizedBox(height: 15),
                             const TextField(
                               keyboardType: TextInputType.number,
                               textAlign: TextAlign.right,
                               decoration: InputDecoration(
                                 prefixText: "Otro",
                                 suffixText: "Horas",
                                 border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                                 isDense: true,
                               ),
                             )
                        ] else if (_accessType == 'Limite') ...[
                             Row(
                               children: [
                                  const Text("Cantidad de usos:", style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 20),
                                  Expanded(
                                      child: TextField(
                                          controller: _usesController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Theme.of(context).scaffoldBackgroundColor,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                          ),
                                      ),
                                  )
                               ],
                             )
                        ] else if (_accessType == 'Permanente') ...[
                             const Padding(
                               padding: EdgeInsets.all(10.0),
                               child: Text("Este código no expirará hasta que lo revoques manualmente.", style: TextStyle(color: Colors.grey)),
                             )
                        ] else ...[
                             const Padding(
                               padding: EdgeInsets.all(10.0),
                               child: Text("El código será válido para una única entrada y salida.", style: TextStyle(color: Colors.grey)),
                             )
                        ]

                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _generateCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text("Generar Código de Acceso", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
          
          if (_isCameraOpen) _buildCameraOverlay(),
        ],
      )),
    ));
  }

  Widget _buildSuccessScreen() {
      return Scaffold(
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 20),
                      const Text("Acceso Creado", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Text(_generatedCode, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 5)),
                      const SizedBox(height: 10),
                      Text("Comparte este código con tu visita", style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 40),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Volver al Inicio"),
                      )
                  ],
              ),
          ),
      );
  }

  Widget _buildCameraOverlay() {
      return Container(
          color: Colors.black,
          child: Stack(
              children: [
                  const Center(child: Text("Simulación de Cámara\nEscaneando...", textAlign: TextAlign.center, style: TextStyle(color: Colors.white))),
                  // Laser effect
                  const Center(child: Divider(color: Colors.red, thickness: 2)),
                  Positioned(
                      bottom: 40,
                      left: 0, 
                      right: 0,
                      child: Center(
                          child: GestureDetector(
                              onTap: () {
                                  // Manual capture
                              },
                              child: Container(
                                  width: 70, height: 70,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4)
                                  ),
                              ),
                          )
                      ),
                  )
              ],
          ),
      );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
    );
  }

  Widget _buildRowInput(String label, TextEditingController controller, String placeholder) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 16))),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: placeholder,
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400])
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _secondaryBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label) {
    bool isSelected = _accessType == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _accessType = label;
        });
      },
      selectedColor: const Color(0xFF0A84FF), // Blue background when selected
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white), // Always white text for dark mode visibility
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF0A84FF) : Colors.transparent)),
    );
  }

  Widget _durationChip(String label) {
    final bool isSelected = _selectedDuration == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A84FF) : Theme.of(context).cardColor, // Blue background when selected
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
