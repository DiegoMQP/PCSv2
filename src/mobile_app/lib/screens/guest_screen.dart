import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import '../widgets/qr_card_widget.dart';

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
  Map<String, dynamic> _generatedCodeData = {};

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
            // Extract generated_code from the parsed server response
            final data = (result['data'] as Map<String, dynamic>?) ?? {};
            String code = data['generated_code']?.toString() ?? '';
            if (code.isEmpty) {
              code = (100000 + Random().nextInt(900000)).toString();
            }
            // Calculate expires_at for display (mirrors server logic)
            int? expiresAt;
            if (_accessType == 'Tiempo') {
              final durations = {'30m': 30, '4h': 240, '12h': 720, '24h': 1440};
              final mins = durations[_selectedDuration] ?? 240;
              expiresAt = DateTime.now().millisecondsSinceEpoch + (mins * 60 * 1000);
            } else if (_accessType == 'Limite' || _accessType == 'Un uso') {
              expiresAt = DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000);
            }
            // Also persist to fractionation_codes so it shows in "Mis Códigos"
            ApiService().saveCode(
              name: _nameController.text,
              code: code,
              username: user.username,
              duration: finalConfigs,
            );
            setState(() {
                _generatedCode = code;
                _generatedCodeData = {
                  'code': code,
                  'name': _nameController.text,
                  'expires_at': expiresAt,
                };
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
        leading: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(fontSize: 14)),
          ),
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
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox(
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
    final cardKey = GlobalKey();
    final user = Provider.of<UserProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('¡Acceso Creado!'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Success badge
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                  color: Color(0xFF34C759), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 14),
            const Text('¡Visita registrada!',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Comparte el código con tu visita',
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 28),
            // QR Card
            RepaintBoundary(
              key: cardKey,
              child: QrCardWidget(
                  codeData: _generatedCodeData, user: user),
            ),
            const SizedBox(height: 28),
            // Action buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir Código'),
                  onPressed: () =>
                      captureAndShare(cardKey, _generatedCode, context),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar Código'),
                  onPressed: () => copyCode(_generatedCode, context),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Volver al Inicio'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ]),
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
