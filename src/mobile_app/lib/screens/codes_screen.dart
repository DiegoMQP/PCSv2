import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';

class CodesScreen extends StatefulWidget {
  const CodesScreen({super.key});

  @override
  State<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends State<CodesScreen> {
  late Future<List<dynamic>> _codesFuture;
  String? _lastUsername;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserProvider>(context, listen: false);
    // Only refresh when we have a username and it changed
    if ((user.username.isNotEmpty) && user.username != _lastUsername) {
      _lastUsername = user.username;
      _refreshCodes();
    }
  }

  void _refreshCodes() {
    final user = Provider.of<UserProvider>(context, listen: false);
    // Debug: ensure we have a username before calling API
    if (user.username.isEmpty) {
      // Avoid calling API with empty username
      if (mounted) {
        setState(() {
          _codesFuture = Future.value([]);
        });
      }
      return;
    }
    setState(() {
      _codesFuture = ApiService().getCodes(user.username);
    });
  }

  Future<void> _deleteCode(String code) async {
    final success = await ApiService().deleteCode(code);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código eliminado')));
        _refreshCodes();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
      }
    }
  }

  void _showAddCodeDialog() {
    final nameController = TextEditingController();
    String duration = "permanent";
    // Checkbox boolean not needed if using dropdown, simpler.
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Nuevo Código"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Nombre (Ej: Casa, Visita)"),
                  ),
                  const SizedBox(height: 20),
                  const Text("Duración:"),
                  DropdownButton<String>(
                    value: duration,
                    isExpanded: true,
                    items: const [
                       DropdownMenuItem(value: "permanent", child: Text("Permanente")),
                       DropdownMenuItem(value: "30m", child: Text("30 Minutos")),
                       DropdownMenuItem(value: "4h", child: Text("4 Horas")),
                       DropdownMenuItem(value: "24h", child: Text("24 Horas")),
                       DropdownMenuItem(value: "1w", child: Text("1 Semana")),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        duration = val!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ElevatedButton(
                    onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    
                    final user = Provider.of<UserProvider>(context, listen: false);
                    final randomCode = (100000 + Random().nextInt(900000)).toString();
                    
                    final res = await ApiService().saveCode(
                        name: nameController.text,
                        code: randomCode,
                        username: user.username,
                        duration: duration
                    );
                    
                    if (mounted) {
                        Navigator.pop(context);
                        if (res['success']) {
                             _refreshCodes();
                        } else {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
                        }
                    }
                  },
                  child: const Text("Guardar"),
                ),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Mis Códigos")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCodeDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
          future: _codesFuture,
          builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
              }
              final codes = snapshot.data ?? [];
              if (codes.isEmpty) {
                  return const Center(child: Text("No tienes códigos generados"));
              }
              return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                      final codeData = codes[index];
                      return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
                          ),
                          child: Column(
                              children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                       Text(codeData['name'] ?? 'Código', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                       IconButton(
                                         icon: const Icon(Icons.delete, color: Colors.red),
                                         onPressed: () => _deleteCode(codeData['code']),
                                       )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  QrImageView(
                                      data: codeData['code'] ?? 'Error',
                                      version: QrVersions.auto,
                                      size: 200.0,
                                      backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(codeData['code'] ?? '', style: const TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.w600)),
                                  if (codeData.containsKey('expires_at') && codeData['expires_at'] != null)
                                      Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text("Expira: ${DateTime.fromMillisecondsSinceEpoch(codeData['expires_at']).toLocal()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      )
                              ],
                          ),
                      );
                  }
              );
          }
      ),
    );
  }
}
