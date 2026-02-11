import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CodesScreen extends StatefulWidget {
  const CodesScreen({super.key});

  @override
  State<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends State<CodesScreen> {
  late Future<List<dynamic>> _codesFuture;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false);
    _codesFuture = ApiService().getCodes(user.username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Mis Códigos")),
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
                                  Text(codeData['name'] ?? 'Código', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 20),
                                  QrImageView(
                                      data: codeData['code'] ?? 'Error',
                                      version: QrVersions.auto,
                                      size: 200.0,
                                      backgroundColor: Colors.white,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(codeData['code'] ?? '', style: const TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.w600)),
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
